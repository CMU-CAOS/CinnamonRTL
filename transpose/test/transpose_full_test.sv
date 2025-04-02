`default_nettype none


/*
 * Fully transpose a 8x8 matrix
 */
module TransposeFull8x8Test
	#(parameter
		p_rowSize = 8,
		p_colSize = 8,
		p_level = 3,
		p_dataWidth = 16
	);

	logic clock, reset;
	logic io_inActive, io_outActive;
	logic [p_dataWidth-1:0] io_inData[p_rowSize-1:0];
	logic [p_dataWidth-1:0] io_outData[p_rowSize-1:0];

	TransposeFull #(
		.p_rowSize(p_rowSize),
		.p_colSize(p_colSize),
		.p_level(p_level),
		.p_dataWidth(p_dataWidth)
	) dut(.*);

	`TestClock(clock)
	logic [p_dataWidth-1:0] m1[p_colSize-1:0][p_rowSize-1:0], m1t[p_colSize-1:0][p_rowSize-1:0];
	integer size = 8;
	integer i, j;
	initial begin
		`TestReset(reset)
		for (i = 0;i < size;i++) begin
			for (j = 0;j < size;j++) begin
				m1[i][j] = p_dataWidth'(i * size + j);
			end
		end
		for (i = 0;i < size;i++) begin
			for (j = 0;j < size;j++) begin
				m1t[i][j] = m1[j][i];
			end
		end

		io_inActive = 0;

		// Input column stream
		for (i = 0;i < size;i++) begin
			io_inActive = 1;
			io_inData = m1[i];
			@(negedge clock);
		end

		// Wait for 1 cycle
		@(negedge clock);

		// Read outputs
		for (i = 0;i < size;i++) begin
			@(negedge clock);
			`TestCheck(io_outActive, 1)
			`TestCheckArray(io_outData, m1t[i], p_rowSize)
		end

		`TestFinish("TransposeFull8x8Test")
	end

endmodule: TransposeFull8x8Test


/*
 * Fully transpose a 64x64 matrix
 */
module TransposeFull64x64Test
	#(parameter
		p_rowSize = 64,
		p_colSize = 64,
		p_level = 6,
		p_dataWidth = 16,
		p_pause = 19
	);

	logic clock, reset;
	logic io_inActive, io_outActive;
	logic [p_dataWidth-1:0] io_inData[p_rowSize-1:0];
	logic [p_dataWidth-1:0] io_outData[p_rowSize-1:0];

	TransposeFull #(
		.p_rowSize(p_rowSize),
		.p_colSize(p_colSize),
		.p_level(p_level),
		.p_dataWidth(p_dataWidth)
	) dut(.*);

	`TestClock(clock)
	logic [p_dataWidth-1:0]
		m1[p_colSize-1:0][p_rowSize-1:0], m1t[p_colSize-1:0][p_rowSize-1:0],
		m2[p_colSize-1:0][p_rowSize-1:0], m2t[p_colSize-1:0][p_rowSize-1:0];
	integer size = 64;
	integer i, j;
	initial begin
		`TestReset(reset)
		for (i = 0;i < size;i++) begin
			for (j = 0;j < size;j++) begin
				m1[i][j] = p_dataWidth'($random);
				m2[i][j] = p_dataWidth'($random);
			end
		end
		for (i = 0;i < size;i++) begin
			for (j = 0;j < size;j++) begin
				m1t[i][j] = m1[j][i];
				m2t[i][j] = m2[j][i];
			end
		end

		// Input column stream
		io_inActive = 1;
		for (i = 0;i < size;i++) begin
			io_inData = m1[i];
			@(negedge clock);
		end
		io_inActive = 0;
		// Wait for 4 cycle
		for (i = 0;i < 4;i++) begin
			@(negedge clock);
		end

		// Read outputs
		for (i = 0;i < size;i++) begin
			@(negedge clock);
			`TestCheck(io_outActive, 1)
			`TestCheckArray(io_outData, m1t[i], p_rowSize)
		end

		// Input column stream
		io_inActive = 1;
		for (i = 0;i < size;i++) begin
			io_inData = m2[i];
			@(negedge clock);
		end
		io_inActive = 0;
		// Wait for 4 cycle
		for (i = 0;i < 4;i++) begin
			@(negedge clock);
		end

		// Read outputs
		for (i = 0;i < size;i++) begin
			@(negedge clock);
			`TestCheck(io_outActive, 1)
			`TestCheckArray(io_outData, m2t[i], p_rowSize)
		end

		// Pause for some cycles to test bubble
		for (i = 0;i < p_pause;i++) @(negedge clock);

		// Transpose m1 again
		io_inActive = 1;
		for (i = 0;i < size;i++) begin
			io_inData = m1[i];
			@(negedge clock);
		end
		io_inActive = 0;
		for (i = 0;i < 4;i++) begin
			@(negedge clock);
		end
		for (i = 0;i < size;i++) begin
			@(negedge clock);
			`TestCheck(io_outActive, 1)
			`TestCheckArray(io_outData, m1t[i], p_rowSize)
		end

		`TestFinish("TransposeFull64x64Test")
	end

endmodule: TransposeFull64x64Test


/*
 * Fully transpose a 256x256 matrix
 */
module TransposeFull256x256Test
	#(parameter
		p_rowSize = 256,
		p_colSize = 256,
		p_level = 8,
		p_dataWidth = 32
	);

	logic clock, reset;
	logic io_inActive, io_outActive;
	logic [p_dataWidth-1:0] io_inData[p_rowSize-1:0];
	logic [p_dataWidth-1:0] io_outData[p_rowSize-1:0];

	TransposeFull #(
		.p_rowSize(p_rowSize),
		.p_colSize(p_colSize),
		.p_level(p_level),
		.p_dataWidth(p_dataWidth)
	) dut(.*);

	`TestClock(clock)
	logic [p_dataWidth-1:0] m1[p_colSize-1:0][p_rowSize-1:0], m1t[p_colSize-1:0][p_rowSize-1:0];
	integer size = 256;
	integer i, j;
	initial begin
		`TestReset(reset)
		for (i = 0;i < size;i++) begin
			for (j = 0;j < size;j++) begin
				m1[i][j] = p_dataWidth'(i * size + j);
			end
		end
		for (i = 0;i < size;i++) begin
			for (j = 0;j < size;j++) begin
				m1t[i][j] = m1[j][i];
			end
		end

		@(negedge clock);

		// Input column stream
		io_inActive = 1;
		for (i = 0;i < size;i++) begin
			io_inData = m1[i];
			@(negedge clock);
		end

		// Wait for 6 cycle
		io_inActive = 0;
		for (i = 0;i < 6;i++) begin
			@(negedge clock);
		end

		// Read outputs
		for (i = 0;i < size;i++) begin
			@(negedge clock);
			`TestCheck(io_outActive, 1)
			`TestCheckArray(io_outData, m1t[i], p_rowSize)
		end

		`TestFinish("TransposeFull256x256Test")
	end

