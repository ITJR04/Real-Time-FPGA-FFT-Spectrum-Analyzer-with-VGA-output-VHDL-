----------------------------------------------------------------------------------
-- Company: University of Connecticut
-- Engineer: Isai Torres
-- 
-- Create Date: 06/20/2025
-- Design Name: FFT Spectrum Analyzer Top Level
-- Module Name: fft_spectrum_top - Behavioral
-- Project Name: Real-Time FFT Spectrum Analyzer on ZedBoard (VGA Output)
-- Target Devices: ZedBoard Zynq-7000 xc7z020clg484-1
-- Tool Versions: Vivado 2025.1
-- Description:
--   Top-level integration of the FFT spectrum analyzer system.
--   A ROM-based signal source streams 128 real-valued samples into the FFT IP,
--   the FFT output magnitudes are computed and scaled, stored in a bar buffer,
--   and rendered as vertical bars on a 640x480 VGA display.
--
-- Dependencies:
--   signal_capture.vhd
--   ftt_wrapper.vhd
--   fft_magnitude.vhd
--   bar_buffer.vhd
--   vga_sync.vhd
--   vga_display.vhd
--   fft_clk_wiz.xci
--   xfft_0.xci
----------------------------------------------------------------------------------


library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

entity fft_spectrum_top is
    Port (
        clk_100mhz : in  std_logic;
        reset      : in  std_logic;
        led        : out std_logic_vector(4 downto 0);

        h_sync     : out std_logic;
        v_sync     : out std_logic;
        red        : out std_logic_vector(3 downto 0);
        green      : out std_logic_vector(3 downto 0);
        blue       : out std_logic_vector(3 downto 0)
    );
end fft_spectrum_top;

architecture Behavioral of fft_spectrum_top is

    --------------------------------------------------------------------
    -- Clocking signals
    --------------------------------------------------------------------
    signal clk_25mhz : std_logic;
    signal locked    : std_logic;

    --------------------------------------------------------------------
    -- Signal capture signals
    --------------------------------------------------------------------
    signal sample_out   : std_logic_vector(15 downto 0);
    signal sample_idx   : integer range 0 to 127 := 0;
    signal sample_valid : std_logic;
    signal sample_last  : std_logic;
    signal capture_en   : std_logic := '1';  -- continuous frame generation

    --------------------------------------------------------------------
    -- FFT interface signals
    --------------------------------------------------------------------
    signal fft_ready    : std_logic;
    signal fft_valid    : std_logic;
    signal fft_real_out : std_logic_vector(15 downto 0);
    signal fft_imag_out : std_logic_vector(15 downto 0);

    --------------------------------------------------------------------
    -- Magnitude signals
    --------------------------------------------------------------------
    signal mag_out      : std_logic_vector(32 downto 0);
    signal mag_valid    : std_logic;

    --------------------------------------------------------------------
    -- Bar buffer signals
    --------------------------------------------------------------------
    signal bar_wr_en    : std_logic;
    signal bar_wr_addr  : integer range 0 to 127 := 0;
    signal bar_wr_data  : std_logic_vector(7 downto 0);
    signal bar_heights  : std_logic_vector(1023 downto 0);

    --------------------------------------------------------------------
    -- VGA sync/display signals
    --------------------------------------------------------------------
    signal pixel_x      : std_logic_vector(11 downto 0);
    signal pixel_y      : std_logic_vector(11 downto 0);
    signal video_on     : std_logic;

    --------------------------------------------------------------------
    -- Clock wizard component
    --------------------------------------------------------------------
    component fft_clk_wiz is
        port (
            clk_in1  : in  std_logic;
            resetn   : in  std_logic;
            locked   : out std_logic;
            clk_out1 : out std_logic
        );
    end component;

