function automatic integer ComputeMontgomeryReducerPipelineStages 
	(

        input integer p_dataWidth_B, p_adderTreeStageDepth, p_pipelineRegAfterShiftMultiply, p_firstAdderTreeStageDepth, p_pipelineRegAfterMultiply, p_numIterations, p_pipelineRegBetweenIterations, p_pipelineRegAfterIterations
	);
    integer i = 0;
    integer pipeline_depth = 0;
    for(i = 0; i < p_numIterations - 1; i++) begin
        pipeline_depth = pipeline_depth + ComputeMultiplierAdderPipelineStages(p_dataWidth_B, p_adderTreeStageDepth, p_pipelineRegAfterShiftMultiply, p_firstAdderTreeStageDepth,p_pipelineRegAfterMultiply); 
        if(p_pipelineRegBetweenIterations == 1) begin
            pipeline_depth = pipeline_depth + 1;
        end 
    end
    pipeline_depth = pipeline_depth + ComputeMultiplierAdderPipelineStages(p_dataWidth_B, p_adderTreeStageDepth, p_pipelineRegAfterShiftMultiply, p_firstAdderTreeStageDepth,p_pipelineRegAfterMultiply); 
    if(p_pipelineRegAfterIterations == 1) begin
        pipeline_depth = pipeline_depth + 1;
    end 

	return pipeline_depth;

endfunction: ComputeMontgomeryReducerPipelineStages


// This module computes the Montgomery modular reduction of A for an NTT friendly prime q
// p_oneIterationReductionFactorLog2 = w where q = qH * (2^w) + 1
// p_numIterations is the number of iterations in the reduction algorithm
// The result will be A * 2^(-w*numIterations) mod q 

// p_pipelineRegBetweenIterations: [0/1] controls whether a pipeline register is added between two iterations
// See module MultiplierAdderPipelined for meaning of other pipeline parameters
// p_pipelineRegAfterIterations: [0/1] controls whether a pipeline register is added after all iterations


