library IEEE;
use IEEE.Std_logic_1164.all;
use IEEE.Numeric_Std.all;

entity decoder_coordinate_tb is
end;

architecture bench of decoder_coordinate_tb is

    component decoder_ram is
        generic (
            CLK_FREQ       : integer                 := 100000000; -- Default : 100 MHz
            byte_per_pixel : integer range 1 to 2    := 2;
            width          : integer range 80 to 160 := 160;
            height         : integer range 60 to 128 := 120);
        port (
            clk   : in std_logic;
            reset : in std_logic;

            new_image : in std_logic;
            new_data  : in std_logic;
            data_in   : in std_logic_vector (7 downto 0);

            addr     : in std_logic_vector (14 downto 0); -- Cover all size for raw image (13 bit to 16 bit)
            data_out : out std_logic_vector (8 * byte_per_pixel - 1 downto 0));
    end component;

    constant byte_per_pixel : integer := 2;

    signal clk       : std_logic;
    signal reset     : std_logic;
    signal new_image : std_logic;
    signal new_data  : std_logic;
    signal data_in   : std_logic_vector (7 downto 0);
    signal addr      : std_logic_vector(14 downto 0);
    signal data_out  : std_logic_vector (8 * byte_per_pixel - 1 downto 0);

    constant clock_period : time := 10 ns;

    signal i : integer := 0;

begin

    -- Insert values for generic parameters !!
    uut : decoder_coordinate generic map(
        byte_per_pixel => byte_per_pixel,
        width          => 10,
        height         => 10)
    port map(
        clk   => clk,
        reset => reset,

        new_image => new_image,
        new_data  => new_data,
        data_in   => data_in,

        addr     => addr,
        data_out => data_out);

    stimulus : process
    begin

        -- Put initialisation code here

        reset     <= '1';
        new_image <= '0';
        new_data  <= '0';
        data_in   <= (others => '0');
        wait for 15 ns;
        reset <= '0';
        wait for 5 ns;

        new_image <= '1';
        wait for clock_period;
        --new_image <= '0';
        wait for 4 * clock_period;

        while i < 100 loop
            new_data <= '1';
            data_in  <= "11111000";
            wait for clock_period;

            new_data <= '0';
            wait for 4 * clock_period;

            new_data <= '1';
            data_in  <= "00011111";
            wait for clock_period;

            i <= i + 1;

            new_data <= '0';
            wait for 4 * clock_period;

        end loop;

        addr <= to_unsigned(29, 15);

        while i < 200 loop
            new_data <= '1';
            data_in  <= "00000111";
            wait for clock_period;

            new_data <= '0';
            wait for 4 * clock_period;

            new_data <= '1';
            data_in  <= "11100000";
            wait for clock_period;

            i <= i + 1;

            new_data <= '0';
            wait for 4 * clock_period;

        end loop;

        -- Put test bench stimulus code here

        wait;
    end process;

    clocking : process
    begin
        while true loop
            clk <= '0', '1' after clock_period / 2;
            wait for clock_period;
        end loop;
        wait;
    end process;

end;