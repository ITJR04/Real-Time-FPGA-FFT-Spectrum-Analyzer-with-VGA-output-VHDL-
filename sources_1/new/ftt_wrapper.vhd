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


-- ftt_wrapper.vhd is an AXI-stream adapter around the Xilinx FFT IP core. It takes
-- 16-bit real time-domain samples and packs them into the 32-bit complex input 
-- format expected by the FFT, with the imaginary part forced to zero. It forwards
-- frame-valid and frame-last control information to the IP, then unpacks the 
-- 32-bit complex FFT output stream into separate 16-bit real and imaginary 
-- components for downstream magnitude processing. Functionally, it isolates 
-- vendor-specific streaming details from the rest of the design.

library IEEE;
use IEEE.STD_LOGIC_1164.ALL;

entity ftt_wrapper is
    Port (
        clk          : in  std_logic;
        reset        : in  std_logic;

        -- streaming sample input from signal_capture
        real_sample  : in  std_logic_vector(15 downto 0);
        sample_valid : in  std_logic;
        sample_last  : in  std_logic;

        -- FFT status/output
        fft_ready    : out std_logic;
        fft_real_out : out std_logic_vector(15 downto 0);
        fft_imag_out : out std_logic_vector(15 downto 0);
        fft_valid    : out std_logic
    );
end ftt_wrapper;

architecture Behavioral of ftt_wrapper is

    -- AXI-stream input side
    signal s_axis_data_tdata  : std_logic_vector(31 downto 0);
    signal s_axis_data_tvalid : std_logic;
    signal s_axis_data_tready : std_logic;
    signal s_axis_data_tlast  : std_logic;

    -- AXI-stream output side
    signal m_axis_data_tdata  : std_logic_vector(31 downto 0);
    signal m_axis_data_tvalid : std_logic;
    signal m_axis_data_tlast  : std_logic;
    signal m_axis_data_tready : std_logic := '1'; -- always ready to accept data
    -- not really good to have held high, would be good to incorporate
    -- actual AXI interface rather than wrap the FFT IP so the deisgn is simpler

    -- would be best to transfer over the blocks into AXI inteface so its more of 
    -- a sophisticated transfer of data between modules

    -- optional config channel signals
    signal s_axis_config_tready : std_logic;

    component xfft_0
      PORT (
        aclk                     : IN  STD_LOGIC;
        s_axis_config_tdata      : IN  STD_LOGIC_VECTOR(15 DOWNTO 0);
        s_axis_config_tvalid     : IN  STD_LOGIC;
        s_axis_config_tready     : OUT STD_LOGIC;
        s_axis_data_tdata        : IN  STD_LOGIC_VECTOR(31 DOWNTO 0);
        s_axis_data_tvalid       : IN  STD_LOGIC;
        s_axis_data_tready       : OUT STD_LOGIC; -- disregarded since signal capture has no current use for FFT wrappers rewady signal
        s_axis_data_tlast        : IN  STD_LOGIC;
        m_axis_data_tdata        : OUT STD_LOGIC_VECTOR(31 DOWNTO 0);
        m_axis_data_tvalid       : OUT STD_LOGIC;
        m_axis_data_tlast        : OUT STD_LOGIC;
        m_axis_data_tready       : IN  STD_LOGIC;
        event_frame_started      : OUT STD_LOGIC;
        event_tlast_unexpected   : OUT STD_LOGIC;
        event_tlast_missing      : OUT STD_LOGIC;
        event_status_channel_halt: OUT STD_LOGIC;
        event_data_in_channel_halt : OUT STD_LOGIC;
        event_data_out_channel_halt: OUT STD_LOGIC
      );
    end component;