module NTTFriendlyMontgomeryModularReducer 
    #(parameter
        p_dataWidth = 0,
        p_oneIterationReductionFactorLog2 = 0,
        p_numIterations = 0,
        p_adderTreeStageDepth = 1,
        p_pipelineRegAfterShiftMultiply = 0,
        p_firstAdderTreeStageDepth = 0,
        p_pipelineRegAfterMultiply = 0,
        p_pipelineRegBetweenIterations = 1,
        p_pipelineRegAfterIterations = 1
    )(
        input logic clock,
        input logic [2*p_dataWidth-1:0] io_A,
        input logic [p_dataWidth-1:0] io_q,
        output logic [p_dataWidth-1:0] io_result
    );
    
    localparam w = p_oneIterationReductionFactorLog2;
    
    logic signed [2*p_dataWidth - 1: 0] intermediate_A [p_numIterations-1:0];
    logic signed [2*p_dataWidth - 1: 0] intermediate_result [p_numIterations-1:0];
    logic [p_dataWidth - 1: 0] q_pipelined [p_numIterations-1:0];

    genvar i;
    generate
        for(i = 0; i < p_numIterations; i++) begin

            localparam MultiplierAdderPipelineStages = ComputeMultiplierAdderPipelineStages(w, p_adderTreeStageDepth, p_pipelineRegAfterShiftMultiply, p_firstAdderTreeStageDepth, p_pipelineRegAfterMultiply);
            logic [p_dataWidth-1:0] q_delayed;

            if (i == 0) begin

                logic [p_dataWidth - 1 - w: 0] q_High;
                assign q_High = io_q[p_dataWidth - 1: w];

                logic signed [2*p_dataWidth - w -1: 0] A_High;
                logic [w - 1: 0] A_low;
                logic signed [w-1: 0] A_low_2sComplement;
                logic carry;

                assign {A_High, A_low} = io_A;
                assign A_low_2sComplement = -A_low;
                assign carry = A_low_2sComplement[w-1] | A_low[w-1];

                MultiplierAdderPipelined #(
                    .p_dataWidth_A(p_dataWidth - w),
                    .p_dataWidth_B(w),
                    .p_dataWidth_C(2*p_dataWidth - w),
                    .p_adderTreeStageDepth(p_adderTreeStageDepth),
                    .p_pipelineRegAfterShiftMultiply(p_pipelineRegAfterShiftMultiply),
                    .p_firstAdderTreeStageDepth(p_firstAdderTreeStageDepth),
                    .p_pipelineRegAfterMultiply(p_pipelineRegAfterMultiply)
                ) multiplierAdder (
                    .clock(clock),
                    .io_A(q_High),
                    .io_B(A_low_2sComplement),
                    .io_C(A_High),
                    .io_carry(carry),
                    .io_result(intermediate_result[i][2*p_dataWidth - w: 0])
                );
                assign intermediate_result[i][2*p_dataWidth - 1: 2*p_dataWidth -w + 1] = 0;

                SignalDelay #(
                    .p_width(p_dataWidth),
                    .p_delay(MultiplierAdderPipelineStages)
                ) delay_q (
                    .clock(clock),
                    .reset(1'b0),
                    .io_inData(io_q),
                    .io_outData(q_delayed)
                );

            end else begin

                logic [p_dataWidth - 1 - w: 0] q_High;
                assign q_High = q_pipelined[i-1][p_dataWidth - 1: w];

                logic signed [2*p_dataWidth - w -i*w -1: 0] A_High;
                logic [w - 1: 0] A_low;
                logic signed [w-1: 0] A_low_2sComplement;
                logic carry;

                assign {A_High, A_low} = intermediate_A[i-1][2*p_dataWidth -i * w - 1 : 0];
                assign A_low_2sComplement = -A_low;
                assign carry = A_low_2sComplement[w-1] | A_low[w-1];

                localparam resultWidth = MathMax(p_dataWidth,2*p_dataWidth -w*i - w ) + 1;

                MultiplierAdderPipelined #(
                    .p_dataWidth_A(p_dataWidth - w),
                    .p_dataWidth_B(w),
                    .p_dataWidth_C(2*p_dataWidth - i*w -w),
                    .p_adderTreeStageDepth(p_adderTreeStageDepth),
                    .p_pipelineRegAfterShiftMultiply(p_pipelineRegAfterShiftMultiply),
                    .p_firstAdderTreeStageDepth(p_firstAdderTreeStageDepth),
                    .p_pipelineRegAfterMultiply(p_pipelineRegAfterMultiply)
                ) multiplierAdder (
                    .clock(clock),
                    .io_A(q_High),
                    .io_B(A_low_2sComplement),
                    .io_C(A_High),
                    .io_carry(carry),
                    .io_result(intermediate_result[i][resultWidth - 1: 0])
                );
                assign intermediate_result[i][2*p_dataWidth - 1: resultWidth] = 0;

                SignalDelay #(
                    .p_width(p_dataWidth),
                    .p_delay(MultiplierAdderPipelineStages)
                ) delay_q (
                    .clock(clock),
                    .reset(1'b0),
                    .io_inData(q_pipelined[i-1]),
                    .io_outData(q_delayed)
                );

            end

            if((p_pipelineRegBetweenIterations == 1 && i != p_numIterations - 1) || (p_pipelineRegAfterIterations && i == p_numIterations - 1)) begin
                always_ff @(posedge clock) begin
                    q_pipelined[i] <= q_delayed;
                    intermediate_A[i] <= intermediate_result[i];
                end
            end else begin
                always_comb begin
                    intermediate_A[i] = intermediate_result[i];
                    q_pipelined[i] = q_delayed;
                end
            end
        end


    endgenerate

    logic signed [p_dataWidth:0] intermediate_result_after_iterations; 
    logic signed [p_dataWidth:0] intermediate_result_subtract_q; 

    assign intermediate_result_after_iterations = intermediate_A[p_numIterations - 1][p_dataWidth:0];
    assign intermediate_result_subtract_q = intermediate_result_after_iterations - q_pipelined[p_numIterations-1];

    assign io_result = intermediate_result_subtract_q < 0 ? intermediate_result_after_iterations[p_dataWidth -1 : 0] : intermediate_result_subtract_q[p_dataWidth -1 : 0];

endmodule: NTTFriendlyMontgomeryModularReducer
