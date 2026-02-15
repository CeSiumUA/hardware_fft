////////////////////////////////////////////////////////
// RS-232 RX and TX modules
// (c) fpga4fun.com & KNJN LLC - 2003 to 2016

`include "async_transmitter.v"
`include "async_receiver.v"
`include "baud_tick_gen.v"

module uart(
	input clk,
	input RxD,
	output TxD,
	output RxD_data_ready,
	output [7:0] RxD_data,
	input [7:0] TxD_data,
	input TxD_start
);

parameter clk_frequency = 50000000; // 50MHz
parameter baud = 115200;
parameter oversampling = 8;

async_transmitter #(clk_frequency, baud) tx(.clk(clk), .TxD_start(TxD_start), .TxD_data(TxD_data), .TxD(TxD), .TxD_busy());
async_receiver #(clk_frequency, baud, oversampling) rx(.clk(clk), .RxD(RxD), .RxD_data_ready(RxD_data_ready), .RxD_data(RxD_data), .RxD_idle(), .RxD_endofpacket());

endmodule