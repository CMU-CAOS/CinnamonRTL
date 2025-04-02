`default_nettype none


/*
 * Fully transpose a 8x8 matrix across 4 clusters
 */
module Transpose8C4Test
	#(parameter
		p_rowSize = 8,
		p_clusterNum = 4,
		p_dataWidth = 16
	);

	localparam p_colSize = p_rowSize / p_clusterNum;

	logic clock, reset;
	logic io_inActive, io_outActive[p_clusterNum-1:0];
	logic [p_dataWidth-1:0]
		io_inData[p_clusterNum-1:0][p_rowSize-1:0],
		io_networkInData[p_clusterNum-1:0][p_rowSize-1:0];
	logic [p_dataWidth-1:0]
		io_outData[p_clusterNum-1:0][p_rowSize-1:0],
		io_networkOutData[p_clusterNum-1:0][p_rowSize-1:0];
	logic [p_rowSize-1:0][p_dataWidth-1:0] ans;

	// Transpose modules
	genvar clusterId;
	generate
	for (clusterId = 0;clusterId < p_clusterNum;clusterId++) begin
		Transpose #(
			.p_rowSize(p_rowSize),
			.p_clusterNum(p_clusterNum),
			.p_dataWidth(p_dataWidth)
		) m_transpose(
			.clock, .reset,
			.io_inActive,
			.io_inData(io_inData[clusterId]),
			.io_outActive(io_outActive[clusterId]),
			.io_outData(io_outData[clusterId]),
			.io_networkInData(io_networkInData[clusterId]),
			.io_networkOutData(io_networkOutData[clusterId])
		);
	end
	endgenerate
	// Transpose network module
	TransposeNetworkPermutation #(
		.p_clusterNum(p_clusterNum),
		.p_rowSize(p_rowSize),
		.p_dataWidth(p_dataWidth)
	) m_network(
		.io_inData(io_networkInData),
		.io_outData(io_networkOutData)
	);

	function void check(input integer clusterId);
		integer i;
		`TestCheck(io_outActive[clusterId], 1)
		for (i = 0;i < p_rowSize;i++) `TestCheck(io_outData[clusterId][i], ans[i])
	endfunction: check

	`TestClock(clock)
	integer i, j;
	initial begin
		`TestReset(reset)

		io_inActive = 1;

		// First row
		io_inData[0] = '{7, 6, 5, 4, 3, 2, 1, 0};
		io_inData[1] = '{15, 14, 13, 12, 11, 10, 9, 8};
		io_inData[2] = '{23, 22, 21, 20, 19, 18, 17, 16};
		io_inData[3] = '{31, 30, 29, 28, 27, 26, 25, 24};
		@(negedge clock);

		// Second row
		io_inData[0] = '{39, 38, 37, 36, 35, 34, 33, 32};
		io_inData[1] = '{47, 46, 45, 44, 43, 42, 41, 40};
		io_inData[2] = '{55, 54, 53, 52, 51, 50, 49, 48};
		io_inData[3] = '{63, 62, 61, 60, 59, 58, 57, 56};
		@(negedge clock);

		io_inActive = 0;

		// Check output
		ans = '{56, 48, 40, 32, 24, 16,  8,  0};check(0);
		ans = '{57, 49, 41, 33, 25, 17,  9,  1};check(1);
		ans = '{58, 50, 42, 34, 26, 18, 10,  2};check(2);
		ans = '{59, 51, 43, 35, 27, 19, 11,  3};check(3);
		@(negedge clock);
		ans = '{60, 52, 44, 36, 28, 20, 12,  4};check(0);
		ans = '{61, 53, 45, 37, 29, 21, 13,  5};check(1);
		ans = '{62, 54, 46, 38, 30, 22, 14,  6};check(2);
		ans = '{63, 55, 47, 39, 31, 23, 15,  7};check(3);
		@(negedge clock);

		`TestFinish("Transpose8C4Test")
	end

endmodule: Transpose8C4Test


/*
 * Fully transpose a 128x128 matrix across 8 clusters
 */
