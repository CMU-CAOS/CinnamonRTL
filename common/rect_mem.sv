`default_nettype none

/*
 * Rectangle-shaped SRAM memory
 * Used for transpose unit
 * Read/Write from columns
 * Read/Write address is column number
 */
module RectMem
	#(parameter
		p_rowSize = 0,
		p_colSize = 0,
		p_dataWidth = 0,
		p_addrWidth = 0
	)
	(
		input logic  clock, reset,
		input logic  [p_addrWidth-1:0] io_readAddr,
		output logic [p_dataWidth-1:0] io_readData[p_rowSize-1:0],
		input logic  [p_addrWidth-1:0] io_writeAddr,
		input logic  [p_dataWidth-1:0] io_writeData[p_rowSize-1:0],
		input logic  io_writeEnable
	);

	// Memory
	logic [p_dataWidth-1:0] mem [p_colSize-1:0][p_rowSize-1:0];

	/* verilator lint_off WIDTH */

	// Read
	logic [p_addrWidth-1:0] r_readAddrReg;
	always_ff @(posedge clock) begin
		r_readAddrReg <= io_readAddr;
	end
	assign io_readData = mem[r_readAddrReg];

	// Write
	always_ff @(posedge clock) begin
		if (io_writeEnable) begin
			mem[io_writeAddr] <= io_writeData;
		end
	end

endmodule: RectMem


/*
 * Mod (prime number) memory
 */
module PrimeModMem
	#(parameter
		p_primeNum = 0,
		p_primeAddrWidth = 0,
		p_dataWidth = 0,
		p_readPortNum = 0
	)
	(
		input logic  clock, reset,
		input logic  [p_primeAddrWidth-1:0] io_primeId[p_readPortNum-1:0],
		output logic [p_dataWidth-1:0] io_mod[p_readPortNum-1:0]
	);

	// Memory
	logic [p_dataWidth-1:0] r_mem[p_primeNum-1:0];

	// Read ports
	genvar readPortId;
	generate
	for (readPortId = 0;readPortId < p_readPortNum;readPortId++) begin
		logic [p_primeAddrWidth-1:0] r_readAddrReg;
		always_ff @(posedge clock) begin
			r_readAddrReg <= io_primeId[readPortId];
		end
		assign io_mod[readPortId] = r_mem[r_readAddrReg];
	end
	endgenerate

endmodule: PrimeModMem
