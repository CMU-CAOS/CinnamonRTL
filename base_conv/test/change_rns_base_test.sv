`default_nettype none

module ChangeRNSBaseMultiplyAccumulateTest
	#(parameter
		p_rowSize = 4,
		p_colSize = 3,
		p_blockNum = 3,
		p_blockAddrWidth = $clog2(p_blockNum),
		p_rowAddrWidth = $clog2(p_colSize),
		p_dataWidth = 28,
		p_numInputPairs = 5
	);

	logic clock, reset;

	logic [p_dataWidth-1:0] io_A [0:p_numInputPairs - 1];
	logic [p_dataWidth-1:0] io_B [0:p_numInputPairs - 1];
	logic [p_dataWidth-1:0] io_q;
	logic [p_dataWidth-1:0] io_result;

	logic [p_dataWidth-1:0] in [0:p_numInputPairs - 1];

	ChangeRNSBaseMultiplyAccumulate #(
		.p_dataWidth(p_dataWidth),
		.p_numInputPairs(p_numInputPairs)
	) dut (
		.clock(clock),
		.reset(reset),
		.io_A(io_A),
		.io_B(io_B),
		.io_q(io_q),
		.io_result(io_result)
	);

	always_ff @(posedge clock) begin
		$display("output = %d",io_result);
	end

	`TestClock(clock)
	initial begin
		`TestReset(reset)

		// Set Buffer Data

			// #1
		in = '{1, 2, 3, 4, 5};
		`TestMontgomeryAssign(io_A, in, 204865537, p_numInputPairs)
		`TestMontgomeryAssign(io_B, in, 204865537, p_numInputPairs)
		#2
		in = '{1, 2, 3, 4, 6};
		`TestMontgomeryAssign(io_A, in, 204865537, p_numInputPairs)
		`TestMontgomeryAssign(io_B, in, 204865537, p_numInputPairs)
		io_q = 204865537;
		#14
		`TestCheck(io_result,ConvertToMontgomery(55,204865537))
		#2
		`TestCheck(io_result,ConvertToMontgomery(66,204865537))
		`TestFinish("ChangeRNSBaseMultiplyAccumulateTest")
		// #1
	end

endmodule: ChangeRNSBaseMultiplyAccumulateTest

