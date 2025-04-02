`default_nettype none

/*
 * Modular adder
 * Combinational
 */
module ModularAdder
	#(parameter
		p_dataWidth = 0
	)
	(
		input logic  [p_dataWidth-1:0] io_A, io_B, io_mod,
		output logic [p_dataWidth-1:0] io_result
	);

	// Sum of io_A and io_B
	logic [1 + p_dataWidth-1:0] w_sum;
	assign w_sum = io_A + io_B;

	// Modular result
	always_comb begin
		if (w_sum >= io_mod) begin
			io_result = w_sum - io_mod;
		end else begin
			io_result = w_sum;
		end
	end

endmodule: ModularAdder


/*
 * Modular subtractor
 * Combinational
 */
module ModularSubtractor
	#(parameter
		p_dataWidth = 0
	)
	(
		input logic  [p_dataWidth-1:0] io_A, io_B, io_mod,
		output logic [p_dataWidth-1:0] io_result
	);

	// Modular result
	always_comb begin
		if (io_A >= io_B) begin
			io_result = io_A - io_B;
		end else begin
			io_result = io_A + (io_mod - io_B);
		end
	end

endmodule: ModularSubtractor


// Modular multiplier number of chained adder in one cycle
`define ModularMultiplierBlockSize 4

/*
 * Modular multiplier
 * Pipelined version
 */
module ModularMultiplier
	#(parameter
		p_dataWidth = 0
	)
	(
		input logic  clock, reset,
		input logic  [p_dataWidth-1:0] io_A, io_B, io_mod,
		output logic [p_dataWidth-1:0] io_result
	);

	// Number of chained adders in one cycles
	localparam p_blockSize = `ModularMultiplierBlockSize;
	// Number of adder levels
	localparam p_blockNum = (p_dataWidth + p_blockSize - 1) / p_blockSize;

	// Adder modules
	genvar blockId, i;
	generate
	for (blockId = 0;blockId < p_blockNum;blockId++) begin: block
		logic [p_dataWidth-1:0] r_mod, r_B, r_sumPrev, r_APrev;
		logic [p_blockSize:0][p_dataWidth-1:0] r_sum, r_A;
		logic [p_blockSize-1:0][p_dataWidth-1:0] w_term;

		// Block size number of adders
		for (i = 0;i < p_blockSize;i++) begin
			localparam index = blockId * p_blockSize + i;
			if (index < p_dataWidth) begin
				assign w_term[i] = r_B[index] ? r_A[i] : p_dataWidth'(0);
			end else begin
				assign w_term[i] = p_dataWidth'(0);
			end
			ModularAdder #(
				.p_dataWidth(p_dataWidth)
			) m_addSum(
				.io_A(r_sum[i]),
				.io_B(w_term[i]),
				.io_mod(r_mod),
				.io_result(r_sum[i + 1])
			), m_addA(
				.io_A(r_A[i]),
				.io_B(r_A[i]),
				.io_mod(r_mod),
				.io_result(r_A[i + 1])
			);
		end
		// Outputs to the next block
		assign r_A[0] = r_APrev;
		assign r_sum[0] = r_sumPrev;
	end
	endgenerate

	// Connection between blocks
	generate
	for (blockId = 0;blockId < p_blockNum - 1;blockId++) begin
		always_ff @(posedge clock) begin
			block[blockId + 1].r_mod <= block[blockId].r_mod;
			block[blockId + 1].r_B <= block[blockId].r_B;
			block[blockId + 1].r_APrev <= block[blockId].r_A[p_blockSize];
			block[blockId + 1].r_sumPrev <= block[blockId].r_sum[p_blockSize];
		end
	end
	endgenerate
	// Connect to input/output
	always_comb begin
		block[0].r_APrev = io_A;
		block[0].r_sumPrev = 0;
		block[0].r_B = io_B;
		block[0].r_mod = io_mod;
	end
	assign io_result = block[p_blockNum - 1].r_sum[p_blockSize];

endmodule: ModularMultiplier
`define ModularMultiplierDelay(p_dataWidth) \
	( (p_dataWidth + `ModularMultiplierBlockSize - 1) / `ModularMultiplierBlockSize - 1 )


/*
 * Normal multiplier
 * Pipelined version
 */
module Multiplier
	#(parameter
		p_dataWidth = 0
	)
	(
		input logic  clock, reset,
		input logic  [p_dataWidth-1:0] io_A, io_B,
		output logic [p_dataWidth-1:0] io_result
	);

	localparam p_level = $clog2(p_dataWidth);

	genvar levelId, blockId;
	// Wires for data at each level
	generate
	for (levelId = 0;levelId <= p_level;levelId++) begin: level
		localparam blockNum = (1 << (p_level - levelId));
		logic [blockNum-1:0][p_dataWidth-1:0] w_levelData;
	end
	// Adders at non-leaf node
	for (levelId = 1;levelId <= p_level;levelId++) begin
		localparam blockNum = (1 << (p_level - levelId));
		for (blockId = 0;blockId < blockNum;blockId++) begin
			always_ff @(posedge clock) begin
				level[levelId].w_levelData[blockId] <=
					level[levelId - 1].w_levelData[2 * blockId] +
					level[levelId - 1].w_levelData[2 * blockId + 1];
			end
		end
	end
	// Connect input data to leaf node
	for (blockId = 0;blockId < (1 << p_level);blockId++) begin
		if (blockId < p_dataWidth) begin
			assign level[0].w_levelData[blockId] = (io_A << blockId) & {p_dataWidth{io_B[blockId]}};
		end else begin
			// Set to 0
			assign level[0].w_levelData[blockId] = 0;
		end
	end
	endgenerate
	// Connect root node to output data
	assign io_result = level[p_level].w_levelData[0];

