`default_nettype none

module ChangeRNSBaseMultiplyAccumulate 
	#(parameter
		p_dataWidth = 28,
		p_numInputPairs = 0
	)
	(
		input logic  clock, reset,
		input logic [p_dataWidth-1:0] io_A [0:p_numInputPairs - 1],
		input logic [p_dataWidth-1:0] io_B [0:p_numInputPairs - 1],
		input logic [p_dataWidth-1:0] io_q,
		output logic [p_dataWidth-1:0] io_result
	);

	// logic [p_dataWidth-1:0] temp_product_w [0:p_numInputPairs-1];
	logic [p_dataWidth-1:0] temp_product [0:p_numInputPairs-1];
	genvar i;

	generate for (i = 0; i < p_numInputPairs; i+=1) begin: multiplier
		MontgomeryMultiplierWrapper m_mult(
			.clock(clock),
			.io_A(io_A[i]),
			.io_B(io_B[i]),
			.io_q(io_q),
			.io_result(temp_product[i])
		);
	end
	endgenerate
	
	localparam numAdderStages = $clog2(p_numInputPairs);
	logic [p_dataWidth-1:0] intermediate_sum_w[1:numAdderStages][0:p_numInputPairs-1];
	logic [p_dataWidth-1:0] intermediate_sum[0:numAdderStages-1][0:p_numInputPairs-1];

	always_ff @(posedge clock) begin
		intermediate_sum[0] <= temp_product;
		// $display("A=%d B=%d R=%d",io_A[0],io_B[0],temp_product[0]);
	end


	generate for (i = 0; i < numAdderStages; i++) begin: adder 
		genvar j;
		localparam step_size = 2 ** i;
		for (j = 0; j < p_numInputPairs; j+=2*step_size) begin
			if (j+step_size < p_numInputPairs) begin 
				// always @(posedge clock) begin
				// 	$display("i=%d j=%d j+ss=%d",i,j,j+step_size);
				// end
				ModularAdder #(
					.p_dataWidth(p_dataWidth)
				) m_adder (
					.io_A(intermediate_sum[i][j]),
					.io_B(intermediate_sum[i][j+step_size]),
					.io_result(intermediate_sum_w[i+1][j]),
					.io_mod(io_q)
				);
			end else begin
				// always @(posedge clock) begin
				// 	$display("i=%d j=%d",i,j);
				// end
				assign intermediate_sum_w[i+1][j] = intermediate_sum[i][j];
			end
		end
		always_ff @(posedge clock) begin
			if( i != numAdderStages - 1) begin
				intermediate_sum[i+1] <= intermediate_sum_w[i+1];
			end
		end
	end
	endgenerate
	assign io_result = intermediate_sum_w[numAdderStages][0];

endmodule : ChangeRNSBaseMultiplyAccumulate

module ChangeRNSBaseLane 
	#(parameter
		p_dataWidth = 28,
		p_numBlocks = 0,
		// p_numPrimes = 64,
		p_numRows = 0,
		localparam p_rowAddrWidth = $clog2(p_numRows)
	)(
		input logic  clock, reset,
		// input logic [p_dataWidth-1:0] io_A [0:p_numInputPairs - 1],
		// input logic  io_outputBaseId,
		input logic [p_rowAddrWidth-1:0] io_rowAddr, 
		input logic io_readBufId, 
		input logic io_readBlockSelect [0:p_numBlocks-1],
		
		input logic  io_writeBufId,
		// input logic io_writeEnable [0:p_numBlocks-1], 
		input logic [0:p_numBlocks-1] io_writeEnable, 
		input logic [p_rowAddrWidth-1:0] io_writeRowAddr, 
		input logic [p_dataWidth-1:0] io_writeData,

		input logic [p_dataWidth-1:0] io_baseConvFactors [0:p_numBlocks - 1],
		input logic [p_dataWidth-1:0] io_q,

		output logic [p_dataWidth-1:0] io_result
	);

	logic [p_dataWidth-1:0] w_bufReadData[0:p_numBlocks-1];
	logic [p_dataWidth-1:0] multiply_accumulate_input [0:p_numBlocks-1];

	genvar bufId, blockId;
	generate
	// for (bufId = 0;bufId < 2;bufId++) begin: buffer
		for (blockId = 0; blockId < p_numBlocks; blockId++) begin : block
			BankedMemory #(
				.p_numRows(p_numRows),
				.p_numBanks(2),
				.p_dataWidth(p_dataWidth)
			) m_buffer(
				.clock, .reset,
				.io_readAddr({io_readBufId, io_rowAddr}),
				.io_writeAddr({io_writeBufId, io_writeRowAddr}),
				.io_writeEnable(io_writeEnable[blockId]),
				.io_writeData(io_writeData),
				.io_readData(w_bufReadData[blockId])
			);
		end
	// end
	endgenerate

	generate
		for (blockId= 0;blockId < p_numBlocks;blockId++) begin
			always_comb begin
				if(io_readBlockSelect[blockId]) begin
					multiply_accumulate_input[blockId] = w_bufReadData[blockId];
				end else begin
					multiply_accumulate_input[blockId] = 0;
				end
			end
		end
	endgenerate

	// generate
	// always @(posedge clock) begin
	// 	$display("io_rowAddr=%d multiply_Accumulate_input=%d",io_rowAddr,multiply_accumulate_input[0]);
	// 	$display("io_rowAddr=%d multiply_Accumulate_input=%d",io_rowAddr,multiply_accumulate_input[1]);
	// 	$display("io_rowAddr=%d multiply_Accumulate_input=%d",io_rowAddr,multiply_accumulate_input[2]);
	// 	$display("io_rowAddr=%d multiply_Accumulate_input=%d",io_rowAddr,multiply_accumulate_input[3]);
	// 	$display("read_block_select=%d",io_readBlockSelect[3]);
	// end
	// endgenerate

	ChangeRNSBaseMultiplyAccumulate #(
		.p_dataWidth(p_dataWidth),
		.p_numInputPairs(p_numBlocks)
	) multiply_accumulate (
		.clock,
		.reset,
		.io_A(multiply_accumulate_input),
		.io_B(io_baseConvFactors),
		.io_q(io_q),
		.io_result(io_result)
	);

endmodule: ChangeRNSBaseLane

module ChangeRNSBase
	#(parameter
		p_dataWidth = 28,
		p_numBlocks = 5,
		p_numLanes = 4,
		p_numRows = 4,
		// p_numPrimes = 64,
		localparam p_rowAddrWidth = $clog2(p_numRows)
	)(
		input logic  clock, reset,
		// input logic [$(p_numB)] io_outputBaseId,
		input logic [p_rowAddrWidth-1:0] io_rowAddr, 
		input logic io_readBufId, 
		input logic io_readBlockSelect [0:p_numBlocks-1],
		
		input logic io_writeEnable, 
		input logic  io_writeBufId,
		input logic [$clog2(p_numBlocks)-1:0] io_writeBlockId, 
		input logic [p_rowAddrWidth-1:0] io_writeRowAddr, 
		input logic [p_dataWidth-1:0] io_writeData [0:p_numLanes-1],

		input logic [p_dataWidth-1:0] io_baseConvFactors [0:p_numBlocks - 1],
		input logic [p_dataWidth-1:0] io_q,
		output logic [p_dataWidth-1:0] io_result [0:p_numLanes-1]
	);

	// logic [p_numBlocks-1:0] io_writeBlockIdDecode;
	logic [0:p_numBlocks-1] io_writeBlockIdDecode;
	assign io_writeBlockIdDecode = {{io_writeEnable}, {{p_numBlocks - 1}{1'b0}}} >> io_writeBlockId;

		// always_ff @(posedge clock) begin
		// 	$display("io_writeBlockIdDecode=%b",io_writeBlockIdDecode);
		// 	// $display("io_writeBlockIdDecode=%b",io_writeBlockIdDecode[1]);
		// end

	genvar laneId;
	generate
		for (laneId = 0; laneId < p_numLanes;laneId++) begin : crb_lane
			ChangeRNSBaseLane #(
				.p_dataWidth(p_dataWidth),
				.p_numBlocks(p_numBlocks),
				.p_numRows(p_numRows)
			) m_crb_lane (
				.clock,
				.reset,
				.io_rowAddr,
				.io_readBufId,
				.io_readBlockSelect,
				.io_writeBufId,
				.io_writeEnable(io_writeBlockIdDecode),
				.io_writeRowAddr,
				.io_writeData(io_writeData[laneId]),
				.io_result(io_result[laneId]),
				.io_q,
				.io_baseConvFactors
			);
		end
	endgenerate

		// always_ff @(posedge clock) begin
		// 	$display("writeRowAddr=%d, writeValue =%d",io_writeRowAddr, crb_lane[0].m_crb_lane.block[2].m_buffer.mem[io_writeBufId][io_writeRowAddr]);
		// 	// $display("io_writeBlockIdDecode=%d",io_writeBlockIdDecode[1]);
		// end

		// always_ff @(posedge clock) begin
			// $display("readRowAddr=%d, readValue =%d",io_readRowAddr, crb_lane[0].m_crb_lane.w_bufReadData[1]);
			// $display("readRowAddr=%d, readValue =%d",io_rowAddr, crb_lane[0].m_crb_lane.io_result);
			// $display("io_writeBlockIdDecode=%d",io_writeBlockIdDecode[1]);
		// end



endmodule : ChangeRNSBase

// /*
//  * Polynomial multiplication/addition
//  */
// module ChangeRNSBasePolyMultAdd
// 	#(
// 		p_rowSize = 0,
// 		p_colSize = 0,
// 		p_rowAddrWidth = 0,
// 		p_dataWidth = 0
// 	)
// 	(
// 		input logic  clock, reset,

// 		// Write port
// 		input logic  io_writeActive,
// 		input logic  io_writeBufId,
// 		input logic  io_writeIsAccumulate,
// 		input logic  [p_rowAddrWidth-1:0] io_writeRow,
// 		input logic  [p_dataWidth-1:0] io_writeConst,
// 		input logic  [p_dataWidth-1:0] io_writeData[0:p_rowSize-1],

// 		// Read port
// 		input logic  io_readBufId,
// 		input logic  [p_rowAddrWidth-1:0] io_readRow,
// 		output logic [p_dataWidth-1:0] io_readData[0:p_rowSize-1]
// 	);

// 	// Mod (should be programmable by some opcode?)
// 	logic [p_dataWidth-1:0] r_mod;

// 	// Double buffer
// 	logic [p_rowAddrWidth-1:0] w_bufReadAddr[0:1], w_bufWriteAddr[0:1];
// 	logic w_bufWriteEnable[0:1];
// 	logic [p_dataWidth-1:0]
// 		w_bufReadData[0:1][0:p_rowSize-1],
// 		w_bufWriteData[0:1][0:p_rowSize-1];
// 	genvar bufId;
// 	generate
// 	for (bufId = 0;bufId < 2;bufId++) begin: buffer
// 		RectMem #(
// 			.p_rowSize(p_rowSize),
// 			.p_colSize(p_colSize),
// 			.p_dataWidth(p_dataWidth),
// 			.p_addrWidth(p_rowAddrWidth)
// 		) m_buffer(
// 			.clock, .reset,
// 			.io_readAddr(w_bufReadAddr[bufId]),
// 			.io_readData(w_bufReadData[bufId]),
// 			.io_writeAddr(w_bufWriteAddr[bufId]),
// 			.io_writeData(w_bufWriteData[bufId]),
// 			.io_writeEnable(w_bufWriteEnable[bufId])
// 		);
// 	end
// 	endgenerate

// 	// Montgomery form: montgomery = writeData * montgomeryR
// 	// Multiplication: multData = const * montgomery
// 	logic [p_dataWidth-1:0] w_multData[0:p_rowSize-1];
// 	logic w_multActive, w_multActivePrev;
// 	logic w_multBufId, w_multIsAccumulate, w_multBufIdPrev;
// 	logic [p_rowAddrWidth-1:0] w_multRow, w_multRowPrev;
// 	// Multipliers
// 	genvar i;
// 	generate
// 	for (i = 0;i < p_rowSize;i++) begin
// 		MontgomeryMultiplierWrapper #(
// 			.p_dataWidth(p_dataWidth)
// 		) m_mult(
// 			.clock,
// 			.io_A(io_writeConst),
// 			.io_B(io_writeData[i]),
// 			.io_q(r_mod),
// 			.io_result(w_multData[i])
// 		);
// 	end
// 	endgenerate
// 	// Delay bufId and row until buffer read time
// 	// (1 cycle before mult complete)
// 	localparam p_multDelay = `MontgomeryMultiplierDelay;
// 	SignalDelay #(
// 		.p_width(1 + p_rowAddrWidth),
// 		.p_delay(p_multDelay - 1)
// 	) m_multDelay(
// 		.clock,
// 		.io_inData({io_writeBufId, io_writeRow}),
// 		.io_outData({w_multBufIdPrev, w_multRowPrev})
// 	);
// 	always_ff @(posedge clock) begin
// 		{w_multBufId, w_multRow} <= {w_multBufIdPrev, w_multRowPrev};
// 	end
// 	SignalDelay #(
// 		.p_width(1),
// 		.p_delay(p_multDelay)
// 	) m_multDelayAcc(
// 		.clock,
// 		.io_inData(io_writeIsAccumulate), .io_outData(w_multIsAccumulate)
// 	);
// 	SignalDelayInit #(
// 		.p_width(1),
// 		.p_delay(p_multDelay - 1),
// 		.p_initValue(0)
// 	) m_multDelayActive1(
// 		.clock, .reset,
// 		.io_inData(io_writeActive), .io_outData(w_multActivePrev)
// 	);
// 	SignalDelayInit #(
// 		.p_width(1),
// 		.p_delay(1),
// 		.p_initValue(0)
// 	) m_multDelayActive2(
// 		.clock, .reset,
// 		.io_inData(w_multActivePrev), .io_outData(w_multActive)
// 	);