module ChangeRNSBaseLaneTest
	#(parameter
		p_dataWidth = 28,
		p_numBlocks = 8,
		p_numRows = 16,
		localparam p_rowAddrWidth = $clog2(p_numRows)
	);

	logic clock, reset;

	logic [p_rowAddrWidth-1:0] io_rowAddr;
	logic io_readBufId;
	logic io_readBlockSelect [0:p_numBlocks-1];

	logic [p_dataWidth-1:0] io_baseConvFactors [0:p_numBlocks - 1];
	logic [p_dataWidth-1:0] io_q;

	logic [p_dataWidth-1:0] io_result;


	ChangeRNSBaseLane #(
		.p_dataWidth(p_dataWidth),
		.p_numBlocks(p_numBlocks),
		.p_numRows(p_numRows)
	) dut (
		.clock(clock),
		.reset(reset),
		.io_rowAddr(io_rowAddr),
		.io_readBufId(io_readBufId),
		.io_readBlockSelect(io_readBlockSelect),
		.io_baseConvFactors(io_baseConvFactors),
		.io_q(io_q),
		.io_result(io_result)
	);

	always_ff @(posedge clock) begin
		$display("output = %d",io_result);
	end

	always_ff @(posedge clock) begin
		if(reset) begin 
			io_rowAddr<= 0;
		end else if(io_rowAddr < p_numRows) begin
			io_rowAddr <= io_rowAddr + 1;
		end else begin
			io_rowAddr <= io_rowAddr;
		end
	end

	// always_ff @(negedge reset) begin
	// 	io_rowAddr <= 0;
	// end

	`TestClock(clock)
	initial begin
		`TestReset(reset)

		// Set the buffer Data
		// io_readBufId = 0;
		dut.block[1].m_buffer.mem[0] = '{73, 4, 54, 61, 73, 1, 26, 59, 62, 35, 83, 20, 4, 66, 62, 41};
		dut.block[2].m_buffer.mem[0] = '{38, 127, 184, 22, 215, 71, 181, 195, 215, 145, 134, 233, 89, 155, 185, 68};

		// io_baseConvFactors <= {111559932, 155773149, 1, 2};
		io_baseConvFactors <= {1, 111559932, 155773149, 2 , 1, 2,1 ,2};
		io_q <= 264634369;
		// io_rowAddr = 0;
		io_readBufId <= 0;
		io_readBlockSelect <= {0,1,1,0, 0, 0, 0, 0};

			// #1
		// in = '{1, 2, 3, 4, 5};
		// `TestMontgomeryAssign(io_A, in, 204865537, p_numInputPairs)
		// `TestMontgomeryAssign(io_B, in, 204865537, p_numInputPairs)
		// #2
		// in = '{1, 2, 3, 4, 6};
		// `TestMontgomeryAssign(io_A, in, 204865537, p_numInputPairs)
		// `TestMontgomeryAssign(io_B, in, 204865537, p_numInputPairs)
		// io_q = 204865537;
		// #14
		// `TestCheck(io_result,ConvertToMontgomery(55,204865537))
		#18
		`TestCheck(io_result,ConvertToMontgomery(21924621,264634369))
			#2
		`TestCheck(io_result,ConvertToMontgomery(202112701,264634369))
			#2
		`TestCheck(io_result,ConvertToMontgomery(59972886,264634369))
			#2
		`TestCheck(io_result,ConvertToMontgomery(237522427,264634369))
			#2
		`TestCheck(io_result,ConvertToMontgomery(201549488,264634369))
			#2
		`TestCheck(io_result,ConvertToMontgomery(221929873,264634369))
			#2
		`TestCheck(io_result,ConvertToMontgomery(258985451,264634369))
			#2
		`TestCheck(io_result,ConvertToMontgomery(28112817,264634369))
			#2
		`TestCheck(io_result,ConvertToMontgomery(178086875,264634369))
			#2
		`TestCheck(io_result,ConvertToMontgomery(14935306,264634369))
			#2
		`TestCheck(io_result,ConvertToMontgomery(256073190,264634369))
			#2
		`TestCheck(io_result,ConvertToMontgomery(172010427,264634369))
			#2
		`TestCheck(io_result,ConvertToMontgomery(263721502,264634369))
			#2
		`TestCheck(io_result,ConvertToMontgomery(188931302,264634369))
			#2
		`TestCheck(io_result,ConvertToMontgomery(143156654,264634369))
			#2
		`TestCheck(io_result,ConvertToMontgomery(205118997,264634369))
		#2
		`TestFinish("ChangeRNSBaseLaneTest")
		// #1
	end


endmodule: ChangeRNSBaseLaneTest

module ChangeRNSBaseTest
	#(parameter
		p_dataWidth = 28,
		p_numBlocks = 13,
		p_numRows = 4,
		p_numLanes = 4,
		localparam p_rowAddrWidth = $clog2(p_numRows)
	);

	logic clock, reset;

	logic [p_rowAddrWidth-1:0] io_rowAddr; 
	logic io_readBufId; 
	logic io_readBlockSelect [0:p_numBlocks-1];
	
	logic  io_writeEnable;
	logic  io_writeBufId;
	logic [$clog2(p_numBlocks)-1:0] io_writeBlockId; 
	logic [p_rowAddrWidth-1:0] io_writeRowAddr; 
	logic [p_dataWidth-1:0] io_writeData [0:p_numLanes-1];

	logic [p_dataWidth-1:0] io_baseConvFactors [0:p_numBlocks - 1];
	logic [p_dataWidth-1:0] io_q;
	logic [p_dataWidth-1:0] io_result [0:p_numLanes-1];

	logic [p_dataWidth-1:0] in [0:p_numRows-1][0:p_numLanes-1];
	logic [p_dataWidth-1:0] ans [0:p_numLanes-1];

	logic r_counter_reset, w_counter_reset;


	ChangeRNSBase #(
		.p_dataWidth(p_dataWidth),
		.p_numBlocks(p_numBlocks),
		.p_numRows(p_numRows),
		.p_numLanes(p_numRows)
	) dut (.*);

	always_ff @(posedge clock) begin
		$display("output = %d",io_result[0]);
	end

	always_ff @(posedge clock) begin
		if(r_counter_reset || reset) begin 
			io_rowAddr <= 0;
		end else if(io_rowAddr < p_numRows - 1) begin
			io_rowAddr <= io_rowAddr + 1;
		end else begin
			io_rowAddr <= io_rowAddr;
		end
	end

	always_ff @(posedge clock) begin
		if(reset || w_counter_reset) begin 
			io_writeRowAddr <= 0;
		end else if(io_writeRowAddr < p_numRows - 1) begin
			io_writeRowAddr <= io_writeRowAddr + 1;
		end else begin
			io_writeRowAddr <= io_writeRowAddr;
		end
		// $display("Write Row Add = %d",io_writeRowAddr);
	end

	// always_ff @(negedge reset) begin
	// 	io_rowAddr <= 0;
	// end
	// always_ff @(posedge clock) begin
	// 	io_writeData <= in[io_writeRowAddr];
	// end
	assign io_writeData = in[io_writeRowAddr];

	integer i, delay;

	// always_ff @(posedge clock) begin
	// 	io_writeData <= in[]

	// end

	`TestClock(clock)
	initial begin
		`TestReset(reset)
		in = '{
				'{73, 4, 54, 61},
				'{73, 1, 26, 59},
				'{62, 35, 83, 20},
				'{4, 66, 62, 41}
		};
		io_writeEnable <= 1;
		io_writeBufId <= 0;
		io_writeBlockId <= 1;

		for (i = 0;i < p_numRows;i++) begin
			@(negedge clock);
		end
		w_counter_reset <= 1;
		@(negedge clock)
		w_counter_reset <= 0;

		in = '{
				'{38, 127, 184, 22},
				'{215, 71, 181, 195},
				'{215, 145, 134, 233},
				'{89, 155, 185, 68}
		};
		io_writeBlockId <= 2;

		for (i = 0;i < p_numRows;i++) begin
			@(negedge clock);
		end

		io_writeEnable <= 0;
		io_baseConvFactors <= {1, 111559932, 155773149, 2 , 1, 2,1 ,2 ,1 ,2,1,2,1};
		io_q <= 264634369;
		r_counter_reset <= 1;
		io_readBufId <= 0;
		io_readBlockSelect <= {0,1,1,0, 0, 0, 0, 0,0,0,0,0,0};

		@(negedge clock)	
		r_counter_reset <= 0;
		// io_rowAddr = 0;

		delay = 9;
		for (i = 0;i < delay;i++) begin
			@(negedge clock);
		end

		// io_baseConvFactors <= {1, 111559932, 155773149, 2 , 1, 2,1 ,2};
		// io_q <= 264634369;
		// io_q <= 265420801;

		// #8
		// r_counter_reset <= 1;
		// #2
		// r_counter_reset <= 0;
		// #8

		@(negedge clock);
		ans = '{21924621, 202112701, 59972886, 237522427};
		`TestMontgomeryCheck(io_result, ans, 264634369, p_numLanes)
		@(negedge clock);
		ans = '{201549488, 221929873, 258985451, 28112817};
		`TestMontgomeryCheck(io_result, ans, 264634369, p_numLanes)
		@(negedge clock);
		ans = '{178086875, 14935306, 256073190, 172010427};
		`TestMontgomeryCheck(io_result, ans, 264634369, p_numLanes)
		@(negedge clock);
		ans = '{263721502, 188931302, 143156654, 205118997};
		`TestMontgomeryCheck(io_result, ans, 264634369, p_numLanes)

		io_baseConvFactors <= {1, 178391480, 176040123, 2 , 1, 2,1 ,2,1,2,1,2,1};
		io_q <= 265420801;
		r_counter_reset <= 1;
		@(negedge clock)
		r_counter_reset <= 0;

		for (i = 0;i < delay;i++) begin
			@(negedge clock);
		end

		@(negedge clock);
		ans = '{5637579, 129594446, 49260596, 173736877};
		`TestMontgomeryCheck(io_result, ans, 265420801, p_numLanes)
		@(negedge clock);
		ans = '{110617592, 15565047, 60475414, 135993341};
		`TestMontgomeryCheck(io_result, ans, 265420801, p_numLanes)
		@(negedge clock);
		ans = '{152193693, 25146212, 100029709, 130626274};
		`TestMontgomeryCheck(io_result, ans, 265420801, p_numLanes)
		@(negedge clock);
		ans = '{41076052, 223361391, 26432687, 204088915};
		`TestMontgomeryCheck(io_result, ans, 265420801, p_numLanes)
		`TestFinish("ChangeRNSBaseTest")
	end