begin

    ----------------------------------------------------------------
    -- Pack 16-bit real sample into 32-bit complex input
    -- [31:16] = imag = 0
    -- [15:0]  = real sample
    ----------------------------------------------------------------
    s_axis_data_tdata <= x"0000" & real_sample;

    ----------------------------------------------------------------
    -- Direct mapping from source stream to AXI-stream
    ----------------------------------------------------------------
    s_axis_data_tvalid <= sample_valid;
    s_axis_data_tlast  <= sample_last;

    ----------------------------------------------------------------
    -- FFT IP instance
    ----------------------------------------------------------------
    xfft_inst : xfft_0 
        port map (
            aclk                       => clk,

            s_axis_config_tdata        => (others => '0'),
            s_axis_config_tvalid       => '0',
            s_axis_config_tready       => s_axis_config_tready,

            s_axis_data_tdata          => s_axis_data_tdata,
            s_axis_data_tvalid         => s_axis_data_tvalid,
            s_axis_data_tready         => s_axis_data_tready,
            s_axis_data_tlast          => s_axis_data_tlast, -- tells FFT the current frame is the last
                                                             -- it is used for error checking and event 
                                                             -- generation as well as ensuring proper 
                                           
                                                             -- frame alignment to prevent downstrea components from failing

            m_axis_data_tdata          => m_axis_data_tdata, -- o/p data
            m_axis_data_tvalid         => m_axis_data_tvalid, -- o/p data is valid for send out
            m_axis_data_tlast          => m_axis_data_tlast, -- 0/p signal that 
            m_axis_data_tready         => m_axis_data_tready, -- set high always so ready to accept always

            event_frame_started        => open,
            event_tlast_unexpected     => open, -- error flag for if tlast is asserted before Nth sample in frame
            event_tlast_missing        => open, -- error flag for when the core reaches the Nth sample in the frame but tlast is not asserted
            event_status_channel_halt  => open,
            event_data_in_channel_halt => open,
            event_data_out_channel_halt=> open
        );

    ----------------------------------------------------------------
    -- Output assignments
    ----------------------------------------------------------------
    fft_valid    <= m_axis_data_tvalid; -- data valid for sending out to FFT magnitude block
    fft_real_out <= m_axis_data_tdata(15 downto 0); --real part of FFT output
    fft_imag_out <= m_axis_data_tdata(31 downto 16); -- imaginary part of FFT output
    fft_ready    <= s_axis_data_tready; -- FFT signal to assert ready to recieive samples
                                        -- unfortunately not used but can simply be implented

end Behavioral;

-- Quanittiative meaning of FFT output bins

-- FFT length 128 means eac sample corresponds to a freq bin k
-- k = 0,1, ... ,127   
-- fk = k/N * fs physical freq represented by bin
-- N  128, fs = sample rate of the input signal, currently in the design is 25MHz
-- so Δf = fs/N = 195312.5 Hz so bin 0 = 0 Hz, bin 1 = 195.3125 kHz and so on
-- FFT bins indexed as follows: [0,1,....,63,64, ..., 127] 0-63 positive freq,64 = nyquist freq, 65-127 negative freq
-- real valued signals mirror in freq so bin in positive and negative of a given freq

-- ROle of IM and Re outputs
-- FFT output is complex because freq-domain info had both amplitude and phase
-- to display spectrum computing magnitude squared we have Re^2 + Im^2
-- so mag squared will give a real value to display which fft_maginutude.vhd does

-- this wrapper assumes a lot such as i/p samples arrive correctly framed, sample_last appears as true final sample of FFT frame
-- FFT i/p readiness will not cause trouble, or source effectivley matches FFT readiness
-- FFT output can always be accepted

-- not full hanshake control, therefore we have a stripped down type of AXI interface

-- simle wrapper, bridges plain source signals to AXI-stream

-- correctly zero-pads the imaginary input

-- cleanly unpacks FFT outputs
-- exposes fft_ready, good for future hadnshake impovemnts 

-- no frame control FSM, ok for now since only one frame is processed and this proejct is more like a 
-- simple sample_source
-- need to implent frame control and event signals and handshake enforcement when having to deal with ADC input

