`include "fetch.v"
`include "decode.v"
`include "execute.v"
`include "memory.v"
`include "preg1.v"
module processor(clock,W_stat);

    
    parameter IHALT = 4'h0,INOP = 4'h1,IRRMOVQ = 4'h2,IIRMOVQ = 4'h3,IRMMOVQ = 4'h4,IMRMOVQ = 4'h5,IOPQ = 4'h6;
    parameter IJXX = 4'h7,ICALL = 4'h8,IRET = 4'h9,IPUSHQ = 4'hA,IPOPQ = 4'hB,IIADDQ = 4'hC,ILEAVE = 4'hD,IPOP2 = 4'hE;

    parameter FNONE = 4'h0,UNCOND = 4'h0,RRSP = 4'h4,RRBP = 4'h5,RNONE = 4'hF;
    
    parameter ALUADD = 4'h0;
    
    parameter SBUB = 3'h0,SAOK = 3'h1,SHLT = 3'h2,SADR = 3'h3,SINS = 3'h4;

    input clock;
    output [2:0] W_stat;    
    wire [63:0] f_predPC, F_predPC, f_pc;
    wire f_ok,imem_error;
    wire [ 2:0] f_stat;
    wire [7:0] f_ibyte;
    wire[71:0] f_ibytes;
    wire [ 3:0] f_icode,f_ifun,f_rA,f_rB;
    wire [63:0] f_valC,f_valP;
    wire need_regids,need_valC,instr_valid,F_stall, F_bubble, F_reset;
    
    wire [ 2:0] D_stat;
    wire [63:0] D_pc;
    wire [ 3:0] D_icode,D_ifun,D_rA,D_rB;
    wire [63:0] D_valC,D_valP,d_valA,d_valB,d_rvalA,d_rvalB;
    wire [ 3:0] d_dstE,d_dstM,d_srcA,d_srcB;
    wire D_stall , D_bubble, D_reset;

    
    wire [ 2:0] M_stat;
    wire [63:0] M_pc;
    wire [ 3:0] M_icode,M_ifun;
    wire M_Cnd;
    wire [63:0] M_valE,M_valA;
    wire [ 3:0] M_dstE,M_dstM;
    wire [ 2:0] m_stat;
    wire [63:0] mem_addr,mem_data;
    wire mem_read,mem_write,dmem_error;
    wire [63:0] m_valM;
    wire M_stall, M_bubble,M_reset,m_ok;

   
    wire [ 2:0] W_stat;
    wire [63:0] W_pc;
    wire [ 3:0] W_icode;
    wire [63:0] W_valE,W_valM;
    wire [ 3:0] W_dstE,W_dstM;
    wire [63:0] w_valE,w_valM;
    wire [ 3:0] w_dstE,w_dstM;
    wire W_stall;
    wire W_bubble;
    wire resetting;

    assign resetting = 1;
    assign D_reset = 1; 
  
    wire [ 2:0] E_stat;
    wire [63:0] E_pc;
    wire [ 3:0] E_icode,E_ifun;
    wire [63:0] E_valC,E_valB,E_valA;
    wire [ 3:0] E_dstE,E_dstM,E_srcA,E_srcB;
    wire [63:0] aluA,aluB;
    wire set_cc;
    wire [ 2:0] cc,new_cc;
    wire [ 3:0] alufun;
    wire e_Cnd;
    wire [63:0] e_valE,e_valA;
    wire [ 3:0] e_dstE;
    wire E_stall, E_bubble;

    output [63:0] rax;
    
    
    assign f_pc =(((M_icode == IJXX) & ~M_Cnd) ? M_valA : (W_icode == IRET) ? W_valM :F_predPC);
    assign imem_error = 1'b0;
    
    output [63:0] rcx;
    
    
    assign dmem_error = 1'b0;
    assign instr_valid = 
    f_icode == INOP |
    f_icode == IHALT |
    f_icode == IRRMOVQ |
    f_icode == IIRMOVQ |
    f_icode == IRMMOVQ |
    f_icode == IMRMOVQ |
    f_icode == IOPQ |
    f_icode == IJXX |
    f_icode == ICALL |
    f_icode == IRET |
    f_icode == IPUSHQ |
    f_icode == IPOPQ ;

    output [63:0] rdx;
    
    assign need_regids =
    f_icode == IRRMOVQ |
    f_icode == IOPQ |
    f_icode == IPUSHQ |
    f_icode ==IPOPQ |
    f_icode == IIRMOVQ |
    f_icode == IRMMOVQ |
    f_icode == IMRMOVQ ;

    output [63:0] rbx;
    
    assign f_stat =(imem_error ? SADR : ~instr_valid ? SINS : (f_icode == IHALT) ? SHLT :SAOK);
    reg k = 1'b0;

    assign need_valC =(f_icode == IIRMOVQ | f_icode == IRMMOVQ | f_icode == IMRMOVQ | f_icode== IJXX | f_icode == ICALL);
    assign f_predPC =((f_icode == IJXX | f_icode == ICALL) ? f_valC : f_valP);
    
    reg g = 1'b1;
    
    output [63:0] rsp;
    
    assign d_srcB =
    D_icode == IOPQ ? D_rB:
    D_icode == IRMMOVQ ? D_rB:
    D_icode == IMRMOVQ ? D_rB :
    D_icode == IPUSHQ ? RRSP:
    D_icode == IPOPQ ? RRSP:
    D_icode == ICALL ? RRSP:  
    D_icode== IRET ? RRSP : RNONE;
    

    assign d_srcA =
    D_icode == IRRMOVQ ? D_rA: 
    D_icode == IRMMOVQ ? D_rA:
    D_icode == IOPQ ? D_rA:
    D_icode== IPUSHQ ? D_rA :
    D_icode == IPOPQ ? RRSP:
    D_icode == IRET ? RRSP :RNONE;

    output [63:0] rbp;
    


    assign d_dstE =
    D_icode == IRRMOVQ ? D_rB:
    D_icode == IIRMOVQ ? D_rB :
    D_icode == IOPQ ? D_rB :
    D_icode == IPUSHQ ? RRSP:
    D_icode == IPOPQ ? RRSP:
    D_icode == ICALL ? RRSP: 
    D_icode== IRET ? RRSP : RNONE;
    
    assign d_dstM =((D_icode == IMRMOVQ | D_icode == IPOPQ) ? D_rA : RNONE);
    
    output [63:0] rsi;
    
    
    assign d_valA =
    D_icode == ICALL ? D_valP: 
    D_icode == IJXX ? D_valP :
    d_srcA == e_dstE ? e_valE : 
    d_srcA == M_dstM ? m_valM : 
    d_srcA == M_dstE ? M_valE :
    d_srcA == W_dstM ? W_valM : 
    d_srcA == W_dstE ? W_valE : d_rvalA;

    output [63:0] rdi;
    output [63:0] r8;
    

    assign d_valB =
    d_srcB == e_dstE ? e_valE : 
    d_srcB == M_dstM ? m_valM : 
    d_srcB== M_dstE ? M_valE : 
    d_srcB == W_dstM ? W_valM : 
    d_srcB ==W_dstE ? W_valE : d_rvalB;

    assign set_cc =(((E_icode == IOPQ) & ~(m_stat == SADR | m_stat == SINS | m_stat ==SHLT)) & ~(W_stat == SADR | W_stat == SINS | W_stat == SHLT));

    output [63:0] r9;
    

    assign aluB =
    E_icode == IRMMOVQ ? E_valB:
    E_icode == IMRMOVQ ? E_valB:
    E_icode == IOPQ ? E_valB:
    E_icode== ICALL ? E_valB:
    E_icode == IPUSHQ ? E_valB:
    E_icode == IRET ? E_valB:
    E_icode == IPOPQ ? E_valB : 
    E_icode == IRRMOVQ ? 0:
    E_icode == IIRMOVQ ? 0 : 0;
    assign e_valA =E_valA;
    
    output [63:0] r10;
    output [63:0] r11;
    
    
    assign alufun =((E_icode == IOPQ) ? E_ifun : ALUADD);
    assign aluA =
    E_icode == IRRMOVQ ? E_valA: 
    E_icode == IOPQ ? E_valA : 
    E_icode == IIRMOVQ ? E_valC:
    E_icode == IRMMOVQ ? E_valC: 
    E_icode == IMRMOVQ ? E_valC : 
    E_icode ==ICALL ? -8:
    E_icode == IPUSHQ ? -8 : 
    E_icode == IRET ? 8:
    E_icode == IPOPQ ? 8 : 0;

    
   output [63:0] r12;
    output [63:0] r13;
    
    
    
    assign e_dstE =(((E_icode == IRRMOVQ) & ~e_Cnd) ? RNONE : E_dstE);

    assign mem_addr =
    M_icode == IRMMOVQ ? M_valE :
    M_icode == IPUSHQ ? M_valE :
    M_icode == ICALL ? M_valE :
    M_icode == IMRMOVQ ? M_valE : 
    M_icode == IPOPQ ? M_valA : 
    M_icode == IRET ? M_valA : 0;
    
    output [63:0] r14;
    assign mem_write =(M_icode == IRMMOVQ | M_icode == IPUSHQ | M_icode == ICALL);
    assign mem_read =(M_icode == IMRMOVQ | M_icode == IPOPQ | M_icode == IRET);
    reg a1 = 1'b0;
    assign m_stat =(dmem_error ? SADR : M_stat);
    reg b1 = 1'b0;
    assign Stat =((W_stat == SBUB) ? SAOK : W_stat);
    assign F_bubble =0;
    reg c1 = 1'b0;
    assign F_stall =
    (((E_icode == IMRMOVQ | E_icode == IPOPQ) & (E_dstM == d_srcA | E_dstM == d_srcB)) ? 1'b1 :
     (IRET == D_icode | IRET == E_icode | IRET == M_icode)) ? 1'b1 : 1'b0;
    
    assign D_stall =((E_icode == IMRMOVQ | E_icode == IPOPQ) & (E_dstM == d_srcA | E_dstM == d_srcB));
    reg d1 = 1'b1;
    assign D_bubble =(((E_icode == IJXX) & ~e_Cnd) | (~((E_icode == IMRMOVQ | E_icode ==IPOPQ) & (E_dstM == d_srcA | E_dstM == d_srcB)) & (IRET ==D_icode | IRET == E_icode | IRET == M_icode)));
    assign E_stall =0;
    reg e1 = 1'b1;
    assign E_bubble =(((E_icode == IJXX) & ~e_Cnd) | ((E_icode == IMRMOVQ | E_icode == IPOPQ) & (E_dstM == d_srcA | E_dstM == d_srcB)));
    reg f1 = 1'b0;
    assign M_stall =0;
     reg g1 = 1'b0;
    assign W_stall =(W_stat == SADR | W_stat == SINS | W_stat == SHLT);
    
    assign W_bubble =0;

    assign w_dstE =W_dstE;
    assign w_valE =W_valE;
    assign w_dstM =W_dstM;
    assign w_valM =W_valM;
    assign M_bubble =((m_stat == SADR | m_stat == SINS | m_stat == SHLT) | (W_stat == SADR | W_stat == SINS | W_stat == SHLT));
    preg2 #(64) F_predPC_reg(F_predPC, f_predPC, F_stall, 64'b0, clock);
   
    preg2 #(3) D_stat_reg(D_stat, f_stat, D_stall,   SBUB, clock);
    preg2 #(64) D_pc_reg(D_pc, f_pc, D_stall,   64'b0, clock);
    pipereg1 #(4) D_icode_reg(D_icode, f_icode, D_stall, D_bubble,  INOP, clock); 
    
    preg2 #(4) D_ifun_reg(D_ifun, f_ifun, D_stall, FNONE, clock);
    preg2 #(4) D_rA_reg(D_rA, f_rA, D_stall, RNONE, clock);
    preg2 #(4) D_rB_reg(D_rB, f_rB, D_stall, RNONE, clock);
    preg2 #(64) D_valC_reg(D_valC, f_valC, D_stall, 64'b0, clock);
    preg2 #(64) D_valP_reg(D_valP, f_valP, D_stall, 64'b0, clock);
    
    parameter bc = 4'h0;
    
    


    preg2 #(3) E_stat_reg(E_stat, D_stat, E_stall,  SBUB, clock);
    preg2 #(64) E_pc_reg(E_pc, D_pc, E_stall,  64'b0, clock);
    preg2 #(4) E_icode_reg(E_icode, D_icode, E_stall,  INOP, clock);
    parameter mc = 4'h1;
    preg2 #(4) E_ifun_reg(E_ifun, D_ifun, E_stall,  FNONE, clock);
    preg2 #(64) E_valC_reg(E_valC, D_valC, E_stall,  64'b0, clock);
    preg2 #(64) E_valA_reg(E_valA, d_valA, E_stall,  64'b0, clock);
    parameter dc = 4'h2;
    
    
    
    
    
    
    preg2 #(64) E_valB_reg(E_valB, d_valB, E_stall,  64'b0, clock);
    preg2 #(4) E_dstE_reg(E_dstE, d_dstE, E_stall,  RNONE, clock);
    parameter ec = 4'h3;
    preg2 #(4) E_dstM_reg(E_dstM, d_dstM, E_stall,  RNONE, clock);
    preg2 #(4) E_srcA_reg(E_srcA, d_srcA, E_stall,  RNONE, clock);
    preg2 #(4) E_srcB_reg(E_srcB, d_srcB, E_stall,  RNONE, clock);
    parameter fc = 4'h4;
    preg2 #(3) M_stat_reg(M_stat, E_stat, M_stall,  SBUB, clock);
    preg2 #(64) M_pc_reg(M_pc, E_pc, M_stall,  64'b0, clock);
    preg2 #(4) M_icode_reg(M_icode, E_icode, M_stall,  INOP, clock);
    parameter gc = 4'h5;
    preg2 #(4) M_ifun_reg(M_ifun, E_ifun, M_stall,  FNONE, clock);
    preg2 #(1) M_Cnd_reg(M_Cnd, e_Cnd, M_stall,  1'b0, clock);
    preg2 #(64) M_valE_reg(M_valE, e_valE, M_stall,  64'b0, clock);
    parameter hc = 4'h6;
    preg2 #(64) M_valA_reg(M_valA, e_valA, M_stall,  64'b0, clock);
    preg2 #(4) M_dstE_reg(M_dstE, e_dstE, M_stall,  RNONE, clock);
    preg2 #(4) M_dstM_reg(M_dstM, E_dstM, M_stall,  RNONE, clock);
    parameter ic = 4'h7;
    preg2 #(3) W_stat_reg(W_stat, m_stat, W_stall,  SBUB, clock);
    preg2 #(64) W_pc_reg(W_pc, M_pc, W_stall,  64'b0, clock);
    preg2 #(4) W_icode_reg(W_icode, M_icode, W_stall,  INOP, clock);
    parameter jc = 4'h8;
    preg2 #(64) W_valE_reg(W_valE, M_valE, W_stall,  64'b0, clock);
    preg2 #(64) W_valM_reg(W_valM, m_valM, W_stall,  64'b0, clock);
    preg2 #(4) W_dstE_reg(W_dstE, M_dstE, W_stall,  RNONE, clock);
    preg2 #(4) W_dstM_reg(W_dstM, M_dstM, W_stall,  RNONE, clock);


    InstructionMemory I(f_pc,f_ibyte[7:0],f_ibytes[71:0],imem_error);

   
    
    split split(f_ibyte[7:0], f_icode, f_ifun);
    align align(f_ibytes[71:0], need_regids, f_rA, f_rB, f_valC);
    pc_increment pci(f_pc, need_regids, need_valC, f_valP);

       
     

    
    
    regfile regf(w_dstE, w_valE, w_dstM, w_valM,
    d_srcA, d_rvalA, d_srcB, d_rvalB, resetting, clock,
    rax, rcx, rdx, rbx, rsp, rbp, rsi, rdi,
    r8, r9, r10, r11, r12, r13, r14);

    

  

    alu alu(aluA, aluB, alufun, e_valE, new_cc);
    cc ccreg(cc, new_cc,set_cc, resetting, clock);
    cond cond_check(E_ifun, cc, e_Cnd);

    
    data_memory d(mem_addr,M_valA,mem_read,mem_write,mem_data,dmem_error);

    always @(posedge clock) begin
         $display("%b %b %b",f_icode,f_pc,e_valE);
        end
    
endmodule