endmodule: ChangeRNSBaseTest

// // CRB instance
// `define CRBInstance \
// 	ChangeRNSBase #( \
// 		.p_rowSize(p_rowSize), \
// 		.p_colSize(p_colSize), \
// 		.p_blockNum(p_blockNum), \
// 		.p_blockAddrWidth(p_blockAddrWidth), \
// 		.p_rowAddrWidth(p_rowAddrWidth), \
// 		.p_dataWidth(p_dataWidth) \
// 	) dut(.*);


// /*
//  * Test RNS base change
//  */
// module ChangeRNSBaseTest
// 	#(parameter
// 		p_rowSize = 4,
// 		p_colSize = 3,
// 		p_blockNum = 3,
// 		p_blockAddrWidth = $clog2(p_blockNum),
// 		p_rowAddrWidth = $clog2(p_colSize),
// 		p_dataWidth = 28
// 	);

// 	logic clock, reset;
// 	logic io_writeActive, io_writeBufId, io_writeIsAccumulate;
// 	logic [p_rowAddrWidth-1:0] io_writeRow;
// 	logic [p_dataWidth-1:0] io_writeConst[0:p_blockNum-1];
// 	logic [p_dataWidth-1:0] io_writeData[0:p_rowSize-1];
// 	logic io_readBufId;
// 	logic [p_rowAddrWidth-1:0] io_readRow;
// 	logic [p_blockAddrWidth-1:0] io_readBlockId;
// 	logic [p_dataWidth-1:0] io_readData[0:p_rowSize-1];
// 	logic [p_dataWidth-1:0] mod[0:p_blockNum-1];
// 	logic [p_dataWidth-1:0] ans[0:p_rowSize-1];
// 	`CRBInstance

