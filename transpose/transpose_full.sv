`default_nettype none

/*
 * Full transpose unit
 * Transpose a stream of input columns to a stream of output columns
 */
module TransposeFull
	#(parameter
		p_rowSize = 0,
		p_colSize = 0,
		p_level = 0,
		p_dataWidth = 0
	)
	(
		input logic  clock, reset,
		input logic  io_inActive,
		input logic  [p_dataWidth-1:0] io_inData[p_rowSize-1:0],
		output logic io_outActive,
		output logic [p_dataWidth-1:0] io_outData[p_rowSize-1:0]
	);

	// Derive counter width
	localparam p_counterWidth = $clog2(p_colSize);
	localparam p_addrWidth = $clog2(p_colSize);

	// Data on each level
	logic w_active[p_level:0];
	logic [p_dataWidth-1:0] w_data[p_level:0][p_rowSize-1:0];

	// Module instantiations
	genvar level, block;
	generate
	for (level = 0;level < p_level;level++) begin
		// Check division
		localparam unitNum = 1 << level;
		if (p_rowSize % unitNum != 0 ||
			p_colSize % unitNum != 0) begin
			$error("rows not multiplies of unit num");
		end
		localparam unitRow = p_rowSize / unitNum;
		localparam unitCol = p_colSize / unitNum;

		// Create unit_num of transpose units
		for (block = 0;block < (1 << level);block++) begin
			TransposeUnit #(
				.p_rowSize(unitRow),
				.p_colSize(unitCol),
				.p_dataWidth(p_dataWidth),
				.p_addrWidth(p_addrWidth)
			) m_transpose(
				.clock, .reset,
				.io_inActive(w_active[level]),
				.io_inData(w_data[level][unitRow*(block+1)-1:unitRow*block]),
				.io_outActive(),
				.io_outData(w_data[level+1][unitRow*(block+1)-1:unitRow*block])
			);
		end

		// Active signal
		SignalDelayInit #(
			.p_width(1),
			.p_delay(unitCol / 2 + 1),
			.p_initValue(0)
		) m_delay(
			.clock, .reset,
			.io_inData(w_active[level]),
			.io_outData(w_active[level + 1])
		);
	end
	endgenerate

	// Connections to begin/end of w_data
	assign w_active[0] = io_inActive;
	assign w_data[0] = io_inData;
	assign io_outActive = w_active[p_level];
	assign io_outData = w_data[p_level];

endmodule: TransposeFull
