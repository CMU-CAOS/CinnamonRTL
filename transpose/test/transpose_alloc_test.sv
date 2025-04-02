`default_nettype none


/*
 * Fully transpose a 128x128 matrix across 8 clusters
 */
module TransposeAllocTest
	#(parameter
		p_portNum = 4,
		p_testNum = 20,
		p_instanceNum = 3,
		p_rowSize = 128,
		p_clusterNum = 8,
		p_dataWidth = 10
	);

	localparam p_colSize = p_rowSize / p_clusterNum;

	logic clock, reset;
	logic io_inActive[p_portNum-1:0],
		io_outActive[p_clusterNum-1:0][p_portNum-1:0];
	logic [p_dataWidth-1:0]
		io_inData[p_clusterNum-1:0][p_portNum-1:0][p_rowSize-1:0],
		io_networkInData[p_instanceNum-1:0][p_clusterNum-1:0][p_rowSize-1:0],
		io_networkInData2[p_clusterNum-1:0][p_instanceNum-1:0][p_rowSize-1:0];
	logic [p_dataWidth-1:0]
		io_outData[p_clusterNum-1:0][p_portNum-1:0][p_rowSize-1:0],
		io_networkOutData[p_instanceNum-1:0][p_clusterNum-1:0][p_rowSize-1:0],
		io_networkOutData2[p_clusterNum-1:0][p_instanceNum-1:0][p_rowSize-1:0];

	genvar clusterId, instanceId;
	generate
	// Transpose modules
	for (clusterId = 0;clusterId < p_clusterNum;clusterId++) begin
		TransposeAlloc #(
			.p_portNum(p_portNum),
			.p_instanceNum(p_instanceNum),
			.p_rowSize(p_rowSize),
			.p_clusterNum(p_clusterNum),
			.p_dataWidth(p_dataWidth)
		) m_transpose(
			.clock, .reset,
			.io_inActive,
			.io_inData(io_inData[clusterId]),
			.io_outActive(io_outActive[clusterId]),
			.io_outData(io_outData[clusterId]),
			.io_networkInData(io_networkInData2[clusterId]),
			.io_networkOutData(io_networkOutData2[clusterId])
		);
	end
	// Transpose network module
	for (instanceId = 0;instanceId < p_instanceNum;instanceId++) begin
		TransposeNetworkPermutation #(
			.p_clusterNum(p_clusterNum),
			.p_rowSize(p_rowSize),
			.p_dataWidth(p_dataWidth)
		) m_network(
			.io_inData(io_networkInData[instanceId]),
			.io_outData(io_networkOutData[instanceId])
		);
	end
	for (clusterId = 0;clusterId < p_clusterNum;clusterId++) begin
		for (instanceId = 0;instanceId < p_instanceNum;instanceId++) begin
			always_comb begin
				io_networkInData[instanceId][clusterId] = io_networkInData2[clusterId][instanceId];
				io_networkOutData2[clusterId][instanceId] = io_networkOutData[instanceId][clusterId];
			end
		end
	end
	endgenerate

	// Matrix of random data
	logic [p_dataWidth-1:0] mat[p_testNum-1:0][p_rowSize-1:0][p_rowSize-1:0];

	`TestClock(clock)
	initial begin
		integer i, j, k;
		`TestReset(reset)

		// Random data
		for (k = 0;k < p_testNum;k++) begin
			for (i = 0;i < p_rowSize;i++) begin
				for (j = 0;j < p_rowSize;j++) begin
					mat[k][i][j] = p_dataWidth'($random);
				end
			end
		end
		for (i = 0;i < p_portNum;i++) io_inActive[i] = 0;
	end

	// Run test on a transpose port
	task automatic check(integer port, integer test);
		integer i, j, cluster;
		io_inActive[port]++;
		for (i = 0;i < p_colSize;i++) begin
			for (cluster = 0;cluster < p_clusterNum;cluster++) begin
				for (j = 0;j < p_rowSize;j++) begin
					io_inData[cluster][port][j] = mat[test][i * p_clusterNum + cluster][j];
				end
			end
			@(negedge clock);
		end
		io_inActive[port]--;
		for (i = 0;i < `TransposeDelay(p_colSize) - p_colSize;i++) begin
			@(negedge clock);
		end
		// Check output
		for (i = 0;i < p_colSize;i++) begin
			for (cluster = 0;cluster < p_clusterNum;cluster++) begin
				`TestCheck(io_outActive[cluster][port], 1)
				for (j = 0;j < p_rowSize;j++) begin
					`TestCheck(io_outData[cluster][port][j], mat[test][j][i * p_clusterNum + cluster])
				end
			end
			@(negedge clock);
		end
	endtask: check

	initial begin `TestWait(10) check(0, 1); end
	initial begin `TestWait(10) check(1, 2); end
	initial begin `TestWait(10) check(2, 4); end
	initial begin `TestWait(26) check(3, 5); end
	initial begin `TestWait(27) check(1, 6); end
	initial begin `TestWait(31) check(0, 7); end
	initial begin `TestWait(43) check(2, 8); end
	initial begin `TestWait(43) check(3, 9); end
	initial begin `TestWait(59) check(0, 10); end
	initial begin `TestWait(59) check(1, 11); end
	initial begin `TestWait(59) check(3, 12); end
	initial begin `TestWait(76) check(2, 13); end

	initial begin
		`TestWait(100)
		`TestFinish("TransposeAllocTest")
	end

endmodule: TransposeAllocTest
