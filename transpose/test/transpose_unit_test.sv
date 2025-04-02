`default_nettype none


/*
 * Transpose a 4x4 matrix
 */
module TransposeHighTest
	#(parameter
		p_rowSize = 4,
		p_colSize = 4,
		p_dataWidth = 16,
		p_addrWidth = 6
	);

	logic clock, reset;
	logic io_inActive, io_outActive;
	logic [p_dataWidth-1:0] io_inData[p_rowSize-1:0];
	logic [p_dataWidth-1:0] io_outData[p_rowSize-1:0];

	TransposeHigh #(
		.p_rowSize(p_rowSize),
		.p_colSize(p_colSize),
		.p_dataWidth(p_dataWidth),
		.p_addrWidth(p_addrWidth)
	) dut(.*);

	`TestClock(clock)
	logic [p_dataWidth-1:0] m1[p_colSize-1:0][p_rowSize-1:0], m1t[p_colSize-1:0][p_rowSize-1:0];
	logic [p_dataWidth-1:0] m2[11:0][p_rowSize-1:0], m2t[11:0][p_rowSize-1:0];
	integer size = 4, halfSize = 2;
	integer i;
	initial begin
		`TestReset(reset)
		m1 = '{
			'{ 0,  1,  2,  3},
			'{ 4,  5,  6,  7},
			'{ 8,  9, 10, 11},
			'{12, 13, 14, 15}
		};
		m1t = '{
			'{ 0,  1,  8,  9},
			'{ 4,  5, 12, 13},
			'{ 2,  3, 10, 11},
			'{ 6,  7, 14, 15}
		};
		m2 = '{
			'{ 0,  4,  8, 12},
			'{ 1,  5,  9, 13},
			'{ 2,  6, 10, 14},
			'{ 3,  7, 11, 15},
			'{43, 25, 29, 90},
			'{35, 93, 12, 59},
			'{43, 23, 19, 29},
			'{94, 23, 96, 67},
			'{ 4,  2,  8,  0},
			'{ 1,  8,  2,  9},
			'{ 4,  3,  3,  8},
			'{ 9,  4,  4,  1}
		};
		m2t = '{
			'{ 0,  4,  2,  6},
			'{ 1,  5,  3,  7},
			'{ 8, 12, 10, 14},
			'{ 9, 13, 11, 15},
			'{43, 25, 43, 23},
			'{35, 93, 94, 23},
			'{29, 90, 19, 29},
			'{12, 59, 96, 67},
			'{ 4,  2,  4,  3},
			'{ 1,  8,  9,  4},
			'{ 8,  0,  3,  8},
			'{ 2,  9,  4,  1}
		};

		// Transpose m1 -> m1t
		// Stage 0
		for (i = 0;i < halfSize;i++) begin
			io_inActive = 1;
			io_inData = m1[i];
			@(negedge clock);
			`TestCheck(io_outActive, 0)
		end
		// Stage 1
		for (i = 0;i < halfSize;i++) begin
			io_inActive = 1;
			io_inData = m1[i + halfSize];
			@(negedge clock);
			`TestCheck(io_outActive, 1)
			`TestCheckArray(io_outData, m1t[i], p_rowSize)
		end
		// Stage 2
		for (i = 0;i < halfSize;i++) begin
			io_inActive = 0;
			@(negedge clock);
			`TestCheck(io_outActive, 1)
			`TestCheckArray(io_outData, m1t[i + halfSize], p_rowSize)
		end

		// Add one more bubble
		io_inActive = 0;
		@(negedge clock);

		// Transpose m2 -> m2t
		// Stage 0
		for (i = 0;i < halfSize;i++) begin
			io_inActive = 1;
			io_inData = m2[i];
			@(negedge clock);
			`TestCheck(io_outActive, 0)
		end
		// Stage 1
		for (i = 0;i < halfSize;i++) begin
			io_inActive = 1;
			io_inData = m2[i + halfSize];
			@(negedge clock);
			`TestCheck(io_outActive, 1)
			`TestCheckArray(io_outData, m2t[i], p_rowSize)
		end
		// Stage 02
		for (i = 0;i < halfSize;i++) begin
			io_inActive = 1;
			io_inData = m2[i + halfSize*2];
			@(negedge clock);
			`TestCheck(io_outActive, 1)
			`TestCheckArray(io_outData, m2t[i + halfSize], p_rowSize)
		end
		// Stage 1
		for (i = 0;i < halfSize;i++) begin
			io_inActive = 1;
			io_inData = m2[i + halfSize*3];
			@(negedge clock);
			`TestCheck(io_outActive, 1)
			`TestCheckArray(io_outData, m2t[i + halfSize*2], p_rowSize)
		end
		// Stage 02
		for (i = 0;i < halfSize;i++) begin
			io_inActive = 1;
			io_inData = m2[i + halfSize*4];
			@(negedge clock);
			`TestCheck(io_outActive, 1)
			`TestCheckArray(io_outData, m2t[i + halfSize*3], p_rowSize)
		end
		// Stage 1
		for (i = 0;i < halfSize;i++) begin
			io_inActive = 1;
			io_inData = m2[i + halfSize*5];
			@(negedge clock);
			`TestCheck(io_outActive, 1)
			`TestCheckArray(io_outData, m2t[i + halfSize*4], p_rowSize)
		end
		// Stage 2
		for (i = 0;i < halfSize;i++) begin
			io_inActive = 0;
			@(negedge clock);
			`TestCheck(io_outActive, 1)
			`TestCheckArray(io_outData, m2t[i + halfSize*5], p_rowSize)
		end
		@(negedge clock);
		`TestCheck(io_outActive, 0)

		`TestFinish("TransposeHighTest")
	end
	
endmodule: TransposeHighTest

/*
 * Transpose a 4x8 matrix
 */
module TransposeHighRectTest
	#(parameter
		p_rowSize = 4,
		p_colSize = 8,
		p_dataWidth = 16,
		p_addrWidth = 6
	);

	logic clock, reset;
	logic io_inActive, io_outActive;
	logic [p_dataWidth-1:0] io_inData[p_rowSize-1:0];
	logic [p_dataWidth-1:0] io_outData[p_rowSize-1:0];

	TransposeHigh #(
		.p_rowSize(p_rowSize),
		.p_colSize(p_colSize),
		.p_dataWidth(p_dataWidth),
		.p_addrWidth(p_addrWidth)
	) dut(.*);

	`TestClock(clock)
	logic [p_dataWidth-1:0] m1[p_colSize-1:0][p_rowSize-1:0], m1t[p_colSize-1:0][p_rowSize-1:0];
	integer size = 8, halfSize = 4;
	integer i;
	initial begin
		`TestReset(reset)
		m1 = '{
			'{ 0,  4,  8, 12},
			'{ 1,  5,  9, 13},
			'{ 2,  6, 10, 14},
			'{ 3,  7, 11, 15},
			'{16, 20, 24, 28},
			'{17, 21, 25, 29},
			'{18, 22, 26, 30},
			'{19, 23, 27, 31}
		};
		m1t = '{
			'{ 0,  4, 16, 20},
			'{ 1,  5, 17, 21},
			'{ 2,  6, 18, 22},
			'{ 3,  7, 19, 23},
			'{ 8, 12, 24, 28},
			'{ 9, 13, 25, 29},
			'{10, 14, 26, 30},
			'{11, 15, 27, 31}
		};

		// Transpose m1 -> m1t
		// Stage 0
		for (i = 0;i < halfSize;i++) begin
			io_inActive = 1;
			io_inData = m1[i];
			@(negedge clock);
			`TestCheck(io_outActive, 0)
		end
		// Stage 1
		for (i = 0;i < halfSize;i++) begin
			io_inActive = 1;
			io_inData = m1[i + halfSize];
			@(negedge clock);
			`TestCheck(io_outActive, 1)
			`TestCheckArray(io_outData, m1t[i], p_rowSize)
		end
		// Stage 2
		for (i = 0;i < halfSize;i++) begin
			io_inActive = 0;
			@(negedge clock);
			`TestCheck(io_outActive, 1)
			`TestCheckArray(io_outData, m1t[i + halfSize], p_rowSize)
		end
		@(negedge clock);
		`TestCheck(io_outActive, 0)

		`TestFinish("TransposeHighRectTest")
	end

