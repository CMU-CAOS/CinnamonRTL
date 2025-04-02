`default_nettype none

/*
 * Permutation network (wires only)
 */
module TransposeNetworkPermutation
	#(parameter
		p_clusterNum = 0,
		p_rowSize = 0,
		p_dataWidth = 0
	)
	(
		input logic  [p_dataWidth-1:0] io_inData[p_clusterNum-1:0][p_rowSize-1:0],
		output logic [p_dataWidth-1:0] io_outData[p_clusterNum-1:0][p_rowSize-1:0]
	);

	// Derive param
	if (p_rowSize % p_clusterNum != 0) $error("rows not multiples of cluster num");
	localparam p_colSize = p_rowSize / p_clusterNum;

	// Connections
	genvar block, srcId, srcElem;
	generate
		for (block = 0;block < p_colSize;block++) begin
			for (srcId = 0;srcId < p_clusterNum;srcId++) begin
				for (srcElem = 0;srcElem < p_clusterNum;srcElem++) begin
					localparam destId = srcElem;
					localparam destElem = srcId;
					always_comb begin
						io_outData[destId][block * p_clusterNum + destElem] =
							io_inData[srcId][block * p_clusterNum + srcElem];
					end
				end
			end
		end
	endgenerate

endmodule: TransposeNetworkPermutation
