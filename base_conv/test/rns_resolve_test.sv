`default_nettype none


// RNSResolve instance
`define RNSResolveInstance \
	RNSResolve #( \
		.p_rowSize(p_rowSize), \
		.p_blockNum(p_blockNum), \
		.p_dataWidth(p_dataWidth) \
	) dut(.*);


/*
 * RNS resolve test 1
 */
module RNSResolveBasicTest
	#(parameter
		p_rowSize = 2,
		p_blockNum = 3,
		p_dataWidth = 28
	);

	logic clock, reset;
	logic io_inActive, io_outActive, io_inIsAccumulate;
	logic [p_dataWidth-1:0]
		io_inData[0:p_rowSize-1],
		io_inSum[0:p_blockNum-1][0:p_rowSize-1],
		io_outData[0:p_blockNum-1][0:p_rowSize-1],
		ans[0:p_blockNum-1][0:p_rowSize-1];
	logic [p_dataWidth*p_blockNum-1:0]
		io_inF, io_inQ;
	`RNSResolveInstance

	integer i;
	`TestClock(clock)
	initial begin
		`TestReset(reset)

		io_inQ = 1000;
		// Not accumulate
		io_inActive = 1;
		io_inIsAccumulate = 0;
		io_inF = 6;
		io_inData = '{1, 2};
		@(negedge clock);
		io_inActive = 1;
		io_inIsAccumulate = 1;
		io_inF = 7;
		io_inData = '{3, 4};
		io_inSum = '{'{6, 12}, '{0, 0}, '{0, 0}};
		@(negedge clock);
		io_inActive = 1;
		io_inIsAccumulate = 1;
		io_inF = 8;
		io_inData = '{5, 6};
		io_inSum = '{'{27, 40}, '{0, 0}, '{0, 0}};
		@(negedge clock);
		io_inActive = 0;
		io_inIsAccumulate = 0;

		for (i = 0;i < `RNSResolveDelay(p_blockNum, p_dataWidth) - 3;i++) begin
			`TestCheck(io_outActive, 0)
			@(negedge clock);
		end

		ans = '{'{6, 12}, '{0, 0}, '{0, 0}};
		`TestCheck(io_outActive, 1)
		for (i = 0;i < p_blockNum;i++) begin
			`TestCheckArray(io_outData[i], ans[i], p_rowSize)
		end
		@(negedge clock);
		`TestCheck(io_outActive, 1)
		ans = '{'{27, 40}, '{0, 0}, '{0, 0}};
		for (i = 0;i < p_blockNum;i++) begin
			`TestCheckArray(io_outData[i], ans[i], p_rowSize)
		end
		@(negedge clock);
		`TestCheck(io_outActive, 1)
		ans = '{'{67, 88}, '{0, 0}, '{0, 0}};
		for (i = 0;i < p_blockNum;i++) begin
			`TestCheckArray(io_outData[i], ans[i], p_rowSize)
		end
		@(negedge clock);
		`TestCheck(io_outActive, 0)

		`TestFinish("RNSResolveBasicTest")
	end

endmodule: RNSResolveBasicTest


/*
 * RNS resolve example 1
 */
module RNSResolveEx1Test
	#(parameter
		p_rowSize = 4,
		p_blockNum = 3,
		p_dataWidth = 40
	);

	logic clock, reset;
	logic io_inActive, io_outActive, io_inIsAccumulate;
	logic [p_dataWidth-1:0]
		io_inData[0:p_rowSize-1],
		io_inSum[0:p_blockNum-1][0:p_rowSize-1],
		io_outData[0:p_blockNum-1][0:p_rowSize-1];
	logic [p_dataWidth*p_blockNum-1:0]
		io_inF, io_inQ;
	logic [p_dataWidth-1:0] mat[0:p_blockNum-1][0:p_rowSize-1][0:p_rowSize-1];
	logic [p_dataWidth*p_blockNum-1:0] ans[0:p_rowSize-1][0:p_rowSize-1];
	`RNSResolveInstance

	integer i, j;
	`TestClock(clock)
	initial begin
		`TestReset(reset)

		mat[0] = '{
			'{40'd28575450,  40'd52916166,  40'd31359687,  40'd101180588},
			'{40'd43111479,  40'd49136002,  40'd57631923,  40'd96581823},
			'{40'd114500955, 40'd77241917,  40'd62286429,  40'd44118165},
			'{40'd8870757,   40'd105982736, 40'd119859481, 40'd28511794}
		};
		mat[1] = '{
			'{40'd26445009,  40'd53396625,  40'd114651220, 40'd12279810},
			'{40'd93581889,  40'd62692434,  40'd54921790,  40'd86465680},
			'{40'd87823648,  40'd118756441, 40'd11633890,  40'd90914245},
			'{40'd28260691,  40'd88067010,  40'd75779677,  40'd96275128}
		};
		mat[2] = '{
			'{40'd42010023,  40'd94156379,  40'd74980076,  40'd31651041},
			'{40'd85782546,  40'd43520282,  40'd117140020, 40'd36543364},
			'{40'd124533814, 40'd53440515,  40'd13390407,  40'd75975632},
			'{40'd104916862, 40'd81180894,  40'd102843542, 40'd79467300}
		};
		ans = '{
			'{120'd1036984319191958849810643, 120'd35871134381677746923884,   120'd1966486791593824776018560, 120'd671015508214401271700026},
			'{120'd387415025569313633991109,  120'd1184954656973262632692793, 120'd604445866664013521808195,  120'd1802633407252548434292614},
			'{120'd107735647591309227482095,  120'd335340780942404855207364,  120'd922657348435733973218089,  120'd1999189567564979325367555},
			'{120'd1104540533871897463127821, 120'd732864900471713571485228,  120'd321514991017921013007027,  120'd907277527660168078999990}
		};

		io_inQ = 120'd2061503672908330186178561;
		// Matrix 0
		io_inActive = 1;
		io_inIsAccumulate = 0;
		io_inF = 120'd1392631718892347930795185;
		for (i = 0;i < p_rowSize;i++) begin
			io_inData = mat[0][i];
			@(negedge clock);
		end
		io_inActive = 0;
		for (i = 0;i < `RNSResolveDelay(p_blockNum, p_dataWidth) - p_rowSize;i++) begin
			`TestCheck(io_outActive, 0)
			@(negedge clock);
		end
		// Matrix 1
		io_inActive = 1;
		io_inIsAccumulate = 1;
		io_inF = 120'd1348717276064081664478537;
		for (i = 0;i < p_rowSize;i++) begin
			io_inData = mat[1][i];
			`TestCheck(io_outActive, 1)
			io_inSum = io_outData;
			@(negedge clock);
		end
		io_inActive = 0;
		for (i = 0;i < `RNSResolveDelay(p_blockNum, p_dataWidth) - p_rowSize;i++) begin
			`TestCheck(io_outActive, 0)
			@(negedge clock);
		end
		// Matrix 2
		io_inActive = 1;
		io_inIsAccumulate = 1;
		io_inF = 120'd1381658350860230777083401;
		for (i = 0;i < p_rowSize;i++) begin
			io_inData = mat[2][i];
			`TestCheck(io_outActive, 1)
			io_inSum = io_outData;
			@(negedge clock);
		end
		io_inActive = 0;
		io_inIsAccumulate = 0;
		for (i = 0;i < `RNSResolveDelay(p_blockNum, p_dataWidth) - p_rowSize;i++) begin
			`TestCheck(io_outActive, 0)
			@(negedge clock);
		end
		// Check answer
		for (i = 0;i < p_rowSize;i++) begin
			`TestCheck(io_outActive, 1)
			for (j = 0;j < p_rowSize;j++) begin
				`TestCheck({io_outData[2][j], io_outData[1][j], io_outData[0][j]} % 120'd2061503672908330186178561, ans[i][j])
			end
			@(negedge clock);
		end

		`TestFinish("RNSResolveEx1Test")
	end

endmodule: RNSResolveEx1Test


/*
 * RNS resolve example 2
 */
module RNSResolveEx2Test
	#(parameter
		p_rowSize = 4,
		p_blockNum = 3,
		p_dataWidth = 28
	);

	logic clock, reset;
	logic io_inActive, io_outActive, io_inIsAccumulate;
	logic [p_dataWidth-1:0]
		io_inData[0:p_rowSize-1],
		io_inSum[0:p_blockNum-1][0:p_rowSize-1],
		io_outData[0:p_blockNum-1][0:p_rowSize-1];
	logic [p_dataWidth*p_blockNum-1:0]
		io_inF, io_inQ;
	logic [p_dataWidth-1:0] mat[0:p_blockNum-1][0:p_rowSize-1][0:p_rowSize-1];
	logic [p_dataWidth*p_blockNum-1:0] ans[0:p_rowSize-1][0:p_rowSize-1];
	`RNSResolveInstance

	integer i, j;
	`TestClock(clock)
	initial begin
		`TestReset(reset)

		mat[0] = '{
			'{73, 4, 54, 61},
			'{73, 1, 26, 59},
			'{62, 35, 83, 20},
			'{4, 66, 62, 41}
		};
		mat[1] = '{
			'{38, 127, 184, 22},
			'{215, 71, 181, 195},
			'{215, 145, 134, 233},
			'{89, 155, 185, 68}
		};
		mat[2] = '{
			'{233, 393, 440, 122},
			'{225, 314, 192, 22},
			'{298, 2, 120, 68},
			'{99, 155, 274, 187}
		};
		ans = '{
			'{2886405, 7737112, 7000350, 4137208},
			'{3621859, 6492405, 3314710, 973454},
			'{2780955, 2260717, 9261643, 247467},
			'{11006885, 3000373, 7861815, 7418116}
		};

		io_inQ = 11193121;
		// Matrix 0
		io_inActive = 1;
		io_inIsAccumulate = 0;
		io_inF = 8769868;
		for (i = 0;i < p_rowSize;i++) begin
			io_inData = mat[0][i];
			@(negedge clock);
		end
		io_inActive = 0;
		for (i = 0;i < `RNSResolveDelay(p_blockNum, p_dataWidth) - p_rowSize;i++) begin
			`TestCheck(io_outActive, 0)
			@(negedge clock);
		end
		// Matrix 1
		io_inActive = 1;
		io_inIsAccumulate = 1;
		io_inF = 653295;
		for (i = 0;i < p_rowSize;i++) begin
			io_inData = mat[1][i];
			`TestCheck(io_outActive, 1)
			io_inSum = io_outData;
			@(negedge clock);
		end
		io_inActive = 0;
		for (i = 0;i < `RNSResolveDelay(p_blockNum, p_dataWidth) - p_rowSize;i++) begin
			`TestCheck(io_outActive, 0)
			@(negedge clock);
		end
		// Matrix 2
		io_inActive = 1;
		io_inIsAccumulate = 1;
		io_inF = 1769959;
		for (i = 0;i < p_rowSize;i++) begin
			io_inData = mat[2][i];
			`TestCheck(io_outActive, 1)
			io_inSum = io_outData;
			@(negedge clock);
		end
		io_inActive = 0;
		io_inIsAccumulate = 0;
		for (i = 0;i < `RNSResolveDelay(p_blockNum, p_dataWidth) - p_rowSize;i++) begin
			`TestCheck(io_outActive, 0)
			@(negedge clock);
		end
		// Check answer
		for (i = 0;i < p_rowSize;i++) begin
			`TestCheck(io_outActive, 1)
			for (j = 0;j < p_rowSize;j++) begin
				`TestCheck({io_outData[2][j], io_outData[1][j], io_outData[0][j]} % 11193121, ans[i][j])
			end
			@(negedge clock);
		end

		`TestFinish("RNSResolveEx2Test")
	end

endmodule: RNSResolveEx2Test