endmodule: TransposeHighRectTest

/*
 * Transpose a 2x2 matrix
 */
module TransposeTwoTest
	#(parameter
		p_rowSize = 2,
		p_colSize = 2,
		p_dataWidth = 32,
		p_addrWidth = 6
	);

	logic clock, reset;
	logic io_inActive;
	logic [p_dataWidth-1:0] io_inData[p_rowSize-1:0];
	logic io_outActive;
	logic [p_dataWidth-1:0] io_outData[p_rowSize-1:0];

	TransposeTwo #(
		.p_rowSize(p_rowSize),
		.p_colSize(p_colSize),
		.p_dataWidth(p_dataWidth),
		.p_addrWidth(p_addrWidth)
	) dut(.*);

	`TestClock(clock)
	logic [p_dataWidth-1:0] m1[p_colSize-1:0][p_rowSize-1:0], m1t[p_colSize-1:0][p_rowSize-1:0];
	logic [p_dataWidth-1:0] m2[3:0][p_rowSize-1:0], m2t[3:0][p_rowSize-1:0];
	initial begin
		`TestReset(reset)
		m1 = '{
			'{7, 8},
			'{1, 6}
		};
		m1t = '{
			'{7, 1},
			'{8, 6}
		};
		m2 = '{
			'{5, 1},
			'{2, 7},
			'{9, 4},
			'{8, 3}
		};
		m2t = '{
			'{5, 2},
			'{1, 7},
			'{9, 8},
			'{4, 3}
		};

		// Transpose m1 -> m1t
		// Stage 0
		io_inActive = 1;
		io_inData = m1[0];
		@(negedge clock);
		`TestCheck(io_outActive, 0)

		// Stage 1
		io_inActive = 1;
		io_inData = m1[1];
		@(negedge clock);
		`TestCheck(io_outActive, 1)
		`TestCheckArray(io_outData, m1t[0], p_rowSize)

		// Stage 2
		io_inActive = 0;
		@(negedge clock);
		`TestCheck(io_outActive, 1)
		`TestCheckArray(io_outData, m1t[1], p_rowSize)

		// Transpose m2 -> m2t (two matrices)
		// Stage 0
		io_inActive = 1;
		io_inData = m2[0];
		@(negedge clock);
		`TestCheck(io_outActive, 0)

		// Stage 1
		io_inActive = 1;
		io_inData = m2[1];
		@(negedge clock);
		`TestCheck(io_outActive, 1)
		`TestCheckArray(io_outData, m2t[0], p_rowSize)

		// Stage 02
		io_inActive = 1;
		io_inData = m2[2];
		@(negedge clock);
		`TestCheck(io_outActive, 1)
		`TestCheckArray(io_outData, m2t[1], p_rowSize)

		// Stage 1
		io_inActive = 1;
		io_inData = m2[3];
		@(negedge clock);
		`TestCheck(io_outActive, 1)
		`TestCheckArray(io_outData, m2t[2], p_rowSize)

		// Stage 2
		io_inActive = 0;
		@(negedge clock);
		`TestCheck(io_outActive, 1)
		`TestCheckArray(io_outData, m2t[3], p_rowSize)

		@(negedge clock);
		`TestCheck(io_outActive, 0)

		`TestFinish("TransposeTwoTest")
	end
	
