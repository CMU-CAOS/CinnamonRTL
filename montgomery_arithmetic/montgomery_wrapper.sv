`default_nettype none

`define MontgomeryMultiplierDataWidth 28
`define MontgomeryMultiplierOneIterationReductionFactorLog2 17
`define MontgomeryMultiplierNumIterations 2
`define MontgomeryMultiplierExt \
	(`MontgomeryMultiplierOneIterationReductionFactorLog2 * `MontgomeryMultiplierNumIterations)

`define MontgomeryMultiplierDelay \
	( ComputeMontgomeryMultiplierPipelineStages( \
		`MontgomeryMultiplierDataWidth, \
		2, 1, 1, 1, \
		`MontgomeryMultiplierOneIterationReductionFactorLog2, \
		`MontgomeryMultiplierNumIterations, \
		1, 1, 0 \
	) )

// Wrapper with pre-defined parameters
module MontgomeryMultiplierWrapper
	#(parameter
		p_dataWidth = 0
	)
	(
		input logic  clock,
		input logic  [p_dataWidth-1:0] io_A, io_B, io_q,
		output logic [p_dataWidth-1:0] io_result
	);

	if (p_dataWidth != `MontgomeryMultiplierDataWidth) $error("Montgomery wrapper incompatiable dataWidth");

	NTTFriendlyMontgomeryMultiplier #(
		.p_dataWidth(p_dataWidth),
		.p_oneIterationReductionFactorLog2(`MontgomeryMultiplierOneIterationReductionFactorLog2),
		.p_numIterations(`MontgomeryMultiplierNumIterations),
		.p_adderTreeStageDepth(2),
		.p_pipelineRegAfterShiftMultiply(1),
		.p_firstAdderTreeStageDepth(1),
		.p_pipelineRegAfterMultiply(1),
		.p_pipelineRegBetweenIterations(1),
		.p_pipelineRegAfterIterations(1),
		.p_pipelineRegBeforeReduction(0)
	) m_multiplier(.*);

endmodule: MontgomeryMultiplierWrapper


function automatic longint ConvertToMontgomery
	(
		input longint x,
		input longint q
	);

	return x * MathPower(2, `MontgomeryMultiplierExt, q) % q;

endfunction: ConvertToMontgomery


function automatic longint ConvertFromMontgomery
	(
		input longint y,
		input longint q
	);

	return y * MathPower((q + 1) / 2, `MontgomeryMultiplierExt, q) % q;

endfunction: ConvertFromMontgomery


function automatic longint MontgomeryR2(input longint q);

	longint R = ConvertToMontgomery(1, q);
	return R * R % q;

endfunction: MontgomeryR2


`define TestMontgomeryAssign(port, in, q, n) \
	for (integer temp = 0;temp < n;temp++) begin \
		port[temp] = ConvertToMontgomery(in[n - 1 - temp], q); \
	end

`define TestMontgomeryCheck(port, out, q, n) \
	for (integer temp = 0;temp < n;temp++) begin \
		`TestCheck(port[temp], ConvertToMontgomery(out[n - 1 - temp], q)) \
	end
