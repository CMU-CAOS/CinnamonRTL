`default_nettype none

/*
 * Single layer of Benes network
 */
module AutomorphismBenesLayer
	#(parameter
		p_levelId = 0,
		p_size = 0,
		p_blockSize = 0,
		p_dataWidth = 0
	)
	(
		input logic  clock, reset,
		input logic  [p_dataWidth-1:0] io_inData[p_size-1:0],
		input logic  [2*$clog2(p_size)*(p_size/2)-1:0] io_inPermInfo,
		output logic [p_dataWidth-1:0] io_outData[p_size-1:0],
		output logic [2*$clog2(p_size)*(p_size/2)-1:0] io_outPermInfo
	);

	localparam p_halfSize = p_size / 2;
	localparam p_halfBlockSize = p_blockSize / 2;
	if (p_size % 2 != 0) $error("AutomorphismBenesLayer size not even");
	if (p_blockSize % 2 != 0) $error("AutomorphismBenesLayer block size not even");

	localparam p_blockNum = p_size / p_blockSize;

	// Permutation info for current level
	localparam p_permInfoLow = p_levelId*p_halfSize;
	localparam p_permInfoHigh = (p_levelId+1)*p_halfSize-1;
	logic [p_halfSize-1:0] w_curPermInfo;
	assign w_curPermInfo = io_inPermInfo[p_permInfoHigh:p_permInfoLow];

	logic [p_dataWidth-1:0] w_data[p_size-1:0];

	genvar blockId, i;
	generate
	for (blockId = 0;blockId < p_blockNum;blockId++) begin
		for (i = 0;i < p_halfBlockSize;i++) begin
			// Index of data/permutation info
			localparam permInfoIdx = blockId * p_halfBlockSize + i;
			localparam idx1 = blockId * p_blockSize + i;
			localparam idx2 = blockId * p_blockSize + i + p_halfBlockSize;

			// Swap idx1 and idx2?
			logic w_swap;
			assign w_swap = w_curPermInfo[permInfoIdx];
			always_comb begin
				w_data[idx1] = w_swap ? io_inData[idx2] : io_inData[idx1];
				w_data[idx2] = w_swap ? io_inData[idx1] : io_inData[idx2];
			end
		end
	end
	endgenerate

	always_ff @(posedge clock) begin
		io_outData <= w_data;
		io_outPermInfo <= io_inPermInfo;
	end

endmodule: AutomorphismBenesLayer

/*
 * Benes permutation network
 */
module AutomorphismPermutation
	#(parameter
		p_size = 0,
		p_dataWidth = 0
	)
	(
		input logic  clock, reset,
		input logic  [p_dataWidth-1:0] io_inData[p_size-1:0],
		input logic  [2*$clog2(p_size)*(p_size/2)-1:0] io_inPermInfo,
		output logic [p_dataWidth-1:0] io_outData[p_size-1:0],
		output logic [2*$clog2(p_size)*(p_size/2)-1:0] io_outPermInfo
	);

	localparam p_halfSize = p_size / 2;
	localparam p_level = $clog2(p_size);
	if (p_size != (1 << p_level)) $error("AutomorphismPermutation size not power of 2");
	localparam p_permInfoWidth = 2 * p_level * p_halfSize;

	logic [p_dataWidth-1:0] w_data[2*p_level:0][p_size-1:0];
	logic [p_permInfoWidth-1:0] w_permInfo[2*p_level:0];

	// Generate 2*p_layer of butterfly layer
	genvar levelId;
	generate
	for (levelId = 0;levelId < 2 * p_level;levelId++) begin
		localparam blockSize = levelId < p_level ?
			(1 << (p_level - levelId)) :
			(1 << (1 + levelId - p_level));
		AutomorphismBenesLayer #(
			.p_levelId(levelId),
			.p_size(p_size),
			.p_blockSize(blockSize),
			.p_dataWidth(p_dataWidth)
		) m_permForward(
			.clock, .reset,
			.io_inData(w_data[levelId]),
			.io_inPermInfo(w_permInfo[levelId]),
			.io_outData(w_data[levelId + 1]),
			.io_outPermInfo(w_permInfo[levelId + 1])
		);
	end
	endgenerate

	// Connect to io
	assign w_data[0] = io_inData;
	assign io_outData = w_data[2*p_level];

	assign w_permInfo[0] = io_inPermInfo;
	assign io_outPermInfo = w_permInfo[2*p_level];

endmodule: AutomorphismPermutation
`define AutomorphismPermutationDelay(p_size) \
	( 2 * $clog2(p_size) )


/*
 * Automorphism
 */
