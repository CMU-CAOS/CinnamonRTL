`default_nettype none


/*
 * NTT type
 */
typedef enum {
	NTT_TYPE_DIT,
	NTT_TYPE_DIF
} NTTType_t;


/*
 * Single butterfly unit (DIT)
 */
module NTTDITButterflyUnit
	#(parameter
		p_dataWidth = 0
	)
	(
		input logic  clock, reset,
		input logic  [p_dataWidth-1:0] io_inA, io_inB, io_twiddle, io_mod,
		output logic [p_dataWidth-1:0] io_outA, io_outB
	);

	logic [p_dataWidth-1:0] w_BxTwiddle;
	logic [p_dataWidth-1:0] w_inA, w_mod;

	// v = r * inp[idx2]
	MontgomeryMultiplierWrapper #(
		.p_dataWidth(p_dataWidth)
	) m_mult(
		.clock,
		.io_A(io_inB),
		.io_B(io_twiddle),
		.io_q(io_mod),
		.io_result(w_BxTwiddle)
	);
	localparam p_multDelay = `MontgomeryMultiplierDelay;

	// inp[idx1] = u + v
	ModularAdder #(
		.p_dataWidth(p_dataWidth)
	) m_addANext(
		.io_A(w_inA),
		.io_B(w_BxTwiddle),
		.io_mod(w_mod),
		.io_result(io_outA)
	);
	// inp[idx2] = u - v
	ModularSubtractor #(
		.p_dataWidth(p_dataWidth)
	) m_subBNext(
		.io_A(w_inA),
		.io_B(w_BxTwiddle),
		.io_mod(w_mod),
		.io_result(io_outB)
	);

	// Delay inA and mod
	SignalDelay #(
		.p_width(p_dataWidth + p_dataWidth),
		.p_delay(p_multDelay)
	) m_delay(
		.clock, .reset,
		.io_inData({io_inA, io_mod}),
		.io_outData({w_inA, w_mod})
	);

endmodule: NTTDITButterflyUnit


/*
 * Single butterfly unit (DIF)
 */
