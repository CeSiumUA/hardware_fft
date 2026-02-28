-- This file is part of bladeRF-wiphy.
--
-- Copyright (C) 2021 Nuand, LLC.
--
-- This program is free software; you can redistribute it and/or modify
-- it under the terms of the GNU General Public License as published by
-- the Free Software Foundation; either version 2 of the License, or
-- (at your option) any later version.
--
-- This program is distributed in the hope that it will be useful,
-- but WITHOUT ANY WARRANTY; without even the implied warranty of
-- MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
-- GNU General Public License for more details.
--
-- You should have received a copy of the GNU General Public License along
-- with this program; if not, write to the Free Software Foundation, Inc.,
-- 51 Franklin Street, Fifth Floor, Boston, MA 02110-1301 USA.

library ieee;
    use ieee.std_logic_1164.all;
    use ieee.numeric_std.all;

entity fft_tb is
end entity;

architecture arch of fft_tb is
   signal clock    : std_logic := '0';
   signal reset_n    : std_logic;

   signal in_real  : std_logic_vector(15 downto 0);
   signal in_imag  : std_logic_vector(15 downto 0);
   signal in_valid : std_logic;
   signal in_sop   : std_logic;
   signal in_eop   : std_logic;

   signal out_real  : std_logic_vector(15 downto 0);
   signal out_imag  : std_logic_vector(15 downto 0);
   signal out_error : std_logic;
   signal out_valid : std_logic;

   -- ch1_slice.bin: 128 bytes = 32 interleaved int16 IQ pairs (little-endian)
   constant N : integer := 32;

   -- Convert two bytes (little-endian) into a signed 16-bit integer
   function to_int16(lo, hi : character) return integer is
      variable val : unsigned(15 downto 0);
   begin
      val(7 downto 0)  := to_unsigned(character'pos(lo), 8);
      val(15 downto 8) := to_unsigned(character'pos(hi), 8);
      return to_integer(signed(val));
   end function;

begin
   clock <= not clock after 6.25 ns;
   reset_n <= '0', '1' after 50 ns;

   process
      type char_file_t is file of character;
      file data_file : char_file_t;
      variable status  : file_open_status;
      variable lo, hi  : character;
      variable i_val   : integer;
      variable q_val   : integer;

      -- Store samples so we can replay them multiple times
      type sample_arr_t is array(0 to N-1) of integer;
      variable samples_i : sample_arr_t;
      variable samples_q : sample_arr_t;
   begin
      in_real    <= ( others => '0' );
      in_imag    <= ( others => '0' );
      in_valid   <= '0';
      in_sop     <= '0';
      in_eop     <= '0';

      -- Read IQ data from binary file (int16 little-endian, interleaved I Q)
      file_open(status, data_file, "ch1_slice.bin", read_mode);
      assert status = open_ok
         report "Failed to open ch1_slice.bin" severity failure;

      for i in 0 to N-1 loop
         read(data_file, lo);
         read(data_file, hi);
         samples_i(i) := to_int16(lo, hi);

         read(data_file, lo);
         read(data_file, hi);
         samples_q(i) := to_int16(lo, hi);
      end loop;
      file_close(data_file);

      wait for 100 ns;

      -- Feed data into FFT (replay a few times to observe steady-state)
      for iz in 0 to 3 loop
         for i in 0 to N-1 loop
            wait until rising_edge(clock);
            in_real    <= std_logic_vector(to_signed(samples_i(i), 16));
            in_imag    <= std_logic_vector(to_signed(samples_q(i), 16));
            in_valid   <= '1';
            if (i = 0) then
               in_sop     <= '1';
            else
               in_sop     <= '0';
            end if;

            if (i = N-1) then
               in_eop     <= '1';
            else
               in_eop     <= '0';
            end if;
         end loop;

         wait until rising_edge(clock);
         in_valid   <= '0';
         in_sop <= '0';
         in_eop <= '0';
         wait for 500 ns;
      end loop;
      wait for 5 ms;
   end process;

   U_uut: entity work.fft(mult)
      generic map(
         N          => N
      )
      port map(
         clock      => clock,
         reset_n    => reset_n,

         inverse    => '0',
         in_real    => in_real,
         in_imag    => in_imag,
         in_valid   => in_valid,
         in_sop     => in_sop,
         in_eop     => in_eop,

         out_real   => out_real,
         out_imag   => out_imag,
         out_error  => out_error,
         out_valid  => out_valid
      );

end architecture;

