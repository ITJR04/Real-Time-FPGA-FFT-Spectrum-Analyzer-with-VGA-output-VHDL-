----------------------------------------------------------------------------------
-- Company: University of Connecticut
-- Engineer: Isai Torres
-- 
-- Create Date: 06/20/2025 12:17:03 PM
-- Design Name: 
-- Module Name:     fft_spectrum_top - Behavioral
-- Project Name:    Real-Time FFT Spectrum Analyzer on ZedBoard (VGA Output)
-- Target Devices:  Zedbaord Zynq-7000 xc7z020clg484-1
-- Tool Versions:   Vivado 2025.1
-- Description: 
--      This module ia the top level design that connects all the submodules together for the final congestion of the system
--      we first generate a sine wave signal that then gets fed into an FFT IP. After the FFT computation is done then the magnitude 
--      response is computed then finally it is rendered in a frequency spectrum as bars on a  VGA monitor.
--
-- Dependencies: 
--      signal_capture.vhd, fft_wrapper.vhd, fft_magnitude.vhd,
--      bar_buffer.vhd,vga_sync.vhd, vga_display.vhd, cloking Wizard IP, FFT IP
--
-- Revision:
--      Revision 0.01 - File Created
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

entity fft_spectrum_top is
  Port (
        clk_100mhz      : in std_logic; -- input clock from the Zedboard
        reset           : in std_logic;  -- reset (will be used as a button on board)
        led             : out std_logic_vector(4 downto 0); -- My personal debugging leds (not necessary for the design works)
        
        -- VGA output ports
        h_sync          : out std_logic; -- Horizontal sync
        v_sync          : out std_logic; -- Vertical sync
        red             : out std_logic_vector(3 downto 0); -- Red channel
        green           : out std_logic_vector(3 downto 0); -- Green channel
        blue            : out std_logic_vector(3 downto 0) -- Blue channel
   );
end fft_spectrum_top;

architecture Behavioral of fft_spectrum_top is
    -- CLocking wizard signals
    signal clk_25mhz        : std_logic; 
    signal locked           : std_logic;
    
    -- Signal capture signals
    signal sample_out       : std_logic_vector(15 downto 0);
    signal sample_idx       : integer range 0 to 127 := 0;
    signal capture_done     : std_logic := '0';
    signal capture_en       : std_logic := '1'; -- Always sampling once per frame
        
    -- FFT signals
    signal fft_ready        : std_logic; 
    signal fft_valid        : std_logic;
    signal fft_real_out     : std_logic_vector(15 downto 0);
    signal fft_imag_out     : std_logic_vector(15 downto 0);
        
    -- Magnitude signals
    signal mag_out          : std_logic_vector(30 downto 0);
    signal mag_valid        : std_logic;
        
    -- Bar Buffer signals
    signal bar_wr_en        : std_logic;
    signal bar_wr_addr      : integer range 0 to 127 := 0;
    signal bar_wr_data      : std_logic_vector(7 downto 0);
    signal bar_heights      : std_logic_vector(1023 downto 0);
    
    -- VGA Sync signals
    signal pixel_x          : std_logic_vector(11 downto 0);
    signal pixel_y          : std_logic_vector(11 downto 0);
    signal video_on         : std_logic;
    
    -- Clocking wiard component
    component fft_clk_wiz is
        port(
            clk_in1 : in std_logic;
            resetn : in std_logic;
            locked : out std_logic;
            clk_out1 : out std_logic
        );
    end component;
