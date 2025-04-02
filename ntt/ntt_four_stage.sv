`default_nettype none


/*
 * Multiplication of twiddle factors
 */
module NTTMultiplyTwiddleUnit
	#(parameter
		p_primeNum = 0,
		p_primeAddrWidth = 0,
		p_rowSize = 0,
		p_colSize = 0,
		p_dataWidth = 0
	)
	(
		input logic  clock, reset,
		input logic  io_inActive,
		input logic  [p_dataWidth-1:0] io_inData[p_rowSize-1:0],
		input logic  [p_dataWidth-1:0] io_inMod,
		input logic  [p_primeAddrWidth-1:0] io_inPrimeId,
		input logic  io_inIsInverse,
		output logic io_outActive,
		output logic [p_dataWidth-1:0] io_outData[p_rowSize-1:0],
		output logic [p_dataWidth-1:0] io_outMod,
		output logic [p_primeAddrWidth-1:0] io_outPrimeId,
		output logic io_outIsInverse
	);

	// Derived param
	localparam p_addrWidth = $clog2(p_colSize);
	localparam p_counterWidth = $clog2(p_colSize);

	// Twiddle factor memory
	logic [p_dataWidth-1:0] r_mem[p_colSize-1:0][p_primeNum-1:0][1:0][p_rowSize-1:0];
	logic [p_addrWidth-1:0] r_memAddr;
	logic [p_primeAddrWidth-1:0] r_memPrimeId;
	logic r_memIsInverse;
	logic [p_dataWidth-1:0] w_memData[p_rowSize-1:0];
	// Counter
	logic [p_counterWidth-1:0] r_counter;

	// Multiplication modules for each element
	genvar i;
	generate
		for (i = 0;i < p_rowSize;i++) begin
			MontgomeryMultiplierWrapper #(
				.p_dataWidth(p_dataWidth)
			) m_multiplier(
				.clock,
				.io_A(io_inData[i]),
				.io_B(w_memData[i]),
				.io_q(io_inMod),
				.io_result(io_outData[i])
			);
		end
	endgenerate

	// Memory data
	always_ff @(posedge clock) begin
		{r_memAddr, r_memPrimeId, r_memIsInverse} <=
			{r_counter, io_inPrimeId, io_inIsInverse};
	end
	assign w_memData = r_mem[r_memAddr][r_memPrimeId][r_memIsInverse];
	// Counter
	always_ff @(posedge clock) begin
		if (reset) begin
			r_counter <= 0;
		end else if (io_inActive) begin
			// Increment counter when active
			if (r_counter == p_colSize - 1) begin
				r_counter <= 0;
			end else begin
				r_counter <= r_counter + 1;
			end
		end
	end

	// Delay PrimeId and IsInverse
	localparam p_multDelay = `MontgomeryMultiplierDelay;
	SignalDelay #(
		.p_width(p_primeAddrWidth + 1 + p_dataWidth),
		.p_delay(p_multDelay)
	) m_primeIdDelay (
		.clock, .reset,
		.io_inData({io_inPrimeId, io_inIsInverse, io_inMod}),
		.io_outData({io_outPrimeId, io_outIsInverse, io_outMod})
	);
	// Delay active
	SignalDelayInit #(
		.p_width(1),
		.p_delay(p_multDelay),
		.p_initValue(0)
	) m_activeDelay(
		.clock, .reset,
		.io_inData(io_inActive),
		.io_outData(io_outActive)
	);

endmodule: NTTMultiplyTwiddleUnit
`define NTTMultiplyTwiddleUnitDelay(p_dataWidth) \
	( `MontgomeryMultiplierDelay )


/*
 * Four stage NTT
 * DIT -> MultiplyTwiddle -> Transpose -> DIF
 */
