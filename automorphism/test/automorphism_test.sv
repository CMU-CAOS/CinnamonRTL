`default_nettype none


/*
 * Test automorphism permutation
 */
module AutomorphismPermutationTest
	#(parameter
		p_size = 8,
		p_dataWidth = 32
	);

	logic clock, reset;
	logic [p_dataWidth-1:0]
		io_inData[p_size-1:0], io_outData[p_size-1:0], ans[p_size-1:0];
	logic [2*$clog2(p_size)*(p_size/2)-1:0] io_inPermInfo, io_outPermInfo;

	AutomorphismPermutation #(
		.p_size(p_size),
		.p_dataWidth(p_dataWidth)
	) dut(.*);

	integer i;
	`TestClock(clock)
	initial begin
		`TestReset(reset)

		io_inData = '{7, 6, 5, 4, 3, 2, 1, 0};
		// Permutation: 0 3 6 1 4 7 2 5
		io_inPermInfo[11:0] = 12'd4095;
		io_inPermInfo[23:12] = 12'd2911;
		@(negedge clock);
		io_inData = '{default: '0};
		io_inPermInfo = 0;
		// Wait for 5 cycles
		for (i = 0;i < `AutomorphismPermutationDelay(p_size) - 1;i++) begin
			@(negedge clock);
		end
		ans = '{5, 2, 7, 4, 1, 6, 3, 0};
		for (i = 0;i < p_size;i++) `TestCheck(io_outData[i], ans[i])

		io_inData = '{7, 6, 5, 4, 3, 2, 1, 0};
		// Permutation: 4 2 7 1 6 3 5 0
		io_inPermInfo[11:0] = 12'd4089;
		io_inPermInfo[23:12] = 12'd22;
		@(negedge clock);
		io_inData = '{default: '0};
		io_inPermInfo = 0;
		// Wait for 5 cycles
		for (i = 0;i < `AutomorphismPermutationDelay(p_size) - 1;i++) begin
			@(negedge clock);
		end
		ans = '{0, 5, 3, 6, 1, 7, 2, 4};
		for (i = 0;i < p_size;i++) `TestCheck(io_outData[i], ans[i])

		`TestFinish("AutomorphismPermutationTest")
	end

endmodule: AutomorphismPermutationTest


