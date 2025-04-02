`default_nettype none

/*
 * NTT DIT test
 */
module NTTUnitDIT4Test
	#(parameter
		p_primeNum = 4,
		p_primeAddrWidth = 3,
		p_size = 4,
		p_dataWidth = 28,
		NTTType_t p_type = NTT_TYPE_DIT
	);

	logic clock, reset;
	logic io_inActive, io_outActive;
	logic [p_dataWidth-1:0] io_inData[p_size-1:0], io_outData[p_size-1:0];
	logic [p_dataWidth-1:0] io_inMod, io_outMod;
	logic [p_primeAddrWidth-1:0] io_inPrimeId, io_outPrimeId;
	logic io_inIsInverse, io_outIsInverse;

	localparam p_readPortNum = `NTTUnitTwiddleFactorMemReadPortNum(p_size);
	logic [p_primeAddrWidth-1:0] io_twiddleFactorMemPrimeId[p_readPortNum-1:0];
	logic io_twiddleFactorMemIsInverse[p_readPortNum-1:0];
	logic [p_dataWidth-1:0] io_twiddleFactorMemData[p_readPortNum-1:0][p_size-1:0];

	NTTUnit #(
		.p_primeNum(p_primeNum),
		.p_primeAddrWidth(p_primeAddrWidth),
		.p_size(p_size),
		.p_dataWidth(p_dataWidth),
		.p_type(p_type)
	) dut(.*);
	NTTTwiddleFactorMem #(
		.p_size(p_size),
		.p_primeNum(p_primeNum),
		.p_primeAddrWidth(p_primeAddrWidth),
		.p_dataWidth(p_dataWidth),
		.p_readPortNum(p_readPortNum)
	) m_twiddleFactorMem(
		.clock, .reset,
		.io_primeId(io_twiddleFactorMemPrimeId),
		.io_isInverse(io_twiddleFactorMemIsInverse),
		.io_twiddleFactor(io_twiddleFactorMemData)
	);

	`TestClock(clock)
	integer i, delay;
	logic [p_dataWidth-1:0] in[p_size-1:0], ans[p_size-1:0];
	initial begin
		`TestReset(reset)

		// Set value
		io_inMod = 1179649;
		// g = 64
		m_twiddleFactorMem.r_mem[1][0][0] = ConvertToMontgomery(1, io_inMod);
		m_twiddleFactorMem.r_mem[1][0][1] = ConvertToMontgomery(683840, io_inMod);
		m_twiddleFactorMem.r_mem[1][0][2] = ConvertToMontgomery(689020, io_inMod);
		m_twiddleFactorMem.r_mem[1][0][3] = ConvertToMontgomery(494273, io_inMod);
		// PrimeId/IsInverse one cycle before first data
		io_inPrimeId = 1;
		io_inIsInverse = 0;
		@(negedge clock);
		in = '{0, 8, 4, 12};
		`TestMontgomeryAssign(io_inData, in, io_inMod, p_size)
		@(negedge clock);
		in = '{1, 9, 5, 13};
		`TestMontgomeryAssign(io_inData, in, io_inMod, p_size)
		@(negedge clock);
		in = '{2, 10, 6, 14};
		`TestMontgomeryAssign(io_inData, in, io_inMod, p_size)
		@(negedge clock);
		in = '{3, 11, 7, 15};
		`TestMontgomeryAssign(io_inData, in, io_inMod, p_size)
		io_inPrimeId = 2;
		io_inIsInverse = 1;
		@(negedge clock);
		io_inData = '{default: '0};

		// Wait for result
		delay = `NTTUnitDelay(p_size, p_dataWidth);
		for (i = 0;i < delay - 5;i++) begin
			@(negedge clock);
		end

		`TestCheck(io_outPrimeId, 1)
		@(negedge clock);
		ans = '{23008, 1132065, 384471, 819754};
		`TestMontgomeryCheck(io_outData, ans, io_inMod, p_size)
		`TestCheck(io_outPrimeId, 1)
		`TestCheck(io_outIsInverse, 0)
		@(negedge clock);
		ans = '{710493, 441510, 1075028, 132271};
		`TestMontgomeryCheck(io_outData, ans, io_inMod, p_size)
		`TestCheck(io_outPrimeId, 1)
		`TestCheck(io_outIsInverse, 0)
		@(negedge clock);
		ans = '{218329, 930604, 585936, 624437};
		`TestMontgomeryCheck(io_outData, ans, io_inMod, p_size)
		`TestCheck(io_outPrimeId, 1)
		`TestCheck(io_outIsInverse, 0)
		@(negedge clock);
		ans = '{905814, 240049,  96844,1116603};
		`TestMontgomeryCheck(io_outData, ans, io_inMod, p_size)
		`TestCheck(io_outPrimeId, 2)
		`TestCheck(io_outIsInverse, 1)
		@(negedge clock);
		`TestCheck(io_outPrimeId, 2)
		`TestCheck(io_outIsInverse, 1)

		`TestFinish("NTTUnitDIT4Test")
	end

endmodule: NTTUnitDIT4Test


/*
 * NTT DIF test
 */
module NTTUnitDIF4Test
	#(parameter
		p_primeNum = 16,
		p_primeAddrWidth = 4,
		p_size = 4,
		p_dataWidth = 28,
		NTTType_t p_type = NTT_TYPE_DIF
	);

	logic clock, reset;
	logic io_inActive, io_outActive;
	logic [p_dataWidth-1:0] io_inData[p_size-1:0], io_outData[p_size-1:0];
	logic [p_dataWidth-1:0] io_inMod, io_outMod;
	logic [p_primeAddrWidth-1:0] io_inPrimeId, io_outPrimeId;
	logic io_inIsInverse, io_outIsInverse;

	localparam p_readPortNum = `NTTUnitTwiddleFactorMemReadPortNum(p_size);
	logic [p_primeAddrWidth-1:0] io_twiddleFactorMemPrimeId[p_readPortNum-1:0];
	logic io_twiddleFactorMemIsInverse[p_readPortNum-1:0];
	logic [p_dataWidth-1:0] io_twiddleFactorMemData[p_readPortNum-1:0][p_size-1:0];

	NTTUnit #(
		.p_primeNum(p_primeNum),
		.p_primeAddrWidth(p_primeAddrWidth),
		.p_size(p_size),
		.p_dataWidth(p_dataWidth),
		.p_type(p_type)
	) dut(.*);
	NTTTwiddleFactorMem #(
		.p_size(p_size),
		.p_primeNum(p_primeNum),
		.p_primeAddrWidth(p_primeAddrWidth),
		.p_dataWidth(p_dataWidth),
		.p_readPortNum(p_readPortNum)
	) m_twiddleFactorMem(
		.clock, .reset,
		.io_primeId(io_twiddleFactorMemPrimeId),
		.io_isInverse(io_twiddleFactorMemIsInverse),
		.io_twiddleFactor(io_twiddleFactorMemData)
	);

	`TestClock(clock)
	integer i, delay;
	logic [p_dataWidth-1:0] in[p_size-1:0], ans[p_size-1:0];
	initial begin
		`TestReset(reset)

		// Set value
		io_inMod = 2752513;
		// g = 64
		m_twiddleFactorMem.r_mem[9][1][0] = ConvertToMontgomery(1, io_inMod);
		m_twiddleFactorMem.r_mem[9][1][1] = ConvertToMontgomery(13629, io_inMod);
		m_twiddleFactorMem.r_mem[9][1][2] = ConvertToMontgomery(1331270, io_inMod);
		m_twiddleFactorMem.r_mem[9][1][3] = ConvertToMontgomery(2065647, io_inMod);
		io_inPrimeId = 9;
		io_inIsInverse = 1;
		@(negedge clock);
		in = '{400282,1662337,  19381, 670193};
		`TestMontgomeryAssign(io_inData, in, io_inMod, p_size)
		@(negedge clock);
		in = '{752708,2477808,1016668,1257758};
		`TestMontgomeryAssign(io_inData, in, io_inMod, p_size)
		io_inPrimeId = 14;
		io_inIsInverse = 0;
		@(negedge clock);
		io_inData = '{default: '0};

		// Wait for result
		delay = `NTTUnitDelay(p_size, p_dataWidth);
		for (i = 0;i < delay - 3;i++) begin
			@(negedge clock);
		end

		`TestCheck(io_outPrimeId, 9);
		@(negedge clock);
		ans = '{2752193,   1120,    560,   1104};
		`TestMontgomeryCheck(io_outData, ans, io_inMod, p_size)
		`TestCheck(io_outPrimeId, 9);
		@(negedge clock);
		ans = '{2752429,   1180,    740,    980};
		`TestMontgomeryCheck(io_outData, ans, io_inMod, p_size)
		`TestCheck(io_outPrimeId, 14);
		@(negedge clock);
		`TestCheck(io_outPrimeId, 14);

		`TestFinish("NTTUnitDIF4Test")
	end

endmodule: NTTUnitDIF4Test