// 	integer i;
// 	logic [p_dataWidth-1:0] tb[0:p_blockNum-1];
// 	logic [p_dataWidth-1:0] t[0:p_rowSize-1];
// 	`TestClock(clock)
// 	initial begin
// 		`TestReset(reset)

// 		// Set prime data
// 		mod[0] = 2752513;
// 		mod[1] = 8257537;
// 		mod[2] = 786433;
// 		dut.pma[0].m_pma.r_mod = mod[0];
// 		dut.pma[1].m_pma.r_mod = mod[1];
// 		dut.pma[2].m_pma.r_mod = mod[2];

// 		io_writeActive = 1;
// 		io_writeBufId = 1;
// 		io_writeIsAccumulate = 0;

// 		// BlockId 0
// 		io_writeConst = '{
// 			(2 * MontgomeryR2(mod[0])) % mod[0],
// 			(3 * MontgomeryR2(mod[1])) % mod[1],
// 			(1 * MontgomeryR2(mod[2])) % mod[2]
// 		};
// 		io_writeRow = 0;
// 		io_writeData = '{3, 1, 2, 3};
// 		@(negedge clock);
// 		io_writeRow = 1;
// 		io_writeData = '{1, 0, 1, 0};
// 		@(negedge clock);
// 		io_writeRow = 2;
// 		io_writeData = '{4, 3, 2, 1};
// 		@(negedge clock);

// 		io_writeIsAccumulate = 1;
// 		// BlockId 1
// 		io_writeConst = '{
// 			(1 * MontgomeryR2(mod[0])) % mod[0],
// 			(2 * MontgomeryR2(mod[1])) % mod[1],
// 			(3 * MontgomeryR2(mod[2])) % mod[2]
// 		};
// 		io_writeRow = 0;
// 		io_writeData = '{0, 8, 2, 1};
// 		@(negedge clock);
// 		io_writeRow = 1;
// 		io_writeData = '{1, 1, 3, 2};
// 		@(negedge clock);
// 		io_writeRow = 2;
// 		io_writeData = '{1, 3, 2, 4};
// 		@(negedge clock);
// 		// BlockId 2
// 		io_writeConst = '{
// 			(3 * MontgomeryR2(mod[0])) % mod[0],
// 			(1 * MontgomeryR2(mod[1])) % mod[1],
// 			(2 * MontgomeryR2(mod[2])) % mod[2]
// 		};
// 		io_writeRow = 0;
// 		io_writeData = '{8, 3, 9, 2};
// 		@(negedge clock);
// 		io_writeRow = 1;
// 		io_writeData = '{3, 2, 7, 8};
// 		@(negedge clock);
// 		io_writeRow = 2;
// 		io_writeData = '{9, 2, 3, 6};
// 		@(negedge clock);

