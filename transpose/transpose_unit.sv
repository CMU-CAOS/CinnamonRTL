`default_nettype none


/*
 * Swap unit for transpose high
 */
module TransposeHighSwapUnit
	#(parameter
		p_size = 0,
		p_dataWidth = 0
	)
	(
		input logic  io_swapEnable,
		input logic  [p_dataWidth-1:0] io_inData[p_size-1:0],
		output logic [p_dataWidth-1:0] io_outData[p_size-1:0]
	);

	// Derived values
	if (p_size % 2 != 0) $error("Transpose swap size odd");
	localparam p_halfSize = p_size / 2;

	// Swap first/second half?
	always_comb begin
		if (io_swapEnable) begin
			io_outData[2*p_halfSize-1:p_halfSize] = io_inData[p_halfSize-1:0];
			io_outData[p_halfSize-1:0] = io_inData[2*p_halfSize-1:p_halfSize];
		end else begin
			io_outData = io_inData;
		end
	end

endmodule: TransposeHighSwapUnit


/*
 * Single transpose unit
 * Transpose a stream of input columns to a stream of output columns
 * Only transpose quadrants
 */
module TransposeHigh
	#(parameter
		p_rowSize = 0,
		p_colSize = 0,
		p_dataWidth = 0,
		p_addrWidth = 0
	)
	(
		input logic  clock, reset,
		input logic  io_inActive,
		input logic  [p_dataWidth-1:0] io_inData[p_rowSize-1:0],
		output logic io_outActive,
		output logic [p_dataWidth-1:0] io_outData[p_rowSize-1:0]
	);

	// Derived parameter
	if (p_colSize == 2) $error("TransposeHigh col size 2");
	if (p_rowSize % 2 != 0) $error("TransposeHigh row size odd");
	if (p_colSize % 2 != 0) $error("TransposeHigh col size odd");
	localparam p_halfRowSize = p_rowSize / 2;
	localparam p_halfColSize = p_colSize / 2;

	// Local controls
	logic w_swapLeftEnable;
	logic r_swapRightEnable, w_swapRightEnableNext;
	// Registers for writing into buffer
	logic [p_addrWidth-1:0] r_bufWriteAddr, w_bufWriteAddrNext;
	logic r_bufTopWriteEnable, w_bufTopWriteEnableNext;
	logic r_bufBottomWriteEnable, w_bufBottomWriteEnableNext;
	logic [p_dataWidth-1:0] r_bufTopWriteData[p_halfRowSize-1:0], w_bufTopWriteDataNext[p_halfRowSize-1:0];
	logic [p_dataWidth-1:0] r_bufBottomWriteData[p_halfRowSize-1:0], w_bufBottomWriteDataNext[p_halfRowSize-1:0];
	// Bypass bottom
	logic r_bottomBypassEnable, w_bottomBypassEnableNext;
	logic [p_dataWidth-1:0] r_bottomBypassData[p_halfRowSize-1:0], w_bottomBypassDataNext[p_halfRowSize-1:0];
	// Data from swap unit and buffer
	logic [p_dataWidth-1:0] w_swapLeftOutData[p_rowSize-1:0], w_swapRightInData[p_rowSize-1:0];
	logic [p_dataWidth-1:0] w_bufTopReadData[p_halfRowSize-1:0], w_bufBottomReadData[p_halfRowSize-1:0];

	// Register
	always_ff @(posedge clock) begin
		r_swapRightEnable <= w_swapRightEnableNext;
		r_bufWriteAddr <= w_bufWriteAddrNext;
		r_bufTopWriteEnable <= w_bufTopWriteEnableNext;
		r_bufBottomWriteEnable <= w_bufBottomWriteEnableNext;
		r_bufTopWriteData <= w_bufTopWriteDataNext;
		r_bufBottomWriteData <= w_bufBottomWriteDataNext;
		r_bottomBypassEnable <= w_bottomBypassEnableNext;
		r_bottomBypassData <= w_bottomBypassDataNext;
	end

	// Read/Write column id
	logic [p_addrWidth-1:0] r_readCol, w_readColInc, w_readColClr,
		r_writeCol, w_writeColInc, w_writeColClr;
	always_ff @(posedge clock) begin
		if (reset || w_readColClr) begin
			r_readCol <= 0;
		end else if (w_readColInc) begin
			r_readCol <= r_readCol + 1;
		end
	end
	always_ff @(posedge clock) begin
		if (reset || w_writeColClr) begin
			r_writeCol <= 0;
		end else if (w_writeColInc) begin
			r_writeCol <= r_writeCol + 1;
		end
	end

	// State machine
	enum { STAGE02, STAGE1 } r_state, w_stateNext;
	always_ff @(posedge clock) begin
		if (reset) begin
			r_state <= STAGE02;
		end else begin
			r_state <= w_stateNext;
		end
	end

	// Module instantiations
	// Top/bottom buffers
	RectMem #(
		.p_rowSize(p_halfRowSize),
		.p_colSize(p_halfColSize),
		.p_dataWidth(p_dataWidth),
		.p_addrWidth(p_addrWidth)
	) m_bufTop(
		.clock, .reset,
		.io_readAddr(r_readCol),
		.io_readData(w_bufTopReadData),
		.io_writeAddr(r_bufWriteAddr),
		.io_writeData(r_bufTopWriteData),
		.io_writeEnable(r_bufTopWriteEnable)
	), m_bufBottom(
		.clock, .reset,
		.io_readAddr(r_readCol),
		.io_readData(w_bufBottomReadData),
		.io_writeAddr(r_bufWriteAddr),
		.io_writeData(r_bufBottomWriteData),
		.io_writeEnable(r_bufBottomWriteEnable)
	);
	// Swap units
	TransposeHighSwapUnit #(
		.p_size(p_rowSize),
		.p_dataWidth(p_dataWidth)
	) m_swapLeft(
		.io_swapEnable(w_swapLeftEnable),
		.io_inData(io_inData),
		.io_outData(w_swapLeftOutData)
	), m_swapRight(
		.io_swapEnable(r_swapRightEnable),
		.io_inData(w_swapRightInData),
		.io_outData(io_outData)
	);

	// Connections
	always_comb begin
		// Bypass data connection
		w_bottomBypassDataNext = w_swapLeftOutData[2*p_halfRowSize-1:p_halfRowSize];
		// Buffer connection
		w_bufTopWriteDataNext = w_swapLeftOutData[p_halfRowSize-1:0];
		w_bufBottomWriteDataNext = w_swapLeftOutData[2*p_halfRowSize-1:p_halfRowSize];
		// Right connection
		w_swapRightInData[p_halfRowSize-1:0] = w_bufTopReadData;
		w_swapRightInData[2*p_halfRowSize-1:p_halfRowSize] =
			r_bottomBypassEnable ?
			r_bottomBypassData :
			w_bufBottomReadData;
	end

	// Case on mode
	always_comb begin
		w_swapLeftEnable = 0;
		w_swapRightEnableNext = 0;
		w_bottomBypassEnableNext = 0;

		w_bufTopWriteEnableNext = 0;
		w_bufBottomWriteEnableNext = 0;

		w_bufWriteAddrNext = r_writeCol;

		w_readColClr = 0;
		w_readColInc = 0;
		w_writeColClr = 0;
		w_writeColInc = 0;
		w_stateNext = r_state;

		unique case (r_state)
		STAGE1: begin
			w_swapLeftEnable = 1;
			w_swapRightEnableNext = 0;
			w_bottomBypassEnableNext = 1;

			w_bufTopWriteEnableNext = 1;
			w_bufBottomWriteEnableNext = 0;

			w_readColInc = 1;
			w_writeColInc = 1;

			if (r_writeCol == p_halfColSize - 1) begin
				w_readColClr = 1;
				w_writeColClr = 1;
				w_stateNext = STAGE02;
			end
		end
		// Stage 0 + Stage 2: store A/C and output previous C/D
		STAGE02: begin
			w_swapLeftEnable = 0;
			w_swapRightEnableNext = 1;
			w_bottomBypassEnableNext = 0;

			w_bufTopWriteEnableNext = 1;
			w_bufBottomWriteEnableNext = 1;

			w_readColInc = 1;
			if (io_inActive) w_writeColInc = 1;
			if (r_writeCol == p_halfColSize - 1) begin
				w_readColClr = 1;
				w_writeColClr = 1;
				w_stateNext = STAGE1;
			end
		end
		endcase
	end

	// Delay active signal
	SignalDelayInit #(
		.p_width(1),
		.p_delay(p_halfColSize + 1),
		.p_initValue(0)
	) m_delay(
		.clock, .reset,
		.io_inData(io_inActive),
		.io_outData(io_outActive)
	);

endmodule: TransposeHigh


/*
 * Single transpose unit for ?x2 matrix
 * Prevent reading/writing to the same address in the same cycle
 * Only transpose quadrants
 */
module TransposeTwo
	#(parameter
		p_rowSize = 0,
		p_colSize = 0,
		p_dataWidth = 0,
		p_addrWidth = 0
	)
	(
		input logic  clock, reset,
		input logic  io_inActive,
		input logic  [p_dataWidth-1:0] io_inData[p_rowSize-1:0],
		output logic io_outActive,
		output logic [p_dataWidth-1:0] io_outData[p_rowSize-1:0]
	);

	// Derived parameter
	// Check ?x2
	if (p_colSize != 2) $error("TransposeTwo col size not 2");
	if (p_rowSize % 2 != 0) $error("TransposeTwo col size odd");
	localparam p_halfRowSize = p_rowSize / 2;

	// Local controls
	logic [p_dataWidth-1:0] r_A[p_halfRowSize-1:0], w_ANext[p_halfRowSize-1:0];
	logic [p_dataWidth-1:0] r_C[p_halfRowSize-1:0], w_CNext[p_halfRowSize-1:0];
	logic [p_dataWidth-1:0] r_outDataTop[p_halfRowSize-1:0], w_outDataTopNext[p_halfRowSize-1:0];
	logic [p_dataWidth-1:0] r_outDataBottom[p_halfRowSize-1:0], w_outDataBottomNext[p_halfRowSize-1:0];
	logic [p_dataWidth-1:0] w_inDataTop[p_halfRowSize-1:0];
	logic [p_dataWidth-1:0] w_inDataBottom[p_halfRowSize-1:0];

	// Register
	always_ff @(posedge clock) begin
		r_A <= w_ANext;
		r_C <= w_CNext;
		r_outDataTop <= w_outDataTopNext;
		r_outDataBottom <= w_outDataBottomNext;
	end

	// State machine
	enum { STAGE02, STAGE1 } r_state, w_stateNext;
	always_ff @(posedge clock) begin
		if (reset) begin
			r_state <= STAGE02;
		end else begin
			r_state <= w_stateNext;
		end
	end

	// Connections
	always_comb begin
		w_inDataTop = io_inData[p_halfRowSize-1:0];
		w_inDataBottom = io_inData[2*p_halfRowSize-1:p_halfRowSize];
		io_outData[p_halfRowSize-1:0] = r_outDataTop;
		io_outData[2*p_halfRowSize-1:p_halfRowSize] = r_outDataBottom;
	end

	// Case on mode
	always_comb begin
		w_ANext = '{default: '0};
		w_CNext = '{default: '0};
		w_outDataTopNext = '{default: '0};
		w_outDataBottomNext = '{default: '0};

		w_stateNext = r_state;

		unique case (r_state)
		STAGE1: begin
			w_outDataTopNext = r_A;
			w_outDataBottomNext = w_inDataTop;

			w_ANext = w_inDataBottom;
			w_CNext = r_C;

			w_stateNext = STAGE02;
		end
		// Stage 0 + Stage 2
		STAGE02: begin
			w_outDataTopNext = r_C;
			w_outDataBottomNext = r_A;

			w_ANext = w_inDataTop;
			w_CNext = w_inDataBottom;

			w_stateNext = io_inActive ? STAGE1 : STAGE02;
		end
		endcase
	end

	// Delay active signal
	SignalDelayInit #(
		.p_width(1),
		.p_delay(2),
		.p_initValue(0)
	) m_delay(
		.clock, .reset,
		.io_inData(io_inActive),
		.io_outData(io_outActive)
	);

endmodule: TransposeTwo


/*
 * Single transpose unit (for all widths)
 * Transpose a stream of input columns to a stream of output columns
 * Only transpose quadrants
 */
module TransposeUnit
	#(parameter
		p_rowSize = 0,
		p_colSize = 0,
		p_dataWidth = 0,
		p_addrWidth = 0
	)
	(
		input logic  clock, reset,
		input logic  io_inActive,
		input logic  [p_dataWidth-1:0] io_inData[p_rowSize-1:0],
		output logic io_outActive,
		output logic [p_dataWidth-1:0] io_outData[p_rowSize-1:0]
	);

	// Select one transpose module
	generate
		if (p_colSize == 2) begin
			TransposeTwo #(
				.p_rowSize(p_rowSize),
				.p_colSize(p_colSize),
				.p_dataWidth(p_dataWidth),
				.p_addrWidth(p_addrWidth)
			) m_transpose(.*);
		end else begin
			TransposeHigh #(
				.p_rowSize(p_rowSize),
				.p_colSize(p_colSize),
				.p_dataWidth(p_dataWidth),
				.p_addrWidth(p_addrWidth)
			) m_transpose(.*);
		end
	endgenerate

endmodule: TransposeUnit
