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


-- bar_buffer stores the processed FFT magnitudes after they’ve been scaled into
-- 8-bit display heights. It holds 128 bins,and updates one bar per clock using
-- a write-enable, address,
-- and data interface. Internally it uses an array of 128 eight-bit values, and
-- then flattens that into a 1024-bit bus so the VGA rendering module can access
-- the full spectrum frame at all times. This decouples FFT output timing from VGA
-- scan timing and lets the display continuously draw a stable spectrum.`
library IEEE;
use IEEE.STD_LOGIC_1164.ALL;

-- Uncomment the following library declaration if using
-- arithmetic functions with Signed or Unsigned values
use IEEE.NUMERIC_STD.ALL;

-- Uncomment the following library declaration if instantiating
-- any Xilinx leaf cells in this code.
--library UNISIM;
--use UNISIM.VComponents.all;


-- This module bridges between signal processing domain and grpahics-domain rednering


entity bar_buffer is
  Port (
        clk     : in std_logic;
        reset   : in std_logic;
        wr_en   : in std_logic; -- write enable from fft_mag output
        wr_addr : in integer range 0 to 127; -- write addr (used for which bin we want to write to)
        -- unsigned(6 downto 0) better for natural binary vectors
        wr_data : in std_logic_vector(7 downto 0); -- Scaled height: 0 to 255 truncated version of mag_out
        bar_heights : out std_logic_vector(1023 downto 0) -- 128 * 8 = 1024 bits, falttended output containing all 128 stored bars with respective values
   );
end bar_buffer;

architecture Behavioral of bar_buffer is
    type bar_array is array(0 to 127) of std_logic_vector(7 downto 0); -- type made for the 128 bin heights
    signal bars : bar_array := (others =>(others => '0')); -- initialize the bar heights to all zero

    -- function to flaten bars
    function flatten_bars(b : bar_array) return std_logic_vector is
        variable temp : std_logic_vector(1023 downto 0);
    begin
        for i in 0 to 127 loop
            temp((i+1)*8 - 1 downto i*8) := b(i);
        end loop;
        return temp;
    end function;
begin
    
    process(clk) -- this module does not write all 128 bars at once, it writes them sequentially, one 
    -- bin at a time as the FFT mag sq results arrive
    begin
        if rising_edge(clk) then -- every clock rising edge
            if reset = '1' then -- if reset enabled, we clear the bars vector
                bars <= (others => (others => '0'));
            elsif wr_en = '1' then -- if mag_out has valid data for us we can assign the truncated value to the respective address computed in FFT_spectrum_top.vhd
                                    -- in the top file the process is used to check for every time mag_out is valid during a rising edge
                                    -- then check of the addr is at 127 (max for 1 frame) then next cycle is reset addr to 0 so next frame can be evaluated

                bars(wr_addr) <= wr_data; -- we input the written data in the bin we want it in
            end if;
            -- for wr_en = 0 nothing happens meaning VGA display keeps drwing the previous spectrum frame until newer data arrives
        end if;
    end process;
    
    
    bar_heights <= flatten_bars(bars);
end Behavioral;

-- Qualitative meaning:
        -- bus is essentially a serialized version of the whole spectrum display state
        -- very 8 bits is a bar height, all 128 bars = one completed spectrum frame descriptor
        -- bar_hieights is not image memory in pixel sense, its more efficient than storing every screen pixel

        -- if one bar is written per clokc, and need all bars updated, 28 writes per frame
            
-- separates FFt timing from VGA timing
-- small resource usage
-- scalable, 