module NTTFourStage
	#(parameter
		p_primeNum = 0,
		p_primeAddrWidth = 0,
		p_rowSize = 0,
		p_clusterNum = 0,
		p_dataWidth = 0
	)
	(
		input logic  clock, reset,
		// Transpose port
		output logic io_transposeInActive,
		output logic [p_dataWidth-1:0] io_transposeInData[p_rowSize-1:0],
		input logic  io_transposeOutActive,
		input logic  [p_dataWidth-1:0] io_transposeOutData[p_rowSize-1:0],
		// TwiddleFactorMem port
		output logic [p_primeAddrWidth-1:0] io_twiddleFactorMemPrimeId[2*$clog2(p_rowSize)-1:0],
		output logic io_twiddleFactorMemIsInverse[2*$clog2(p_rowSize)-1:0],
		input logic  [p_dataWidth-1:0] io_twiddleFactorMemData[2*$clog2(p_rowSize)-1:0][p_rowSize-1:0],
		// Prime info
		input logic  io_inActive,
		input logic  [p_dataWidth-1:0] io_inData[p_rowSize-1:0],
		input logic  [p_dataWidth-1:0] io_inMod,
		input logic  [p_primeAddrWidth-1:0] io_inPrimeId,
		input logic  io_inIsInverse,
		output logic io_outActive,
		output logic [p_dataWidth-1:0] io_outData[p_rowSize-1:0]
	);

	// Column size
	if (p_rowSize % p_clusterNum != 0) $error("row size not multiples of cluster num");
	localparam p_colSize = p_rowSize / p_clusterNum;

	// Data between layers
	logic [p_dataWidth-1:0]
		w_data0[p_rowSize-1:0],
		w_data1[p_rowSize-1:0],
		w_data2[p_rowSize-1:0],
		w_data3[p_rowSize-1:0];
	logic [p_dataWidth-1:0] w_mod0, w_mod1, w_mod2, w_mod3;
	logic [p_primeAddrWidth-1:0] w_primeId1, w_primeId2, w_primeId3;
	logic w_isInverse1, w_isInverse2, w_isInverse3;
	logic w_active0, w_active1, w_active2, w_active3;

	// Add one cycle delay for data/mod before NTT units
	// Active/PrimeId/IsInverse are one cycle ahead
	always_ff @(posedge clock) begin
		w_data0 <= io_inData;
		w_mod0 <= io_inMod;
	end

	// NTT Unit read ports
	localparam p_nttUnitReadPortNum = `NTTUnitTwiddleFactorMemReadPortNum(p_rowSize);

	// NTT DIT
	NTTUnit #(
		.p_primeNum(p_primeNum),
		.p_primeAddrWidth(p_primeAddrWidth),
		.p_size(p_rowSize),
		.p_dataWidth(p_dataWidth),
		.p_type(NTT_TYPE_DIT)
	) m_nttdit(
		.clock, .reset,
		.io_twiddleFactorMemPrimeId(io_twiddleFactorMemPrimeId[p_nttUnitReadPortNum-1:0]),
		.io_twiddleFactorMemIsInverse(io_twiddleFactorMemIsInverse[p_nttUnitReadPortNum-1:0]),
		.io_twiddleFactorMemData(io_twiddleFactorMemData[p_nttUnitReadPortNum-1:0]),
		.io_inActive(io_inActive),
		.io_inData(w_data0),
		.io_inMod(w_mod0),
		.io_inPrimeId(io_inPrimeId),
		.io_inIsInverse(io_inIsInverse),
		.io_outActive(w_active1),
		.io_outData(w_data1),
		.io_outMod(w_mod1),
		.io_outPrimeId(w_primeId1),
		.io_outIsInverse(w_isInverse1)
	);

	// Multiply twiddle
	NTTMultiplyTwiddleUnit #(
		.p_primeNum(p_primeNum),
		.p_primeAddrWidth(p_primeAddrWidth),
		.p_rowSize(p_rowSize),
		.p_colSize(p_colSize),
		.p_dataWidth(p_dataWidth)
	) m_multiply(
		.clock, .reset,
		.io_inActive(w_active1),
		.io_inData(w_data1),
		.io_inMod(w_mod1),
		.io_inPrimeId(w_primeId1),
		.io_inIsInverse(w_isInverse1),
		.io_outActive(w_active0),
		.io_outData(w_data2),
		.io_outMod(w_mod2),
		.io_outPrimeId(w_primeId2),
		.io_outIsInverse(w_isInverse2)
	);
	// Delay active to synchronize with data
	SignalDelayInit #(
		.p_width(1),
		.p_delay(1),
		.p_initValue(0)
	) m_activeDelay(
		.clock, .reset,
		.io_inData(w_active0),
		.io_outData(w_active2)
	);

	// Transpose
	// Use transpose port
	assign io_transposeInActive = w_active2;
	assign io_transposeInData = w_data2;
	assign w_active3 = io_transposeOutActive;
	assign w_data3 = io_transposeOutData;
	// Pass PrimeId and IsInverse with transpose
	SignalDelay #(
		.p_width(p_primeAddrWidth + 1 + p_dataWidth),
		.p_delay(`TransposeDelay(p_colSize))
	) m_transposeDelay(
		.clock, .reset,
		.io_inData({w_primeId2, w_isInverse2, w_mod2}),
		.io_outData({w_primeId3, w_isInverse3, w_mod3})
	);

	// NTT DIF
	NTTUnit #(
		.p_primeNum(p_primeNum),
		.p_primeAddrWidth(p_primeAddrWidth),
		.p_size(p_rowSize),
		.p_dataWidth(p_dataWidth),
		.p_type(NTT_TYPE_DIF)
	) m_nttdif(
		.clock, .reset,
		.io_twiddleFactorMemPrimeId(io_twiddleFactorMemPrimeId[2*p_nttUnitReadPortNum-1:p_nttUnitReadPortNum]),
		.io_twiddleFactorMemIsInverse(io_twiddleFactorMemIsInverse[2*p_nttUnitReadPortNum-1:p_nttUnitReadPortNum]),
		.io_twiddleFactorMemData(io_twiddleFactorMemData[2*p_nttUnitReadPortNum-1:p_nttUnitReadPortNum]),
		.io_inActive(w_active3),
		.io_inData(w_data3),
		.io_inMod(w_mod3), 
		.io_inPrimeId(w_primeId3),
		.io_inIsInverse(w_isInverse3),
		.io_outActive(io_outActive),
		.io_outData(io_outData),
		.io_outMod(), 
		.io_outPrimeId(),
		.io_outIsInverse()
	);

endmodule: NTTFourStage
`define NTTFourStageDelay(p_rowSize, p_clusterNum, p_dataWidth) \
	( \
		1 + \
		2 * `NTTUnitDelay(p_rowSize, p_dataWidth) + \
		`NTTMultiplyTwiddleUnitDelay(p_dataWidth) + \
		`TransposeDelay(p_rowSize / p_clusterNum) \
	)

// Twiddle factor memory ports required by NTTFourStage
`define NTTFourStageTwiddleFactorMemReadPortNum(p_rowSize) \
	( 2 * `NTTUnitTwiddleFactorMemReadPortNum(p_rowSize) )