endmodule: TransposeFull256x256Test


/*
 * Fully transpose a 128x8 matrix
 */
module TransposeFull128x8Test
	#(parameter
		p_rowSize = 128,
		p_colSize = 8,
		p_level = 3,
		p_dataWidth = 16
	);

	localparam p_ratio = p_rowSize / p_colSize;

	logic clock, reset;
	logic io_inActive, io_outActive;
	logic [p_dataWidth-1:0] io_inData[p_rowSize-1:0];
	logic [p_dataWidth-1:0] io_outData[p_rowSize-1:0];

	TransposeFull #(
		.p_rowSize(p_rowSize),
		.p_colSize(p_colSize),
		.p_level(p_level),
		.p_dataWidth(p_dataWidth)
	) dut(.*);

	`TestClock(clock)
	logic [p_dataWidth-1:0] m1[p_colSize-1:0][p_rowSize-1:0], m1t[p_colSize-1:0][p_rowSize-1:0];
	integer i, j, k;
	initial begin
		`TestReset(reset)
		for (i = 0;i < p_rowSize;i++) begin
			for (j = 0;j < p_colSize;j++) begin
				m1[j][i] = p_dataWidth'($random);
			end
		end
		for (i = 0;i < p_colSize;i++) begin
			for (j = 0;j < p_colSize;j++) begin
				for (k = 0;k < p_ratio;k++) begin
					m1t[j][i * p_ratio + k] = m1[i][j * p_ratio + k];
				end
			end
		end

		// Input column stream
		for (i = 0;i < p_colSize;i++) begin
			io_inActive = 1;
			io_inData = m1[i];
			@(negedge clock);
		end

		// Wait for 1 cycle
		io_inActive = 0;
		@(negedge clock);

		// Read outputs
		for (i = 0;i < p_colSize;i++) begin
			@(negedge clock);
			`TestCheck(io_outActive, 1)
			`TestCheckArray(io_outData, m1t[i], p_rowSize)
		end

		`TestFinish("TransposeFull128x8Test")
	end

endmodule: TransposeFull128x8Test


/*
 * Fully transpose a 8x128 matrix
 */
module TransposeFull8x128Test
	#(parameter
		p_rowSize = 8,
		p_colSize = 128,
		p_level = 3,
		p_dataWidth = 16
	);

	localparam p_ratio = p_colSize / p_rowSize;
	localparam p_delta = 114;

	logic clock, reset;
	logic io_inActive, io_outActive;
	logic [p_dataWidth-1:0] io_inData[p_rowSize-1:0];
	logic [p_dataWidth-1:0] io_outData[p_rowSize-1:0];

	TransposeFull #(
		.p_rowSize(p_rowSize),
		.p_colSize(p_colSize),
		.p_level(p_level),
		.p_dataWidth(p_dataWidth)
	) dut(.*);

	`TestClock(clock)
	logic [p_dataWidth-1:0] m1[p_colSize-1:0][p_rowSize-1:0], m1t[p_colSize-1:0][p_rowSize-1:0];
	integer i, j, k;
	initial begin
		`TestReset(reset)
		for (i = 0;i < p_rowSize;i++) begin
			for (j = 0;j < p_colSize;j++) begin
				m1[j][i] = p_dataWidth'($random);
			end
		end
		for (i = 0;i < p_rowSize;i++) begin
			for (j = 0;j < p_rowSize;j++) begin
				for (k = 0;k < p_ratio;k++) begin
					m1t[j * p_ratio + k][i] = m1[i * p_ratio + k][j];
				end
			end
		end

		// Input column stream
		for (i = 0;i < p_colSize;i++) begin
			io_inData = m1[i];
			io_inActive = 1;
			@(negedge clock);

			if (i >= p_delta) begin
				`TestCheck(io_outActive, 1)
				`TestCheckArray(io_outData, m1t[i - p_delta], p_rowSize)
			end
		end

		// Read outputs
		for (i = p_colSize - p_delta;i < p_colSize;i++) begin
			io_inActive = 0;
			@(negedge clock);
			`TestCheck(io_outActive, 1)
			`TestCheckArray(io_outData, m1t[i], p_rowSize)
		end
		
		@(negedge clock);
		`TestCheck(io_outActive, 0)

		`TestFinish("TransposeFull8x128Test")
	end

endmodule: TransposeFull8x128Test
