`default_nettype none

/*
 * Test modular adder for 4 bit
 */
module ModularAdder4Test
	#(parameter
		p_dataWidth = 4
	);

	logic clock, reset;
	logic [p_dataWidth-1:0] io_A, io_B, io_mod, io_result;

	ModularAdder #(
		.p_dataWidth(p_dataWidth)
	) dut(.*);

	`TestClock(clock)
	initial begin
		`TestReset(reset)

		// (3 + 7) % 13 = 10
		io_A = 3;
		io_B = 7;
		io_mod = 13;
		@(negedge clock);
		`TestCheck(io_result, 10)

		// (14 + 12) % 15 = 11
		io_A = 14;
		io_B = 12;
		io_mod = 15;
		@(negedge clock);
		`TestCheck(io_result, 11)

		// (6 + 3) % 8 = 1
		io_A = 6;
		io_B = 3;
		io_mod = 8;
		@(negedge clock);
		`TestCheck(io_result, 1)

		`TestFinish("ModularAdder4Test")
	end

endmodule: ModularAdder4Test


/*
 * Test modular adder for 8 bit
 */
module ModularAdder8Test
	#(parameter
		p_dataWidth = 8
	);

	logic clock, reset;
	logic [p_dataWidth-1:0] io_A, io_B, io_mod, io_result;

	ModularAdder #(
		.p_dataWidth(p_dataWidth)
	) dut(.*);

	`TestClock(clock)
	initial begin
		`TestReset(reset)

		// (252 + 254) % 255 = 251
		io_A = 252;
		io_B = 254;
		io_mod = 255;
		@(negedge clock);
		`TestCheck(io_result, 251)

		// (0 + 90) % 101 = 90
		io_A = 0;
		io_B = 90;
		io_mod = 101;
		@(negedge clock);
		`TestCheck(io_result, 90)

		`TestFinish("ModularAdder8Test")
	end

endmodule: ModularAdder8Test


/*
 * Test modular subtractor for 10 bit
 */
module ModularSubtractor10Test
	#(parameter
		p_dataWidth = 10
	);

	logic clock, reset;
	logic [p_dataWidth-1:0] io_A, io_B, io_mod, io_result;

	ModularSubtractor #(
		.p_dataWidth(p_dataWidth)
	) dut(.*);

	`TestClock(clock)
	initial begin
		`TestReset(reset)

		// (1 - 5) % 1023 = 1019
		io_A = 1;
		io_B = 5;
		io_mod = 1023;
		@(negedge clock);
		`TestCheck(io_result, 1019)

		// (73 - 10) % 512 = 63
		io_A = 73;
		io_B = 10;
		io_mod = 512;
		@(negedge clock);
		`TestCheck(io_result, 63)

		`TestFinish("ModularSubtractor10Test")
	end

endmodule: ModularSubtractor10Test



/*
 * Test modular multiplier for 9 bit
 */
module ModularMultiplier45Test
	#(parameter
		p_dataWidth = 45
	);

	logic clock, reset;
	logic io_start, io_done;
	logic [p_dataWidth-1:0] io_A, io_B, io_mod, io_result;

	ModularMultiplier #(
		.p_dataWidth(p_dataWidth)
	) m_multiplier(.*);

	`TestClock(clock)
	integer i;
	initial begin
		`TestReset(reset)

		// (400 * 231) % 471 = 84
		// (361 * 13) % 401 = 282
		// (117 * 169) % 173 = 51
		io_A = 400;
		io_B = 231;
		io_mod = 471;
		@(negedge clock);
		io_A = 361;
		io_B = 13;
		io_mod = 401;
		@(negedge clock);
		io_A = 117;
		io_B = 169;
		io_mod = 173;

		// Wait for result
		for (i = 0;i < `ModularMultiplierDelay(p_dataWidth) - 2;i++) begin
			@(negedge clock);
		end
		`TestCheck(io_result, 84);
		@(negedge clock);
		`TestCheck(io_result, 282);
		@(negedge clock);
		`TestCheck(io_result, 51);

		`TestFinish("ModularMultiplier45Test")
	end

endmodule: ModularMultiplier45Test


/*
 * Test modular multiplier pipelined for 4 bit
 */
