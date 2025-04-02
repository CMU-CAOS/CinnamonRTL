`default_nettype none

module MontgomeryReducerTest 
    #(parameter
        p_dataWidth = 28,
        p_oneIterationReductionFactorLog2 = 17,
        p_numIterations = 2,
        p_adderTreeStageDepth = 2,
        p_pipelineRegAfterShiftMultiply = 1,
        p_firstAdderTreeStageDepth = 1,
        p_pipelineRegAfterMultiply = 0,
        p_pipelineRegBetweenIterations = 1,
        p_pipelineRegAfterIterations = 0
    );

    logic clock;
    logic reset;

    logic [2*p_dataWidth - 1:0] io_A;
    logic [p_dataWidth - 1:0] io_q;
    logic [p_dataWidth - 1:0] io_result;

    logic [31:0] counter;

    logic [2*p_dataWidth - 1:0] A_delayed;
    logic [p_dataWidth - 1:0] q_delayed;


    NTTFriendlyMontgomeryModularReducer#(
        .p_dataWidth(p_dataWidth),
        .p_oneIterationReductionFactorLog2(p_oneIterationReductionFactorLog2),
        .p_numIterations(p_numIterations),
        .p_adderTreeStageDepth(p_adderTreeStageDepth),
        .p_pipelineRegAfterShiftMultiply(p_pipelineRegAfterShiftMultiply),
        .p_firstAdderTreeStageDepth(p_firstAdderTreeStageDepth),
        .p_pipelineRegAfterMultiply(p_pipelineRegAfterMultiply),
        .p_pipelineRegBetweenIterations(p_pipelineRegBetweenIterations),
        .p_pipelineRegAfterIterations(p_pipelineRegAfterIterations)
    ) dut(.*);

    localparam PipelineStages = ComputeMontgomeryReducerPipelineStages(p_oneIterationReductionFactorLog2,p_adderTreeStageDepth,p_pipelineRegAfterShiftMultiply,p_firstAdderTreeStageDepth,p_pipelineRegAfterMultiply,p_numIterations,p_pipelineRegBetweenIterations,p_pipelineRegAfterIterations);

    SignalDelay #(
        .p_width(2*p_dataWidth),
        .p_delay(PipelineStages)
    ) delayA (
        .clock(clock),
        .reset(1'b0),
        .io_inData(io_A),
        .io_outData(A_delayed)
    );

    SignalDelay #(
        .p_width(p_dataWidth),
        .p_delay(PipelineStages)
    ) delayQ (
        .clock(clock),
        .reset(1'b0),
        .io_inData(io_q),
        .io_outData(q_delayed)
    );

	`TestClock(clock)

    always @(posedge clock) begin
        counter <= counter + 1;
        $display("Cycle: %d, A_delayed: %d, Q_delayed: %d, Result: %d",counter,A_delayed,q_delayed,io_result);
    end

    logic [p_dataWidth-1:0] reference_result, reference_result_delayed;
    SignalDelay #(
        .p_width(p_dataWidth),
        .p_delay(PipelineStages)
    ) delayReferenceResult (
        .clock(clock),
        .reset(1'b0),
        .io_inData(reference_result),
        .io_outData(reference_result_delayed)
    );

	initial begin
        `TestCheck(reference_result_delayed,io_result);
		forever #2 `TestCheck(reference_result_delayed,io_result);
	end

	initial begin

        $dumpfile("montgomery_reducer.vcd");
        $dumpvars(0,MontgomeryReducerTest); 

        $display("Montgomery Reducer Pipeline Depth: %d",PipelineStages);

        counter <= 0;
        io_A <= 34234;
        io_q <= 268042241;
        reference_result <= 32887156;

        #2

        io_A <= 14;
        io_q <= 265420801;
        reference_result <= 57408750;

        #2

        io_A <= 4;
        io_q <= 268042241;
        reference_result <= 16728100;

        #2

        io_A <= 456;
        io_q <= 265420801;
        reference_result <= 11939393;

        #40

		`TestFinish("MotgomeryReducerTest")
    end

endmodule : MontgomeryReducerTest 