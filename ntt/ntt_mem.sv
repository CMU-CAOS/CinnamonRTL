`default_nettype none

/*
 * NTT Twiddle factor memory
 */
module NTTTwiddleFactorMem
	#(parameter
		p_size = 0,
		p_primeNum = 0,
		p_primeAddrWidth = 0,
		p_dataWidth = 0,
		p_readPortNum = 0
	)
	(
		input logic  clock, reset,
		input logic  [p_primeAddrWidth-1:0] io_primeId[p_readPortNum-1:0],
		input logic  io_isInverse[p_readPortNum-1:0],
		output logic [p_dataWidth-1:0] io_twiddleFactor[p_readPortNum-1:0][p_size-1:0]
	);

	// Memory
	logic [p_dataWidth-1:0] r_mem[p_primeNum-1:0][1:0][p_size-1:0];

	// Read ports
	genvar readPortId;
	generate
	for (readPortId = 0;readPortId < p_readPortNum;readPortId++) begin
		logic [p_primeAddrWidth-1:0] r_primeId;
		logic r_isInverse;
		always_ff @(posedge clock) begin
			r_primeId <= io_primeId[readPortId];
			r_isInverse <= io_isInverse[readPortId];
		end
		assign io_twiddleFactor[readPortId] = r_mem[r_primeId][r_isInverse];
	end
	endgenerate

endmodule: NTTTwiddleFactorMem