endmodule: Multiplier
`define MultiplierDelay(p_dataWidth) \
	( $clog2(p_dataWidth) )


/*
 * Barrett reduction to compute a mod b
 */
module ModularBarrettReduction
	#(
		p_dataWidth = 0
	)
	(
		input logic  clock, reset,
		input logic  [p_dataWidth-1:0] io_mod, io_M, io_K,
		input logic  [p_dataWidth-1:0] io_A,
		output logic [p_dataWidth-1:0] io_result
	);

	// Multiplication delay
	localparam p_multDelay = `MultiplierDelay(p_dataWidth);

	// Quotient and remain (can differ by 1)
	logic [p_dataWidth-1:0] w_Q, w_R;
	logic [p_dataWidth-1:0] w_mult1Out, w_mult2Out;
	logic [p_dataWidth-1:0] w_K1;
	logic [p_dataWidth-1:0] w_A1, w_A2, w_mod1, w_mod2;

	// Step 1 - Approximate quotient
	Multiplier #(
		.p_dataWidth(p_dataWidth)
	) m_mult1(
		.clock, .reset,
		.io_A(io_A), .io_B(io_M),
		.io_result(w_mult1Out)
	);
	SignalDelay #(
		.p_width(p_dataWidth * 3),
		.p_delay(p_multDelay)
	) m_delayPrimeId1(
		.clock, .reset,
		.io_inData({io_mod, io_K, io_A}),
		.io_outData({w_mod1, w_K1, w_A1})
	);
	assign w_Q = w_mult1Out >> w_K1;
	// Step 2 - Approximate remain
	Multiplier #(
		.p_dataWidth(p_dataWidth)
	) m_mult2(
		.clock, .reset,
		.io_A(w_Q), .io_B(w_mod1),
		.io_result(w_mult2Out)
	);
	SignalDelay #(
		.p_width(p_dataWidth * 2),
		.p_delay(p_multDelay)
	) m_delayPrimeId2(
		.clock, .reset,
		.io_inData({w_mod1, w_A1}),
		.io_outData({w_mod2, w_A2})
	);
	assign w_R = w_A2 - w_mult2Out;
	// Step 3 - Convert remain into [0, io_mod)
	always_comb begin
		if (w_R >= w_mod2) begin
			io_result = w_R - w_mod2;
		end else begin
			io_result = w_R;
		end
	end

endmodule: ModularBarrettReduction
`define ModularBarrettReductionDelay(p_dataWidth) \
	( 2 * `MultiplierDelay(p_dataWidth) )

/*
 * Barrett reduction constants memory
 */
module BarrettReductionMem
	#(
		p_primeNum = 0,
		p_primeAddrWidth = 0,
		p_dataWidth = 0,
		p_readPortNum = 0
	)
	(
		input logic  clock, reset,
		input logic  [p_readPortNum-1:0][p_primeAddrWidth-1:0] io_primeId,
		output logic [p_readPortNum-1:0][p_dataWidth-1:0] io_brM, io_brK
	);

	// Memory
	logic [p_dataWidth-1:0] r_brM[p_primeNum-1:0];
	logic [p_dataWidth-1:0] r_brK[p_primeNum-1:0];

	// Read from mem
	genvar readPortId;
	generate
	for (readPortId = 0;readPortId < p_readPortNum;readPortId++) begin
		logic [p_primeAddrWidth-1:0] r_readAddrReg;
		always_ff @(posedge clock) begin
			r_readAddrReg <= io_primeId[readPortId];
		end
		assign io_brM[readPortId] = r_brM[r_readAddrReg];
		assign io_brK[readPortId] = r_brK[r_readAddrReg];
	end
	endgenerate

endmodule: BarrettReductionMem
