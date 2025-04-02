`default_nettype none

/*
 * Overall transpose FU
 */
module Transpose
	#(parameter
		p_rowSize = 0,
		p_clusterNum = 0,
		p_dataWidth = 0
	)
	(
		input logic  clock, reset,
		input logic  io_inActive,
		input logic  [p_dataWidth-1:0] io_inData[p_rowSize-1:0],
		output logic io_outActive,
		output logic [p_dataWidth-1:0] io_outData[p_rowSize-1:0],
		output logic [p_dataWidth-1:0] io_networkInData[p_rowSize-1:0],
		input logic  [p_dataWidth-1:0] io_networkOutData[p_rowSize-1:0]
	);

	// Derive column size
	if (p_rowSize % p_clusterNum != 0) $error("row size not multiples of cluster num");
	localparam p_colSize = p_rowSize / p_clusterNum;
	localparam p_transposeLevel = $clog2(p_colSize);
	if (p_colSize != (1 << p_transposeLevel)) $error("col size not power of 2");

	// Transpose full module
	logic [p_dataWidth-1:0]
		w_transposeSingleInData[p_clusterNum-1:0][p_colSize-1:0],
		w_transposeSingleOutData[p_clusterNum-1:0][p_colSize-1:0];
	logic [p_dataWidth-1:0]
		w_transposeInData[p_rowSize-1:0],
		w_transposeOutData[p_rowSize-1:0];
	genvar blockId, i;
	generate
	for (blockId = 0;blockId < p_clusterNum;blockId++) begin
		TransposeFull #(
			.p_rowSize(p_colSize),
			.p_colSize(p_colSize),
			.p_level(p_transposeLevel),
			.p_dataWidth(p_dataWidth)
		) m_transposeFull(
			.clock, .reset,
			.io_inActive,
			.io_inData(w_transposeSingleInData[blockId]),
			.io_outActive(),
			.io_outData(w_transposeSingleOutData[blockId])
		);
	end
	endgenerate
	SignalDelayInit #(
		.p_width(1),
		.p_delay(p_colSize + $clog2(p_colSize) - 1),
		.p_initValue(0)
	) m_delay(
		.clock, .reset,
		.io_inData(io_inActive),
		.io_outData(io_outActive)
	);
	// Connect data to single transpose unit
	generate
		for (blockId = 0;blockId < p_clusterNum;blockId++) begin
			for (i = 0;i < p_colSize;i++) begin
				always_comb begin
					w_transposeSingleInData[blockId][i] = w_transposeInData[i * p_clusterNum + blockId];
					w_transposeOutData[i * p_clusterNum + blockId] = w_transposeSingleOutData[blockId][i];
				end
			end
		end
	endgenerate

	// Dataflow: input data -> TransposeFull -> TransposeNetwork -> output data
	assign w_transposeInData = io_inData;
	assign io_networkInData = w_transposeOutData;
	assign io_outData = io_networkOutData;
	
endmodule: Transpose
`define TransposeDelay(p_colSize) \
	( p_colSize + $clog2(p_colSize) - 1 )
