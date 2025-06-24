----------------------------------------------------------------------------------
-- Company: University of Connecticut
-- Engineer: Isai Torres
-- 
-- Create Date:    06/18/2025
-- Design Name:    VGA Display Controller
-- Module Name:    vga_display - Behavioral
-- Project Name:   Real-Time FFT Spectrum Analyzer on ZedBoard (VGA Output)
-- Target Devices: ZedBoard Zynq-7000 xc7z020clg484-1
-- Tool Versions:  Vivado 2025.1
-- Description: 
--   This module generates VGA pixel output for displaying the FFT magnitude spectrum.
--   Each bar corresponds to a frequency bin, and its height represents the magnitude
--   of that bin. The module reads from a 1024-bit input vector (128 bars x 8-bit height).
--   It computes the current pixel's location and determines whether to light it up
--   based on its relation to the bar height.
--
-- Dependencies: Requires pixel coordinates and sync signals from vga_sync.vhd
--
-- Revision:
--      Revision 0.01 - File Created
-- Additional Comments:
--      Assumes screen size of 640x480.
--      Each bar is 5 pixels wide to span 128 bars across 640 horizontal pixels.
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

entity vga_display is
  Port (
        clk     : in std_logic;
        reset   : in std_logic; 
        
        -- VGA sync signals from vga_sync.vhd
        pixel_x     : in std_logic_vector(11 downto 0);
        pixel_y     : in std_logic_vector(11 downto 0);
        h_sync      : out std_logic; 
        v_sync      : out std_logic;
        video_on    : std_logic;
        
        -- Bar height data (128 values, 8 bits each) 1024 bits (1 height per FFT bin)
        bar_heights : in std_logic_vector(1023 downto 0);
        
        -- VGA output (RGB channels) 4-bit color channels
        red     : out std_logic_vector(3 downto 0);
        green   : out std_logic_vector(3 downto 0);
        blue    : out std_logic_vector(3 downto 0)
   );
end vga_display;

architecture Behavioral of vga_display is
    constant NUM_BARS   : integer := 128; -- the number of freq bins
    constant BAR_WIDTH  : integer := 5; -- width of frequency bin based off calcualtion of 640/128
    constant MAX_HEIGHT : integer := 255; -- max amplitude of all the possible bars 8-bit range
    constant SCREEN_HEIGHT : integer := 480; 
    
    signal bar_index : integer range 0 to 127; -- the FFT bin we're planing to render
    signal bar_height : integer range 0 to 255; -- how much amplitude the bar should have
    
    signal x_int, y_int : integer; -- integer version of the pixel coordinates
begin
    -- Convert input pixel coordinates from std_logic_vector to unsigned and casted finally to integer
    x_int <= to_integer(unsigned(pixel_x)); 
    y_int <= to_integer(unsigned(pixel_y));
    
    -- Compute current bar index (which bar column is the current?)
    bar_index <= x_int / BAR_WIDTH;
    
    process(clk)
        variable height_byte : std_logic_vector(7 downto 0); -- temporary 8-bit value that stores current bar height for bar at given bar_index
    begin
        if rising_edge(clk) then
            if reset = '1' then -- reset button to reset all pixels to black 
                red   <= (others => '0');
                green <= (others => '0');
                blue  <= (others => '0');
            elsif video_on = '1' then -- if video_on this means that the current y_int and x_int are in the visible display
                -- Extract bar height from the bar_heights vector
                -- FFT IP outputs bin magnitudes in reverse order and all heights are stored as 8 bits (byte)
                -- this byte stores the height of the given bin from the FFT so we can use it to display
                height_byte := bar_heights((127 - bar_index) * 8 + 7 downto (127 - bar_index) * 8);
                -- convert the height_byte value to integer in order for it to be compared to y_int
                bar_height <= to_integer(unsigned(height_byte));
        
                -- Draw bar pixel: from bottom up
                -- y_int must be within the visible height of the current bar
                -- y_int must be within vertical pixel heigt of 480 to be visible
                -- x_int must be witihn horizontal pixel height to be visible
                if y_int > (SCREEN_HEIGHT - bar_height) and y_int < SCREEN_HEIGHT and x_int < 640 and y_int < 480 then
                  red   <= "1111";
                  green <= "1111";
                  blue  <= "1111";
                else -- if these conditinos fail then we dont color the pixel for it is not witihin the bar contrainted area
                  red   <= "0000";
                  green <= "0000";
                  blue  <= "0000";
                end if;
            else -- if video off then we make the VGA color output black
                red   <= (others => '0');
                green <= (others => '0');
                blue  <= (others => '0');
              end if;
       end if;
   end process;
   
  
                
        

end Behavioral;
