module pipereg1(out, in, stall,bubble, bubbleval, clock);

 parameter width = 8;
 output reg [width-1:0] out;
 input [width-1:0] in;
 input stall,bubble;
 input [width-1:0] bubbleval;
 input clock;

 initial begin 
     out <= bubbleval;
 end
 always @(posedge clock) begin
    if (!stall && !bubble)
        out <= in;
    else if (!stall && bubble)
        out <= bubbleval;
    end
 endmodule