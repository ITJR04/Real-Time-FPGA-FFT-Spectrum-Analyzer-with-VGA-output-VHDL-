----------------------------------------------------------------------------------
-- Company: University of Connecticut
-- Engineer: Isai Torres
-- 
-- Create Date:    06/19/2025
-- Design Name:    FFT Magnitude Calculator
-- Module Name:    fft_magnitude - Behavioral
-- Project Name:   Real-Time FFT Spectrum Analyzer on ZedBoard (VGA Output)
-- Target Devices: ZedBoard Zynq-7000 xc7z020clg484-1
-- Tool Versions:  Vivado 2025.1
-- Description: 
--   This module computes the magnitude squared of complex FFT output values. It takes in
--   16-bit real and imaginary components and outputs the magnitude sq using a simple
--   approximation: magnitude^2 = real^2 + imag^2 .
--   
--   The magnitude is used to visualize spectral amplitude on VGA.
--
-- Dependencies: fft_valid from "fft_wrapper.vhd" to use as i/p valid_in
--
-- Revision:
-- Revision 0.01 - File Created
-- Additional Comments:
--   Uses unsigned arithmetic for simplicity.
--   Adjust calculation if higher accuracy is required.
--
----------------------------------------------------------------------------------

-- fft_magnitude.vhd is a synchronous arithmetic stage that converts each complex
-- FFT output bin into a scalar intensity metric for display. It interprets the
-- FFT real and imaginary outputs as signed 16-bit values, computes their squares,
-- sums them to obtain magnitude squared, and registers the result along with a
-- valid pulse. This avoids the hardware cost of a square-root operation while
-- preserving the relative spectral strength needed for bar-graph visualization.

library IEEE;
use IEEE.STD_LOGIC_1164.ALL;

-- Uncomment the following library declaration if using
-- arithmetic functions with Signed or Unsigned values
use IEEE.NUMERIC_STD.ALL;

-- Uncomment the following library declaration if instantiating
-- any Xilinx leaf cells in this code.
--library UNISIM;
--use UNISIM.VComponents.all;

entity fft_magnitude is
  Port (
        clk       : in std_logic; 
        reset     : std_logic;
        valid_in  : in std_Logic; -- High when real/imag is valid
        real_in   : in std_logic_vector(15 downto 0); -- Real part of FFT
        imag_in   : in std_logic_vector(15 downto 0); -- Imag part of FFT output
        mag_out   : out std_logic_vector(32 downto 0); -- Magnitude squared up to 33 bits
        valid_out : out std_logic
   );
end fft_magnitude;

architecture Behavioral of fft_magnitude is
begin
    
    process(clk)
        variable real_v   : signed(15 downto 0);
        variable imag_v   : signed(15 downto 0);
        variable real_sq  : signed(31 downto 0);
        variable imag_sq  : signed(31 downto 0);
        variable mag_sq   : unsigned(32 downto 0);
    begin
        if rising_edge(clk) then
            if reset = '1' then
                mag_out   <= (others => '0');
                valid_out <= '0';
            else
                valid_out <= '0';

                if valid_in = '1' then
                    real_v := signed(real_in);
                    imag_v := signed(imag_in);

                    real_sq := real_v * real_v; --squaring effectively makes max value of a signal to have double the bits
                    imag_sq := imag_v * imag_v;

                    mag_sq := unsigned('0' & real_sq) + unsigned('0' & imag_sq); -- adding two 32 bit values can cause overflow
                    -- so concaenating a 0 at the end of the signed values gives exra space for overflow

                    mag_out   <= std_logic_vector(mag_sq); -- cast mag_sq back to std_logic vector for later module processing
                    valid_out <= '1';
                end if;
            end if;
        end if;
    end process;



end Behavioral;

-- Big picture of fft_magnitue

-- FFt wrapper goves for each freq bin, real_in, imag_in, valid_in (fft_valid)
-- eacg FFT output sample is complex so to compute magnitude square we convert the std_vecotors
-- for real and imaginary into signed values to compute easily by squaring them first then adding them
-- to recieve magnitude squared

-- signed values range: −32768 to 32767
-- max square magnitude for real_in^2 (or imag_in^2): 32768^2 =1,073,741,824
-- of both real and imag near maximum then ∣X∣2=32768^2+32768^2 =2,147,483,648
-- 31 bits of magnitude, 1 bit of sign and 1 bit of overflow for adding 2 32 bit values

-- after each valid_in assertion being checked mag is computed and valid_out is asserted for the VGA_display

-- Uses signed interpretation correctly, practical dispaly metric of Mag sq, bit groqth handled (no overflow issue)

-- no bin index passes through (fine since later modules already know which FFT output bin is currently arriving), no scaling or compression (33 bit value might be to large
-- to directly map to VGA bar heights unless scaled or truncated by later moduels which it is)

-- FFT output gives rectangular complex coordinates, this FFT mag converts them into radial strength