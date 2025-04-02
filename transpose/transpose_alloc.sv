`default_nettype none


/*
 * Transpose with allocator
 */
module TransposeAlloc
	#(parameter
		p_portNum = 0,
		p_instanceNum = 0,
		p_rowSize = 0,
		p_clusterNum = 0,
		p_dataWidth = 0
	)
	(
		input logic  clock, reset,
		// Ports
		input logic  io_inActive[p_portNum-1:0],
		input logic  [p_dataWidth-1:0]
			io_inData[p_portNum-1:0][p_rowSize-1:0],
		output logic io_outActive[p_portNum-1:0],
		output logic [p_dataWidth-1:0]
			io_outData[p_portNum-1:0][p_rowSize-1:0],
		// Transpose network
		output logic [p_dataWidth-1:0]
			io_networkInData[p_instanceNum-1:0][p_rowSize-1:0],
		input logic  [p_dataWidth-1:0]
			io_networkOutData[p_instanceNum-1:0][p_rowSize-1:0]
	);

	// Column size
	localparam p_colSize = p_rowSize / p_clusterNum;

	// Address width
	localparam p_portAddrWidth = $clog2(p_portNum);
	localparam p_instanceAddrWidth = $clog2(p_instanceNum);

	logic w_instanceInActive[p_instanceNum-1:0],
		w_instanceOutActive[p_instanceNum-1:0];
	logic [p_dataWidth-1:0]
		w_instanceInData[p_instanceNum-1:0][p_rowSize-1:0],
		w_instanceOutData[p_instanceNum-1:0][p_rowSize-1:0];

	// Allocator logic
	// Instance is used
	logic w_instanceIsUsed[p_instanceNum-1:0],
		r_instanceIsUsedPrev[p_instanceNum-1:0];
	// Port id for each instance
	logic [p_portAddrWidth-1:0] w_instanceToPort[p_instanceNum-1:0],
		w_instanceToPortDelayed[p_instanceNum-1:0],
		r_instanceToPortPrev[p_instanceNum-1:0];
	logic r_inActivePrev[p_portNum-1:0];
	always_ff @(posedge clock) begin
		if (reset) begin
			r_instanceIsUsedPrev <= '{default: 0};
			r_instanceToPortPrev <= '{default: 0};
			r_inActivePrev <= '{default: 0};
		end else begin
			r_instanceIsUsedPrev <= w_instanceIsUsed;
			r_instanceToPortPrev <= w_instanceToPort;
			r_inActivePrev <= io_inActive;
		end
	end

	always_comb begin
		integer i, j;
		for (i = 0;i < p_instanceNum;i++) begin
			w_instanceIsUsed[i] = r_instanceIsUsedPrev[i];
			w_instanceToPort[i] = r_instanceToPortPrev[i];
		end
		for (i = 0;i < p_instanceNum;i++) begin
			if (w_instanceIsUsed[i] && !io_inActive[w_instanceToPort[i]]) begin
				w_instanceIsUsed[i] = 0;
			end
		end
		for (j = 0;j < p_portNum;j++) begin
			if (!r_inActivePrev[j] && io_inActive[j]) begin
				for (i = 0;i < p_instanceNum;i++) begin
					if (!w_instanceIsUsed[i]) begin
						w_instanceIsUsed[i] = 1;
						w_instanceToPort[i] = j;
						break;
					end
				end
				if (i == p_instanceNum) $error("Insufficient transpose instance");
			end
		end
	end

	// Delay port assignment until output
	genvar instanceId;
	generate
	for (instanceId = 0;instanceId < p_instanceNum;instanceId++) begin
		SignalDelay #(
			.p_width(p_portAddrWidth),
			.p_delay(`TransposeDelay(p_colSize))
		) m_mapDelay(
			.clock, .reset,
			.io_inData(w_instanceToPort[instanceId]),
			.io_outData(w_instanceToPortDelayed[instanceId])
		);
	end
	endgenerate

	// Wire IO
	always_comb begin
		integer i;
		for (i = 0;i < p_instanceNum;i++) begin
			w_instanceInActive[i] = io_inActive[w_instanceToPort[i]];
			w_instanceInData[i] = io_inData[w_instanceToPort[i]];
		end
		for (i = 0;i < p_portNum;i++) begin
			io_outActive[i] = 0;
			io_outData[i] = '{default: 0};
		end
		for (i = 0;i < p_instanceNum;i++) begin
			io_outActive[w_instanceToPortDelayed[i]] = w_instanceOutActive[i];
			io_outData[w_instanceToPortDelayed[i]] = w_instanceOutData[i];
		end
	end

	// Transpose unit instances
	generate
	for (instanceId = 0;instanceId < p_instanceNum;instanceId++) begin
		Transpose #(
			.p_rowSize(p_rowSize),
			.p_clusterNum(p_clusterNum),
			.p_dataWidth(p_dataWidth)
		) m_transpose(
			.clock, .reset,
			.io_inActive(w_instanceInActive[instanceId]),
			.io_inData(w_instanceInData[instanceId]),
			.io_outActive(w_instanceOutActive[instanceId]),
			.io_outData(w_instanceOutData[instanceId]),
			.io_networkInData(io_networkInData[instanceId]),
			.io_networkOutData(io_networkOutData[instanceId])
		);
	end
	endgenerate

endmodule: TransposeAlloc