module NTTDIFButterflyUnit
	#(parameter
		p_dataWidth = 0
	)
	(
		input logic  clock, reset,
		input logic  [p_dataWidth-1:0] io_inA, io_inB, io_twiddle, io_mod,
		output logic [p_dataWidth-1:0] io_outA, io_outB
	);

	logic [p_dataWidth-1:0] w_AminusB;
	logic [p_dataWidth-1:0] w_outANext;

	// inp[idx1] = u + v
	ModularAdder #(
		.p_dataWidth(p_dataWidth)
	) m_addANext(
		.io_A(io_inA),
		.io_B(io_inB),
		.io_mod,
		.io_result(w_outANext)
	);
	// u - v
	ModularSubtractor #(
		.p_dataWidth(p_dataWidth)
	) m_subBNext(
		.io_A(io_inA),
		.io_B(io_inB),
		.io_mod,
		.io_result(w_AminusB)
	);
	// inp[idx2] = ((u - v)*r) % p
	MontgomeryMultiplierWrapper #(
		.p_dataWidth(p_dataWidth)
	) m_mult(
		.clock,
		.io_A(w_AminusB),
		.io_B(io_twiddle),
		.io_q(io_mod),
		.io_result(io_outB)
	);
	localparam p_multDelay = `MontgomeryMultiplierDelay;

	// Delay outA
	SignalDelay #(
		.p_width(p_dataWidth),
		.p_delay(p_multDelay)
	) m_delay(
		.clock, .reset,
		.io_inData(w_outANext),
		.io_outData(io_outA)
	);

endmodule: NTTDIFButterflyUnit

`define NTTButterflyUnitDelay(p_dataWidth) \
	( `MontgomeryMultiplierDelay )


/*
 * NTT unit
 * p_size should be power of 2
 * io_twiddle[i] = g^i, 0 <= i < N
 */
`define NTTUnitDelay(p_size, p_dataWidth) \
	( $clog2(p_size) * (`NTTButterflyUnitDelay(p_dataWidth) + 0) + 0 )
module NTTUnit
	#(parameter
		p_primeNum = 0,
		p_primeAddrWidth = 0,
		p_size = 0,
		p_dataWidth = 0,
		NTTType_t p_type = NTT_TYPE_DIT
	)
	(
		input logic  clock, reset,
		// Twiddle factor memory ports
		output logic [p_primeAddrWidth-1:0] io_twiddleFactorMemPrimeId[$clog2(p_size)-1:0],
		output logic io_twiddleFactorMemIsInverse[$clog2(p_size)-1:0],
		input logic  [p_dataWidth-1:0] io_twiddleFactorMemData[$clog2(p_size)-1:0][p_size-1:0],
		// Data input/output
		input logic  io_inActive,
		input logic  [p_dataWidth-1:0] io_inData[p_size-1:0],
		input logic  [p_dataWidth-1:0] io_inMod,
		input logic  [p_primeAddrWidth-1:0] io_inPrimeId,
		input logic  io_inIsInverse,
		output logic io_outActive,
		output logic [p_dataWidth-1:0] io_outData[p_size-1:0],
		output logic [p_dataWidth-1:0] io_outMod,
		output logic [p_primeAddrWidth-1:0] io_outPrimeId,
		output logic io_outIsInverse
	);

	// Derived param
	localparam p_level = $clog2(p_size);
	if (p_size != (1 << p_level)) $error("p_size not power of 2");
	localparam p_counterWidth = $clog2(p_level + 1);

	// Data on each level
	logic [p_dataWidth-1:0]
		w_levelInData[p_level-1:0][p_size-1:0],
		w_levelOutData[p_level-1:0][p_size-1:0];
	logic [p_dataWidth-1:0]
		w_levelInMod[p_level-1:0],
		w_levelOutMod[p_level-1:0];
	logic [p_primeAddrWidth-1:0]
		w_levelInPrimeId[p_level-1:0],
		w_levelOutPrimeId[p_level-1:0];
	logic w_levelInIsInverse[p_level-1:0], w_levelOutIsInverse[p_level-1:0];

	// Module
	// Butterfly units
	genvar levelId, blockId, i;
	generate
	case (p_type)
	NTT_TYPE_DIT: begin
		for (levelId = 0;levelId < p_level;levelId++) begin
			// Twiddle factor data for this level
			logic [p_dataWidth-1:0] w_curLevelTwiddleFactor[p_size-1:0];
			always_comb begin
				io_twiddleFactorMemPrimeId[levelId] = w_levelInPrimeId[levelId];
				io_twiddleFactorMemIsInverse[levelId] = w_levelInIsInverse[levelId];
				w_curLevelTwiddleFactor = io_twiddleFactorMemData[levelId];
			end
			// Inverse signal synchronized with data
			logic w_curLevelIsInverse;
			always_ff @(posedge clock) w_curLevelIsInverse <= w_levelInIsInverse[levelId];
			// Modules for each block
			localparam halfBlockSize = (1 << levelId);
			localparam blockSize = 2 * halfBlockSize;
			localparam blockNum = p_size / blockSize;
			for (blockId = 0;blockId < blockNum;blockId++) begin
				for (i = 0;i < halfBlockSize;i++) begin
					localparam idx1 = blockId * blockSize + i;
					localparam idx2 = blockId * blockSize + i + halfBlockSize;
					localparam twiddleExponentNormal = (2 * i + 1) * blockNum;
					localparam twiddleExponentInverse = (2 * i) * blockNum;
					// Current twiddle factor
					logic [p_dataWidth-1:0] w_twiddleFactor;
					assign w_twiddleFactor =
						w_curLevelIsInverse ?
						w_curLevelTwiddleFactor[twiddleExponentInverse] :
						w_curLevelTwiddleFactor[twiddleExponentNormal];
					NTTDITButterflyUnit #(
						.p_dataWidth(p_dataWidth)
					) m_butterfly(
						.clock, .reset,
						.io_inA(w_levelInData[levelId][idx1]),
						.io_inB(w_levelInData[levelId][idx2]),
						.io_twiddle(w_twiddleFactor),
						.io_mod(w_levelInMod[levelId]),
						.io_outA(w_levelOutData[levelId][idx1]),
						.io_outB(w_levelOutData[levelId][idx2])
					);
				end
			end
		end
	end
	NTT_TYPE_DIF: begin
		for (levelId = 0;levelId < p_level;levelId++) begin
			// Twiddle factor data for this level
			logic [p_dataWidth-1:0] w_curLevelTwiddleFactor[p_size-1:0];
			always_comb begin
				io_twiddleFactorMemPrimeId[levelId] = w_levelInPrimeId[levelId];
				io_twiddleFactorMemIsInverse[levelId] = w_levelInIsInverse[levelId];
				w_curLevelTwiddleFactor = io_twiddleFactorMemData[levelId];
			end
			// Inverse signal synchronized with data
			logic w_curLevelIsInverse;
			always_ff @(posedge clock) w_curLevelIsInverse <= w_levelInIsInverse[levelId];
			// Modules for each block
			localparam blockSize = (1 << (p_level - levelId));
			localparam halfBlockSize = blockSize / 2;
			localparam blockNum = p_size / blockSize;
			for (blockId = 0;blockId < blockNum;blockId++) begin
				for (i = 0;i < halfBlockSize;i++) begin
					localparam idx1 = blockId * blockSize + i;
					localparam idx2 = blockId * blockSize + i + halfBlockSize;
					localparam twiddleExponentNormal = (2 * i) * blockNum;
					localparam twiddleExponentInverse = (2 * i + 1) * blockNum;
					// Current twiddle factor
					logic [p_dataWidth-1:0] w_twiddleFactor;
					assign w_twiddleFactor =
						w_curLevelIsInverse ?
						w_curLevelTwiddleFactor[twiddleExponentInverse] :
						w_curLevelTwiddleFactor[twiddleExponentNormal];
					NTTDIFButterflyUnit #(
						.p_dataWidth(p_dataWidth)
					) m_butterfly(
						.clock, .reset,
						.io_inA(w_levelInData[levelId][idx1]),
						.io_inB(w_levelInData[levelId][idx2]),
						.io_twiddle(w_twiddleFactor),
						.io_mod(w_levelInMod[levelId]),
						.io_outA(w_levelOutData[levelId][idx1]),
						.io_outB(w_levelOutData[levelId][idx2])
					);
				end
			end
		end
	end
	default: $error("Unknown NTT type");
	endcase
	endgenerate

	// Delay primeId/isInverse at each level
	generate
		for (levelId = 0;levelId < p_level;levelId++) begin
			// Delay at each level
			SignalDelay #(
				.p_width(p_dataWidth + p_primeAddrWidth + 1),
				.p_delay(`NTTButterflyUnitDelay(p_dataWidth))
			) m_delay(
				.clock, .reset,
				.io_inData({
					w_levelInMod[levelId],
					w_levelInPrimeId[levelId],
					w_levelInIsInverse[levelId]
				}),
				.io_outData({
					w_levelOutMod[levelId],
					w_levelOutPrimeId[levelId],
					w_levelOutIsInverse[levelId]
				})
			);
		end
	endgenerate

	// Connect data between levels
	generate
		for (levelId = 0;levelId < p_level - 1;levelId++) begin
			always_comb begin
				w_levelInData[levelId + 1] = w_levelOutData[levelId];
				w_levelInMod[levelId + 1] = w_levelOutMod[levelId];
				w_levelInPrimeId[levelId + 1] = w_levelOutPrimeId[levelId];
				w_levelInIsInverse[levelId + 1] = w_levelOutIsInverse[levelId];
			end
		end
	endgenerate
	always_comb begin
		io_outData = w_levelOutData[p_level - 1];
		io_outMod = w_levelOutMod[p_level - 1];
		io_outPrimeId = w_levelOutPrimeId[p_level - 1];
		io_outIsInverse = w_levelOutIsInverse[p_level - 1];
	end
	always_comb begin
		w_levelInData[0] = io_inData;
		w_levelInMod[0] = io_inMod;
		w_levelInPrimeId[0] = io_inPrimeId;
		w_levelInIsInverse[0] = io_inIsInverse;
	end

	// Pass along active signal
	SignalDelayInit #(
		.p_width(1),
		.p_delay(`NTTUnitDelay(p_size, p_dataWidth)),
		.p_initValue(0)
	) m_activeDelay(
		.clock, .reset,
		.io_inData(io_inActive),
		.io_outData(io_outActive)
	);

endmodule: NTTUnit

// Twiddle factor memory ports required by NTTUnit
`define NTTUnitTwiddleFactorMemReadPortNum(p_size) \
	( $clog2(p_size) )
