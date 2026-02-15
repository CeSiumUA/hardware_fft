module control_for_fft(clk, insignal, sink_valid, sink_ready, sink_error, sink_sop, sink_eop, inverse, outreal, outimag, fft_pts);

input clk;
input [13:0] insignal;

output reg sink_valid, sink_sop, sink_eop, inverse, sink_ready;
output reg [1:0] sink_error;

output [13:0] outreal, outimag;
output reg [10:0] fft_pts;
reg [9:0] count;

initial begin
    count = 10'd1;
    inverse = 0;
    sink_valid = 0;
    sink_ready = 1;
    sink_error = 2'b00;
    fft_pts = 11'd1023;
end

assign outreal = insignal;
assign outimag = 14'd0;

always @(posedge clk) begin
    begin
        count <= count + 1'b1;
    end
    if (count == 10'd1023)
    begin
        sink_eop <= 1;
    end
    if (count == 10'd0)
    begin
        sink_eop <= 0;
        sink_sop <= 1;
        sink_valid <= 1;
    end
    if (count == 10'd1)
    begin
        sink_sop <= 0;
    end
end

endmodule