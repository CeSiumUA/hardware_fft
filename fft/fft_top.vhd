-- fft_top.vhd
-- Top-level entity that instantiates the FFT core and the peak detector.
-- The FFT output bus is exposed for observation and also fed into the
-- peak detector, which produces the index of the highest-magnitude bin.

library ieee;
    use ieee.std_logic_1164.all;
    use ieee.numeric_std.all;
    use ieee.math_real.all;

entity fft_top is
    generic(
        PARALLEL : natural := 4;
        N        : natural := 32;
        BITS     : natural := 16
    );
    port(
        clock      : in  std_logic;
        reset_n    : in  std_logic;

        -- FFT input stream
        inverse    : in  std_logic;
        in_real    : in  std_logic_vector(BITS-1 downto 0);
        in_imag    : in  std_logic_vector(BITS-1 downto 0);
        in_valid   : in  std_logic;
        in_sop     : in  std_logic;
        in_eop     : in  std_logic;

        -- FFT output stream (directly from FFT core)
        out_real   : out std_logic_vector(BITS-1 downto 0);
        out_imag   : out std_logic_vector(BITS-1 downto 0);
        out_error  : out std_logic;
        out_valid  : out std_logic;
        out_sop    : out std_logic;
        out_eop    : out std_logic;

        -- Peak detector result
        peak_bin   : out std_logic_vector(integer(ceil(log2(real(N))))-1 downto 0);
        peak_valid : out std_logic
    );
end entity;

architecture struct of fft_top is

    constant IDX_BITS : integer := integer(ceil(log2(real(N))));

    -- Internal wires between FFT and peak detector
    signal fft_real_i   : std_logic_vector(BITS-1 downto 0);
    signal fft_imag_i   : std_logic_vector(BITS-1 downto 0);
    signal fft_error_i  : std_logic;
    signal fft_valid_i  : std_logic;
    signal fft_sop_i    : std_logic;
    signal fft_eop_i    : std_logic;

begin

    -- Pass FFT outputs to top-level ports
    out_real  <= fft_real_i;
    out_imag  <= fft_imag_i;
    out_error <= fft_error_i;
    out_valid <= fft_valid_i;
    out_sop   <= fft_sop_i;
    out_eop   <= fft_eop_i;

    -- FFT core
    U_fft : entity work.fft(mult)
        generic map(
            PARALLEL => PARALLEL,
            N        => N,
            BITS     => BITS
        )
        port map(
            clock     => clock,
            reset_n   => reset_n,
            inverse   => inverse,
            in_real   => in_real,
            in_imag   => in_imag,
            in_valid  => in_valid,
            in_sop    => in_sop,
            in_eop    => in_eop,
            out_real  => fft_real_i,
            out_imag  => fft_imag_i,
            out_error => fft_error_i,
            out_valid => fft_valid_i,
            out_sop   => fft_sop_i,
            out_eop   => fft_eop_i
        );

    -- Peak detector (finds bin with largest |Re|^2+|Im|^2)
    U_peak : entity work.peak_detector
        generic map(
            BITS => BITS,
            N    => N
        )
        port map(
            clock      => clock,
            reset_n    => reset_n,
            fft_real   => fft_real_i,
            fft_imag   => fft_imag_i,
            fft_valid  => fft_valid_i,
            fft_sop    => fft_sop_i,
            fft_eop    => fft_eop_i,
            peak_bin   => peak_bin,
            peak_valid => peak_valid
        );

end architecture;
