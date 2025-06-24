----------------------------------------------------------------------------------
-- Company: University of COnnecticut
-- Engineer: Isai Torres
-- 
-- Create Date:    06/19/2025 10:54:59 AM
-- Design Name:    fft_wrapper
-- Module Name:    ftt_wrapper - Behavioral
-- Project Name:   Real-Time FFT Spectrum Analyzer on ZedBoard (VGA Output)
-- Target Devices: Zedboard Zynq-7000 xc7z020clg484-1
-- Tool Versions:  Vivado Design Suite 2025.1
-- Description: 
--      This module wraps the Xilinx FFT IP core and manages the input/output AXI-stream 
--      interface required for real-time FFT processing. It handles streaming 128 real-valued 
--      samples into the FFT block, manages valid/ready/tlast handshaking, and outputs the 
--      resulting 16-bit real and imaginary components along with a valid signal. The module 
--      supports burst-driven FFT execution initiated via a 'start' pulse and indicates FFT 
--      readiness with the 'fft_ready' output.
--
-- Dependencies: 
--      Xilinx FFT IP Core (xfft_0.xci)
--      signal_done (signal_capture)
-- Revision:
--      Revision 0.01: Initial implementation and integration of AXI-stream wrapper.
--
-- Additional Comments:
--      The real sample input is zero-padded in the imaginary part.
--      FFT configuration is default (config inputs are unused).
--      Assumes continuous 25MHz clocking environment and externally synchronized control.
--
----------------------------------------------------------------------------------


library IEEE;
use IEEE.STD_LOGIC_1164.ALL;

-- Uncomment the following library declaration if using
-- arithmetic functions with Signed or Unsigned values
--use IEEE.NUMERIC_STD.ALL;

-- Uncomment the following library declaration if instantiating
-- any Xilinx leaf cells in this code.
--library UNISIM;
--use UNISIM.VComponents.all;

entity ftt_wrapper is
  Port (
        clk          : in std_logic;
        reset        : in std_logic;
        start        : in std_logic; -- input is the check if the capture of the input is done
        real_sample  : in std_logic_vector(15 downto 0); -- we only have real sample in this module for we use a pure sine wave
        sample_valid : in std_logic; -- valid check from the "signal_capture.vhd", sample_done
        
        fft_ready    : out std_logic; -- output to indicate that FFT output is ready to accept input
        fft_real_out : out std_logic_vector(15 downto 0); -- outputted real part of computation
        fft_imag_out : out std_logic_vector(15 downto 0); -- outputted imaginary part of computation
        fft_valid    : out std_logic -- high when output is valid for use
   );
end ftt_wrapper;

architecture Behavioral of ftt_wrapper is
    -- Input sample counter
    signal sample_cnt : integer range 0 to 127 := 0;
    
    -- FFT i/p stream ctrl
    signal sending       : std_logic := '0';
    signal tvalid        : std_logic := '0';
    signal tlast         : std_logic := '0';
    signal start_latched : std_logic := '0';
    
    -- FFT AXI-stream signals
    -- s_axis_* are input stream
    -- m_axis_* are output stream
    signal s_axis_data_tready : std_logic;
    signal m_axis_data_tvalid : std_logic;
    signal m_axis_data_tdata  : std_logic_vector(31 downto 0); -- [31:16] is imaginary, [15:0] is real
    signal m_axis_data_tlast  : std_logic;
    signal m_axis_data_tready : std_logic := '1';  -- Always ready
    -- Prepared 32-bit input data [31:16] is imaginary = 0, [15:0] is real
    signal s_axis_data_tdata : std_logic_vector(31 downto 0);

    -- Xilinx FFT IP
    component xfft_0 IS
      PORT (
        aclk : IN STD_LOGIC;
        s_axis_config_tdata : IN STD_LOGIC_VECTOR(15 DOWNTO 0);
        s_axis_config_tvalid : IN STD_LOGIC;
        s_axis_config_tready : OUT STD_LOGIC;
        s_axis_data_tdata : IN STD_LOGIC_VECTOR(31 DOWNTO 0);
        s_axis_data_tvalid : IN STD_LOGIC;
        s_axis_data_tready : OUT STD_LOGIC;
        s_axis_data_tlast : IN STD_LOGIC;
        m_axis_data_tdata : OUT STD_LOGIC_VECTOR(31 DOWNTO 0);
        m_axis_data_tvalid : OUT STD_LOGIC;
        m_axis_data_tlast : OUT STD_LOGIC;
        m_axis_data_tready : IN STD_LOGIC;
        event_frame_started : OUT STD_LOGIC;
        event_tlast_unexpected : OUT STD_LOGIC;
        event_tlast_missing : OUT STD_LOGIC;
        event_status_channel_halt : OUT STD_LOGIC;
        event_data_in_channel_halt : OUT STD_LOGIC;
        event_data_out_channel_halt : OUT STD_LOGIC
      );
    end component;