module Transpose128C8Test
	#(parameter
		p_rowSize = 128,
		p_clusterNum = 8,
		p_dataWidth = 10
	);

	localparam p_colSize = p_rowSize / p_clusterNum;

	logic clock, reset;
	logic io_inActive, io_outActive[p_clusterNum-1:0];
	logic [p_dataWidth-1:0]
		data[p_clusterNum-1:0][p_rowSize-1:0],
		io_inData[p_clusterNum-1:0][p_rowSize-1:0],
		io_networkInData[p_clusterNum-1:0][p_rowSize-1:0];
	logic [p_dataWidth-1:0]
		io_outData[p_clusterNum-1:0][p_rowSize-1:0],
		io_networkOutData[p_clusterNum-1:0][p_rowSize-1:0];

	// Transpose modules
	genvar clusterId;
	generate
	for (clusterId = 0;clusterId < p_clusterNum;clusterId++) begin
		Transpose #(
			.p_rowSize(p_rowSize),
			.p_clusterNum(p_clusterNum),
			.p_dataWidth(p_dataWidth)
		) m_transpose(
			.clock, .reset,
			.io_inActive,
			.io_inData(io_inData[clusterId]),
			.io_outActive(io_outActive[clusterId]),
			.io_outData(io_outData[clusterId]),
			.io_networkInData(io_networkInData[clusterId]),
			.io_networkOutData(io_networkOutData[clusterId])
		);
	end
	endgenerate
	// Transpose network module
	TransposeNetworkPermutation #(
		.p_clusterNum(p_clusterNum),
		.p_rowSize(p_rowSize),
		.p_dataWidth(p_dataWidth)
	) m_network(
		.io_inData(io_networkInData),
		.io_outData(io_networkOutData)
	);

	// Matrix of random data
	logic [p_dataWidth-1:0] mat[p_rowSize-1:0][p_rowSize-1:0];

	`TestClock(clock)
	integer i, j, cluster;
	initial begin
		`TestReset(reset)

		// Random data
		for (i = 0;i < p_rowSize;i++) begin
			for (j = 0;j < p_rowSize;j++) begin
				mat[i][j] = p_dataWidth'($random);
			end
		end

		for (i = 0;i < p_colSize;i++) begin
			for (cluster = 0;cluster < p_clusterNum;cluster++) begin
				for (j = 0;j < p_rowSize;j++) begin
					data[cluster][j] = mat[i * p_clusterNum + cluster][j];
				end
			end
			io_inData = data;
			io_inActive = 1;
			@(negedge clock);
		end
		io_inActive = 0;
		for (i = 0;i < `TransposeDelay(p_colSize) - p_colSize;i++) begin
			@(negedge clock);
		end
		// Check output
		for (i = 0;i < p_colSize;i++) begin
			for (cluster = 0;cluster < p_clusterNum;cluster++) begin
				`TestCheck(io_outActive[cluster], 1)
				for (j = 0;j < p_rowSize;j++) begin
					`TestCheck(io_outData[cluster][j], mat[j][i * p_clusterNum + cluster])
				end
			end
			@(negedge clock);
		end

		`TestFinish("Transpose128C8Test")
	end

endmodule: Transpose128C8Test


/*
 * Fully transpose a 256x256 matrix across 4 clusters
 * Test pipeline bubbles
 */
module Transpose256C4Test
	#(parameter
		p_rowSize = 256,
		p_clusterNum = 4,
		p_dataWidth = 10,
		p_pause1 = 3,
		p_pause2 = 47
	);

	localparam p_colSize = p_rowSize / p_clusterNum;

	logic clock, reset;
	logic io_inActive, io_outActive[p_clusterNum-1:0];
	logic [p_dataWidth-1:0]
		data[p_clusterNum-1:0][p_rowSize-1:0],
		io_inData[p_clusterNum-1:0][p_rowSize-1:0],
		io_networkInData[p_clusterNum-1:0][p_rowSize-1:0];
	logic [p_dataWidth-1:0]
		io_outData[p_clusterNum-1:0][p_rowSize-1:0],
		io_networkOutData[p_clusterNum-1:0][p_rowSize-1:0];

	// Transpose modules
	genvar clusterId;
	generate
	for (clusterId = 0;clusterId < p_clusterNum;clusterId++) begin
		Transpose #(
			.p_rowSize(p_rowSize),
			.p_clusterNum(p_clusterNum),
			.p_dataWidth(p_dataWidth)
		) m_transpose(
			.clock, .reset,
			.io_inActive,
			.io_inData(io_inData[clusterId]),
			.io_outActive(io_outActive[clusterId]),
			.io_outData(io_outData[clusterId]),
			.io_networkInData(io_networkInData[clusterId]),
			.io_networkOutData(io_networkOutData[clusterId])
		);
	end
	endgenerate
	// Transpose network module
	TransposeNetworkPermutation #(
		.p_clusterNum(p_clusterNum),
		.p_rowSize(p_rowSize),
		.p_dataWidth(p_dataWidth)
	) m_network(
		.io_inData(io_networkInData),
		.io_outData(io_networkOutData)
	);

	// Matrix of random data
	logic [p_dataWidth-1:0] mat[p_rowSize-1:0][p_rowSize-1:0];

	`TestClock(clock)
	integer i, j, c1;
	initial begin
		`TestReset(reset)

		// Random data
		for (i = 0;i < p_rowSize;i++) begin
			for (j = 0;j < p_rowSize;j++) begin
				mat[i][j] = p_dataWidth'($random);
			end
		end

		// Data 1
		io_inActive = 1;
		for (i = 0;i < p_colSize;i++) begin
			for (c1 = 0;c1 < p_clusterNum;c1++) begin
				for (j = 0;j < p_rowSize;j++) begin
					data[c1][j] = mat[i * p_clusterNum + c1][j];
				end
			end
			io_inData = data;
			@(negedge clock);
		end
		// Pause 1
		io_inActive = 0;
		for (i = 0;i < p_pause1;i++) begin
			@(negedge clock);
		end
		// Data 2
		io_inActive = 1;
		for (i = 0;i < p_colSize;i++) begin
			for (c1 = 0;c1 < p_clusterNum;c1++) begin
				for (j = 0;j < p_rowSize;j++) begin
					data[c1][j] = mat[i * p_clusterNum + c1][j];
				end
			end
			io_inData = data;
			@(negedge clock);
		end
		// Pause 2
		io_inActive = 0;
		for (i = 0;i < p_pause2;i++) begin
			@(negedge clock);
		end
		// Data 3
		io_inActive = 1;
		for (i = 0;i < p_colSize;i++) begin
			for (c1 = 0;c1 < p_clusterNum;c1++) begin
				for (j = 0;j < p_rowSize;j++) begin
					data[c1][j] = mat[i * p_clusterNum + c1][j];
				end
			end
			io_inData = data;
			@(negedge clock);
		end
		// End
		io_inActive = 0;
	end

	integer k, l, c2;
	initial begin
		@(negedge clock);
		for (k = 0;k < `TransposeDelay(p_colSize);k++) begin
			@(negedge clock);
		end
		// Data 1
		for (k = 0;k < p_colSize;k++) begin
			for (c2 = 0;c2 < p_clusterNum;c2++) begin
				`TestCheck(io_outActive[c2], 1)
				for (l = 0;l < p_rowSize;l++) begin
					`TestCheck(io_outData[c2][l], mat[l][k * p_clusterNum + c2])
				end
			end
			@(negedge clock);
		end
		// Pause 1
		for (k = 0;k < p_pause1;k++) begin
			for (c2 = 0;c2 < p_clusterNum;c2++) begin
				`TestCheck(io_outActive[c2], 0)
			end
			@(negedge clock);
		end
		// Data 2
		for (k = 0;k < p_colSize;k++) begin
			for (c2 = 0;c2 < p_clusterNum;c2++) begin
				`TestCheck(io_outActive[c2], 1)
				for (l = 0;l < p_rowSize;l++) begin
					`TestCheck(io_outData[c2][l], mat[l][k * p_clusterNum + c2])
				end
			end
			@(negedge clock);
		end
		// Pause 2
		for (k = 0;k < p_pause2;k++) begin
			for (c2 = 0;c2 < p_clusterNum;c2++) begin
				`TestCheck(io_outActive[c2], 0)
			end
			@(negedge clock);
		end
		// Data 3
		for (k = 0;k < p_colSize;k++) begin
			for (c2 = 0;c2 < p_clusterNum;c2++) begin
				`TestCheck(io_outActive[c2], 1)
				for (l = 0;l < p_rowSize;l++) begin
					`TestCheck(io_outData[c2][l], mat[l][k * p_clusterNum + c2])
				end
			end
			@(negedge clock);
		end
		// End
		for (c2 = 0;c2 < p_clusterNum;c2++) begin
			`TestCheck(io_outActive[c2], 0)
		end
		`TestFinish("Transpose256C4Test")
	end

endmodule: Transpose256C4Test
