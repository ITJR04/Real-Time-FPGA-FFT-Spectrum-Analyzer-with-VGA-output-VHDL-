----------------------------------------------------------------------------------
-- Company: University of Connecticut
-- Engineer: Isai Torres
-- 
-- Create Date:    06/19/2025 11:42:46 AM
-- Design Name:    FFT Spectrum Analyzer Frame Buffer
-- Module Name:    bar_buffer - Behavioral
-- Project Name:   Real-Time FFT Spectrum Analyzer on ZedBoard (VGA Output)
-- Target Devices: Zedbaord Zynq-7000 xc7z020clg484-1
-- Tool Versions:  Vivado Design Suite 2025.1
-- 
-- Description: 
-- This module serves as a frame buffer that stores 128 FFT magnitude values,
-- each represented as an 8-bit height. It supports synchronous writing of bar
-- heights during FFT processing and outputs a 1024-bit flattened vector to be
-- rendered by the VGA module as vertical spectrum bars.
-- 
-- Dependencies: None
-- 
-- Revision:
--      Revision 0.01 - File Created
-- Additional Comments:
--      The buffer enables decoupling of the FFT magnitude computation from the
--      rendering logic by acting as a simple storage interface.
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

entity bar_buffer is
  Port (
        clk     : in std_logic;
        wr_en   : in std_logic; -- write enable 
        wr_addr : in integer range 0 to 127; -- write addr (used for which bin we want to write to)
        wr_data : in std_logic_vector(7 downto 0); -- Scaled height: 0 to 255
        bar_heights : out std_logic_vector(1023 downto 0) -- 128 * 8 = 1024 bits
   );
end bar_buffer;

architecture Behavioral of bar_buffer is
    type bar_array is array(0 to 127) of std_logic_vector(7 downto 0); -- type made for the 128 bin heights
    signal bars : bar_array := (others =>(others => '0')); -- initialize the bar heights to all zero
begin
    
    process(clk)
    begin
        if rising_edge(clk) then -- every clock rising edge
            if wr_en = '1' then -- if our write enable is on means we are ready to assign values to the bin heights
                bars(wr_addr) <= wr_data; -- we input the written data in the bin we want it in
            end if;
        end if;
    end process;
    
  -- Process to flatten bars into wide output vector
    process(bars)
    begin
        for i in 0 to 127 loop -- for loop to be able to assign the written data in bars into the outputted bar heights all together
        bar_heights((i+1)*8 - 1 downto i*8) <= bars(i);
        end loop;
    end process;
    
end Behavioral;
