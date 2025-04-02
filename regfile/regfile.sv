`default_nettype none

/*
 * Register file
 */
module Regfile 
	#(parameter
		p_rowSize = 0,
		p_clusterNum = 0,
		p_regNum = 0,
		p_regAddrWidth = 0,
		p_rowAddrWidth = 0,
		p_dataWidth = 0,
		p_readPortNum = 0,
		p_writePortNum = 0
	)
	(
		input logic  clock, reset,

		input logic  [p_regAddrWidth-1:0] io_readAddr[p_readPortNum-1:0],
		input logic  [p_rowAddrWidth-1:0] io_readRow[p_readPortNum-1:0],
		output logic [p_dataWidth-1:0] io_readData[p_readPortNum-1:0][p_rowSize-1:0],

		input logic  io_writeEnable[p_writePortNum-1:0],
		input logic  [p_regAddrWidth-1:0] io_writeAddr[p_writePortNum-1:0],
		input logic  [p_rowAddrWidth-1:0] io_writeRow[p_writePortNum-1:0],
		input logic  [p_dataWidth-1:0] io_writeData[p_writePortNum-1:0][p_rowSize-1:0]
	);

	localparam p_colSize = p_rowSize / p_clusterNum;

	genvar bankId, readPortId, writePortId;
	generate
	for (bankId = 0;bankId < p_rowSize;bankId++) begin: bank
		logic [p_dataWidth-1:0] r_bankMem[p_regNum-1:0][p_colSize-1:0];

		// Read ports
		for (readPortId = 0;readPortId < p_readPortNum;readPortId++) begin
			always_ff @(posedge clock) begin
				io_readData[readPortId][bankId] <= r_bankMem[io_readAddr[readPortId]][io_readRow[readPortId]];
			end
		end

		// Write ports
		for (writePortId = 0;writePortId < p_writePortNum;writePortId++) begin
			always @(posedge clock) begin
				if (io_writeEnable[writePortId]) begin
					r_bankMem[io_writeAddr[writePortId]][io_writeRow[writePortId]] <= io_writeData[writePortId][bankId];
				end
			end
		end
	end
	endgenerate

endmodule: Regfile
