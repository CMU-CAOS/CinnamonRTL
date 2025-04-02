function automatic integer ComputeMontgomeryMultiplierPipelineStages 
	(

        input integer p_dataWidth, p_adderTreeStageDepth, p_pipelineRegAfterShiftMultiply, p_firstAdderTreeStageDepth, p_pipelineRegAfterMultiply, p_oneIterationReductionFactorLog2, p_numIterations, p_pipelineRegBetweenIterations, p_pipelineRegAfterIterations, p_pipelineRegBeforeReduction
	);
    integer i = 0;
    integer pipeline_depth = ComputeMultiplierPipelineStages(p_dataWidth, p_adderTreeStageDepth, p_pipelineRegAfterShiftMultiply, p_firstAdderTreeStageDepth);
    
    pipeline_depth = pipeline_depth + ComputeMontgomeryReducerPipelineStages(p_oneIterationReductionFactorLog2,p_adderTreeStageDepth,p_pipelineRegAfterShiftMultiply,p_firstAdderTreeStageDepth,p_pipelineRegAfterMultiply,p_numIterations,p_pipelineRegBetweenIterations,p_pipelineRegAfterIterations);
    if(p_pipelineRegBeforeReduction == 1) begin
        pipeline_depth = pipeline_depth + 1;
    end 

	return pipeline_depth;

endfunction: ComputeMontgomeryMultiplierPipelineStages

// This module computes the Montgomery modular product and reduction of A and B for an NTT friendly prime q
// p_oneIterationReductionFactorLog2 = w where q = qH * (2^w) + 1
// p_numIterations is the number of iterations in the reduction algorithm
// The result will be A * B * 2^(-w*numIterations) mod q 

// p_pipelineRegBeforeReduction: [0/1] controls whether a pipeline register is added between the multiply and Montgomery reduction 
module NTTFriendlyMontgomeryMultiplier
    #(parameter
        p_dataWidth = 0,
        p_oneIterationReductionFactorLog2 = 0,
        p_numIterations = 0,
        p_adderTreeStageDepth = 1,
        p_pipelineRegAfterShiftMultiply = 0,
        p_firstAdderTreeStageDepth = 0,
        p_pipelineRegAfterMultiply = 0,
        p_pipelineRegBetweenIterations = 1,
        p_pipelineRegAfterIterations = 1,
        p_pipelineRegBeforeReduction = 0
    )(
        input logic clock,
        input logic [p_dataWidth-1:0] io_A, io_B, io_q,
        output logic [p_dataWidth-1:0] io_result
    );

    logic [2*p_dataWidth-1:0] product;
    logic [2*p_dataWidth-1:0] product_pipeline_reg;
    logic [p_dataWidth-1:0] q_delayed, q_delayed_pipeline_reg;

    MultiplierPipelined #(
        .p_dataWidth_A(p_dataWidth),
        .p_dataWidth_B(p_dataWidth),
        .p_adderTreeStageDepth(p_adderTreeStageDepth),
        .p_pipelineRegAfterShiftMultiply(p_pipelineRegAfterShiftMultiply),
        .p_firstAdderTreeStageDepth(p_firstAdderTreeStageDepth)
    ) multiplier (
        .clock(clock),
        .io_A(io_A),
        .io_B(io_B),
        .io_result(product)
    );

    localparam MultiplierDelay = ComputeMultiplierPipelineStages(p_dataWidth, p_adderTreeStageDepth, p_pipelineRegAfterShiftMultiply, p_firstAdderTreeStageDepth);
    localparam q_DelayTime = p_pipelineRegBeforeReduction == 1 ? MultiplierDelay + 1 : MultiplierDelay;

    generate
        if(p_pipelineRegBeforeReduction== 1) begin
            always_ff @(posedge clock) begin
                product_pipeline_reg <= product;
            end
        end else begin
            assign product_pipeline_reg = product;
        end
    endgenerate

    SignalDelay #(
        .p_width(p_dataWidth),
        .p_delay(q_DelayTime)
    ) delay_q (
        .clock(clock),
        .reset(1'b0),
        .io_inData(io_q),
        .io_outData(q_delayed)
    );

    NTTFriendlyMontgomeryModularReducer #(
        .p_dataWidth(p_dataWidth),
        .p_oneIterationReductionFactorLog2(p_oneIterationReductionFactorLog2),
        .p_numIterations(p_numIterations),
        .p_adderTreeStageDepth(p_adderTreeStageDepth),
        .p_pipelineRegAfterShiftMultiply(p_pipelineRegAfterShiftMultiply),
        .p_firstAdderTreeStageDepth(p_firstAdderTreeStageDepth),
        .p_pipelineRegAfterMultiply(p_pipelineRegAfterMultiply),
        .p_pipelineRegBetweenIterations(p_pipelineRegBetweenIterations),
        .p_pipelineRegAfterIterations(p_pipelineRegAfterIterations)
    ) montgomeryModularReducer (
        .clock(clock),
        .io_A(product_pipeline_reg),
        .io_q(q_delayed),
        .io_result(io_result)
    );

endmodule: NTTFriendlyMontgomeryMultiplier