endmodule: TransposeTwoTest


/*
 * Transpose a 6x2 matrix
 */
module TransposeTwoRectTest
	#(parameter
		p_rowSize = 6,
		p_colSize = 2,
		p_dataWidth = 32,
		p_addrWidth = 6
	);

	logic clock, reset;
	logic io_inActive;
	logic [p_dataWidth-1:0] io_inData[p_rowSize-1:0];
	logic io_outActive;
	logic [p_dataWidth-1:0] io_outData[p_rowSize-1:0];

	TransposeTwo #(
		.p_rowSize(p_rowSize),
		.p_colSize(p_colSize),
		.p_dataWidth(p_dataWidth),
		.p_addrWidth(p_addrWidth)
	) dut(.*);

	`TestClock(clock)
	logic [p_dataWidth-1:0] m1[p_colSize-1:0][p_rowSize-1:0], m1t[p_colSize-1:0][p_rowSize-1:0];
	initial begin
		`TestReset(reset)
		m1 = '{
			'{7, 8, 1, 1, 1, 2},
			'{0, 3, 7, 2, 9, 1}
		};
		m1t = '{
			'{7, 8, 1, 0, 3, 7},
			'{1, 1, 2, 2, 9, 1}
		};

		// Transpose m1 -> m1t
		// Stage 0
		io_inActive = 1;
		io_inData = m1[0];
		@(negedge clock);
		`TestCheck(io_outActive, 0)

		// Stage 1
		io_inActive = 1;
		io_inData = m1[1];
		@(negedge clock);
		`TestCheck(io_outActive, 1)
		`TestCheckArray(io_outData, m1t[0], p_rowSize)

		// Stage 2
		io_inActive = 0;
		@(negedge clock);
		`TestCheck(io_outActive, 1)
		`TestCheckArray(io_outData, m1t[1], p_rowSize)

		`TestFinish("TransposeTwoRectTest")
	end

endmodule: TransposeTwoRectTest
