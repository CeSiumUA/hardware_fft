`timescale 10ns/100ps
module testbench;

reg clk;

wire [13:0] fsin_o,fcos_o;
wire [13:0] real_power_sig, imag_power_sig;


initial
begin
    clk = 0;
end


always
begin
    #10 clk = !clk;
end

wire reset_n;

nco nco_inst(
    .clk       (clk),       // clk.clk
    .reset_n   (reset_n),   // rst.reset_n
    .clken     (1'b1),     //  in.clken
    .phi_inc_i (32'd41943040), //    .phi_inc_i
    .fsin_o    (fsin_o),    // out.fsin_o
    .fcos_o    (fcos_o),    //    .fcos_o
    .out_valid (out_valid)  //    .out_valid
);

fft_wrapper fft_wrapper_inst
(
    .clk(clk) , // input  clk_sig
    .in_signal(fsin_o) , // input [13:0] in_signal_sig
    .real_power(real_power_sig) , // output [24:0] real_power_sig
    .imag_power(imag_power_sig) , // output [24:0] imag_power_sig
    .fft_source_sop(fft_source_sop_sig) , // output  fft_source_sop_sig
    .sink_sop(sink_sop_sig) , // output  sink_sop_sig
    .sink_eop(sink_eop_sig) , // output  sink_eop_sig
    .sink_valid(sink_valid_sig) , // output  sink_valid_sig
    .reset_n(reset_n)  // output  reset_n_sig
);

endmodule