// 		io_writeActive = 1;
// 		io_writeBufId = 0;
// 		io_writeIsAccumulate = 0;

// 		// BlockId 0
// 		io_writeConst = '{
// 			(2 * MontgomeryR2(mod[0])) % mod[0],
// 			(3 * MontgomeryR2(mod[1])) % mod[1],
// 			(1 * MontgomeryR2(mod[2])) % mod[2]
// 		};
// 		io_writeRow = 0;
// 		io_writeData = '{5, 3, 6, 4};
// 		@(negedge clock);
// 		io_writeRow = 1;
// 		io_writeData = '{3, 5, 2, 3};
// 		@(negedge clock);
// 		io_writeRow = 2;
// 		io_writeData = '{3, 4, 1, 2};
// 		@(negedge clock);

// 		io_writeIsAccumulate = 1;
// 		// BlockId 1
// 		io_writeConst = '{
// 			(1 * MontgomeryR2(mod[0])) % mod[0],
// 			(2 * MontgomeryR2(mod[1])) % mod[1],
// 			(3 * MontgomeryR2(mod[2])) % mod[2]
// 		};
// 		io_writeRow = 0;
// 		io_writeData = '{6, 6, 5, 8};
// 		@(negedge clock);
// 		io_writeRow = 1;
// 		io_writeData = '{1, 5, 3, 1};
// 		@(negedge clock);
// 		io_writeRow = 2;
// 		io_writeData = '{6, 8, 5, 6};
// 		@(negedge clock);
// 		// BlockId 2
// 		io_writeConst = '{
// 			(3 * MontgomeryR2(mod[0])) % mod[0],
// 			(1 * MontgomeryR2(mod[1])) % mod[1],
// 			(2 * MontgomeryR2(mod[2])) % mod[2]
// 		};
// 		io_writeRow = 0;
// 		io_writeData = '{2, 4, 5, 4};
// 		@(negedge clock);
// 		io_writeRow = 1;
// 		io_writeData = '{2, 3, 1, 2};
// 		@(negedge clock);
// 		io_writeRow = 2;
// 		io_writeData = '{5, 9, 0, 3};
// 		@(negedge clock);

// 		io_writeActive = 0;

// 		// Wait for 50 cycles
// 		for (i = 0;i < 50;i++) @(negedge clock);

// 		// BlockId 0
// 		io_readBufId = 1;
// 		io_readBlockId = 0;
// 		io_readRow = 0;
// 		@(negedge clock);
// 		ans = '{30, 19, 33, 13};
// 		`TestMontgomeryCheck(io_readData, ans, mod[0], p_rowSize)

// 		io_readRow = 1;
// 		@(negedge clock);
// 		ans = '{12, 7, 26, 26};
// 		`TestMontgomeryCheck(io_readData, ans, mod[0], p_rowSize)

// 		io_readRow = 2;
// 		@(negedge clock);
// 		ans = '{36, 15, 15, 24};
// 		`TestMontgomeryCheck(io_readData, ans, mod[0], p_rowSize)

// 		// BlockId 1
// 		io_readBlockId = 1;
// 		io_readRow = 0;
// 		@(negedge clock);
// 		ans = '{17, 22, 19, 13};
// 		`TestMontgomeryCheck(io_readData, ans, mod[1], p_rowSize)

// 		io_readRow = 1;
// 		@(negedge clock);
// 		ans = '{8, 4, 16, 12};
// 		`TestMontgomeryCheck(io_readData, ans, mod[1], p_rowSize)

// 		io_readRow = 2;
// 		@(negedge clock);
// 		ans = '{23, 17, 13, 17};
// 		`TestMontgomeryCheck(io_readData, ans, mod[1], p_rowSize)

// 		// BlockId 2
// 		io_readBlockId = 2;
// 		io_readRow = 0;
// 		@(negedge clock);
// 		ans = '{19, 31, 26, 10};
// 		`TestMontgomeryCheck(io_readData, ans, mod[2], p_rowSize)

// 		io_readRow = 1;
// 		@(negedge clock);
// 		ans = '{10, 7, 24, 22};
// 		`TestMontgomeryCheck(io_readData, ans, mod[2], p_rowSize)

