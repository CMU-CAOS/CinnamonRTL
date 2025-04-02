`default_nettype none

module MultiplierAdderTest 
    #(parameter
        p_dataWidth_A = 28,
        p_dataWidth_B = 20,
        p_dataWidth_C = 20,
        p_adderTreeStageDepth = 2,
        p_pipelineRegAfterShiftMultiply = 1,
        p_firstAdderTreeStageDepth = 1,
        p_pipelineRegAfterMultiply = 0,
        localparam p_dataWidth_R = MathMax(p_dataWidth_A + p_dataWidth_B, p_dataWidth_C) + 1
    );

    logic clock;
    logic reset;

    logic [p_dataWidth_A - 1:0] io_A;
    logic [p_dataWidth_B - 1:0] io_B;
    logic [p_dataWidth_C - 1:0] io_C;
    logic [p_dataWidth_R - 1:0] io_result;

    logic [0:0] io_carry;

    logic [31:0] counter;

    logic [p_dataWidth_A - 1:0] A_delayed;
    logic [p_dataWidth_B - 1:0] B_delayed;
    logic [p_dataWidth_C - 1:0] C_delayed;
    logic [0:0] carry_delayed;


    MultiplierAdderPipelined #(
        .p_dataWidth_A(p_dataWidth_A),
        .p_dataWidth_B(p_dataWidth_B),
        .p_dataWidth_C(p_dataWidth_C),
        .p_adderTreeStageDepth(p_adderTreeStageDepth),
        .p_pipelineRegAfterShiftMultiply(p_pipelineRegAfterShiftMultiply),
        .p_firstAdderTreeStageDepth(p_firstAdderTreeStageDepth),
        .p_pipelineRegAfterMultiply(p_pipelineRegAfterMultiply)
    ) dut(.*);

    localparam MultiplierAdderPipelineStages = ComputeMultiplierAdderPipelineStages(p_dataWidth_B,p_adderTreeStageDepth,p_pipelineRegAfterShiftMultiply,p_firstAdderTreeStageDepth,p_pipelineRegAfterMultiply);

    SignalDelay #(
        .p_width(p_dataWidth_A),
        .p_delay(MultiplierAdderPipelineStages)
    ) delayA (
        .clock(clock),
        .reset(1'b0),
        .io_inData(io_A),
        .io_outData(A_delayed)
    );

    SignalDelay #(
        .p_width(p_dataWidth_B),
        .p_delay(MultiplierAdderPipelineStages)
    ) delayB (
        .clock(clock),
        .reset(1'b0),
        .io_inData(io_B),
        .io_outData(B_delayed)
    );

    SignalDelay #(
        .p_width(p_dataWidth_C),
        .p_delay(MultiplierAdderPipelineStages)
    ) delayC (
        .clock(clock),
        .reset(1'b0),
        .io_inData(io_C),
        .io_outData(C_delayed)
    );

    SignalDelay #(
        .p_width(1),
        .p_delay(MultiplierAdderPipelineStages)
    ) delayCarry (
        .clock(clock),
        .reset(1'b0),
        .io_inData(io_carry),
        .io_outData(carry_delayed)
    );


	`TestClock(clock)

    always @(posedge clock) begin
        counter <= counter + 1;
        $display("Cycle: %d, A_delayed: %d, B_delayed: %d, C_delayed: %d, Carry_Delayd: %d, Result: %d",counter,A_delayed,B_delayed,C_delayed, carry_delayed,io_result);
    end

    logic [p_dataWidth_R-1:0] reference_result;
    assign reference_result = A_delayed*B_delayed + C_delayed + carry_delayed;

	initial begin
        `TestCheck(reference_result,io_result);
		forever #1 `TestCheck(reference_result,io_result);
	end

	initial begin

        $dumpfile("multiplier_adder.vcd");
        $dumpvars(0,MultiplierAdderTest); 

        $display("Multiplier Adder Pipeline Depth: %d",MultiplierAdderPipelineStages);

        counter <= 0;
        io_A <= 34234;
        io_B <= 723;
        io_C <= 100;
        io_carry <= 1;

        #2

        io_A <= 14;
        io_B <= 9;
        io_C <= 120;
        io_carry <= 0;

        #2

        io_A <= 4;
        io_B <= 7;
        io_C <= 1345;
        io_carry <= 0;

        #2

        io_A <= 879374;
        io_B <= 73843;
        io_C <= 456;
        io_carry <= 1;

        #20

		`TestFinish("MultiplierAdderTest")
    end

endmodule : MultiplierAdderTest