module ModularMultiplier16Test
	#(parameter
		p_dataWidth = 16
	);

	logic clock, reset;
	logic io_start, io_done;
	logic [p_dataWidth-1:0] io_A, io_B, io_mod, io_result;

	ModularMultiplier #(
		.p_dataWidth(p_dataWidth)
	) m_multiplier(.*);

	`TestClock(clock)
	integer i;
	initial begin
		`TestReset(reset)

		// (12 * 9) % 15 = 3
		// (9 * 4) % 13 = 10
		// (13 * 13) % 14 = 1
		// (4 * 3) % 7 = 5
		io_A = 12;
		io_B = 9;
		io_mod = 15;
		@(negedge clock);
		io_A = 9;
		io_B = 4;
		io_mod = 13;
		@(negedge clock);
		io_A = 13;
		io_B = 13;
		io_mod = 14;
		@(negedge clock);
		io_A = 4;
		io_B = 3;
		io_mod = 7;

		// Wait for result
		for (i = 0;i < `ModularMultiplierDelay(p_dataWidth) - 3;i++) begin
			@(negedge clock);
		end
		`TestCheck(io_result, 3);
		@(negedge clock);
		`TestCheck(io_result, 10);
		@(negedge clock);
		`TestCheck(io_result, 1);
		@(negedge clock);
		`TestCheck(io_result, 5);

		`TestFinish("ModularMultiplier16Test")
	end

endmodule: ModularMultiplier16Test


/*
 * Test multiplier
 */
module MultiplierTest
	#(parameter
		p_dataWidth = 16
	);

	logic clock, reset;
	logic io_start, io_done;
	logic [p_dataWidth-1:0] io_A, io_B, io_mod, io_result;

	Multiplier #(
		.p_dataWidth(p_dataWidth)
	) m_multiplier(.*);

	`TestClock(clock)
	integer i;
	initial begin
		`TestReset(reset)

		io_A = 102;
		io_B = 193;
		@(negedge clock);
		io_A = 3671;
		io_B = 13;
		@(negedge clock);
		io_A = 95;
		io_B = 384;
		@(negedge clock);
		io_A = 13;
		io_B = 10;

		// Wait for result
		for (i = 0;i < `MultiplierDelay(p_dataWidth) - 3;i++) begin
			@(negedge clock);
		end
		`TestCheck(io_result, 19686);
		@(negedge clock);
		`TestCheck(io_result, 47723);
		@(negedge clock);
		`TestCheck(io_result, 36480);
		@(negedge clock);
		`TestCheck(io_result, 130);

		`TestFinish("MultiplierTest")
	end

endmodule: MultiplierTest


/*
 * Test Barrett Reduction mod
 */
module ModularBarrettReductionTest
	#(parameter
		p_dataWidth = 16
	);

	logic clock, reset;
	logic [p_dataWidth-1:0] io_mod, io_M, io_K;
	logic [p_dataWidth-1:0] io_A, io_result;

	ModularBarrettReduction #(
		.p_dataWidth(p_dataWidth)
	) m_mod(.*);

	`TestClock(clock)
	integer i;
	initial begin
		`TestReset(reset)

		// 47 % 7 = 5
		io_A = 47;
		io_mod = 7;
		io_M = 18;
		io_K = 7;
		@(negedge clock);
		// 80 % 7 = 3
		io_A = 80;
		io_mod = 7;
		io_M = 18;
		io_K = 7;
		@(negedge clock);
		// 102 % 13 = 11
		io_A = 102;
		io_mod = 13;
		io_M = 19;
		io_K = 8;
		@(negedge clock);
		// 14 % 7 = 0
		io_A = 14;
		io_mod = 7;
		io_M = 18;
		io_K = 7;
		@(negedge clock);
		// end
		io_A = 0;
		@(negedge clock);

		// Latency is 2 * p_dataWidth
		for (i = 0;i < `ModularBarrettReductionDelay(p_dataWidth) - 5;i++) begin
			@(negedge clock);
		end
		`TestCheck(io_result, 5);
		@(negedge clock);
		`TestCheck(io_result, 3);
		@(negedge clock);
		`TestCheck(io_result, 11);
		@(negedge clock);
		`TestCheck(io_result, 0);
		@(negedge clock);

		`TestFinish("ModularBarrettReductionTest")
	end

endmodule: ModularBarrettReductionTest