begin

    --------------------------------------------------------------------
    -- Clock Wizard
    -- Generate 25 MHz pixel/system clock from 100 MHz board clock
    --------------------------------------------------------------------
    clk_wiz_inst : fft_clk_wiz
        port map (
            clk_in1  => clk_100mhz,
            resetn   => '1',
            locked   => locked,
            clk_out1 => clk_25mhz
        );

    --------------------------------------------------------------------
    -- Signal Capture / ROM Signal Source
    -- Streams one sample per clock with valid/last flags
    --------------------------------------------------------------------
    signal_gen_inst : entity work.signal_capture
        port map (
            clk          => clk_25mhz,
            reset        => reset,
            enable       => capture_en,
            sample_out   => sample_out,
            sample_idx   => sample_idx,
            sample_valid => sample_valid,
            sample_last  => sample_last
        );

    --------------------------------------------------------------------
    -- FFT Wrapper
    -- Maps sample stream into AXI-stream interface for FFT IP
    --------------------------------------------------------------------
    fft_wrap_inst : entity work.ftt_wrapper
        port map (
            clk          => clk_25mhz,
            reset        => reset,
            real_sample  => sample_out,
            sample_valid => sample_valid,
            sample_last  => sample_last,
            fft_ready    => fft_ready,
            fft_real_out => fft_real_out,
            fft_imag_out => fft_imag_out,
            fft_valid    => fft_valid
        );

    --------------------------------------------------------------------
    -- FFT Magnitude
    -- Computes magnitude-squared = Re^2 + Im^2
    --------------------------------------------------------------------
    mag_calc : entity work.fft_magnitude
        port map (
            clk       => clk_25mhz,
            reset     => reset,
            valid_in  => fft_valid,
            real_in   => fft_real_out,
            imag_in   => fft_imag_out,
            mag_out   => mag_out,
            valid_out => mag_valid
        );

    --------------------------------------------------------------------
    -- Magnitude Scaling and Write Address Generation
    -- One FFT magnitude result is written into one bar-buffer location
    --------------------------------------------------------------------
    process(clk_25mhz)
    begin
        if rising_edge(clk_25mhz) then
            if reset = '1' then
                bar_wr_addr <= 0;
            elsif mag_valid = '1' then -- for every valid mag out sample
                if bar_wr_addr = 127 then -- check if it is the last bin to write to
                    bar_wr_addr <= 0; -- if so next process cycle sohuld wrap to next frame index 0
                else
                    bar_wr_addr <= bar_wr_addr + 1; -- if we are still processing the current frame just increment
                end if;
            end if;
        end if;
    end process;

    -- Scale 33-bit magnitude to 8-bit display height
    -- Simple truncation for visualization
    bar_wr_data <= mag_out(15 downto 8);
    bar_wr_en   <= mag_valid;

    --------------------------------------------------------------------
    -- Bar Buffer
    -- Stores 128 bar heights for VGA rendering
    --------------------------------------------------------------------
    bar_buf : entity work.bar_buffer
        port map (
            clk         => clk_25mhz,
            reset       => reset,
            wr_en       => bar_wr_en,
            wr_addr     => bar_wr_addr,
            wr_data     => bar_wr_data, -- the trncated mag value from the magnitude squared calcualtion
            bar_heights => bar_heights -- output bar heights 
        );

    --------------------------------------------------------------------
    -- VGA Sync Generator
    -- Produces hsync, vsync, visible-region flag, and pixel coordinates
    --------------------------------------------------------------------
    vga_sync_inst : entity work.vga_sync
        port map (
            clk      => clk_25mhz,
            reset    => reset,
            hsync    => h_sync,
            vsync    => v_sync,
            video_on => video_on,
            xCoord   => pixel_x,
            yCoord   => pixel_y
        );

    --------------------------------------------------------------------
    -- VGA Display Renderer
    -- Draws spectrum bars based on current pixel position and bar buffer
    --------------------------------------------------------------------
    vga_disp : entity work.vga_display
        port map (
            clk         => clk_25mhz,
            reset       => reset,
            pixel_x     => pixel_x,
            pixel_y     => pixel_y,
            video_on    => video_on,
            bar_heights => bar_heights,
            red         => red,
            green       => green,
            blue        => blue
        );

    --------------------------------------------------------------------
    -- Debug LEDs
    --------------------------------------------------------------------
    led(0) <= sample_valid;
    led(1) <= sample_last;
    led(2) <= fft_valid;
    led(3) <= mag_valid;
    led(4) <= bar_wr_data(7);

end Behavioral;