`default_nettype none

module MultiplierTest 
    #(parameter
        p_dataWidth_A = 28,
        p_dataWidth_B = 20,
        p_adderTreeStageDepth = 1,
        p_pipelineRegAfterShiftMultiply = 1,
        p_firstAdderTreeStageDepth = 1,
        localparam p_dataWidth_R = p_dataWidth_A + p_dataWidth_B
    );

    logic clock;
    logic reset;

    logic [p_dataWidth_A - 1:0] io_A;
    logic [p_dataWidth_B - 1:0] io_B;
    logic [p_dataWidth_R - 1:0] io_result;

    logic [31:0] counter;

    logic [p_dataWidth_A - 1:0] A_delayed;
    logic [p_dataWidth_B - 1:0] B_delayed;


    MultiplierPipelined #(
        .p_dataWidth_A(p_dataWidth_A),
        .p_dataWidth_B(p_dataWidth_B),
        .p_adderTreeStageDepth(p_adderTreeStageDepth),
        .p_pipelineRegAfterShiftMultiply(p_pipelineRegAfterShiftMultiply),
        .p_firstAdderTreeStageDepth(p_firstAdderTreeStageDepth)
    ) dut(.*);

    localparam MultiplierPipelineStages = ComputeMultiplierPipelineStages(p_dataWidth_B,p_adderTreeStageDepth,p_pipelineRegAfterShiftMultiply,p_firstAdderTreeStageDepth);

    SignalDelay #(
        .p_width(p_dataWidth_A),
        .p_delay(MultiplierPipelineStages)
    ) delayA (
        .clock(clock),
        .reset(1'b0),
        .io_inData(io_A),
        .io_outData(A_delayed)
    );

    SignalDelay #(
        .p_width(p_dataWidth_B),
        .p_delay(MultiplierPipelineStages)
    ) delayB (
        .clock(clock),
        .reset(1'b0),
        .io_inData(io_B),
        .io_outData(B_delayed)
    );

	`TestClock(clock)

    always @(posedge clock) begin
        counter <= counter + 1;
        $display("Cycle: %d, A_delayed: %d, B_delayed: %d, Result: %d",counter,A_delayed,B_delayed,io_result);
    end

    logic [p_dataWidth_R-1:0] reference_product;
    assign reference_product = A_delayed*B_delayed;

	initial begin
        `TestCheck(A_delayed*B_delayed,io_result);
		forever #1 `TestCheck(reference_product,io_result);
	end

	initial begin

        $dumpfile("multiplier.vcd");
        $dumpvars(0,MultiplierTest); 

        $display("Multiplier Pipeline Depth: %d",MultiplierPipelineStages);

        counter <= 0;
        io_A <= 34234;
        io_B <= 723;

        #2

        io_A <= 14;
        io_B <= 9;

        #2

        io_A <= 4;
        io_B <= 7;

        #2

        io_A <= 879374;
        io_B <= 73843;

        #20

		`TestFinish("MultiplierTest")
    end

endmodule : MultiplierTest