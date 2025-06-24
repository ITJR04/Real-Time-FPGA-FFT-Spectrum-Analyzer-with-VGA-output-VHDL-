----------------------------------------------------------------------------------
-- Company: University of Connecticut
-- Engineer: Isai Torres
-- 
-- Create Date:    06/19/2025
-- Design Name:    Signal Capture Module
-- Module Name:    signal_capture - Behavioral
-- Project Name:   Real-Time FFT Spectrum Analyzer on ZedBoard (VGA Output)
-- Target Devices: ZedBoard Zynq-7000 xc7z020clg484-1
-- Tool Versions:  Vivado 2025.1
-- Description: 
--   This module captures a stream of real-valued samples for use in FFT processing. 
--   It waits for a trigger signal (`start_capture`) and stores a fixed number of samples 
--   into an internal buffer (e.g., 128 samples). Once capture is complete, it asserts 
--   `capture_done` to notify downstream logic.
--
-- Dependencies: None
--
-- Revision:
-- Revision 0.01 - File Created
-- Additional Comments:
--   Assumes incoming data is 16-bit wide.
--   Modify SAMPLE_COUNT if a different FFT size is desired.
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

entity signal_capture is
  Port (
        clk : in std_logic; -- System clock
        enable : in std_logic; -- Trigger to start sampling
        sample_out : out std_logic_vector(15 downto 0); -- Output sample
        sample_idx : out integer range 0 to 127;
        done : out std_logic
   );
end signal_capture;

architecture Behavioral of signal_capture is
    type signal_rom_type is array(0 to 127) of std_logic_vector(15 downto 0); -- ROM table with 128 addresses with each address having 16 bit width
    constant signal_rom : signal_rom_type := ( -- ROM for the sampled signal of a sine wave
    0 => x"0080",
    1 => x"0086",
    2 => x"008C",
    3 => x"0092",
    4 => x"0098",
    5 => x"009E",
    6 => x"00A5",
    7 => x"00AA",
    8 => x"00B0",
    9 => x"00B6",
    10 => x"00BC",
    11 => x"00C1",
    12 => x"00C6",
    13 => x"00CB",
    14 => x"00D0",
    15 => x"00D5",
    16 => x"00DA",
    17 => x"00DE",
    18 => x"00E2",
    19 => x"00E6",
    20 => x"00EA",
    21 => x"00ED",
    22 => x"00F0",
    23 => x"00F3",
    24 => x"00F5",
    25 => x"00F8",
    26 => x"00FA",
    27 => x"00FB",
    28 => x"00FD",
    29 => x"00FE",
    30 => x"00FE",
    31 => x"00FF",
    32 => x"00FF",
    33 => x"00FF",
    34 => x"00FE",
    35 => x"00FE",
    36 => x"00FD",
    37 => x"00FB",
    38 => x"00FA",
    39 => x"00F8",
    40 => x"00F5",
    41 => x"00F3",
    42 => x"00F0",
    43 => x"00ED",
    44 => x"00EA",
    45 => x"00E6",
    46 => x"00E2",
    47 => x"00DE",
    48 => x"00DA",
    49 => x"00D5",
    50 => x"00D0",
    51 => x"00CB",
    52 => x"00C6",
    53 => x"00C1",
    54 => x"00BC",
    55 => x"00B6",
    56 => x"00B0",
    57 => x"00AA",
    58 => x"00A5",
    59 => x"009E",
    60 => x"0098",
    61 => x"0092",
    62 => x"008C",
    63 => x"0086",
    64 => x"0080",
    65 => x"0079",
    66 => x"0073",
    67 => x"006D",
    68 => x"0067",
    69 => x"0061",
    70 => x"005A",
    71 => x"0055",
    72 => x"004F",
    73 => x"0049",
    74 => x"0043",
    75 => x"003E",
    76 => x"0039",
    77 => x"0034",
    78 => x"002F",
    79 => x"002A",
    80 => x"0025",
    81 => x"0021",
    82 => x"001D",
    83 => x"0019",
    84 => x"0015",
    85 => x"0012",
    86 => x"000F",
    87 => x"000C",
    88 => x"000A",
    89 => x"0007",
    90 => x"0005",
    91 => x"0004",
    92 => x"0002",
    93 => x"0001",
    94 => x"0001",
    95 => x"0000",
    96 => x"0000",
    97 => x"0000",
    98 => x"0001",
    99 => x"0001",
    100 => x"0002",
    101 => x"0004",
    102 => x"0005",
    103 => x"0007",
    104 => x"000A",
    105 => x"000C",
    106 => x"000F",
    107 => x"0012",
    108 => x"0015",
    109 => x"0019",
    110 => x"001D",
    111 => x"0021",
    112 => x"0025",
    113 => x"002A",
    114 => x"002F",
    115 => x"0034",
    116 => x"0039",
    117 => x"003E",
    118 => x"0043",
    119 => x"0049",
    120 => x"004F",
    121 => x"0055",
    122 => x"005A",
    123 => x"0061",
    124 => x"0067",
    125 => x"006D",
    126 => x"0073",
    127 => x"0079"
    );
    
    signal index : integer range 0 to 127 := 0;
    signal running : std_logic := '0';
    
begin
    process(clk)
    begin
        if rising_edge(clk) then
            if enable = '1' then
                running <= '1';
            end if;
            
            if running = '1' then
                sample_out <= signal_rom(index);
                sample_idx <= index;
            end if;
            
            if index = 127 then
                done <= '1';
                running <= '0';
            else
                index <= index + 1;
                done <= '0';
            end if;
        end if;
    end process;
           
end Behavioral;