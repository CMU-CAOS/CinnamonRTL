`default_nettype none

module RectMemTest
	#(parameter
		p_rowSize = 3,
		p_colSize = 4,
		p_dataWidth = 32,
		p_addrWidth = 2
	);

	logic clock, reset;
	logic [p_addrWidth-1:0] io_readAddr;
	logic [p_dataWidth-1:0] io_readData[p_rowSize-1:0];
	logic [p_addrWidth-1:0] io_writeAddr;
	logic [p_dataWidth-1:0] io_writeData[p_rowSize-1:0];
	logic io_writeEnable;

	RectMem #(
		.p_rowSize(p_rowSize),
		.p_colSize(p_colSize),
		.p_dataWidth(p_dataWidth),
		.p_addrWidth(p_addrWidth)
	) dut(.*);

	// Test data
	logic [p_dataWidth-1:0] l_d1[p_rowSize-1:0], l_d2[p_rowSize-1:0], l_d3[p_rowSize-1:0];

	`TestClock(clock)
	initial begin
		`TestReset(reset)

		// Prepare test data
		l_d1 = '{8, 6, 7};
		l_d2 = '{2, 23, 9};
		l_d3 = '{9, 0, 2};

		// Write d1 at addr 1
		io_readAddr = 1;
		io_writeAddr = 1;
		io_writeEnable = 1;
		io_writeData = l_d1;

		@(negedge clock);

		// Check output is d1
		`TestCheckArray(io_readData, l_d1, p_rowSize)
		// Disable write
		io_writeEnable = 0;
		io_writeData = l_d2;

		@(negedge clock);

		// check output is d1
		`TestCheckArray(io_readData, l_d1, p_rowSize)
		// Enable write
		io_writeEnable = 1;

		@(negedge clock);

		// Check output is d2
		`TestCheckArray(io_readData, l_d2, p_rowSize)
		// Try addr 2
		io_readAddr = 2;
		io_writeAddr = 2;
		io_writeEnable = 1;
		io_writeData = l_d3;
		`TestCheckArray(io_readData, l_d2, p_rowSize)

		@(negedge clock);

		// Check output is d3
		`TestCheckArray(io_readData, l_d3, p_rowSize)
		// Try addr 1
		io_writeEnable = 0;
		io_readAddr = 1;
		io_writeAddr = 1;

		@(negedge clock);

		// Check output is d2
		`TestCheckArray(io_readData, l_d2, p_rowSize)

		`TestFinish("RectMemTest")
	end

endmodule: RectMemTest