module Automorphism
	#(parameter
		p_rowSize = 0,
		p_clusterNum = 0,
		p_dataWidth = 0
	)
	(
		input logic  clock, reset,
		// Transpose port A
		output logic io_transposeInActiveA,
		output logic [p_dataWidth-1:0] io_transposeInDataA[p_rowSize-1:0],
		input logic  io_transposeOutActiveA,
		input logic  [p_dataWidth-1:0] io_transposeOutDataA[p_rowSize-1:0],
		// Transpose port B
		output logic io_transposeInActiveB,
		output logic [p_dataWidth-1:0] io_transposeInDataB[p_rowSize-1:0],
		input logic  io_transposeOutActiveB,
		input logic  [p_dataWidth-1:0] io_transposeOutDataB[p_rowSize-1:0],
		// Data
		input logic  io_inActive,
		input logic  [p_dataWidth-1:0] io_inData[p_rowSize-1:0],
		input logic  [2*$clog2(p_rowSize)*(p_rowSize/2)-1:0] io_colPermInfo, io_rowPermInfo,
		output logic io_outActive,
		output logic [p_dataWidth-1:0] io_outData[p_rowSize-1:0]
	);

	// Derive permutation params
	localparam p_halfSize = p_rowSize / 2;
	localparam p_rowLevel = $clog2(p_rowSize);
	if (p_rowSize != (1 << p_rowLevel)) $error("AutomorphismPermutation size not power of 2");
	localparam p_permInfoWidth = 2 * p_rowLevel * p_halfSize;
	if (p_rowSize % p_clusterNum != 0) $error("row size not multiples of cluster num");
	localparam p_colSize = p_rowSize / p_clusterNum;

	logic [p_dataWidth-1:0]
		w_data1[p_rowSize-1:0],
		w_data2[p_rowSize-1:0],
		w_data3[p_rowSize-1:0];
	logic [p_permInfoWidth-1:0] w_rowPermInfo1, w_rowPermInfo2;
	logic w_active1, w_active2, w_active3;
	genvar i;

	// Stage 1 - column permutation
	AutomorphismPermutation #(
		.p_size(p_rowSize),
		.p_dataWidth(p_dataWidth)
	) m_permutation1(
		.clock, .reset,
		.io_inData(io_inData),
		.io_inPermInfo(io_colPermInfo),
		.io_outData(w_data1),
		.io_outPermInfo()
	);
	// Pass along active and rowPermInfo
	SignalDelay #(
		.p_width(p_permInfoWidth),
		.p_delay(`AutomorphismPermutationDelay(p_rowSize))
	) m_perm1Delay(
		.clock, .reset,
		.io_inData(io_rowPermInfo),
		.io_outData(w_rowPermInfo1)
	);
	SignalDelayInit #(
		.p_width(1),
		.p_delay(`AutomorphismPermutationDelay(p_rowSize))
	) m_perm1DelayActive(
		.clock, .reset,
		.io_inData(io_inActive),
		.io_outData(w_active1)
	);

	// Stage 2 - transpose
	assign io_transposeInActiveA = w_active1;
	assign io_transposeInDataA = w_data1;
	assign w_active2 = io_transposeOutActiveA;
	assign w_data2 = io_transposeOutDataA;
	// Pass along rowPermInfo
	SignalDelay #(
		.p_width(p_permInfoWidth),
		.p_delay(`TransposeDelay(p_colSize))
	) m_transpose1Delay(
		.clock, .reset,
		.io_inData(w_rowPermInfo1),
		.io_outData(w_rowPermInfo2)
	);

	// Stage 3 - row permutation
	AutomorphismPermutation #(
		.p_size(p_rowSize),
		.p_dataWidth(p_dataWidth)
	) m_permutation3(
		.clock, .reset,
		.io_inData(w_data2),
		.io_inPermInfo(w_rowPermInfo2),
		.io_outData(w_data3),
		.io_outPermInfo()
	);
	// Pass along active
	SignalDelayInit #(
		.p_width(1),
		.p_delay(`AutomorphismPermutationDelay(p_rowSize))
	) m_perm2Delay(
		.clock, .reset,
		.io_inData(w_active2),
		.io_outData(w_active3)
	);

	// Stage 4 - transpose
	assign io_transposeInActiveB = w_active3;
	assign io_transposeInDataB = w_data3;
	assign io_outActive = io_transposeOutActiveB;
	assign io_outData = io_transposeOutDataB;

endmodule: Automorphism
`define AutomorphismDelay(p_rowSize, p_clusterNum) \
	( \
		2 * `AutomorphismPermutationDelay(p_rowSize) + \
		2 * `TransposeDelay(p_rowSize / p_clusterNum) \
	)

// Calculate PermInfo width
`define AutomorphismPermInfoWidth(p_rowSize) \
	( 2*$clog2(p_rowSize)*(p_rowSize/2) )


/*
 * Permutation info memory
 */
module AutomorphismPermInfoMem
	#(parameter
		p_primeNum = 0,
		p_primeAddrWidth = 0,
		p_rowSize = 0,
		p_clusterNum = 0,
		p_dataWidth = 0,
		p_addrWidth = 0,
		p_readPortNum = 0
	)
	(
		input logic  clock, reset,
		input logic  [p_primeAddrWidth-1:0] io_primeId[p_readPortNum-1:0],
		input logic  [p_addrWidth-1:0] io_addr[p_readPortNum-1:0],
		output logic [`AutomorphismPermInfoWidth(p_rowSize)-1:0]
			io_colPermInfo[p_readPortNum-1:0],
			io_rowPermInfo[p_readPortNum-1:0]
	);

	localparam p_permInfoWidth = `AutomorphismPermInfoWidth(p_rowSize);
	if (p_rowSize % p_clusterNum != 0) $error("row size not multiples of cluster num");
	localparam p_colSize = p_rowSize / p_clusterNum;

	// Memory
	logic [p_permInfoWidth-1:0] r_col[p_primeNum-1:0][p_colSize-1:0];
	logic [p_permInfoWidth-1:0] r_row[p_primeNum-1:0][p_colSize-1:0];

	// Read ports
	genvar readPortId;
	generate
	for (readPortId = 0;readPortId < p_readPortNum;readPortId++) begin
		logic [p_primeAddrWidth-1:0] r_primeId;
		logic [p_addrWidth-1:0] r_addr;
		always_ff @(posedge clock) begin
			r_primeId <= io_primeId[readPortId];
			r_addr <= io_addr[readPortId];
		end
		assign io_colPermInfo[readPortId] = r_col[r_primeId][r_addr];
		assign io_rowPermInfo[readPortId] = r_row[r_primeId][r_addr];
	end
	endgenerate

endmodule: AutomorphismPermInfoMem
