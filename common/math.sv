`default_nettype none

/*
 * Max of two integers
 */
function automatic integer MathMax
	(
		input integer A, B
	);

	return A > B ? A : B;

endfunction: MathMax

/*
 * Reverse a binary number
 */
function automatic integer MathBinaryReverse
	(
		input integer x, len
	);

	integer ret = 0, i;
	for (i = 0;i < len;i++) begin
		if (x & (1 << i)) begin
			ret |= (1 << (len - 1 - i));
		end
	end
	return ret;

endfunction: MathBinaryReverse

/*
 * Compute power of a integer
 */
function automatic longint MathPower
	(
		input longint b, pt, modulus
	);

	longint a = 1;
	while (pt) begin
		if (pt & 1) a = a * b % modulus;
		b = b * b % modulus;
		pt >>= 1;
	end
	return a;

endfunction: MathPower