// 	// Addition: bufWriteData = multData * bufReadData
// 	logic [p_dataWidth-1:0]
// 		w_addInData[0:p_rowSize-1],
// 		w_addOutData[0:p_rowSize-1];
// 	generate
// 	for (i = 0;i < p_rowSize;i++) begin
// 		ModularAdder #(
// 			.p_dataWidth(p_dataWidth)
// 		) m_add(
// 			.io_A(w_multData[i]),
// 			.io_B(w_addInData[i]),
// 			.io_mod(r_mod),
// 			.io_result(w_addOutData[i])
// 		);
// 	end
// 	endgenerate

// 	// Last read buf id
// 	logic r_readBufIdPrev;
// 	always_ff @(posedge clock) r_readBufIdPrev <= io_readBufId;
// 	always_comb begin
// 		// Clear default read/write enable
// 		w_bufWriteEnable = '{default: 0};
// 		w_bufReadAddr = '{default: 0};
// 		w_bufWriteAddr = '{default: 0};
// 		w_bufWriteData = '{default: 0};

// 		// Forward read request
// 		w_bufReadAddr[io_readBufId] = io_readRow;
// 		io_readData = w_bufReadData[r_readBufIdPrev];

// 		// Read before addition
// 		if (w_multActivePrev) begin
// 			w_bufReadAddr[w_multBufIdPrev] = w_multRowPrev;
// 		end
// 		w_addInData = w_bufReadData[w_multBufId];
// 		w_bufWriteEnable[w_multBufId] = w_multActive;
// 		w_bufWriteAddr[w_multBufId] = w_multRow;
// 		w_bufWriteData[w_multBufId] = w_multIsAccumulate ? w_addOutData : w_multData;
// 	end