// Automorphism test instance
`define AutomorphismInstance \
	Automorphism #( \
		.p_rowSize(p_rowSize), \
		.p_clusterNum(p_clusterNum), \
		.p_dataWidth(p_dataWidth) \
	) dut(.*); \
	Transpose #( \
		.p_rowSize(p_rowSize), \
		.p_clusterNum(1), \
		.p_dataWidth(p_dataWidth) \
	) m_transposeA( \
		.clock, .reset, \
		.io_inActive(io_transposeInActiveA), \
		.io_inData(io_transposeInDataA), \
		.io_outActive(io_transposeOutActiveA), \
		.io_outData(io_transposeOutDataA), \
		.io_networkInData(io_transposeNetworkDataA), \
		.io_networkOutData(io_transposeNetworkDataA) \
	), m_transposeB( \
		.clock, .reset, \
		.io_inActive(io_transposeInActiveB), \
		.io_inData(io_transposeInDataB), \
		.io_outActive(io_transposeOutActiveB), \
		.io_outData(io_transposeOutDataB), \
		.io_networkInData(io_transposeNetworkDataB), \
		.io_networkOutData(io_transposeNetworkDataB) \
	);


/*
 * Test overall automorphism
 */
module AutomorphismTest
	#(parameter
		p_rowSize = 4,
		p_clusterNum = 1,
		p_dataWidth = 16
	);

	logic clock, reset;
	logic io_inActive, io_outActive;
	logic [p_dataWidth-1:0]
		io_inData[p_rowSize-1:0],
		io_outData[p_rowSize-1:0],
		ans[p_rowSize-1:0];
	logic [2*$clog2(p_rowSize)*(p_rowSize/2)-1:0] io_colPermInfo, io_rowPermInfo;

	logic io_transposeInActiveA, io_transposeOutActiveA,
		io_transposeInActiveB, io_transposeOutActiveB;
	logic [p_dataWidth-1:0]
		io_transposeInDataA[p_rowSize-1:0], io_transposeOutDataA[p_rowSize-1:0],
		io_transposeInDataB[p_rowSize-1:0], io_transposeOutDataB[p_rowSize-1:0],
		io_transposeNetworkDataA[p_rowSize-1:0], io_transposeNetworkDataB[p_rowSize-1:0]
	;
	`AutomorphismInstance

	integer i;
	`TestClock(clock)
	initial begin
		`TestReset(reset)

		io_inActive = 1;
		/*
		0 1 2 3
		4 5 6 7
		8 9 10 11
		12 13 14 15
		->
		0 11 6 1
		12 7 2 13
		8 3 14 9
		4 15 10 5
		*/
		io_inData = '{3, 2, 1, 0};
		// Col permutation: 0 3 2 1
		io_colPermInfo[3:0] = 4'd15;
		io_colPermInfo[7:4] = 4'd7;
		// Row permutation: 0 3 2 1
		io_rowPermInfo[3:0] = 4'd15;
		io_rowPermInfo[7:4] = 4'd7;
		@(negedge clock);

		io_inData = '{7, 6, 5, 4};
		// Col permutation: 0 3 2 1
		io_colPermInfo[3:0] = 4'd15;
		io_colPermInfo[7:4] = 4'd7;
		// Row permutation: 2 1 0 3
		io_rowPermInfo[3:0] = 4'd15;
		io_rowPermInfo[7:4] = 4'd11;
		@(negedge clock);

		io_inData = '{11, 10, 9, 8};
		// Col permutation: 0 3 2 1
		io_colPermInfo[3:0] = 4'd15;
		io_colPermInfo[7:4] = 4'd7;
		// Row permutation: 1 0 3 2
		io_rowPermInfo[3:0] = 4'd15;
		io_rowPermInfo[7:4] = 4'd12;
		@(negedge clock);

		io_inData = '{15, 14, 13, 12};
		// Column permutation: 0 3 2 1
		io_colPermInfo[3:0] = 4'd15;
		io_colPermInfo[7:4] = 4'd7;
		// Row permutation: 0 3 2 1
		io_rowPermInfo[3:0] = 4'd15;
		io_rowPermInfo[7:4] = 4'd7;
		@(negedge clock);

		io_inActive = 0;
		io_inData = '{default: '0};
		io_colPermInfo = 0;
		io_rowPermInfo = 0;

		// Wait for 14 cycles
		for (i = 0;i < `AutomorphismDelay(p_rowSize, p_clusterNum) - 4;i++) begin
			`TestCheck(io_outActive, 0)
			@(negedge clock);
		end

		// Check answer
		ans = '{1, 6, 11, 0};
		`TestCheck(io_outActive, 1)
		`TestCheckArray(io_outData, ans, p_rowSize)
		@(negedge clock);
		ans = '{13, 2, 7, 12};
		`TestCheck(io_outActive, 1)
		`TestCheckArray(io_outData, ans, p_rowSize)
		@(negedge clock);
		ans = '{9, 14, 3, 8};
		`TestCheck(io_outActive, 1)
		`TestCheckArray(io_outData, ans, p_rowSize)
		@(negedge clock);
		ans = '{5, 10, 15, 4};
		`TestCheck(io_outActive, 1)
		`TestCheckArray(io_outData, ans, p_rowSize)
		@(negedge clock);
		`TestCheck(io_outActive, 0)

		`TestFinish("AutomorphismTest")
	end

endmodule: AutomorphismTest


/*
 * Test automorphism based on automorphism.py
 */
module Automorphism4x4Test
	#(parameter
		p_rowSize = 4,
		p_clusterNum = 1,
		p_dataWidth = 16
	);

	logic clock, reset;
	logic io_inActive, io_outActive;
	logic [p_dataWidth-1:0]
		io_inData[p_rowSize-1:0],
		io_outData[p_rowSize-1:0],
		ans[p_rowSize-1:0];
	logic [2*$clog2(p_rowSize)*(p_rowSize/2)-1:0] io_colPermInfo, io_rowPermInfo;

	logic io_transposeInActiveA, io_transposeOutActiveA,
		io_transposeInActiveB, io_transposeOutActiveB;
	logic [p_dataWidth-1:0]
		io_transposeInDataA[p_rowSize-1:0], io_transposeOutDataA[p_rowSize-1:0],
		io_transposeInDataB[p_rowSize-1:0], io_transposeOutDataB[p_rowSize-1:0],
		io_transposeNetworkDataA[p_rowSize-1:0], io_transposeNetworkDataB[p_rowSize-1:0]
	;
	`AutomorphismInstance

	integer i;
	`TestClock(clock)
	initial begin
		`TestReset(reset)

		io_inActive = 1;
		/*
		[[ 8 60 32 51]
		 [49 27 72 13]
		 [20 67 67 36]
		 [55 96  8 18]]
		->
		[[49 27 13 72]
		 [32 51  8 60]
		 [ 8 18 55 96]
		 [67 20 67 36]]
		*/
		io_inData = '{51, 32, 60, 8};
		// Column permutation: 2 3 0 1
		io_colPermInfo[3:0] = 4'd15;
		io_colPermInfo[7:4] = 4'd3;
		// Row permutation: 1 0 3 2
		io_rowPermInfo[3:0] = 4'd15;
		io_rowPermInfo[7:4] = 4'd12;
		@(negedge clock);

		io_inData = '{13, 72, 27, 49};
		// Column permutation: 0 1 3 2
		io_colPermInfo[3:0] = 4'd15;
		io_colPermInfo[7:4] = 4'd14;
		// Row permutation: 1 0 3 2
		io_rowPermInfo[3:0] = 4'd15;
		io_rowPermInfo[7:4] = 4'd12;
		@(negedge clock);

		io_inData = '{36, 67, 67, 20};
		// Column permutation: 1 0 2 3
		io_colPermInfo[3:0] = 4'd15;
		io_colPermInfo[7:4] = 4'd13;
		// Row permutation: 1 0 3 2
		io_rowPermInfo[3:0] = 4'd15;
		io_rowPermInfo[7:4] = 4'd12;
		@(negedge clock);

		io_inData = '{18, 8, 96, 55};
		// Column permutation: 2 3 0 1
		io_colPermInfo[3:0] = 4'd15;
		io_colPermInfo[7:4] = 4'd3;
		// Row permutation: 1 0 3 2
		io_rowPermInfo[3:0] = 4'd15;
		io_rowPermInfo[7:4] = 4'd12;
		@(negedge clock);

		io_inActive = 0;
		io_inData = '{default: '0};
		io_colPermInfo = 0;
		io_rowPermInfo = 0;

		// Wait for 14 cycles
		for (i = 0;i < `AutomorphismDelay(p_rowSize, p_clusterNum) - 4;i++) begin
			`TestCheck(io_outActive, 0)
			@(negedge clock);
		end

		// Check answer
		ans = '{72, 13, 27, 49};
		`TestCheck(io_outActive, 1)
		`TestCheckArray(io_outData, ans, p_rowSize)
		@(negedge clock);
		ans = '{60, 8, 51, 32};
		`TestCheck(io_outActive, 1)
		`TestCheckArray(io_outData, ans, p_rowSize)
		@(negedge clock);
		ans = '{96, 55, 18, 8};
		`TestCheck(io_outActive, 1)
		`TestCheckArray(io_outData, ans, p_rowSize)
		@(negedge clock);
		ans = '{36, 67, 20, 67};
		`TestCheck(io_outActive, 1)
		`TestCheckArray(io_outData, ans, p_rowSize)
		@(negedge clock);
		`TestCheck(io_outActive, 0)

		`TestFinish("Automorphism4x4Test")
	end

endmodule: Automorphism4x4Test


/*
 * Test automorphism based on automorphism.py (8x8)
 */
module Automorphism8x8Test
	#(parameter
		p_rowSize = 8,
		p_clusterNum = 1,
		p_dataWidth = 24
	);

	logic clock, reset;
	logic io_inActive, io_outActive;
	logic [p_dataWidth-1:0]
		io_inData[p_rowSize-1:0],
		io_outData[p_rowSize-1:0],
		ans[p_rowSize-1:0];
	logic [2*$clog2(p_rowSize)*(p_rowSize/2)-1:0] io_colPermInfo, io_rowPermInfo;

	logic io_transposeInActiveA, io_transposeOutActiveA,
		io_transposeInActiveB, io_transposeOutActiveB;
	logic [p_dataWidth-1:0]
		io_transposeInDataA[p_rowSize-1:0], io_transposeOutDataA[p_rowSize-1:0],
		io_transposeInDataB[p_rowSize-1:0], io_transposeOutDataB[p_rowSize-1:0],
		io_transposeNetworkDataA[p_rowSize-1:0], io_transposeNetworkDataB[p_rowSize-1:0]
	;
	`AutomorphismInstance

	integer i;
	`TestClock(clock)
	initial begin
		`TestReset(reset)

		io_inActive = 1;
		/*
		[ 19 113 147 220 145 177 147  63]
		 [185 105  21 241 222 212 113 187]
		 [ 70 234 198 102 141 197 160  39]
		 [188 104  29 175  67 220 173 206]
		 [146 139  41 192  73   9 187 194]
		 [ 40 144 246  62  83  23 223 235]
		 [254 224  78  38  58 250 102  19]
		 [ 18  16   0  42 126   5 243  94]]
		->
		[[185 105 241  21 113 187 222 212]
		 [146 139 192  41 187 194  73   9]
		 [ 18  16  42   0 243  94 126   5]
		 [141 197  39 160 234  70 198 102]
		 [ 83  23 235 223 144  40 246  62]
		 [147 220  19 113 177 145 147  63]
		 [ 29 175 188 104 220  67 173 206]
		 [ 78  38 254 224 250  58 102  19]]
		*/

		// Row permutation: 1 4 7 2 5 0 3 6
		io_rowPermInfo[11:0] = 12'd4095;
		io_rowPermInfo[23:12] = 12'd2544;

		io_inData = '{63, 147, 177, 145, 220, 147, 113, 19};
		// Column permutation: 2 3 0 1 5 4 6 7
		io_colPermInfo[11:0] = 12'd4095;
		io_colPermInfo[23:12] = 12'd3901;
		@(negedge clock);

		io_inData = '{187, 113, 212, 222, 241, 21, 105, 185};
		// Column permutation: 0 1 3 2 6 7 4 5
		io_colPermInfo[11:0] = 12'd4095;
		io_colPermInfo[23:12] = 12'd4043;
		@(negedge clock);

		io_inData = '{39, 160, 197, 141, 102, 198, 234, 70};
		// Column permutation: 4 5 7 6 1 0 2 3
		io_colPermInfo[11:0] = 12'd4095;
		io_colPermInfo[23:12] = 12'd246;
		@(negedge clock);

		io_inData = '{206, 173, 220, 67, 175, 29, 104, 188};
		// Column permutation: 2 3 0 1 5 4 6 7
		io_colPermInfo[11:0] = 12'd4095;
		io_colPermInfo[23:12] = 12'd3901;
		@(negedge clock);

		io_inData = '{194, 187, 9, 73, 192, 41, 139, 146};
		// Column permutation: 0 1 3 2 6 7 4 5
		io_colPermInfo[11:0] = 12'd4095;
		io_colPermInfo[23:12] = 12'd4043;
		@(negedge clock);

		io_inData = '{235, 223, 23, 83, 62, 246, 144, 40};
		// Column permutation: 4 5 7 6 1 0 2 3
		io_colPermInfo[11:0] = 12'd4095;
		io_colPermInfo[23:12] = 12'd246;
		@(negedge clock);

		io_inData = '{19, 102, 250, 58, 38, 78, 224, 254};
		// Column permutation: 2 3 0 1 5 4 6 7
		io_colPermInfo[11:0] = 12'd4095;
		io_colPermInfo[23:12] = 12'd3901;
		@(negedge clock);

		io_inData = '{94, 243, 5, 126, 42, 0, 16, 18};
		// Column permutation: 0 1 3 2 6 7 4 5
		io_colPermInfo[11:0] = 12'd4095;
		io_colPermInfo[23:12] = 12'd4043;
		@(negedge clock);

		io_inActive = 0;
		io_inData = '{default: '0};
		io_colPermInfo = 0;
		io_rowPermInfo = 0;

		// Wait for 14 cycles
		for (i = 0;i < `AutomorphismDelay(p_rowSize, p_clusterNum) - 8;i++) begin
			`TestCheck(io_outActive, 0)
			@(negedge clock);
		end

		// Check answer
		ans = '{212, 222, 187, 113, 21, 241, 105, 185};
		`TestCheck(io_outActive, 1)
		`TestCheckArray(io_outData, ans, p_rowSize)
		@(negedge clock);
		ans = '{9, 73, 194, 187, 41, 192, 139, 146};
		`TestCheck(io_outActive, 1)
		`TestCheckArray(io_outData, ans, p_rowSize)
		@(negedge clock);
		ans = '{5, 126, 94, 243, 0, 42, 16, 18};
		`TestCheck(io_outActive, 1)
		`TestCheckArray(io_outData, ans, p_rowSize)
		@(negedge clock);
		ans = '{102, 198, 70, 234, 160, 39, 197, 141};
		`TestCheck(io_outActive, 1)
		`TestCheckArray(io_outData, ans, p_rowSize)
		@(negedge clock);
		ans = '{62, 246, 40, 144, 223, 235, 23, 83};
		`TestCheck(io_outActive, 1)
		`TestCheckArray(io_outData, ans, p_rowSize)
		@(negedge clock);
		ans = '{63, 147, 145, 177, 113, 19, 220, 147};
		`TestCheck(io_outActive, 1)
		`TestCheckArray(io_outData, ans, p_rowSize)
		@(negedge clock);
		ans = '{206, 173, 67, 220, 104, 188, 175, 29};
		`TestCheck(io_outActive, 1)
		`TestCheckArray(io_outData, ans, p_rowSize)
		@(negedge clock);
		ans = '{19, 102, 58, 250, 224, 254, 38, 78};
		`TestCheck(io_outActive, 1)
		`TestCheckArray(io_outData, ans, p_rowSize)
		@(negedge clock);
		`TestCheck(io_outActive, 0)

		`TestFinish("Automorphism8x8Test")
	end

endmodule: Automorphism8x8Test
