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
--   This module computes the magnitude of complex FFT output values. It takes in
--   16-bit real and imaginary components and outputs the magnitude using a simple
--   approximation: magnitude = |real| + |imag| (no square root for speed/efficiency).
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
        valid_in  : in std_Logic; -- High when real/imag is valid
        real_in   : in std_logic_vector(15 downto 0); -- Real part of FFT
        imag_in   : in std_logic_vector(15 downto 0); -- Imag part of FFT output
        mag_out   : out std_logic_vector(30 downto 0); -- Magnitude squared 24^2 up to 48 bits but we keep 31 bits
        valid_out : out std_logic
   );
end fft_magnitude;

architecture Behavioral of fft_magnitude is
    -- signals to compute magnitude squared 
    signal real_sq : unsigned(31 downto 0); 
    signal imag_sq : unsigned(31 downto 0);
    signal mag_sq  : unsigned(32 downto 0); -- one extra bit for possible carry/overflow
    signal real_s  : signed(15 downto 0);
    signal imag_s  : signed(15 downto 0);
begin
    
    process(clk)
    begin
        if rising_edge(clk) then
            if valid_in = '1' then -- if the FFT IP finished computation then this condition is true
                -- Convert real and imaginary input into signed for computation
                real_s <= signed(real_in); 
                imag_s <= signed(imag_in);
                
                -- Square the signed versions of real and imaginary for magnitude squared
                real_sq <= unsigned(real_s) * unsigned(real_s);
                imag_sq <= unsigned(imag_s) * unsigned(imag_s);
                
                -- Sum the real and imaginary squares and concatenate with 0 for possible carry
                mag_sq <= ("0" & real_sq) + ("0" & imag_sq);
                
                -- Oconvert the magnitude squared to std_logic_vector to be outputted
                mag_out <= std_logic_vector(mag_sq(30 downto 0));
                valid_out <= '1'; -- indicate that computation is done and valid
            else -- since FFT didnt finsih computation
                valid_out <= '0'; -- Magnitude squared computation isn't done yet
            end if;
        end if;
    end process;


end Behavioral;
