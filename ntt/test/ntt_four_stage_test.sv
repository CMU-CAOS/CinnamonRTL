`default_nettype none


/*
 * NTT (four stage) test
 */
module NTTFourStageTest
	#(parameter
		p_primeNum = 5,
		p_primeAddrWidth = 3,
		p_rowSize = 4,
		p_clusterNum = 1,
		p_dataWidth = 28
	);

	logic clock, reset;
	logic io_inActive, io_outActive;
	logic [p_dataWidth-1:0] io_inData[p_rowSize-1:0], io_outData[p_rowSize-1:0];
	logic [p_dataWidth-1:0] io_inMod;
	logic [p_primeAddrWidth-1:0] io_inPrimeId;
	logic io_inIsInverse;
	logic io_transposeRestart;
	logic io_transposeInActive, io_transposeOutActive;
	logic [p_dataWidth-1:0] io_transposeInData[p_rowSize-1:0],
		io_transposeOutData[p_rowSize-1:0],
		io_transposeNetworkData[p_rowSize-1:0];

	localparam p_readPortNum = `NTTFourStageTwiddleFactorMemReadPortNum(p_rowSize);
	logic [p_primeAddrWidth-1:0] io_twiddleFactorMemPrimeId[p_readPortNum-1:0];
	logic io_twiddleFactorMemIsInverse[p_readPortNum-1:0];
	logic [p_dataWidth-1:0] io_twiddleFactorMemData[p_readPortNum-1:0][p_rowSize-1:0];

	NTTFourStage #(
		.p_primeNum(p_primeNum),
		.p_primeAddrWidth(p_primeAddrWidth),
		.p_rowSize(p_rowSize),
		.p_clusterNum(p_clusterNum),
		.p_dataWidth(p_dataWidth)
	) dut(.*);
	Transpose #(
		.p_rowSize(p_rowSize),
		.p_clusterNum(1),
		.p_dataWidth(p_dataWidth)
	) m_transpose(
		.clock, .reset,
		.io_inActive(io_transposeInActive),
		.io_inData(io_transposeInData),
		.io_outActive(io_transposeOutActive),
		.io_outData(io_transposeOutData),
		.io_networkInData(io_transposeNetworkData),
		.io_networkOutData(io_transposeNetworkData)
	);
	NTTTwiddleFactorMem #(
		.p_size(p_rowSize),
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
	logic [p_dataWidth-1:0] mod2, mod3, mod4;
	logic [p_dataWidth-1:0] inp[12:0][p_rowSize-1:0], ans[15:0][p_rowSize-1:0];
	logic [p_dataWidth-1:0] t[p_rowSize-1:0];
	integer i, iter;
	initial begin
		`TestReset(reset)

		// Set value
		mod2 = 6946817;  // Inverse NTT
		mod3 = 5767169;  // Not inverse NTT
		mod4 = 786433;   // Not inverse NTT
		// PrimeId 2
		t = '{1, 4288696, 6626758, 6658417};
		`TestMontgomeryAssign(m_twiddleFactorMem.r_mem[2][1], t, mod2, p_rowSize)
		t = '{6512641,4717708,4626047,4200265};
		`TestMontgomeryAssign(dut.m_multiply.r_mem[0][2][1], t, mod2, p_rowSize)
		t = '{6512641,4200265,2828098,1344714};
		`TestMontgomeryAssign(dut.m_multiply.r_mem[1][2][1], t, mod2, p_rowSize)
		t = '{6512641,2511758,1864522,1735192};
		`TestMontgomeryAssign(dut.m_multiply.r_mem[2][2][1], t, mod2, p_rowSize)
		t = '{6512641, 531263,5090501,4435059};
		`TestMontgomeryAssign(dut.m_multiply.r_mem[3][2][1], t, mod2, p_rowSize)
		// PrimeId 3
		t = '{1, 5392703, 1838090, 3643041};
		`TestMontgomeryAssign(m_twiddleFactorMem.r_mem[3][0], t, mod3, p_rowSize)
		t = '{      1,      1,      1,      1};
		`TestMontgomeryAssign(dut.m_multiply.r_mem[0][3][0], t, mod3, p_rowSize)
		t = '{2253851,1864395,  11570,3639563};
		`TestMontgomeryAssign(dut.m_multiply.r_mem[1][3][0], t, mod3, p_rowSize)
		t = '{ 764452,3685021,1220013,4438615};
		`TestMontgomeryAssign(dut.m_multiply.r_mem[2][3][0], t, mod3, p_rowSize)
		t = '{1864395,4339468,3287867,5755599};
		`TestMontgomeryAssign(dut.m_multiply.r_mem[3][3][0], t, mod3, p_rowSize)
		// PrimeId 4
		t = '{1, 388249, 100025, 544685};
		`TestMontgomeryAssign(m_twiddleFactorMem.r_mem[4][0], t, mod4, p_rowSize)
		t = '{     1,     1,     1,     1};
		`TestMontgomeryAssign(dut.m_multiply.r_mem[0][4][0], t, mod4, p_rowSize)
		t = '{ 41596,462518,203749,399061};
		`TestMontgomeryAssign(dut.m_multiply.r_mem[1][4][0], t, mod4, p_rowSize)
		t = '{ 74616,541396,216230,144953};
		`TestMontgomeryAssign(dut.m_multiply.r_mem[2][4][0], t, mod4, p_rowSize)
		t = '{462518,409330,669610,582684};
		`TestMontgomeryAssign(dut.m_multiply.r_mem[3][4][0], t, mod4, p_rowSize)

		// PrimeId 3 (NTT)
		// [[ 16   0   8  -8]
		//  [ 14  -2   6 -10]
		//  [ 12  -4   4 -12]
		//  [ 10  -6   2 -14]]
		t = '{16,  0,  8, mod3-8};
		`TestMontgomeryAssign(inp[0], t, mod3, p_rowSize)
		t = '{14, mod3-2,  6,mod3-10};
		`TestMontgomeryAssign(inp[1], t, mod3, p_rowSize)
		t = '{12, mod3-4,  4,mod3-12};
		`TestMontgomeryAssign(inp[2], t, mod3, p_rowSize)
		t = '{10, mod3-6,  2,mod3-14};
		`TestMontgomeryAssign(inp[3], t, mod3, p_rowSize)
		// [[3174788 2497340 4450828 5496109]
		//  [ 428676 2458570 4908974 5420688]
		//  [5420688 4908974 2458570  428676]
		//  [5496109 4450828 2497340 3174788]]
		t = '{ 3174788,2497340,4450828,5496109};
		`TestMontgomeryAssign(ans[0], t, mod3, p_rowSize)
		t = '{  428676,2458570,4908974,5420688};
		`TestMontgomeryAssign(ans[1], t, mod3, p_rowSize)
		t = '{ 5420688,4908974,2458570, 428676};
		`TestMontgomeryAssign(ans[2], t, mod3, p_rowSize)
		t = '{ 5496109,4450828,2497340,3174788};
		`TestMontgomeryAssign(ans[3], t, mod3, p_rowSize)
		// PrimeId 2 (INTT)
		// [[ 602025 2993513    8543 6318128]
		//  [4397038 1878776 6020024 5584663]
		//  [4800638   54946 3329824 5701673]
		//  [ 654727 2159778 6418447 4642833]]
		t = '{ 602025,2993513,   8543,6318128};
		`TestMontgomeryAssign(inp[4], t, mod2, p_rowSize)
		t = '{4397038,1878776,6020024,5584663};
		`TestMontgomeryAssign(inp[5], t, mod2, p_rowSize)
		t = '{4800638,  54946,3329824,5701673};
		`TestMontgomeryAssign(inp[6], t, mod2, p_rowSize)
		t = '{ 654727,2159778,6418447,4642833};
		`TestMontgomeryAssign(inp[7], t, mod2, p_rowSize)
		// [[6946257    1024     360    1176]
		//  [6946497    1120     560    1104]
		//  [6946733    1180     740     980]
		//  [    144    1200     896     800]]
		t = '{6946257,   1024,    360,   1176};
		`TestMontgomeryAssign(ans[4], t, mod2, p_rowSize)
		t = '{6946497,   1120,    560,   1104};
		`TestMontgomeryAssign(ans[5], t, mod2, p_rowSize)
		t = '{6946733,   1180,    740,    980};
		`TestMontgomeryAssign(ans[6], t, mod2, p_rowSize)
		t = '{    144,   1200,    896,    800};
		`TestMontgomeryAssign(ans[7], t, mod2, p_rowSize)
		// PrimeId 4 (NTT)
		// [[ 0  8  4 12]
		//  [ 1  9  5 13]
		//  [ 2 10  6 14]
		//  [ 3 11  7 15]]
		t = '{0, 8, 4,12};
		`TestMontgomeryAssign(inp[8], t, mod4, p_rowSize)
		t = '{1, 9, 5,13};
		`TestMontgomeryAssign(inp[9], t, mod4, p_rowSize)
		t = '{2,10, 6,14};
		`TestMontgomeryAssign(inp[10], t, mod4, p_rowSize)
		t = '{3,11, 7,15};
		`TestMontgomeryAssign(inp[11], t, mod4, p_rowSize)
		// [[266859 446720 233079   7954]
		//  [629702 142266  98362 473225]
		//  [ 15294 558225 506536 434768]
		//  [229730 586154 771768 104389]]
		t = '{266859,446720,233079,  7954};
		`TestMontgomeryAssign(ans[8], t, mod4, p_rowSize)
		t = '{629702,142266, 98362,473225};
		`TestMontgomeryAssign(ans[9], t, mod4, p_rowSize)
		t = '{ 15294,558225,506536,434768};
		`TestMontgomeryAssign(ans[10], t, mod4, p_rowSize)
		t = '{229730,586154,771768,104389};
		`TestMontgomeryAssign(ans[11], t, mod4, p_rowSize)

		io_inActive = 0;
		@(negedge clock);

		io_inActive = 1;
		for (iter = 0;iter < 4;iter++) begin
			io_inData = inp[iter];
			io_inMod = mod3;
			io_inPrimeId = 3;
			io_inIsInverse = 0;
			@(negedge clock);
		end
		for (iter = 4;iter < 8;iter++) begin
			io_inData = inp[iter];
			io_inMod = mod2;
			io_inPrimeId = 2;
			io_inIsInverse = 1;
			@(negedge clock);
		end
		for (iter = 8;iter < 12;iter++) begin
			io_inData = inp[iter];
			io_inMod = mod4;
			io_inPrimeId = 4;
			io_inIsInverse = 0;
			@(negedge clock);
		end
		io_inActive = 0;
		io_inData = '{default: '0};
		io_inPrimeId = 1;
		io_inIsInverse = 0;

		// Wait for ans
		for (i = 0;i < `NTTFourStageDelay(p_rowSize, p_clusterNum, p_dataWidth) - 12;i++) begin
			`TestCheck(io_outActive, 0)
			@(negedge clock);
		end

		for (iter = 0;iter < 12;iter++) begin
			`TestCheck(io_outActive, 1)
			`TestCheckArray(io_outData, ans[iter], p_rowSize)
			@(negedge clock);
		end
		`TestCheck(io_outActive, 0)

		`TestFinish("NTTFourStageTest")
	end

endmodule: NTTFourStageTest


/*
 * NTT (four stage) test
 * 8x8 matrix
 */
module NTTFourStage8x8Test
	#(parameter
		p_primeNum = 16,
		p_primeAddrWidth = 4,
		p_rowSize = 8,
		p_clusterNum = 1,
		p_dataWidth = 28
	);

	logic clock, reset;
	logic io_inActive, io_outActive;
	logic [p_dataWidth-1:0] io_inData[p_rowSize-1:0], io_outData[p_rowSize-1:0];
	logic [p_dataWidth-1:0] io_inMod;
	logic [p_primeAddrWidth-1:0] io_inPrimeId;
	logic io_inIsInverse;
	logic io_transposeInActive, io_transposeOutActive;
	logic [p_dataWidth-1:0] io_transposeInData[p_rowSize-1:0],
		io_transposeOutData[p_rowSize-1:0],
		io_transposeNetworkData[p_rowSize-1:0];

	localparam p_readPortNum = `NTTFourStageTwiddleFactorMemReadPortNum(p_rowSize);
	logic [p_primeAddrWidth-1:0] io_twiddleFactorMemPrimeId[p_readPortNum-1:0];
	logic io_twiddleFactorMemIsInverse[p_readPortNum-1:0];
	logic [p_dataWidth-1:0] io_twiddleFactorMemData[p_readPortNum-1:0][p_rowSize-1:0];

	NTTFourStage #(
		.p_primeNum(p_primeNum),
		.p_primeAddrWidth(p_primeAddrWidth),
		.p_rowSize(p_rowSize),
		.p_clusterNum(p_clusterNum),
		.p_dataWidth(p_dataWidth)
	) dut(.*);
	Transpose #(
		.p_rowSize(p_rowSize),
		.p_clusterNum(1),
		.p_dataWidth(p_dataWidth)
	) m_transpose(
		.clock, .reset,
		.io_inActive(io_transposeInActive),
		.io_inData(io_transposeInData),
		.io_outActive(io_transposeOutActive),
		.io_outData(io_transposeOutData),
		.io_networkInData(io_transposeNetworkData),
		.io_networkOutData(io_transposeNetworkData)
	);
	NTTTwiddleFactorMem #(
		.p_size(p_rowSize),
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
	logic [p_dataWidth-1:0] mod4, mod9;
	logic [p_dataWidth-1:0] inp[15:0][p_rowSize-1:0], ans[15:0][p_rowSize-1:0];
	logic [p_dataWidth-1:0] t[p_rowSize-1:0];
	integer i, iter;
	initial begin
		`TestReset(reset)

		// Add some cycles before
		io_inActive = 0;
		for (i = 0;i < 3;i++) begin
			@(negedge clock);
		end

		// Set value
		// 4 is not inverse, 9 is inverse
		mod4 = 786433;
		mod9 = 786433;
		// g = 541396
		t = '{1, 541396, 544685, 711817, 686408, 641480, 388249, 216230};
		`TestMontgomeryAssign(m_twiddleFactorMem.r_mem[4][0], t, mod4, p_rowSize)
		t = '{     1,     1,     1,     1,     1,     1,     1,     1};
		`TestMontgomeryAssign(dut.m_multiply.r_mem[0][4][0], t, mod4, p_rowSize)
		t = '{320990,392262,741786,284518,669865,710432, 97476,634717};
		`TestMontgomeryAssign(dut.m_multiply.r_mem[1][4][0], t, mod4, p_rowSize)
		t = '{ 60605,714462,533387,584335,109250,588049,673503,423612};
		`TestMontgomeryAssign(dut.m_multiply.r_mem[2][4][0], t, mod4, p_rowSize)
		t = '{392262,669865,634717,316464,442002,675341,524454,159434};
		`TestMontgomeryAssign(dut.m_multiply.r_mem[3][4][0], t, mod4, p_rowSize)
		t = '{323915,377103,116823,203749,655292,744837,387372,417470};
		`TestMontgomeryAssign(dut.m_multiply.r_mem[4][4][0], t, mod4, p_rowSize)
		t = '{741786,634717,613608,708686,159434,663369,465443, 76001};
		`TestMontgomeryAssign(dut.m_multiply.r_mem[5][4][0], t, mod4, p_rowSize)
		t = '{714462,109250,423612,366478, 82144,725828,202098,112930};
		`TestMontgomeryAssign(dut.m_multiply.r_mem[6][4][0], t, mod4, p_rowSize)
		t = '{284518,316464,708686,368299,246416,688957,344431,727891};
		`TestMontgomeryAssign(dut.m_multiply.r_mem[7][4][0], t, mod4, p_rowSize)

		t = '{1, 570203, 398184, 144953, 100025, 74616, 241748, 245037};
		`TestMontgomeryAssign(m_twiddleFactorMem.r_mem[9][1], t, mod9, p_rowSize)
		t = '{774145,192758,325006,512492,755334,288032,671371,635276};
		`TestMontgomeryAssign(dut.m_multiply.r_mem[0][9][1], t, mod9, p_rowSize)
		t = '{774145,512492,671371,100227,534620,522630,706789,277333};
		`TestMontgomeryAssign(dut.m_multiply.r_mem[1][9][1], t, mod9, p_rowSize)
		t = '{774145,288032,391933,522630, 49802,458750, 88978,736494};
		`TestMontgomeryAssign(dut.m_multiply.r_mem[2][9][1], t, mod9, p_rowSize)
		t = '{774145,635276,261872,277333,727042,736494,199708,346435};
		`TestMontgomeryAssign(dut.m_multiply.r_mem[3][9][1], t, mod9, p_rowSize)
		t = '{774145,100227,706789,  5263,451473,154688,126834,363625};
		`TestMontgomeryAssign(dut.m_multiply.r_mem[4][9][1], t, mod9, p_rowSize)
		t = '{774145,128870,166306,427522,280799,493342,461427,384358};
		`TestMontgomeryAssign(dut.m_multiply.r_mem[5][9][1], t, mod9, p_rowSize)
		t = '{774145,402075,112286,481933,178428,593675,524561,781170};
		`TestMontgomeryAssign(dut.m_multiply.r_mem[6][9][1], t, mod9, p_rowSize)
		t = '{774145,522630, 88978,154688,130107,657563,674147,242209};
		`TestMontgomeryAssign(dut.m_multiply.r_mem[7][9][1], t, mod9, p_rowSize)

		// PrimeId 4
		// [[ 0 32 16 48  8 40 24 56]
		//  [ 1 33 17 49  9 41 25 57]
		//  [ 2 34 18 50 10 42 26 58]
		//  [ 3 35 19 51 11 43 27 59]
		//  [ 4 36 20 52 12 44 28 60]
		//  [ 5 37 21 53 13 45 29 61]
		//  [ 6 38 22 54 14 46 30 62]
		//  [ 7 39 23 55 15 47 31 63]]
		t = '{ 0,32,16,48, 8,40,24,56};
		`TestMontgomeryAssign(inp[0], t, mod4, p_rowSize)
		t = '{ 1,33,17,49, 9,41,25,57};
		`TestMontgomeryAssign(inp[1], t, mod4, p_rowSize)
		t = '{ 2,34,18,50,10,42,26,58};
		`TestMontgomeryAssign(inp[2], t, mod4, p_rowSize)
		t = '{ 3,35,19,51,11,43,27,59};
		`TestMontgomeryAssign(inp[3], t, mod4, p_rowSize)
		t = '{ 4,36,20,52,12,44,28,60};
		`TestMontgomeryAssign(inp[4], t, mod4, p_rowSize)
		t = '{ 5,37,21,53,13,45,29,61};
		`TestMontgomeryAssign(inp[5], t, mod4, p_rowSize)
		t = '{ 6,38,22,54,14,46,30,62};
		`TestMontgomeryAssign(inp[6], t, mod4, p_rowSize)
		t = '{ 7,39,23,55,15,47,31,63};
		`TestMontgomeryAssign(inp[7], t, mod4, p_rowSize)
		// [[486400 323764 642525  37134 497691 681060 519177 512974]
		//  [514900 573483 459830 151917 384136 555962 134984 294883]
		//  [168041 518193  70810 126747 100411 431723 328000 478092]
		//  [443156 644726 122927 606761 455973 762668 192495 442567]
		//  [704328 490645  50232 328587 149779 357486  53407 719464]
		//  [ 33912   1111 700250 120783 427162 343019 237300 116531]
		//  [ 62790 398530 190381  76000 518422 490199 535607 558586]
		//  [648237 100800 657339  44881 463853 401519 121442  39865]]
		t = '{486400,323764,642525, 37134,497691,681060,519177,512974};
		`TestMontgomeryAssign(ans[0], t, mod4, p_rowSize)
		t = '{514900,573483,459830,151917,384136,555962,134984,294883};
		`TestMontgomeryAssign(ans[1], t, mod4, p_rowSize)
		t = '{168041,518193, 70810,126747,100411,431723,328000,478092};
		`TestMontgomeryAssign(ans[2], t, mod4, p_rowSize)
		t = '{443156,644726,122927,606761,455973,762668,192495,442567};
		`TestMontgomeryAssign(ans[3], t, mod4, p_rowSize)
		t = '{704328,490645, 50232,328587,149779,357486, 53407,719464};
		`TestMontgomeryAssign(ans[4], t, mod4, p_rowSize)
		t = '{ 33912,  1111,700250,120783,427162,343019,237300,116531};
		`TestMontgomeryAssign(ans[5], t, mod4, p_rowSize)
		t = '{ 62790,398530,190381, 76000,518422,490199,535607,558586};
		`TestMontgomeryAssign(ans[6], t, mod4, p_rowSize)
		t = '{648237,100800,657339, 44881,463853,401519,121442, 39865};
		`TestMontgomeryAssign(ans[7], t, mod4, p_rowSize)

		// PrimeId 9
		// [[453450 757092  59252 225067 760697 421962 774350 627991]
		//  [124600 470367 231034 391232 151700 411010 163546 772656]
		//  [612541  16015 648198 390231 264892 229034 289621  46213]
		//  [164430 575311 673849 699781  55442 680194 523681 147229]
		//  [149732  36126 436975 248722 329238 389369 658148 705063]
		//  [385628 120128 591161  92756 315067 666274 168485 440666]
		//  [752339 604390 429914 125613 115000 252121 193314  38032]
		//  [508626 376481 339153 450565 139263 420576 469656 310977]]
		t = '{453450,757092, 59252,225067,760697,421962,774350,627991};
		`TestMontgomeryAssign(inp[8], t, mod9, p_rowSize)
		t = '{124600,470367,231034,391232,151700,411010,163546,772656};
		`TestMontgomeryAssign(inp[9], t, mod9, p_rowSize)
		t = '{612541, 16015,648198,390231,264892,229034,289621, 46213};
		`TestMontgomeryAssign(inp[10], t, mod9, p_rowSize)
		t = '{164430,575311,673849,699781, 55442,680194,523681,147229};
		`TestMontgomeryAssign(inp[11], t, mod9, p_rowSize)
		t = '{149732, 36126,436975,248722,329238,389369,658148,705063};
		`TestMontgomeryAssign(inp[12], t, mod9, p_rowSize)
		t = '{385628,120128,591161, 92756,315067,666274,168485,440666};
		`TestMontgomeryAssign(inp[13], t, mod9, p_rowSize)
		t = '{752339,604390,429914,125613,115000,252121,193314, 38032};
		`TestMontgomeryAssign(inp[14], t, mod9, p_rowSize)
		t = '{508626,376481,339153,450565,139263,420576,469656,310977};
		`TestMontgomeryAssign(inp[15], t, mod9, p_rowSize)
		// [[744769  65536  20128  78176 776689  76976  45904  67088]
		//  [748801  67456  23616  77504 780577  77728  48736  64736]
		//  [752829  69244  27036  76636 784429  78316  51468  62156]
		//  [756849  70896  30384  75568   1808  78736  54096  59344]
		//  [760857  72408  33656  74296   5576  78984  56616  56296]
		//  [764849  73776  36848  72816   9296  79056  59024  53008]
		//  [768821  74996  39956  71124  12964  78948  61316  49476]
		//  [772769  76064  42976  69216  16576  78656  63488  45696]]
		t = '{744769, 65536, 20128, 78176,776689, 76976, 45904, 67088};
		`TestMontgomeryAssign(ans[8], t, mod9, p_rowSize)
		t = '{748801, 67456, 23616, 77504,780577, 77728, 48736, 64736};
		`TestMontgomeryAssign(ans[9], t, mod9, p_rowSize)
		t = '{752829, 69244, 27036, 76636,784429, 78316, 51468, 62156};
		`TestMontgomeryAssign(ans[10], t, mod9, p_rowSize)
		t = '{756849, 70896, 30384, 75568,  1808, 78736, 54096, 59344};
		`TestMontgomeryAssign(ans[11], t, mod9, p_rowSize)
		t = '{760857, 72408, 33656, 74296,  5576, 78984, 56616, 56296};
		`TestMontgomeryAssign(ans[12], t, mod9, p_rowSize)
		t = '{764849, 73776, 36848, 72816,  9296, 79056, 59024, 53008};
		`TestMontgomeryAssign(ans[13], t, mod9, p_rowSize)
		t = '{768821, 74996, 39956, 71124, 12964, 78948, 61316, 49476};
		`TestMontgomeryAssign(ans[14], t, mod9, p_rowSize)
		t = '{772769, 76064, 42976, 69216, 16576, 78656, 63488, 45696};
		`TestMontgomeryAssign(ans[15], t, mod9, p_rowSize)

		io_inActive = 1;
		for (iter = 0;iter < 8;iter++) begin
			io_inData = inp[iter];
			io_inMod = mod4;
			io_inPrimeId = 4;
			io_inIsInverse = 0;
			@(negedge clock);
		end
		for (iter = 8;iter < 16;iter++) begin
			io_inData = inp[iter];
			io_inMod = mod9;
			io_inPrimeId = 9;
			io_inIsInverse = 1;
			@(negedge clock);
		end
		io_inActive = 0;
		io_inData = '{default: '0};
		io_inPrimeId = 0;
		io_inIsInverse = 0;

		// Wait for ans
		for (i = 0;i < `NTTFourStageDelay(p_rowSize, p_clusterNum, p_dataWidth) - 16;i++) begin
			`TestCheck(io_outActive, 0)
			@(negedge clock);
		end

		for (iter = 0;iter < 16;iter++) begin
			`TestCheck(io_outActive, 1)
			`TestCheckArray(io_outData, ans[iter], p_rowSize)
			@(negedge clock);
		end
		`TestCheck(io_outActive, 0)

		`TestFinish("NTTFourStage8x8Test")
	end

endmodule: NTTFourStage8x8Test


/*
 * NTT bubble test
 * 8x8 matrix
 */
module NTTBubbleTest
	#(parameter
		p_primeNum = 16,
		p_primeAddrWidth = 4,
		p_rowSize = 8,
		p_clusterNum = 1,
		p_dataWidth = 28,
		p_pause1 = 23,
		p_pause2 = 3,
		p_pause3 = 8
	);

	logic clock, reset;
	logic io_inActive, io_outActive;
	logic [p_dataWidth-1:0] io_inData[p_rowSize-1:0], io_outData[p_rowSize-1:0];
	logic [p_dataWidth-1:0] io_inMod;
	logic [p_primeAddrWidth-1:0] io_inPrimeId;
	logic io_inIsInverse;
	logic io_transposeInActive, io_transposeOutActive;
	logic [p_dataWidth-1:0] io_transposeInData[p_rowSize-1:0],
		io_transposeOutData[p_rowSize-1:0],
		io_transposeNetworkData[p_rowSize-1:0];

	localparam p_readPortNum = `NTTFourStageTwiddleFactorMemReadPortNum(p_rowSize);
	logic [p_primeAddrWidth-1:0] io_twiddleFactorMemPrimeId[p_readPortNum-1:0];
	logic io_twiddleFactorMemIsInverse[p_readPortNum-1:0];
	logic [p_dataWidth-1:0] io_twiddleFactorMemData[p_readPortNum-1:0][p_rowSize-1:0];
	logic [p_dataWidth-1:0] mod4, mod9;
	logic [p_dataWidth-1:0] inp[15:0][p_rowSize-1:0], ans[15:0][p_rowSize-1:0];
	logic [p_dataWidth-1:0] t[p_rowSize-1:0];

	NTTFourStage #(
		.p_primeNum(p_primeNum),
		.p_primeAddrWidth(p_primeAddrWidth),
		.p_rowSize(p_rowSize),
		.p_clusterNum(p_clusterNum),
		.p_dataWidth(p_dataWidth)
	) dut(.*);
	Transpose #(
		.p_rowSize(p_rowSize),
		.p_clusterNum(1),
		.p_dataWidth(p_dataWidth)
	) m_transpose(
		.clock, .reset,
		.io_inActive(io_transposeInActive),
		.io_inData(io_transposeInData),
		.io_outActive(io_transposeOutActive),
		.io_outData(io_transposeOutData),
		.io_networkInData(io_transposeNetworkData),
		.io_networkOutData(io_transposeNetworkData)
	);
	NTTTwiddleFactorMem #(
		.p_size(p_rowSize),
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

	task enter();
		integer iter;
		io_inActive = 1;
		for (iter = 0;iter < 8;iter++) begin
			io_inData = inp[iter];
			io_inMod = mod4;
			io_inPrimeId = 4;
			io_inIsInverse = 0;
			@(negedge clock);
		end
		for (iter = 8;iter < 16;iter++) begin
			io_inData = inp[iter];
			io_inMod = mod9;
			io_inPrimeId = 9;
			io_inIsInverse = 1;
			@(negedge clock);
		end
		io_inActive = 0;
		io_inData = '{default: '0};
		io_inPrimeId = 0;
		io_inIsInverse = 0;
	endtask: enter

	task check();
		integer iter;
		for (iter = 0;iter < 16;iter++) begin
			`TestCheck(io_outActive, 1)
			`TestCheckArray(io_outData, ans[iter], p_rowSize)
			@(negedge clock);
		end
	endtask: check

	`TestClock(clock)
	integer i;
	initial begin
		`TestReset(reset)

		// Set value
		// 4 is not inverse, 9 is inverse
		mod4 = 786433;
		mod9 = 786433;
		// g = 541396
		t = '{1, 541396, 544685, 711817, 686408, 641480, 388249, 216230};
		`TestMontgomeryAssign(m_twiddleFactorMem.r_mem[4][0], t, mod4, p_rowSize)
		t = '{     1,     1,     1,     1,     1,     1,     1,     1};
		`TestMontgomeryAssign(dut.m_multiply.r_mem[0][4][0], t, mod4, p_rowSize)
		t = '{320990,392262,741786,284518,669865,710432, 97476,634717};
		`TestMontgomeryAssign(dut.m_multiply.r_mem[1][4][0], t, mod4, p_rowSize)
		t = '{ 60605,714462,533387,584335,109250,588049,673503,423612};
		`TestMontgomeryAssign(dut.m_multiply.r_mem[2][4][0], t, mod4, p_rowSize)
		t = '{392262,669865,634717,316464,442002,675341,524454,159434};
		`TestMontgomeryAssign(dut.m_multiply.r_mem[3][4][0], t, mod4, p_rowSize)
		t = '{323915,377103,116823,203749,655292,744837,387372,417470};
		`TestMontgomeryAssign(dut.m_multiply.r_mem[4][4][0], t, mod4, p_rowSize)
		t = '{741786,634717,613608,708686,159434,663369,465443, 76001};
		`TestMontgomeryAssign(dut.m_multiply.r_mem[5][4][0], t, mod4, p_rowSize)
		t = '{714462,109250,423612,366478, 82144,725828,202098,112930};
		`TestMontgomeryAssign(dut.m_multiply.r_mem[6][4][0], t, mod4, p_rowSize)
		t = '{284518,316464,708686,368299,246416,688957,344431,727891};
		`TestMontgomeryAssign(dut.m_multiply.r_mem[7][4][0], t, mod4, p_rowSize)

		t = '{1, 570203, 398184, 144953, 100025, 74616, 241748, 245037};
		`TestMontgomeryAssign(m_twiddleFactorMem.r_mem[9][1], t, mod9, p_rowSize)
		t = '{774145,192758,325006,512492,755334,288032,671371,635276};
		`TestMontgomeryAssign(dut.m_multiply.r_mem[0][9][1], t, mod9, p_rowSize)
		t = '{774145,512492,671371,100227,534620,522630,706789,277333};
		`TestMontgomeryAssign(dut.m_multiply.r_mem[1][9][1], t, mod9, p_rowSize)
		t = '{774145,288032,391933,522630, 49802,458750, 88978,736494};
		`TestMontgomeryAssign(dut.m_multiply.r_mem[2][9][1], t, mod9, p_rowSize)
		t = '{774145,635276,261872,277333,727042,736494,199708,346435};
		`TestMontgomeryAssign(dut.m_multiply.r_mem[3][9][1], t, mod9, p_rowSize)
		t = '{774145,100227,706789,  5263,451473,154688,126834,363625};
		`TestMontgomeryAssign(dut.m_multiply.r_mem[4][9][1], t, mod9, p_rowSize)
		t = '{774145,128870,166306,427522,280799,493342,461427,384358};
		`TestMontgomeryAssign(dut.m_multiply.r_mem[5][9][1], t, mod9, p_rowSize)
		t = '{774145,402075,112286,481933,178428,593675,524561,781170};
		`TestMontgomeryAssign(dut.m_multiply.r_mem[6][9][1], t, mod9, p_rowSize)
		t = '{774145,522630, 88978,154688,130107,657563,674147,242209};
		`TestMontgomeryAssign(dut.m_multiply.r_mem[7][9][1], t, mod9, p_rowSize)

		// PrimeId 4
		// [[ 0 32 16 48  8 40 24 56]
		//  [ 1 33 17 49  9 41 25 57]
		//  [ 2 34 18 50 10 42 26 58]
		//  [ 3 35 19 51 11 43 27 59]
		//  [ 4 36 20 52 12 44 28 60]
		//  [ 5 37 21 53 13 45 29 61]
		//  [ 6 38 22 54 14 46 30 62]
		//  [ 7 39 23 55 15 47 31 63]]
		t = '{ 0,32,16,48, 8,40,24,56};
		`TestMontgomeryAssign(inp[0], t, mod4, p_rowSize)
		t = '{ 1,33,17,49, 9,41,25,57};
		`TestMontgomeryAssign(inp[1], t, mod4, p_rowSize)
		t = '{ 2,34,18,50,10,42,26,58};
		`TestMontgomeryAssign(inp[2], t, mod4, p_rowSize)
		t = '{ 3,35,19,51,11,43,27,59};
		`TestMontgomeryAssign(inp[3], t, mod4, p_rowSize)
		t = '{ 4,36,20,52,12,44,28,60};
		`TestMontgomeryAssign(inp[4], t, mod4, p_rowSize)
		t = '{ 5,37,21,53,13,45,29,61};
		`TestMontgomeryAssign(inp[5], t, mod4, p_rowSize)
		t = '{ 6,38,22,54,14,46,30,62};
		`TestMontgomeryAssign(inp[6], t, mod4, p_rowSize)
		t = '{ 7,39,23,55,15,47,31,63};
		`TestMontgomeryAssign(inp[7], t, mod4, p_rowSize)
		// [[486400 323764 642525  37134 497691 681060 519177 512974]
		//  [514900 573483 459830 151917 384136 555962 134984 294883]
		//  [168041 518193  70810 126747 100411 431723 328000 478092]
		//  [443156 644726 122927 606761 455973 762668 192495 442567]
		//  [704328 490645  50232 328587 149779 357486  53407 719464]
		//  [ 33912   1111 700250 120783 427162 343019 237300 116531]
		//  [ 62790 398530 190381  76000 518422 490199 535607 558586]
		//  [648237 100800 657339  44881 463853 401519 121442  39865]]
		t = '{486400,323764,642525, 37134,497691,681060,519177,512974};
		`TestMontgomeryAssign(ans[0], t, mod4, p_rowSize)
		t = '{514900,573483,459830,151917,384136,555962,134984,294883};
		`TestMontgomeryAssign(ans[1], t, mod4, p_rowSize)
		t = '{168041,518193, 70810,126747,100411,431723,328000,478092};
		`TestMontgomeryAssign(ans[2], t, mod4, p_rowSize)
		t = '{443156,644726,122927,606761,455973,762668,192495,442567};
		`TestMontgomeryAssign(ans[3], t, mod4, p_rowSize)
		t = '{704328,490645, 50232,328587,149779,357486, 53407,719464};
		`TestMontgomeryAssign(ans[4], t, mod4, p_rowSize)
		t = '{ 33912,  1111,700250,120783,427162,343019,237300,116531};
		`TestMontgomeryAssign(ans[5], t, mod4, p_rowSize)
		t = '{ 62790,398530,190381, 76000,518422,490199,535607,558586};
		`TestMontgomeryAssign(ans[6], t, mod4, p_rowSize)
		t = '{648237,100800,657339, 44881,463853,401519,121442, 39865};
		`TestMontgomeryAssign(ans[7], t, mod4, p_rowSize)

		// PrimeId 9
		// [[453450 757092  59252 225067 760697 421962 774350 627991]
		//  [124600 470367 231034 391232 151700 411010 163546 772656]
		//  [612541  16015 648198 390231 264892 229034 289621  46213]
		//  [164430 575311 673849 699781  55442 680194 523681 147229]
		//  [149732  36126 436975 248722 329238 389369 658148 705063]
		//  [385628 120128 591161  92756 315067 666274 168485 440666]
		//  [752339 604390 429914 125613 115000 252121 193314  38032]
		//  [508626 376481 339153 450565 139263 420576 469656 310977]]
		t = '{453450,757092, 59252,225067,760697,421962,774350,627991};
		`TestMontgomeryAssign(inp[8], t, mod9, p_rowSize)
		t = '{124600,470367,231034,391232,151700,411010,163546,772656};
		`TestMontgomeryAssign(inp[9], t, mod9, p_rowSize)
		t = '{612541, 16015,648198,390231,264892,229034,289621, 46213};
		`TestMontgomeryAssign(inp[10], t, mod9, p_rowSize)
		t = '{164430,575311,673849,699781, 55442,680194,523681,147229};
		`TestMontgomeryAssign(inp[11], t, mod9, p_rowSize)
		t = '{149732, 36126,436975,248722,329238,389369,658148,705063};
		`TestMontgomeryAssign(inp[12], t, mod9, p_rowSize)
		t = '{385628,120128,591161, 92756,315067,666274,168485,440666};
		`TestMontgomeryAssign(inp[13], t, mod9, p_rowSize)
		t = '{752339,604390,429914,125613,115000,252121,193314, 38032};
		`TestMontgomeryAssign(inp[14], t, mod9, p_rowSize)
		t = '{508626,376481,339153,450565,139263,420576,469656,310977};
		`TestMontgomeryAssign(inp[15], t, mod9, p_rowSize)
		// [[744769  65536  20128  78176 776689  76976  45904  67088]
		//  [748801  67456  23616  77504 780577  77728  48736  64736]
		//  [752829  69244  27036  76636 784429  78316  51468  62156]
		//  [756849  70896  30384  75568   1808  78736  54096  59344]
		//  [760857  72408  33656  74296   5576  78984  56616  56296]
		//  [764849  73776  36848  72816   9296  79056  59024  53008]
		//  [768821  74996  39956  71124  12964  78948  61316  49476]
		//  [772769  76064  42976  69216  16576  78656  63488  45696]]
		t = '{744769, 65536, 20128, 78176,776689, 76976, 45904, 67088};
		`TestMontgomeryAssign(ans[8], t, mod9, p_rowSize)
		t = '{748801, 67456, 23616, 77504,780577, 77728, 48736, 64736};
		`TestMontgomeryAssign(ans[9], t, mod9, p_rowSize)
		t = '{752829, 69244, 27036, 76636,784429, 78316, 51468, 62156};
		`TestMontgomeryAssign(ans[10], t, mod9, p_rowSize)
		t = '{756849, 70896, 30384, 75568,  1808, 78736, 54096, 59344};
		`TestMontgomeryAssign(ans[11], t, mod9, p_rowSize)
		t = '{760857, 72408, 33656, 74296,  5576, 78984, 56616, 56296};
		`TestMontgomeryAssign(ans[12], t, mod9, p_rowSize)
		t = '{764849, 73776, 36848, 72816,  9296, 79056, 59024, 53008};
		`TestMontgomeryAssign(ans[13], t, mod9, p_rowSize)
		t = '{768821, 74996, 39956, 71124, 12964, 78948, 61316, 49476};
		`TestMontgomeryAssign(ans[14], t, mod9, p_rowSize)
		t = '{772769, 76064, 42976, 69216, 16576, 78656, 63488, 45696};
		`TestMontgomeryAssign(ans[15], t, mod9, p_rowSize)


		enter();
		io_inActive = 0;
		for (i = 0;i < p_pause1;i++) @(negedge clock);
		enter();
		io_inActive = 0;
		for (i = 0;i < p_pause2;i++) @(negedge clock);
		enter();
		io_inActive = 0;
		for (i = 0;i < p_pause3;i++) @(negedge clock);
		enter();
		io_inActive = 0;
	end

	integer j;
	initial begin
		@(negedge clock);
		for (j = 0;j < `NTTFourStageDelay(p_rowSize, p_clusterNum, p_dataWidth);j++) begin
			`TestCheck(io_outActive, 0)
			@(negedge clock);
		end
		check();
		for (j = 0;j < p_pause1;j++) begin
			`TestCheck(io_outActive, 0)
			@(negedge clock);
		end
		check();
		for (j = 0;j < p_pause2;j++) begin
			`TestCheck(io_outActive, 0)
			@(negedge clock);
		end
		check();
		for (j = 0;j < p_pause3;j++) begin
			`TestCheck(io_outActive, 0)
			@(negedge clock);
		end
		check();
		@(negedge clock);
		`TestCheck(io_outActive, 0)

		`TestFinish("NTTBubbleTest")
	end

endmodule: NTTBubbleTest
