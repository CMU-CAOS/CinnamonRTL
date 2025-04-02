`default_nettype none

function automatic integer RoundUpToPowerOf2
    (
        input integer A
    );

    return A  == 1 << $clog2(A) ? A : 1 << ($clog2(A) + 1);
endfunction: RoundUpToPowerOf2

function automatic integer ComputeLastAdderTreeDepth 
	(
		input integer totalAdderTreeDepth, firstAdderTreeStageDepth, adderTreeStageDepth
	);

    int i = 0;
    for(i = firstAdderTreeStageDepth; i < (totalAdderTreeDepth - adderTreeStageDepth); i=i+adderTreeStageDepth);

	return totalAdderTreeDepth - i;

endfunction: ComputeLastAdderTreeDepth

function automatic integer ComputeMultiplierPipelineStages 
	(

        input integer p_dataWidth_B, p_adderTreeStageDepth, p_pipelineRegAfterShiftMultiply, p_firstAdderTreeStageDepth
	);

    integer padded_dataWidth_B = RoundUpToPowerOf2(p_dataWidth_B);
    integer firstAdderTreeStageDepth = p_pipelineRegAfterShiftMultiply == 1 ? p_firstAdderTreeStageDepth : p_adderTreeStageDepth;
    integer totalAdderTreeDepth = $clog2(padded_dataWidth_B);
    integer pipeline_depth = 0; 

    if(p_pipelineRegAfterShiftMultiply) begin
        pipeline_depth = pipeline_depth+1;
    end

    if(firstAdderTreeStageDepth < totalAdderTreeDepth) begin
        pipeline_depth++;
        for(integer j = firstAdderTreeStageDepth; j < (totalAdderTreeDepth - p_adderTreeStageDepth); j = j+p_adderTreeStageDepth ) begin
            pipeline_depth = pipeline_depth+1;
        end
    end

	return pipeline_depth;

endfunction: ComputeMultiplierPipelineStages


// This moduel computes the bitwise partial product of the two values.
// Purely Combinational 
module MultiplierUnaggregated
    #(parameter
        p_dataWidth_A = 0,
        p_dataWidth_B = p_dataWidth_A,
        localparam p_dataWidth_R = p_dataWidth_A + p_dataWidth_B // datawidth of the result
    )
    (
        input   logic [p_dataWidth_A-1:0] io_A,
        input   logic [p_dataWidth_B-1:0] io_B,
        output  logic [p_dataWidth_B-1:0][p_dataWidth_R-1:0] io_result
    );

    genvar i;
    generate 
        for(i = 0; i < p_dataWidth_B; i++) begin
            assign io_result[i] = io_B[i] == 1'b1 ? {{(p_dataWidth_B - i ){1'b0}}, io_A, {i{1'b0}}} : 0;
        end
    endgenerate

endmodule: MultiplierUnaggregated

// This module implements an adder tree that computes the sum of the inputs
// Purely Combinational 
module AdderTree
    #(parameter
        p_dataWidth = 0,
        p_numInputs = 0
    )
    (
        input   logic [p_numInputs-1:0][p_dataWidth-1:0] io_inputs,
        output  logic [p_dataWidth-1:0] io_result
    );

    if(p_numInputs != (1 << $clog2(p_numInputs))) begin
        // $error("Number of inputs for the adder tree must be a power of 2");
    end

    logic [p_dataWidth-1:0] intermediate_sum [$clog2(p_numInputs)-1:0][p_numInputs-1:0];
    genvar i,j;
    generate 
        for(i = p_numInputs/2; i > 0; i=i/2) begin
            if(i == p_numInputs/2) begin
                for(j = 0; j < i; j=j+1) begin
                    assign intermediate_sum[$clog2(i)][j] = io_inputs[2*j] + io_inputs[2*j+1];
                end
            end 
            else begin
                for(j = 0; j < i; j=j+1) begin
                    assign intermediate_sum[$clog2(i)][j] = intermediate_sum[$clog2(i) + 1][2*j] + intermediate_sum[$clog2(i) + 1][2*j+1];
                end
            end
        end
    endgenerate
    assign io_result = intermediate_sum[0][0];

endmodule: AdderTree

// This module implements a shift multiplier and adder tree to aggregate the partial products
// Parameters can be set to add pipeline stages 
// p_adderTreeStageDepth: Int Default Max depth of the adder tree generated in a single pipeline stage
// p_pipelineRegAfterShiftMultiply: [0/1] -> Insert a pipeline register after the partital shift multiply before proceeding to the adder tree
// p_firstAdderTreeStageDepth: Int Max depth of the first stage of adder tree generated after the shift multiply. This parameter is only to be used if
//                              p_pipelineRegAfterShiftMultiply = 0.
module MultiplierPipelined
    #(parameter
        p_dataWidth_A = 32,
        p_dataWidth_B = p_dataWidth_A,
        p_adderTreeStageDepth = 1,
        p_pipelineRegAfterShiftMultiply = 0,
        p_firstAdderTreeStageDepth = 1,
        localparam p_dataWidth_R = p_dataWidth_A + p_dataWidth_B // datawidth of the result
    )
    (
        input   logic clock,
        input   logic [p_dataWidth_A-1:0] io_A,
        input   logic [p_dataWidth_B-1:0] io_B,
        output  logic [p_dataWidth_R-1:0] io_result
    );
    
    // If p_dataWidth_B is not a multiple of 2, pad B to the nearest power of 2 width
    localparam padded_dataWidth_B= RoundUpToPowerOf2(p_dataWidth_B);
    localparam padded_dataWidth_R= p_dataWidth_A + padded_dataWidth_B;
    logic [padded_dataWidth_B- 1: 0] B_padded;
    assign B_padded = {{(padded_dataWidth_B - p_dataWidth_B){1'b0}}, io_B};

    logic [padded_dataWidth_B-1:0][padded_dataWidth_R-1:0] intermediate_product_padded;
    logic [padded_dataWidth_B-1:0][padded_dataWidth_R-1:0] intermediate_product_padded_next;

    MultiplierUnaggregated #(
        .p_dataWidth_A(p_dataWidth_A),
        .p_dataWidth_B(padded_dataWidth_B)
    ) multiplier_unaggregated(.io_A(io_A), .io_B(B_padded), .io_result(intermediate_product_padded));

    localparam firstAdderTreeStageDepth = p_pipelineRegAfterShiftMultiply == 1 ? p_firstAdderTreeStageDepth : p_adderTreeStageDepth;

    generate
        if(p_pipelineRegAfterShiftMultiply == 1) begin
            always_ff @( posedge clock ) begin
                intermediate_product_padded_next <= intermediate_product_padded;
            end
        end else begin
            always_comb begin
                intermediate_product_padded_next = intermediate_product_padded;
            end
        end
    endgenerate
    
    localparam  totalAdderTreeDepth = $clog2(padded_dataWidth_B);

    logic [padded_dataWidth_B-1:0][padded_dataWidth_R-1:0] intermediate_sum_padded [totalAdderTreeDepth-1:0];
    logic [padded_dataWidth_B-1:0][padded_dataWidth_R-1:0] intermediate_sum_padded_next [totalAdderTreeDepth-1:0];

    genvar i;
    generate
        if(firstAdderTreeStageDepth >= totalAdderTreeDepth) begin
            AdderTree#(
                .p_dataWidth(padded_dataWidth_R),
                .p_numInputs(padded_dataWidth_B)
            ) AdderTree(.io_inputs(intermediate_product_padded_next), .io_result(intermediate_sum_padded[totalAdderTreeDepth-1][0]));
        end
        else begin 
            localparam firstAdderTreeInputs = (1 << firstAdderTreeStageDepth);
            for(i = 0; i < padded_dataWidth_B; i= i+firstAdderTreeInputs) begin
                AdderTree#(
                    .p_dataWidth(padded_dataWidth_R),
                    .p_numInputs(firstAdderTreeInputs)
                ) AdderTree(.io_inputs(intermediate_product_padded_next[i+firstAdderTreeInputs-1:i]), .io_result(intermediate_sum_padded[firstAdderTreeStageDepth-1][i/firstAdderTreeInputs]));

                always_ff @(posedge clock) begin
                    intermediate_sum_padded_next[firstAdderTreeStageDepth-1][i/firstAdderTreeInputs] <= intermediate_sum_padded[firstAdderTreeStageDepth-1][i/firstAdderTreeInputs];
                end

            end
            localparam lastAdderTreeDepth= ComputeLastAdderTreeDepth(totalAdderTreeDepth,firstAdderTreeStageDepth,p_adderTreeStageDepth);
            for(genvar j = firstAdderTreeStageDepth; j < (totalAdderTreeDepth - p_adderTreeStageDepth); j = j+p_adderTreeStageDepth ) begin
                localparam adderTreeInputs = (1 << p_adderTreeStageDepth);
                for(i = 0; i < padded_dataWidth_B/(1 << j); i= i+adderTreeInputs) begin
                    AdderTree#(
                        .p_dataWidth(padded_dataWidth_R),
                        .p_numInputs(adderTreeInputs)
                    ) AdderTree(.io_inputs(intermediate_sum_padded_next[j-1][i+adderTreeInputs-1:i]), .io_result(intermediate_sum_padded[j+p_adderTreeStageDepth-1][i/adderTreeInputs]));

                    always_ff @(posedge clock) begin
                        intermediate_sum_padded_next[j+p_adderTreeStageDepth-1][i/adderTreeInputs] <= intermediate_sum_padded[j+p_adderTreeStageDepth-1][i/adderTreeInputs];
                    end
                end
            end

            localparam lastAdderTreeInputs = (1 << (lastAdderTreeDepth));
            AdderTree#(
                .p_dataWidth(padded_dataWidth_R),
                .p_numInputs(lastAdderTreeInputs)
            ) AdderTree(.io_inputs(intermediate_sum_padded_next[totalAdderTreeDepth -lastAdderTreeDepth - 1][lastAdderTreeInputs-1:0]), .io_result(intermediate_sum_padded[totalAdderTreeDepth-1][0]));
        end 
    endgenerate

    assign io_result = intermediate_sum_padded[totalAdderTreeDepth-1][0][p_dataWidth_R-1:0];
    
endmodule : MultiplierPipelined
