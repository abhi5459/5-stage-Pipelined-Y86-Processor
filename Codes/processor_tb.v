`timescale 1ns / 1ps
module processor_tb;

	
    reg clock = 0;
	wire [2:0] W_stat;

	
	processor uut (
		
		.clock(clock),
		.W_stat(W_stat)
	
		);
		
		

	initial begin
		// Initialize Inputs
		$dumpfile("processor_tb.vcd");
		$dumpvars(0,processor_tb);
	end

	always #10 clock = ~clock;

	always @(posedge clock)
	begin
		if(W_stat == 2'h2)
			$finish;
	end
      
endmodule