begin
    ---------------------------
    -- Clocking Wizard Instance
    ---------------------------
    -- This instance is used in order to have a 25MHz clock from the Zedboard 100MHz clock for VGA and entire system design
    clk_wiz_inst : fft_clk_wiz
        port map (
            clk_in1 => clk_100mhz,
            resetn => '1',
            locked => locked,
            clk_out1 => clk_25mhz
        );
        
    ---------------------------
    -- Signal Generator
    ---------------------------
    -- outputs a 16.bit sample of a synthesized sine wave from ROM
    -- valid will always be high unless noise is simulated or control the windowing
    signal_gen_inst : entity work.signal_capture
        port map (
            clk         => clk_25mhz,
            enable      => capture_en,
            sample_out  => sample_out, 
            sample_idx  => sample_idx,
            done        => capture_done
        );
        
    ---------------------------
    -- FFT Wrapper
    ---------------------------
    -- This sends 128 samples to FFT when start_fft is asserted
    -- Produces real and imaginary FFT outputs with valid outputs
    fft_wrap_inst : entity work.ftt_wrapper
        port map (
          clk           => clk_25mhz,
          reset         => reset,
          start         => capture_done, -- capture done is inputted to here to start FFT
          real_sample   => sample_out, -- our sample from signal capture
          sample_valid  => '1', 
          fft_ready     => fft_ready, 
          fft_real_out  => fft_real_out,
          fft_imag_out  => fft_imag_out,
          fft_valid     => fft_valid   
        );
        
    --------------------------------
    -- FFT Magnitude
    --------------------------------
    -- computes mag^2 = real^2 + imag^2
    -- outputs a 31-bit result when fft_valid is high
    mag_calc : entity work.fft_magnitude
      port map (
        clk        => clk_25mhz,
        valid_in   => fft_valid, -- FFT valid inputted so when FFT is done we can then start magnitude computation
        real_in    => fft_real_out, -- FFT real portion
        imag_in    => fft_imag_out, -- FFT imaginary portion
        mag_out    => mag_out, -- outputted magnitude
        valid_out  => mag_valid -- output to indicate magnitude is valid for use
      );

    --------------------------------
    -- Magnitude Scaling & Buffer Write
    --------------------------------
    -- This process is used to write to buffer for magnitude display if the magnitude output is ready for use
    process(clk_25mhz, reset)
    begin
        if reset = '1' then
            bar_wr_addr <= 0; 
        elsif rising_edge(clk_25mhz) then -- use pixel clock
            if mag_valid = '1' then -- if the magnitude validity is true
                if bar_wr_addr < 127 then -- if the bar write address is in valid bound
                    bar_wr_addr <= bar_wr_addr + 1; -- increment the address to next freq bin bar
                else
                    bar_wr_addr <= 0; -- if bar write address is out of bounds we reset it to initial address
                end if;
            end if;
        end if;
    end process;
    -- Scale magnitude to 8-bit height
    bar_wr_data <= mag_out(15 downto 8);  -- scale down to 8 bits (simple truncation)
    bar_wr_en <= mag_valid; -- bar write enable is given value of whether the magnitude is valdi for use or not
    --------------------------------
    -- Bar Buffer
    --------------------------------
    bar_buf : entity work.bar_buffer
        port map (
            clk         => clk_25mhz,
            wr_en       => bar_wr_en,
            wr_addr     => bar_wr_addr,
            wr_data     => bar_wr_data,
            bar_heights => bar_heights
            );

    --------------------------------
    -- VGA Sync
    --------------------------------
    vga_sync_inst : entity work.vga_sync
        port map (
            clk       => clk_25mhz,
            reset     => reset,
            hsync    => h_sync,
            vsync    => v_sync,
            video_on  => video_on,
            xCoord   => pixel_x,
            yCoord   => pixel_y
            );

    --------------------------------
    -- VGA Display
    --------------------------------
    vga_disp : entity work.vga_display
        port map (
            clk         => clk_25mhz,
            reset       => reset,
            pixel_x     => pixel_x,
            pixel_y     => pixel_y,
            h_sync      => open, -- already connected
            v_sync      => open, -- already connected
            video_on    => video_on,
            bar_heights => bar_heights,
            red         => red,
            green       => green,
            blue        => blue
            );
    
    led(0) <= capture_done;
    led(1) <= fft_valid;
    led(2) <= mag_valid;
    led(3) <= bar_wr_en;
    led(4) <= bar_wr_data(7); -- MSB of data
end Behavioral;
