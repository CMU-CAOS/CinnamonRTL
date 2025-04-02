`default_nettype none

`define TestClock(clock) \
	initial begin \
		clock = 0; \
		forever #1 clock = ~clock; \
	end \

`define TestReset(reset) \
	reset = 1; \
	#2 reset = 0; \
	@(negedge clock);

`define TestCheck(A, B) \
	if (A !== B) $error("\033[91mERROR\033[0m: %d = %d", A, B);

`define TestCheckArray(A, B, n) \
	for (integer temp = 0;temp < n;temp++) `TestCheck(A[temp], B[temp])

`define TestWait(n) \
	for (integer temp = 0;temp < n;temp++) @(negedge clock);

`define TestFinish(name) \
	$display("\033[92m* %s passed\033[0m", name); \
	$finish;
