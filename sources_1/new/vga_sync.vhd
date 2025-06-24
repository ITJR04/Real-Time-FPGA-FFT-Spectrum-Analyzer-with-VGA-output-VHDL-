-- Company: University of Connecticut
-- Engineer: Isai Torres
-- 
-- Create Date:    06/04/2025
-- Design Name:    VGA Sync Generator
-- Module Name:    vga_sync - Behavioral
-- Project Name:   Real-Time FFT Spectrum Analyzer on ZedBoard (VGA Output)
-- Target Devices: ZedBoard Zynq-7000 xc7z020clg484-1
-- Tool Versions:  Vivado 2025.1
-- Description: 
-- Generates horizontal and vertical sync signals, video enable signal, and pixel coordinates
-- for a 640x480 resolution VGA display running at 60Hz with 25 MHz pixel clock.
-- This will be used by vga_display.vhd to know current (x,y) location on vga display
--
-- Dependencies: None
-- 
-- Revision:
--      Revision 1.00 - File Created
-- Additional Comments:
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

entity vga_sync is
    Port (
        clk       : in  std_logic; -- 25.175 MHz clock
        reset     : in  std_logic;  -- synchronous reset
        hsync     : out std_logic; -- Horizontal sync pulse to indicate end of row
        vsync     : out std_logic; -- Vertical sync pulse to indicate end of frame
        video_on  : out std_logic;  -- high when pixel is in visible area
        xCoord    : out std_logic_vector(11 downto 0); -- horizontal position
        yCoord    : out std_logic_vector(11 downto 0)  -- vertical position
    );
end vga_sync;

architecture Behavioral of vga_sync is

    -- VGA timing constants
    constant H_DISPLAY : integer := 640; -- Visible pixels per line
    constant H_FRONT   : integer := 16; -- front porch
    constant H_SYNC    : integer := 96; -- sync pulse
    constant H_BACK    : integer := 48; -- back porch
    constant H_TOTAL   : integer := 800; -- total line length

    constant V_DISPLAY : integer := 480;
    constant V_FRONT   : integer := 10;
    constant V_SYNC    : integer := 2;
    constant V_BACK    : integer := 33;
    constant V_TOTAL   : integer := 525;

    -- counters that increment on every clck cycle
    signal h_count : integer range 0 to H_TOTAL - 1 := 0;
    signal v_count : integer range 0 to V_TOTAL - 1 := 0;

begin

    -- Count pixels and Generate Sync Process
    main_proc : process(clk) 
    begin
        if rising_edge(clk) then
            if reset = '1' then -- if reset is indicated as on
                h_count <= 0; -- reset horizontal count
                v_count <= 0; -- reset vertical count
            else -- continue the logic
                if h_count = H_TOTAL - 1 then -- if horizontal count is at max
                    h_count <= 0; -- reset horizontal count
                    if v_count = V_TOTAL - 1 then -- nested if vertical count is max
                        v_count <= 0; -- we reset vertical count
                    else -- since horizontal count isnt max
                        v_count <= v_count + 1; -- we increment vertical count and check again
                    end if;
                else -- if horizontal count is not at max
                    h_count <= h_count + 1; -- we increment till its max
                end if;
            end if;
        end if;
    end process;

    -- Generate sync signals (active low)
    hsync <= '0' when (h_count >= H_DISPLAY + H_FRONT and h_count < H_DISPLAY + H_FRONT + H_SYNC) else '1'; 
    vsync <= '0' when (v_count >= V_DISPLAY + V_FRONT and v_count < V_DISPLAY + V_FRONT + V_SYNC) else '1';

    -- Visible region 
    video_on <= '1' when (h_count < H_DISPLAY and v_count < V_DISPLAY) else '0';

    -- Output pixel coordinates for renderer
    xCoord <= std_logic_vector(to_unsigned(h_count, 12));
    yCoord <= std_logic_vector(to_unsigned(v_count, 12));
end Behavioral;