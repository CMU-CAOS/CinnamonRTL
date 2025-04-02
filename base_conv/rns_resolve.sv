`default_nettype none

/*
 * Large CRB unit
 */
`define RNSResolveDelay(p_blockNum, p_dataWidth) (1)
module RNSResolve
	#(parameter
		p_rowSize = 0,
		p_blockNum = 0,
		p_dataWidth = 0
	)
	(
		input logic  clock, reset,
		input logic  io_inActive,
		input logic  io_inIsAccumulate,
		input logic  [p_dataWidth-1:0] io_inData[0:p_rowSize-1],
		input logic  [p_dataWidth*p_blockNum-1:0] io_inF,
		input logic  [p_dataWidth*p_blockNum-1:0] io_inQ,
		input logic  [p_dataWidth-1:0] io_inSum[0:p_blockNum-1][0:p_rowSize-1],
		output logic io_outActive,
		output logic [p_dataWidth-1:0] io_outData[0:p_blockNum-1][0:p_rowSize-1]
	);

	// Large data width
	localparam p_dataWidthLarge = p_dataWidth *  p_blockNum;
	localparam p_multDelay = `RNSResolveDelay(p_blockNum,p_dataWidth);

	// Multiply inData and F
	logic [p_dataWidthLarge-1:0] w_multData[0:p_rowSize-1], w_multSum[0:p_rowSize-1];
	logic [p_dataWidthLarge-1:0] w_multQ;
	logic w_multIsAccumulate;
	genvar blockId, i;
	generate
	for (i = 0;i < p_rowSize;i++) begin
        logic [p_dataWidthLarge + p_dataWidth - 1:0] product;
        CW_mult_n_stage #(
            .wA(p_dataWidthLarge),
            .wB(p_dataWidth),
            .stages(p_multDelay )
        ) m_mult (
            .A(io_inF),
            .B(io_inData[i]),
            .CLK(clock),
            .TC(1'b0),
            //.Z({{(p_dataWidth){1'bZ}}, w_multData[i]})
            .Z(product)
        );
        //assign w_multData[i] = product[p_dataWidthLarge - 1:0];
		//MultiplierPipelinedWrapper #(
		//	.p_dataWidth_A(p_dataWidthLarge),
		//	.p_dataWidth_B(p_dataWidth),
		//	.p_dataWidth_R(p_dataWidthLarge)
		//) m_mult(
		//	.clock,
		//	.io_A(io_inF),
		//	.io_B(io_inData[i]),
		//	.io_result(w_multData[i])
		//);
		for (blockId = 0;blockId < p_blockNum;blockId++) begin
			SignalDelay #(
				.p_delay(p_multDelay),
				.p_width(p_dataWidth)
			) m_multDelay(
				.clock,
				.io_inData(io_inSum[blockId][i]),
				.io_outData(w_multSum[i][(blockId+1)*p_dataWidth-1:blockId*p_dataWidth])
			);
		end
	end
	endgenerate
	SignalDelay #(
		.p_delay(p_multDelay),
		.p_width(1 + p_dataWidthLarge)
	) m_multAccDelay(
		.clock,
		.io_inData({io_inIsAccumulate, io_inQ}),
		.io_outData({w_multIsAccumulate, w_multQ})
	);

	// Select accumulate data or not
	logic [p_dataWidthLarge:0] w_selData[0:p_rowSize-1];
	generate
	for (i = 0;i < p_rowSize;i++) begin
		always_comb begin
			if (w_multIsAccumulate) begin
				w_selData[i] = w_multData[i] + w_multSum[i];
			end else begin
				w_selData[i] = w_multData[i];
			end
			if (w_selData[i] >= w_multQ) w_selData[i] -= w_multQ;
		end
	end
	endgenerate

	// Assign selection to output
	generate
	for (blockId = 0;blockId < p_blockNum;blockId++) begin
		for (i = 0;i < p_rowSize;i++) begin
			assign io_outData[blockId][i] =
				w_selData[i][(blockId+1)*p_dataWidth-1:blockId*p_dataWidth];
		end
	end
	endgenerate

	// Delay active signal
	SignalDelayInit #(
		.p_delay(p_multDelay),
		.p_width(1),
		.p_initValue(0)
	) m_activeDelay(
		.clock, .reset,
		.io_inData(io_inActive),
		.io_outData(io_outActive)
	);

endmodule: RNSResolve

/*
 * RNS Resolve factor memory
 */
module RNSResolveFactorMem
	#(parameter
		p_primeNum = 0,
		p_primeAddrWidth = 0,
		p_rowSize = 0,
		p_blockNum = 0,
		p_dataWidth = 0
	)
	(
		input logic  clock, reset,
		input logic  [p_primeAddrWidth-1:0] io_primeId,
		output logic [p_dataWidth*p_blockNum-1:0] io_F, io_Q
	);

	localparam p_dataWidthLarge = p_dataWidth * p_blockNum;

	// Factor memory
	logic [p_dataWidthLarge-1:0] r_memF[0:p_primeNum-1];
	logic [p_dataWidthLarge-1:0] r_memQ[0:p_primeNum-1];

	logic [p_primeAddrWidth-1:0] r_addr;
	always_ff @(posedge clock) begin
		r_addr <= io_primeId;
	end
	assign io_F = r_memF[r_addr];
	assign io_Q = r_memQ[r_addr];

endmodule: RNSResolveFactorMem
