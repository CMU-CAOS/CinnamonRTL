`default_nettype none


/*
 * Test Register file
 */
module RegfileTest
	#(parameter
		p_rowSize = 9,
		p_clusterNum = 1,
		p_regNum = 3,
		p_regAddrWidth = $clog2(p_regNum),
		p_rowAddrWidth = $clog2(p_rowSize),
		p_dataWidth = 28,
		p_readPortNum = 3,
		p_writePortNum = 2
	);

	logic clock, reset;
	logic [p_regAddrWidth-1:0] io_readAddr[p_readPortNum-1:0];
	logic [p_rowAddrWidth-1:0] io_readRow[p_readPortNum-1:0];
	logic [p_dataWidth-1:0] io_readData[p_readPortNum-1:0][p_rowSize-1:0];
	logic io_writeEnable[p_writePortNum-1:0];
	logic [p_regAddrWidth-1:0] io_writeAddr[p_writePortNum-1:0];
	logic [p_rowAddrWidth-1:0] io_writeRow[p_writePortNum-1:0];
	logic [p_dataWidth-1:0] io_writeData[p_writePortNum-1:0][p_rowSize-1:0];

	Regfile #(
		.p_rowSize(p_rowSize),
		.p_clusterNum(p_clusterNum),
		.p_regNum(p_regNum),
		.p_regAddrWidth(p_regAddrWidth),
		.p_rowAddrWidth(p_rowAddrWidth),
		.p_dataWidth(p_dataWidth),
		.p_readPortNum(p_readPortNum),
		.p_writePortNum(p_writePortNum)
	) dut(.*);

	integer i;
	`TestClock(clock)
	initial begin
		`TestReset(reset)

		io_writeAddr[0] = 2;
		io_writeRow[0] = 4;
		io_writeData[0][1] = 638;
		io_writeData[0][2] = 92;
		io_writeEnable[0] = 1;
		io_writeEnable[1] = 0;

		@(negedge clock);

		io_writeEnable[0] = 0;
		io_writeData[0] = '{default: '0};
		io_readAddr[0] = 2;
		io_readRow[0] = 4;

		@(negedge clock);

		`TestCheck(io_readData[0][1], 638);
		`TestCheck(io_readData[0][2], 92);


		`TestFinish("RegfileTest")
	end

endmodule: RegfileTest