// 		io_readRow = 2;
// 		@(negedge clock);
// 		ans = '{25, 16, 14, 25};
// 		`TestMontgomeryCheck(io_readData, ans, mod[2], p_rowSize)


// 		// BlockId 0
// 		io_readBufId = 0;
// 		io_readBlockId = 0;
// 		io_readRow = 0;
// 		@(negedge clock);
// 		ans = '{22, 24, 32, 28};
// 		`TestMontgomeryCheck(io_readData, ans, mod[0], p_rowSize)

// 		io_readRow = 1;
// 		@(negedge clock);
// 		ans = '{13, 24, 10, 13};
// 		`TestMontgomeryCheck(io_readData, ans, mod[0], p_rowSize)

// 		io_readRow = 2;
// 		@(negedge clock);
// 		ans = '{27, 43, 7, 19};
// 		`TestMontgomeryCheck(io_readData, ans, mod[0], p_rowSize)

// 		// BlockId 1
// 		io_readBlockId = 1;
// 		io_readRow = 0;
// 		@(negedge clock);
// 		ans = '{29, 25, 33, 32};
// 		`TestMontgomeryCheck(io_readData, ans, mod[1], p_rowSize)

// 		io_readRow = 1;
// 		@(negedge clock);
// 		ans = '{13, 28, 13, 13};
// 		`TestMontgomeryCheck(io_readData, ans, mod[1], p_rowSize)

// 		io_readRow = 2;
// 		@(negedge clock);
// 		ans = '{26, 37, 13, 21};
// 		`TestMontgomeryCheck(io_readData, ans, mod[1], p_rowSize)

// 		// BlockId 2
// 		io_readBlockId = 2;
// 		io_readRow = 0;
// 		@(negedge clock);
// 		ans = '{27, 29, 31, 36};
// 		`TestMontgomeryCheck(io_readData, ans, mod[2], p_rowSize)

// 		io_readRow = 1;
// 		@(negedge clock);
// 		ans = '{10, 26, 13, 10};
// 		`TestMontgomeryCheck(io_readData, ans, mod[2], p_rowSize)

// 		io_readRow = 2;
// 		@(negedge clock);
// 		ans = '{31, 46, 16, 26};
// 		`TestMontgomeryCheck(io_readData, ans, mod[2], p_rowSize)

// 		`TestFinish("ChangeRNSBaseTest")
// 	end

// endmodule: ChangeRNSBaseTest


// /*
//  * Test RNS base change (large)
//  */
// module ChangeRNSBaseLargeTest
// 	#(parameter
// 		p_testNum = 20,

// 		p_rowSize = 10,
// 		p_colSize = 13,
// 		p_blockNum = 9,
// 		p_blockAddrWidth = $clog2(p_blockNum),
// 		p_rowAddrWidth = $clog2(p_colSize),
// 		p_dataWidth = 28
// 	);

// 	logic clock, reset;
// 	logic io_writeActive, io_writeBufId, io_writeIsAccumulate;
// 	logic [p_rowAddrWidth-1:0] io_writeRow;
// 	logic [p_dataWidth-1:0] io_writeConst[0:p_blockNum-1];
// 	logic [p_dataWidth-1:0] io_writeData[0:p_rowSize-1];
// 	logic io_readBufId;
// 	logic [p_rowAddrWidth-1:0] io_readRow;
// 	logic [p_blockAddrWidth-1:0] io_readBlockId;
// 	logic [p_dataWidth-1:0] io_readData[0:p_rowSize-1];
// 	logic [p_dataWidth-1:0] ans[0:p_rowSize-1];
// 	`CRBInstance

// 	logic [p_dataWidth-1:0] mod[0:p_blockNum-1];
// 	logic [p_dataWidth-1:0] constMem[0:p_blockNum-1][0:p_blockNum-1];
// 	logic [p_dataWidth-1:0]
// 		in[0:p_testNum-1][0:p_blockNum-1][0:p_colSize-1][0:p_rowSize-1],
// 		out[0:p_testNum-1][0:p_blockNum-1][0:p_colSize-1][0:p_rowSize-1];

// 	integer i, j, k, blockId, testId, t1, t2, t3, delta;
// 	`TestClock(clock)
// 	initial begin
// 		`TestReset(reset)

