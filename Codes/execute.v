module preg2(out, in, stall, bubbleval, clock);

 input stall,clock;
 parameter width = 8;
 output reg [width-1:0] out;
 input [width-1:0] in,bubbleval;

 initial begin 
     out <= bubbleval;
 end
 always @(posedge clock) begin
    if (!stall) begin
        out <= in;
    end
    end

 endmodule



module alu(aluA, aluB, alufun, valE, new_cc);

parameter ALUADD = 4'b0000;
parameter ALUSUB = 4'b0001;
parameter ALUAND = 4'b0010;
parameter ALUXOR = 4'b0011;
input [63:0] aluA, aluB;
input [ 3:0] alufun;
reg g= 1'b1;
output [63:0] valE; 
output [ 2:0] new_cc; 




assign valE =
    alufun == ALUSUB ? aluB - aluA :
    alufun == ALUXOR ? aluB ^ aluA :
    alufun == ALUAND ? aluB & aluA :
    aluB + aluA;
reg k = 3'b100;
//preg2 #(3) c(cc, new_cc, ~set_cc, k, clock);

assign new_cc[2] = (valE == 0) ? 1 : 0; 
assign new_cc[1] = valE[63]; 
reg gg= 3'b100;
//preg2 #(3) c(cc, new_cc, ~set_cc, gg, clock);
assign new_cc[0] = 
    alufun == ALUADD ?
        (aluA[63] == aluB[63]) & (aluA[63] != valE[63]) :
    alufun == ALUSUB ?
        (~aluA[63] == aluB[63]) & (aluB[63] != valE[63]) :
    0;
endmodule

module cc(cc, new_cc, set_cc, reset, clock);
input set_cc,reset,clock;
input [2:0] new_cc;
output[2:0] cc;

preg2 #(3) c(cc, new_cc, ~set_cc, 3'b100, clock);
endmodule

module cond(ifun, cc, Cnd);

parameter C_YES = 4'b0000;
parameter C_LE = 4'b0001;
parameter C_L = 4'b0010;
parameter C_E = 4'b0011;
parameter C_NE = 4'b0100;
parameter C_GE = 4'b0101;
parameter C_G = 4'b0110;

wire of = cc[0];
wire sf = cc[1];
wire zf = cc[2];




input [3:0] ifun;
input [2:0] cc;
output Cnd;

assign Cnd =
(ifun == C_YES) ? 1'b1:
(ifun == C_LE & ((sf^of)|zf))  ? 1'b1: 
(ifun == C_L & (sf^of)) ?1'b1:
(ifun == C_E & zf) ?1'b1:
(ifun == C_NE & ~zf) ?1'b1:
(ifun == C_GE & (~sf^of)) ?1'b1: 
(ifun == C_G & (~sf^of)&~zf) ?1'b1: 1'b0; 

endmodule
