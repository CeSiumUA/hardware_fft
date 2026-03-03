// peak_detector.v
// Monitors the output of an FFT block and latches the bin index with the
// highest magnitude (|Re|^2 + |Im|^2).  The peak bin index is presented on
// `peak_bin` and strobed with `peak_valid` once per FFT frame (on EOP).

module peak_detector #(
    parameter BITS  = 16,   // sample width (signed)
    parameter N     = 32    // FFT length
) (
    input  wire                         clock,
    input  wire                         reset_n,

    // FFT streaming output (Avalon-ST style)
    input  wire signed [BITS-1:0]       fft_real,
    input  wire signed [BITS-1:0]       fft_imag,
    input  wire                         fft_valid,
    input  wire                         fft_sop,
    input  wire                         fft_eop,

    // Peak result
    output reg  [$clog2(N)-1:0]         peak_bin,
    output reg                          peak_valid
);

    localparam IDX_BITS = $clog2(N);
    localparam MAG_BITS = (BITS * 2);       // width of |re|^2 + |im|^2

    // Running state inside the current frame
    reg [IDX_BITS-1:0]  cur_idx;
    reg [MAG_BITS-1:0]  max_mag;
    reg [IDX_BITS-1:0]  max_idx;

    // Combinational magnitude-squared of the current sample
    wire signed [MAG_BITS-1:0] re_sq;
    wire signed [MAG_BITS-1:0] im_sq;
    wire        [MAG_BITS-1:0] mag;         // unsigned sum

    assign re_sq = fft_real * fft_real;
    assign im_sq = fft_imag * fft_imag;
    assign mag   = re_sq[MAG_BITS-1:0] + im_sq[MAG_BITS-1:0];   // always positive

    always @(posedge clock or negedge reset_n) begin
        if (!reset_n) begin
            cur_idx    <= {IDX_BITS{1'b0}};
            max_mag    <= {MAG_BITS{1'b0}};
            max_idx    <= {IDX_BITS{1'b0}};
            peak_bin   <= {IDX_BITS{1'b0}};
            peak_valid <= 1'b0;
        end else begin
            peak_valid <= 1'b0;             // default: single-cycle pulse

            if (fft_valid) begin
                // Start of a new frame — reset tracking registers
                if (fft_sop) begin
                    cur_idx <= {{(IDX_BITS-1){1'b0}}, 1'b1};  // next will be 1
                    max_mag <= mag;
                    max_idx <= {IDX_BITS{1'b0}};               // bin 0
                end else begin
                    cur_idx <= cur_idx + 1'b1;

                    if (mag > max_mag) begin
                        max_mag <= mag;
                        max_idx <= cur_idx;
                    end
                end

                // End of frame — publish result
                if (fft_eop) begin
                    // Check last sample against running max
                    if (fft_sop) begin
                        // Degenerate: single-sample frame
                        peak_bin <= {IDX_BITS{1'b0}};
                    end else if (mag > max_mag) begin
                        peak_bin <= cur_idx;
                    end else begin
                        peak_bin <= max_idx;
                    end
                    peak_valid <= 1'b1;
                end
            end
        end
    end

endmodule
