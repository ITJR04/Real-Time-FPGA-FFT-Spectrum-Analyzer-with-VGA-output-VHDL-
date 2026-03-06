library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;



entity signal_capture is
    Port (
        clk          : in  std_logic;  -- system/sample clock
        reset        : in  std_logic;
        enable       : in  std_logic;  -- start/continue streaming frame

        sample_out   : out std_logic_vector(15 downto 0);
        sample_idx   : out integer range 0 to 127;
        sample_valid : out std_logic;
        sample_last  : out std_logic
    );
end signal_capture;

architecture Behavioral of signal_capture is

    type signal_rom_type is array(0 to 127) of std_logic_vector(15 downto 0);
    constant signal_rom : signal_rom_type := (
        0 => x"0080",  1 => x"0086",  2 => x"008C",  3 => x"0092",
        4 => x"0098",  5 => x"009E",  6 => x"00A5",  7 => x"00AA",
        8 => x"00B0",  9 => x"00B6", 10 => x"00BC", 11 => x"00C1",
        12 => x"00C6", 13 => x"00CB", 14 => x"00D0", 15 => x"00D5",
        16 => x"00DA", 17 => x"00DE", 18 => x"00E2", 19 => x"00E6",
        20 => x"00EA", 21 => x"00ED", 22 => x"00F0", 23 => x"00F3",
        24 => x"00F5", 25 => x"00F8", 26 => x"00FA", 27 => x"00FB",
        28 => x"00FD", 29 => x"00FE", 30 => x"00FE", 31 => x"00FF",
        32 => x"00FF", 33 => x"00FF", 34 => x"00FE", 35 => x"00FE",
        36 => x"00FD", 37 => x"00FB", 38 => x"00FA", 39 => x"00F8",
        40 => x"00F5", 41 => x"00F3", 42 => x"00F0", 43 => x"00ED",
        44 => x"00EA", 45 => x"00E6", 46 => x"00E2", 47 => x"00DE", -- 00EA 00E6 00E2 00DE
        48 => x"00DA", 49 => x"00D5", 50 => x"00D0", 51 => x"00CB",
        52 => x"0000", 53 => x"0086", 54 => x"00A5", 55 => x"0080", -- 00c6 00c1 00BC 00B6
        56 => x"00B0", 57 => x"00AA", 58 => x"00A5", 59 => x"009E",
        60 => x"0098", 61 => x"0092", 62 => x"008C", 63 => x"0086",
        64 => x"0080", 65 => x"0079", 66 => x"0073", 67 => x"006D",
        68 => x"0067", 69 => x"0061", 70 => x"005A", 71 => x"0055",
        72 => x"004F", 73 => x"0049", 74 => x"0043", 75 => x"003E",
        76 => x"0039", 77 => x"0034", 78 => x"002F", 79 => x"002A",
        80 => x"0025", 81 => x"0021", 82 => x"001D", 83 => x"0019",
        84 => x"0015", 85 => x"0012", 86 => x"000F", 87 => x"000C",
        88 => x"00FF", 89 => x"00FF", 90 => x"00FF", 91 => x"00FF", -- 000A 0007 0005 0004
        92 => x"00FF", 93 => x"00FF", 94 => x"00FF", 95 => x"00FF", -- 0002 0001 0001 0000
        96 => x"00FF", 97 => x"00FF", 98 => x"00FF", 99 => x"00FF", -- 0000 0000 0001 0001
        100 => x"0002", 101 => x"0004", 102 => x"0005", 103 => x"0007",
        104 => x"000A", 105 => x"000C", 106 => x"000F", 107 => x"0012",
        108 => x"0015", 109 => x"0019", 110 => x"001D", 111 => x"0021",
        112 => x"0025", 113 => x"002A", 114 => x"002F", 115 => x"0034",
        116 => x"0039", 117 => x"003E", 118 => x"0043", 119 => x"0049",
        120 => x"004F", 121 => x"0055", 122 => x"005A", 123 => x"0061",
        124 => x"0067", 125 => x"006D", 126 => x"0073", 127 => x"0079"
    );

    signal index   : integer range 0 to 127 := 0;
    signal running : std_logic := '0';

begin

    process(clk)
    begin
        if rising_edge(clk) then
            if reset = '1' then
                index        <= 0;
                running      <= '0';
                sample_out   <= (others => '0');
                sample_idx   <= 0;
                sample_valid <= '0';
                sample_last  <= '0';

            else
                -- default outputs each cycle unless actively streaming
                sample_valid <= '0';
                sample_last  <= '0';

                -- start streaming a frame
                if enable = '1' and running = '0' then
                    running <= '1';
                    index   <= 0;
                end if;

                if running = '1' then
                    sample_out   <= signal_rom(index);
                    sample_idx   <= index;
                    sample_valid <= '1';

                    if index = 127 then
                        sample_last <= '1';
                        running     <= '0';
                    else
                        index <= index + 1;
                    end if;
                end if;
            end if;
        end if;
    end process;

end Behavioral;