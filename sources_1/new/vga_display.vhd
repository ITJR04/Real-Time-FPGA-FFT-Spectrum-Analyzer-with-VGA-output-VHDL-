
library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

entity vga_display is
  Port (
        clk         : in  std_logic;
        reset       : in  std_logic;

        pixel_x     : in  std_logic_vector(11 downto 0);
        pixel_y     : in  std_logic_vector(11 downto 0);
        video_on    : in  std_logic;

        bar_heights : in  std_logic_vector(1023 downto 0);

        red         : out std_logic_vector(3 downto 0);
        green       : out std_logic_vector(3 downto 0);
        blue        : out std_logic_vector(3 downto 0)
   );
end vga_display;

architecture Behavioral of vga_display is
    constant BAR_WIDTH      : integer := 5;
    constant SCREEN_WIDTH   : integer := 640;
    constant SCREEN_HEIGHT  : integer := 480;
begin

    process(clk)
        variable x_int        : integer;
        variable y_int        : integer;
        variable bar_index    : integer range 0 to 127;
        variable height_byte  : std_logic_vector(7 downto 0);
        variable bar_height   : integer range 0 to 255;
    begin
        if rising_edge(clk) then
            if reset = '1' then
                red   <= (others => '0');
                green <= (others => '0');
                blue  <= (others => '0');

            elsif video_on = '1' then
                x_int := to_integer(unsigned(pixel_x));
                y_int := to_integer(unsigned(pixel_y));

                bar_index := x_int / BAR_WIDTH;

                -- natural-order mapping, matching your original intent
                height_byte := bar_heights(bar_index * 8 + 7 downto bar_index * 8);
                bar_height  := to_integer(unsigned(height_byte));

                if y_int >= (SCREEN_HEIGHT - bar_height) then
                    red   <= "1111";
                    green <= "1111";
                    blue  <= "1111";
                else
                    red   <= "0000";
                    green <= "0000";
                    blue  <= "0000";
                end if;

            else
                red   <= (others => '0');
                green <= (others => '0');
                blue  <= (others => '0');
            end if;
        end if;
    end process;

end Behavioral;