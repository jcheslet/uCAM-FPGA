library IEEE;
use IEEE.Std_logic_1164.all;
use IEEE.Numeric_Std.all;

entity triangle_filter_tb is
end;

architecture bench of triangle_filter_tb is

  component triangle_filter is
    generic (
        CLK_FREQ        : integer                 := 100000000; -- Default : 100 MHz
        BYTES_PER_PIXEL : integer range 1 to 2    :=         2;
        WIDTH           : integer := 160;--range 80 to 160 :=       160;
        HEIGHT          : integer := 120);--range 60 to 128 :=       120);
    port ( clk   : in std_logic;
           reset : in std_logic;
   
           ucam_on     : in std_logic; -- High when ucam is on
           new_data_in : in std_logic; -- Impulse
           data_in     : in std_logic_vector (8 * BYTES_PER_PIXEL - 1 downto 0);
   
           new_data_out : out std_logic;
           data_out     : out std_logic_vector (8 * BYTES_PER_PIXEL - 1 downto 0);
           
           -- Coordinate interface
           --addr       : in std_logic_vector (14 downto 0); -- Cover all size for raw image (13 bit to 16 bit)
           X_coord      : out STD_LOGIC_VECTOR ( 7 downto 0 );
           Y_coord      : out STD_LOGIC_VECTOR ( 6 downto 0 ));
  end component;

  constant BYTES_PER_PIXEL : integer := 2;

  signal clk   : STD_LOGIC;
  signal reset : STD_LOGIC;

  signal ucam_on     : STD_LOGIC;
  signal new_data_in : STD_LOGIC;
  signal data_in     : STD_LOGIC_VECTOR (8 * BYTES_PER_PIXEL - 1 downto 0);

  signal new_data_out : STD_LOGIC;
  signal data_out     : STD_LOGIC_VECTOR (8 * BYTES_PER_PIXEL - 1 downto 0);

  signal X_coord : STD_LOGIC_VECTOR (7 downto 0);
  signal Y_coord : STD_LOGIC_VECTOR (6 downto 0);

  constant clock_period : time := 10 ns;
  
  signal i : integer := 0;
  signal j : integer := 0;
  
begin

  -- Insert values for generic parameters !!
  uut: triangle_filter generic    map ( BYTES_PER_PIXEL => BYTES_PER_PIXEL,
                                        WIDTH          => 80,
                                        height         => 60)
                             port map ( clk            => clk,
                                        reset          => reset,
                                        
                                        ucam_on        => ucam_on,
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
    ucam_on <= '0';
    new_data_in <= '0';
    data_in <= (others=>'0');
    wait for 15 ns;
    reset <= '0';
    wait for 5 ns;
    
    wait for 4 * clock_period;
    ucam_on <= '1';
    wait for 4 * clock_period;
    
    i <= 0;
    while i < 4800 loop
      --if (i / 10) mod 2 = 0 then
      if j <= 0 then
        j <= 1;
        data_in <= "11111" & "111111" & "11111";
      else
        j <= 0;
        data_in <= "11111" & "000000" & "00000";
      end if;
      new_data_in <= '1';
      i <= i + 1;
      wait for clock_period;
      
      new_data_in <= '0';
      wait for 20 * clock_period;
      
      -- new_data_in <= '1';
      -- data_in <= "11111" & "111111" & "11111";
      -- wait for clock_period;
      
      
      -- new_data_in <= '0';
      -- wait for 4 * clock_period;
      
    end loop;
    

    wait;

--     while i < 200 loop
--      new_data_in <= '1';
--      data_in <= "00000111";
--      wait for clock_period;
      
--      new_data_in <= '0';
--      wait for 4 * clock_period;
      
--      new_data_in <= '1';
--      data_in <= "11100000";
--      wait for clock_period;
      
--      i <= i + 1;
      
--      new_data_in <= '0';
--      wait for 4 * clock_period;
      
--    end loop;

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