`default_nettype none


/*
 * Acutal signal delay
 * p_delay has to be positive
 */
module SignalDelayActual
	#(parameter
		p_width = 0,
		p_delay = 0
	)
	(
		input logic  clock, reset,
		input logic  [p_width-1:0] io_inData,
		output logic [p_width-1:0] io_outData
	);

	// Validate delay
	if (p_delay <= 0) $error("Signal delay at least 1");

	logic [p_delay-1:0][p_width-1:0] r_data;
	always_ff @(posedge clock) begin
		r_data[0] <= io_inData;
	end
	genvar i;
	generate
		for (i = 1;i < p_delay;i++) begin
			always_ff @(posedge clock) begin
				r_data[i] <= r_data[i - 1];
			end
		end
	endgenerate
	assign io_outData = r_data[p_delay - 1];

endmodule: SignalDelayActual


/*
 * Acutal signal delay
 * p_delay has to be positive
 * Initialize to p_initValue
 */
module SignalDelayInitActual
	#(parameter
		p_width = 0,
		p_delay = 0,
		p_initValue = 9
	)
	(
		input logic  clock, reset,
		input logic  [p_width-1:0] io_inData,
		output logic [p_width-1:0] io_outData
	);

	// Validate delay
	if (p_delay <= 0) $error("Signal delay at least 1");

	logic [p_delay-1:0][p_width-1:0] r_data;
	always_ff @(posedge clock) begin
		if (reset) begin
			r_data[0] <= p_initValue;
		end else begin
			r_data[0] <= io_inData;
		end
	end
	genvar i;
	generate
		for (i = 1;i < p_delay;i++) begin
			always_ff @(posedge clock) begin
				if (reset) begin
					r_data[i] <= p_initValue;
				end else begin
					r_data[i] <= r_data[i - 1];
				end
			end
		end
	endgenerate
	assign io_outData = r_data[p_delay - 1];

endmodule: SignalDelayInitActual



/*
 * Delay a signal for some time
 * Used in NTTMultiplyTwiddleUnit to delay primeId for some
 * cycles to output at the same time as data
 */
module SignalDelay
	#(parameter
		p_width = 0,
		p_delay = 0
	)
	(
		input logic  clock, reset,
		input logic  [p_width-1:0] io_inData,
		output logic [p_width-1:0] io_outData
	);

	if (p_delay >= 1) begin
		// Delay value
		SignalDelayActual #(
			.p_width(p_width),
			.p_delay(p_delay)
		) m_delay(
			.clock, .reset, .io_inData, .io_outData
		);
	end else begin
		// No delay
		assign io_outData = io_inData;
	end

endmodule: SignalDelay


module SignalDelayInit
	#(parameter
		p_width = 0,
		p_delay = 0,
		p_initValue = 0
	)
	(
		input logic  clock, reset,
		input logic  [p_width-1:0] io_inData,
		output logic [p_width-1:0] io_outData
	);

	if (p_delay >= 1) begin
		// Delay value
		SignalDelayInitActual #(
			.p_width(p_width),
			.p_delay(p_delay),
			.p_initValue(p_initValue)
		) m_delay(
			.clock, .reset, .io_inData, .io_outData
		);
	end else begin
		// No delay
		assign io_outData = io_inData;
	end

endmodule: SignalDelayInit
