`default_nettype none

// Test for 28 bit q = qH*(2^17) + 1, with R = 2^34
module MontgomeryMultiplierTest
    #(parameter
        p_dataWidth = 28,
        p_oneIterationReductionFactorLog2 = 17,
        p_numIterations = 2,
        p_adderTreeStageDepth = 2,
        p_pipelineRegAfterShiftMultiply = 1,
        p_firstAdderTreeStageDepth = 1,
        p_pipelineRegAfterMultiply = 1,
        p_pipelineRegBetweenIterations = 1,
        p_pipelineRegAfterIterations = 1,
        p_pipelineRegBeforeReduction = 0
    );

    logic clock;
    logic reset;

    logic [p_dataWidth - 1:0] io_A;
    logic [p_dataWidth - 1:0] io_B;
    logic [p_dataWidth - 1:0] io_q;
    logic [p_dataWidth - 1:0] io_result;

    logic [31:0] counter;

    logic [p_dataWidth - 1:0] A_delayed;
    logic [p_dataWidth - 1:0] B_delayed;
    logic [p_dataWidth - 1:0] q_delayed;


    NTTFriendlyMontgomeryMultiplier#(
        .p_dataWidth(p_dataWidth),
        .p_oneIterationReductionFactorLog2(p_oneIterationReductionFactorLog2),
        .p_numIterations(p_numIterations),
        .p_adderTreeStageDepth(p_adderTreeStageDepth),
        .p_pipelineRegAfterShiftMultiply(p_pipelineRegAfterShiftMultiply),
        .p_firstAdderTreeStageDepth(p_firstAdderTreeStageDepth),
        .p_pipelineRegAfterMultiply(p_pipelineRegAfterMultiply),
        .p_pipelineRegBetweenIterations(p_pipelineRegBetweenIterations),
        .p_pipelineRegAfterIterations(p_pipelineRegAfterIterations),
        .p_pipelineRegBeforeReduction(p_pipelineRegBeforeReduction)
    ) dut(.*);

    localparam PipelineStages = ComputeMontgomeryMultiplierPipelineStages(p_dataWidth, p_adderTreeStageDepth,p_pipelineRegAfterShiftMultiply,p_firstAdderTreeStageDepth,p_pipelineRegAfterMultiply, p_oneIterationReductionFactorLog2, p_numIterations,p_pipelineRegBetweenIterations,p_pipelineRegAfterIterations, p_pipelineRegBeforeReduction);

    SignalDelay #(
        .p_width(p_dataWidth),
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
    ) delayB (
        .clock(clock),
        .reset(1'b0),
        .io_inData(io_B),
        .io_outData(B_delayed)
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
        $display("Cycle: %d, A_delayed: %d, B_delayed %d, Q_delayed: %d, Result: %d",counter,A_delayed,B_delayed, q_delayed,io_result);
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

        $dumpfile("montgomery_multiplier.vcd");
        $dumpvars(0,MontgomeryMultiplierTest); 

        $display("Montgomery Reducer Pipeline Depth: %d",PipelineStages);

        counter <= 0;
        io_A <= 34234;
        io_B <= 7652;
        io_q <= 268042241;
        reference_result <= 228895654;

        #2

        io_A <= 14;
        io_q <= 265420801;
        reference_result <= 20329345;

        #2

        io_A <= 4;
        io_B <= 8986652;
        io_q <= 268042241;
        reference_result <= 266794278;

        #2

        io_A <= 2*(1<<14);
        io_q <= 265420801;
        reference_result <= 228081843;

        #40

		`TestFinish("MotgomeryMultiplierTest")
    end

endmodule : MontgomeryMultiplierTest 