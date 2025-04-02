`default_nettype none

function automatic integer ComputeMultiplierAdderPipelineStages 
	(

        input integer p_dataWidth_B, p_adderTreeStageDepth, p_pipelineRegAfterShiftMultiply, p_firstAdderTreeStageDepth, p_pipelineRegAfterMultiply
	);
    integer pipeline_depth = ComputeMultiplierPipelineStages(p_dataWidth_B, p_adderTreeStageDepth, p_pipelineRegAfterShiftMultiply, p_firstAdderTreeStageDepth); 

    if(p_pipelineRegAfterMultiply) begin
        pipeline_depth = pipeline_depth+1;
    end

	return pipeline_depth;

endfunction: ComputeMultiplierAdderPipelineStages


// This module computes io_result = io_A*io_B + io_C + carry
// See module MultiplierPipelined for the pipelining parameters
// p_pipelineRegAfterMultiply : [0/1] inserts a pipeline register after the product is computed and before the sum is computed

module MultiplierAdderPipelined
    #(parameter
        p_dataWidth_A = 32,
        p_dataWidth_B = p_dataWidth_A,
        p_dataWidth_C = p_dataWidth_A,
        p_adderTreeStageDepth = 1,
        p_pipelineRegAfterShiftMultiply = 1,
        p_firstAdderTreeStageDepth = 1,
        p_pipelineRegAfterMultiply = 1,
        localparam p_dataWidth_P = p_dataWidth_A + p_dataWidth_B, // datawidth of the product
        localparam p_dataWidth_R = MathMax(p_dataWidth_P, p_dataWidth_C) + 1 // datawidth of the result
    )
    (
        input   logic clock,
        input   logic [p_dataWidth_A-1:0] io_A,
        input   logic [p_dataWidth_B-1:0] io_B,
        input   logic [p_dataWidth_C-1:0] io_C,
        input   logic io_carry,
        output  logic [p_dataWidth_R-1:0] io_result
    );


    logic [p_dataWidth_P - 1: 0] product;

    MultiplierPipelined #(
        .p_dataWidth_A(p_dataWidth_A),
        .p_dataWidth_B(p_dataWidth_B),
        .p_adderTreeStageDepth(p_adderTreeStageDepth),
        .p_pipelineRegAfterShiftMultiply(p_pipelineRegAfterShiftMultiply),
        .p_firstAdderTreeStageDepth(p_firstAdderTreeStageDepth)
    ) multiplier (
        .clock(clock),
        .io_A(io_A),
        .io_B(io_B),
        .io_result(product)
    );


    logic [p_dataWidth_C: 0]  C_plus_carry, C_plus_carry_delayed;

    always_comb begin
        C_plus_carry = io_C + io_carry;
    end

    localparam multiplierPipelineStages = ComputeMultiplierPipelineStages( p_dataWidth_B, p_adderTreeStageDepth, p_pipelineRegAfterShiftMultiply, p_firstAdderTreeStageDepth);

    SignalDelay #(
        .p_width(p_dataWidth_C + 1),
        .p_delay(multiplierPipelineStages)
    ) signalDelay (
        .clock(clock),
        .reset(1'b0),
        .io_inData(C_plus_carry),
        .io_outData(C_plus_carry_delayed)
    );

    generate
        if(p_pipelineRegAfterMultiply == 1) begin
            always_ff @(posedge clock) begin
                io_result <= C_plus_carry_delayed + product;
            end
        end else begin    
            always_comb begin
                io_result = C_plus_carry_delayed + product;
            end
        end
    endgenerate
    
endmodule : MultiplierAdderPipelined