// 		// Set prime data
// 		mod = '{
// 			27918337,
// 			35389441,
// 			28704769,
// 			31326209,
// 			29884417,
// 			28311553,
// 			32899073,
// 			33292289,
// 			30539777
// 		};
// 		dut.pma[0].m_pma.r_mod = mod[0];
// 		dut.pma[1].m_pma.r_mod = mod[1];
// 		dut.pma[2].m_pma.r_mod = mod[2];
// 		dut.pma[3].m_pma.r_mod = mod[3];
// 		dut.pma[4].m_pma.r_mod = mod[4];
// 		dut.pma[5].m_pma.r_mod = mod[5];
// 		dut.pma[6].m_pma.r_mod = mod[6];
// 		dut.pma[7].m_pma.r_mod = mod[7];
// 		dut.pma[8].m_pma.r_mod = mod[8];

// 		// Set const memory
// 		for (blockId = 0;blockId < p_blockNum;blockId++) begin
// 			for (i = 0;i < p_blockNum;i++) begin
// 				constMem[i][blockId] = $urandom % mod[blockId];
// 			end
// 		end

// 		// Set input data
// 		for (testId = 0;testId < p_testNum;testId++) begin
// 		for (blockId = 0;blockId < p_blockNum;blockId++) begin
// 			for (i = 0;i < p_colSize;i++) begin
// 				for (j = 0;j < p_rowSize;j++) begin
// 					in[testId][blockId][i][j] = $urandom % 27918337;
// 				end
// 			end
// 		end
// 		end
// 		// Compute output data
// 		for (testId = 0;testId < p_testNum;testId++) begin
// 		for (blockId = 0;blockId < p_blockNum;blockId++) begin
// 			for (i = 0;i < p_colSize;i++) begin
// 				for (j = 0;j < p_rowSize;j++) begin
// 					out[testId][blockId][i][j] = 0;
// 					for (k = 0;k < p_blockNum;k++) begin
// 						out[testId][blockId][i][j] = (out[testId][blockId][i][j] + (2*p_dataWidth)'(constMem[k][blockId]) * (2*p_dataWidth)'(in[testId][k][i][j]) % (2*p_dataWidth)'(mod[blockId])) % mod[blockId];
// 					end
// 				end
// 			end
// 		end
// 		end

// 		// Send input/assert output
// 		delta = `MontgomeryMultiplierDelay + p_blockNum * p_colSize - 1;
// 		for (t1 = 0;t1 < p_testNum * p_blockNum * p_colSize + delta;t1++) begin
// 			if (t1 < p_testNum * p_blockNum * p_colSize) begin
// 				testId = t1 / p_colSize / p_blockNum;
// 				blockId = t1 / p_colSize % p_blockNum;
// 				i = t1 % p_colSize;

// 				io_writeActive = 1;
// 				io_writeBufId = testId % 2;
// 				io_writeIsAccumulate = blockId != 0;
// 				io_writeRow = i;
// 				for (j = 0;j < p_blockNum;j++)
// 					io_writeConst[j] = (constMem[blockId][j] * MontgomeryR2(mod[j])) % mod[j];
// 				for (j = 0;j < p_rowSize;j++)
// 					io_writeData[j] = in[testId][blockId][i][j];
// 			end else if (t1 == p_testNum * p_blockNum * p_colSize) begin
// 				io_writeActive = 0;
// 				io_writeBufId = 1;
// 			end
// 			t2 = t1 - delta;
// 			if (t2 >= 0) begin
// 				testId = t2 / p_colSize / p_blockNum;
// 				blockId = t2 / p_colSize % p_blockNum;
// 				i = t2 % p_colSize;

// 				io_readBufId = testId % 2;
// 				io_readBlockId = blockId;
// 				io_readRow = i;
// 			end
// 			t3 = t2 - 1;
// 			if (t3 >= 0) begin
// 				testId = t3 / p_colSize / p_blockNum;
// 				blockId = t3 / p_colSize % p_blockNum;
// 				i = t3 % p_colSize;

// 				for (j = 0;j < p_rowSize;j++)
// 					`TestCheck(io_readData[j], ConvertToMontgomery(out[testId][blockId][i][j], mod[blockId]))
// 			end

// 			@(negedge clock);
// 		end

// 		`TestFinish("ChangeRNSBaseLargeTest")
// 	end

// endmodule: ChangeRNSBaseLargeTest
