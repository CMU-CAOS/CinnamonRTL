`default_nettype none

/*
 * CRB constants memory
 */
module CRBConstMem
	#(parameter
		p_primeNum = 0,
		p_primeAddrWidth = 0,
		p_blockNum = 0,
		p_dataWidth = 0
	)
	(
		input logic  clock, reset,
		input logic  [p_primeAddrWidth-1:0] io_primeId,
		output logic [p_dataWidth-1:0] io_data[0:p_blockNum-1]
	);

	RectMem #(
		.p_rowSize(p_blockNum),
		.p_colSize(p_primeNum),
		.p_dataWidth(p_dataWidth),
		.p_addrWidth(p_primeAddrWidth)
	) mem(
		.clock, .reset,
		.io_readAddr(io_primeId),
		.io_readData(io_data),
		.io_writeAddr(),
		.io_writeData(),
		.io_writeEnable(1'd0)
	);

endmodule: CRBConstMem
