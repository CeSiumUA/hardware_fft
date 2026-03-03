-- peak_detector.vhd
-- Monitors the output of an FFT block and latches the bin index with the
-- highest magnitude (|Re|^2 + |Im|^2).  The peak bin index is presented on
-- peak_bin and strobed with peak_valid once per FFT frame (on EOP).

library ieee;
    use ieee.std_logic_1164.all;
    use ieee.numeric_std.all;
    use ieee.math_real.all;

entity peak_detector is
    generic(
        BITS : natural := 16;   -- sample width (signed)
        N    : natural := 32    -- FFT length
    );
    port(
        clock      : in  std_logic;
        reset_n    : in  std_logic;

        -- FFT streaming output (Avalon-ST style)
        fft_real   : in  std_logic_vector(BITS-1 downto 0);
        fft_imag   : in  std_logic_vector(BITS-1 downto 0);
        fft_valid  : in  std_logic;
        fft_sop    : in  std_logic;
        fft_eop    : in  std_logic;

        -- Peak result
        peak_bin   : out std_logic_vector(integer(ceil(log2(real(N))))-1 downto 0);
        peak_valid : out std_logic
    );
end entity;

architecture rtl of peak_detector is

    constant IDX_BITS : integer := integer(ceil(log2(real(N))));
    constant MAG_BITS : integer := BITS * 2;   -- width of |re|^2 + |im|^2

    -- Running state inside the current frame
    signal cur_idx  : unsigned(IDX_BITS-1 downto 0);
    signal max_mag  : unsigned(MAG_BITS-1 downto 0);
    signal max_idx  : unsigned(IDX_BITS-1 downto 0);

    signal peak_bin_r   : unsigned(IDX_BITS-1 downto 0);
    signal peak_valid_r : std_logic;

    -- Combinational magnitude-squared of the current sample
    signal re_s     : signed(BITS-1 downto 0);
    signal im_s     : signed(BITS-1 downto 0);
    signal re_sq    : signed(MAG_BITS-1 downto 0);
    signal im_sq    : signed(MAG_BITS-1 downto 0);
    signal mag      : unsigned(MAG_BITS-1 downto 0);  -- always positive

begin

    re_s  <= signed(fft_real);
    im_s  <= signed(fft_imag);
    re_sq <= re_s * re_s;
    im_sq <= im_s * im_s;
    mag   <= unsigned(re_sq) + unsigned(im_sq);

    peak_bin   <= std_logic_vector(peak_bin_r);
    peak_valid <= peak_valid_r;

    process(clock, reset_n)
    begin
        if (reset_n = '0') then
            cur_idx     <= (others => '0');
            max_mag     <= (others => '0');
            max_idx     <= (others => '0');
            peak_bin_r  <= (others => '0');
            peak_valid_r <= '0';
        elsif rising_edge(clock) then
            peak_valid_r <= '0';           -- default: single-cycle pulse

            if (fft_valid = '1') then
                -- Start of a new frame: reset tracking registers
                if (fft_sop = '1') then
                    cur_idx <= to_unsigned(1, IDX_BITS);   -- next sample will be bin 1
                    max_mag <= mag;
                    max_idx <= (others => '0');             -- bin 0
                else
                    cur_idx <= cur_idx + 1;

                    if (mag > max_mag) then
                        max_mag <= mag;
                        max_idx <= cur_idx;
                    end if;
                end if;

                -- End of frame: publish result
                if (fft_eop = '1') then
                    -- Check last sample against running max
                    if (fft_sop = '1') then
                        -- Degenerate: single-sample frame
                        peak_bin_r <= (others => '0');
                    elsif (mag > max_mag) then
                        peak_bin_r <= cur_idx;
                    else
                        peak_bin_r <= max_idx;
                    end if;
                    peak_valid_r <= '1';
                end if;
            end if;
        end if;
    end process;

end architecture;