// endmodule: ChangeRNSBasePolyMultAdd


// /*
//  * Change RNS base
//  */
// module ChangeRNSBase
// 	#(parameter
// 		p_rowSize = 0,
// 		p_colSize = 0,
// 		p_blockNum = 0,
// 		p_blockAddrWidth = 0,
// 		p_rowAddrWidth = 0,
// 		p_dataWidth = 0
// 	)
// 	(
// 		input logic  clock, reset,

// 		// Write port
// 		input logic  io_writeActive,
// 		input logic  io_writeBufId,
// 		input logic  io_writeIsAccumulate,
// 		input logic  [p_rowAddrWidth-1:0] io_writeRow,
// 		input logic  [p_dataWidth-1:0] io_writeConst[0:p_blockNum-1],
// 		input logic  [p_dataWidth-1:0] io_writeData[0:p_rowSize-1],

// 		// Read port
// 		input logic  io_readBufId,
// 		input logic  [p_rowAddrWidth-1:0] io_readRow,
// 		input logic  [p_blockAddrWidth-1:0] io_readBlockId,
// 		output logic [p_dataWidth-1:0] io_readData[0:p_rowSize-1]
// 	);

// 	// Poly mult/add
// 	logic [p_dataWidth-1:0] w_readDataAll[0:p_blockNum-1][0:p_rowSize-1];
// 	genvar blockId;
// 	generate
// 	for (blockId = 0;blockId < p_blockNum;blockId++) begin: pma
// 		ChangeRNSBasePolyMultAdd #(
// 			.p_rowSize(p_rowSize),
// 			.p_colSize(p_colSize),
// 			.p_rowAddrWidth(p_rowAddrWidth),
// 			.p_dataWidth(p_dataWidth)
// 		) m_pma(
// 			.clock, .reset,

// 			.io_writeActive,
// 			.io_writeBufId,
// 			.io_writeIsAccumulate,
// 			.io_writeRow,
// 			.io_writeConst(io_writeConst[blockId]),
// 			.io_writeData,

// 			.io_readBufId,
// 			.io_readRow,
// 			.io_readData(w_readDataAll[blockId])
// 		);
// 	end
// 	endgenerate

// 	// Select read data from block id at request time
// 	logic [p_blockAddrWidth-1:0] w_readBlockIdPrev;
// 	always_ff @(posedge clock) w_readBlockIdPrev <= io_readBlockId;
// 	assign io_readData = w_readDataAll[w_readBlockIdPrev];

// endmodule: ChangeRNSBase
