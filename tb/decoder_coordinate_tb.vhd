library IEEE;
use IEEE.Std_logic_1164.all;
use IEEE.Numeric_Std.all;

entity decoder_coordinate_tb is
end;

architecture bench of decoder_coordinate_tb is

  component decoder_coordinate
      Generic( CLK_FREQ       : integer                   := 100000000;
               byte_per_pixel : integer range 1 to 2      :=         2;
               width          : integer                   :=        80;
               height         : integer                   :=        60);
      Port ( clk          : in    STD_LOGIC;
             reset        : in    STD_LOGIC;
             new_image    : in    STD_LOGIC;
             new_data_in  : in    STD_LOGIC;
             data_in      : in    STD_LOGIC_VECTOR (7 downto 0);
             new_data_out : out   STD_LOGIC;
             data_out     : out   STD_LOGIC_VECTOR (8 * byte_per_pixel - 1 downto 0);
             X_coord      : out   STD_LOGIC_VECTOR (7 downto 0);
             Y_coord      : out   STD_LOGIC_VECTOR (6 downto 0));
  end component;

  constant byte_per_pixel : integer := 2;

  signal clk: STD_LOGIC;
  signal reset: STD_LOGIC;
  signal new_image: STD_LOGIC;
  signal new_data_in: STD_LOGIC;
  signal data_in: STD_LOGIC_VECTOR (7 downto 0);
  signal new_data_out: STD_LOGIC;
  signal data_out: STD_LOGIC_VECTOR (8 * byte_per_pixel - 1 downto 0);
  signal X_coord: STD_LOGIC_VECTOR (7 downto 0);
  signal Y_coord: STD_LOGIC_VECTOR (6 downto 0);

  constant clock_period: time := 10 ns;
  
  signal i : integer := 0;
  
begin

  -- Insert values for generic parameters !!
  uut: decoder_coordinate generic map ( byte_per_pixel => byte_per_pixel,
                                        width          => 10,
                                        height         => 10)
                             port map ( clk            => clk,
                                        reset          => reset,
                                        
                                        new_image      => new_image,
                                        new_data_in    => new_data_in,
                                        data_in        => data_in,
                                        
                                        new_data_out   => new_data_out,
                                        data_out       => data_out,
                                        X_coord        => X_coord,
                                        Y_coord        => Y_coord );

  stimulus: process
  begin
  
    -- Put initialisation code here

    reset <= '1';
    new_image <= '0';
    new_data_in <= '0';
    data_in <= (others=>'0');
    wait for 15 ns;
    reset <= '0';
    wait for 5 ns;
    
    new_image <= '1';
    wait for clock_period;
    --new_image <= '0';
    wait for 4 * clock_period;
    
    while i < 100 loop
      new_data_in <= '1';
      data_in <= "11111000";
      wait for clock_period;
      
      new_data_in <= '0';
      wait for 4 * clock_period;
      
      new_data_in <= '1';
      data_in <= "00011111";
      wait for clock_period;
      
      i <= i + 1;
      
      new_data_in <= '0';
      wait for 4 * clock_period;
      
    end loop;
    

     while i < 200 loop
      new_data_in <= '1';
      data_in <= "00000111";
      wait for clock_period;
      
      new_data_in <= '0';
      wait for 4 * clock_period;
      
      new_data_in <= '1';
      data_in <= "11100000";
      wait for clock_period;
      
      i <= i + 1;
      
      new_data_in <= '0';
      wait for 4 * clock_period;
      
    end loop;

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