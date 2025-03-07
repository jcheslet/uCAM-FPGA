library IEEE;
use IEEE.Std_logic_1164.all;
use IEEE.Numeric_Std.all;

entity top_ucam_tb is
end;

architecture bench of top_ucam_tb is

	component top_ucam
		port (
			clk   : in std_logic;
			reset : in std_logic;

			-- PMOD oled
			CS    : out std_logic;
			MOSI  : out std_logic;
			SCK   : out std_logic;
			DC    : out std_logic;
			RES   : out std_logic;
			VCCEN : out std_logic;
			EN    : out std_logic;

			-- VGA
			VGA_hs    : out std_logic;
			VGA_vs    : out std_logic;
			VGA_red   : out std_logic_vector(3 downto 0);
			VGA_green : out std_logic_vector(3 downto 0);
			VGA_blue  : out std_logic_vector(3 downto 0);

			-- ucam
			GET_PICTURE : in std_logic;
			Rx          : in std_logic;
			Tx          : out std_logic;
			reset_cam   : out std_logic;
			LED         : out std_logic_vector(1 downto 0));
	end component;

	signal clk        : STD_LOGIC;
	signal reset      : STD_LOGIC := '0';

	signal CS         : STD_LOGIC;
	signal MOSI       : STD_LOGIC;
	signal SCK        : STD_LOGIC;
	signal DC         : STD_LOGIC;
	signal RES        : STD_LOGIC;
	signal VCCEN      : STD_LOGIC;
	signal EN         : STD_LOGIC;

	signal VGA_hs    : std_logic;
	signal VGA_vs    : std_logic;
	signal VGA_red   : std_logic_vector(3 downto 0);
	signal VGA_green : std_logic_vector(3 downto 0);
	signal VGA_blue  : std_logic_vector(3 downto 0);
	
	signal GET_PICTURE: STD_LOGIC := '0';
	signal Rx         : STD_LOGIC := '0';
	signal Tx         : STD_LOGIC;
	signal reset_cam  : STD_LOGIC;
	signal LED		  : std_logic_vector(1 downto 0);

	
	constant clock_period: time := 10 ns;
  

begin

    uut: top_ucam port map ( clk         => clk,
                             reset       => reset,

                             CS          => CS,
                             MOSI        => MOSI,
                             SCK         => SCK,
                             DC          => DC,
                             RES         => RES,
                             VCCEN       => VCCEN,
                             EN          => EN,

							 VGA_hs      => VGA_hs,
   							 VGA_vs      => VGA_vs,
   							 VGA_red     => VGA_red,
   							 VGA_green   => VGA_green,
   							 VGA_blue    => VGA_blue,

                             GET_PICTURE => GET_PICTURE,
                             Rx          => Rx,
                             Tx          => Tx,
                             reset_cam   => reset_cam,
                             LED         => LED);

	stimulus: process
	begin

		-- Put initialisation code here
		reset <= '1';
		wait for 55ns;
		reset <= '0';
		wait for clock_period;



	-- Put test bench stimulus code here

	wait;
	end process;


	clocking: process
	begin
		while true loop
			clk <= '0', '1' after clock_period / 2;
			wait for clock_period;
		end loop;
		wait;
	end process;


end;