begin
    -- Concatentation of real and imaginary part to form 32-bit input sample
    s_axis_data_tdata <= x"0000" & real_sample; 
    
    -- FFT IP instance with connected AXI signals
    xfft_inst : xfft_0
        port map (
            aclk => clk,
            s_axis_data_tvalid => tvalid,
            s_axis_data_tready => s_axis_data_tready,
            s_axis_data_tdata => s_axis_data_tdata,
            s_axis_data_tlast => tlast,
            
            s_axis_config_tvalid => '0', -- default configuration used
            s_axis_config_tdata => (others => '0'),
            
            m_axis_data_tvalid => m_axis_data_tvalid,
            m_axis_data_tdata => m_axis_data_tdata,
            m_axis_data_tlast => m_axis_data_tlast,
            m_axis_data_tready => m_axis_data_tready,
            
            event_frame_started           => open,
            event_tlast_unexpected        => open,
            event_tlast_missing           => open,
            event_status_channel_halt     => open,
            event_data_in_channel_halt    => open,
            event_data_out_channel_halt   => open
        );

    -- Drive ctrl signals to FFT i/p
    process(clk)
    begin
        if rising_edge(clk) then -- on rising edge of clock
            if reset = '1' then -- if reset is high clear all SMs and counters
                sample_cnt <= 0; 
                sending <= '0'; 
                tvalid <= '0'; 
                tlast <= '0';
            else -- if there is no reset
                if start = '1' then -- if the start input is on
                    start_latched <= '1'; -- make sure we latch the value of start instead of a pulse
                end if;
                if start_latched <= '1' then -- uses start latch to continue the control and stream samples
                    sending <= '1'; -- sending starts
                    sample_cnt <= 0; -- sample count is initialized to zero
                    start_latched <= '0'; -- we then turn the latch down to zero to progress the control logic
                end if; -- this ends with keeping sending on 
                -- if we are allowed to send and the sampled data is fully sampled and the slave is ready
                if sending = '1' and sample_valid = '1' and s_axis_data_tready = '1' then
                    tvalid <= '1'; -- then we have a valid
                    
                    if sample_cnt = 127 then -- if the sample count has reached the last point
                        tlast <= '1'; -- we indicate we have reached the last
                        sending <= '0'; -- we turn sending off for we do not need to send anymore
                    else -- we continue computaton
                        tlast <= '0';
                    end if;
                    
                    sample_cnt <= sample_cnt + 1; -- we continue to increment sample count if outer if statemnt is valid
                    
                else -- if start is not on
                    tvalid <= '0'; -- transfer valid signal is invalid
                    tlast <= '0'; -- transfer last is not true so we have not reached end of packet/frame
                end if;
            end if;
        end if;
    end process;
    
    -- FFT o/p assignments
    fft_valid <= m_axis_data_tvalid; -- tells downstream logic when FFT o/p is ready
    fft_real_out <= m_axis_data_tdata(15 downto 0); -- the first 16 bits of output from FFT IP is real
    fft_imag_out <= m_axis_data_tdata(31 downto 16); -- last 16 bits are the imaginary output
    fft_ready <= s_axis_data_tready; -- tells upstream logic if FFT can accept i/p
end Behavioral;
