library IEEE;
use IEEE.STD_LOGIC_1164.all;
use IEEE.NUMERIC_STD.all;


entity triangle_filter is
    generic (
        CLK_FREQ        : integer                 := 100000000; -- Default : 100 MHz
        BYTES_PER_PIXEL : integer range 1 to 2    :=         2;
        WIDTH           : integer range 80 to 160 :=       160;
        HEIGHT          : integer range 60 to 128 :=       120);
    port ( clk   : in std_logic;
           reset : in std_logic;
   
           ucam_on     : in std_logic; -- High when ucam is on
           new_data_in : in std_logic; -- Impulse
           data_in     : in std_logic_vector (8 * BYTES_PER_PIXEL - 1 downto 0);
   
           new_data_out : out std_logic;
           data_out     : out std_logic_vector (8 * BYTES_PER_PIXEL - 1 downto 0);
           
           -- Coordinate interface
           X_coord      : out STD_LOGIC_VECTOR ( 7 downto 0 );
           Y_coord      : out STD_LOGIC_VECTOR ( 6 downto 0 ));
end triangle_filter;

architecture Behavioral of triangle_filter is

   -- RAM
    type RAM is array (2 * WIDTH + 2 downto 0 ) of std_logic_vector( 8 * BYTES_PER_PIXEL - 1 downto 0 );
    signal pixels : RAM;
   
   -- Result filter
    signal pixel_filtered : std_logic_vector( 8 * BYTES_PER_PIXEL - 1 downto 0 ) := (others => '0');

   -- Coordinates
   signal X_pos    : integer range 0 to WIDTH  - 1 := 0;  -- pixel X coordinate
   signal Y_pos    : integer range 0 to HEIGHT - 1 := 0;  -- pixel Y coordinate

   -- Pixel counter
    constant NB_PIXEL : integer := WIDTH * HEIGHT;-- + WIDTH;
    signal pxl_cnt_r  : integer range 0 to NB_PIXEL := 0;   -- count pixel receive
    signal pxl_cnt_s  : integer range 0 to NB_PIXEL := 0;   -- count pixel send back
    signal fsm        : integer range 0 to 12       := 0;
    signal fsm_tempo  : std_logic := '0';

    signal red_buffer    : unsigned( 8 downto 0  ) := (others => '0');
    signal green_buffer  : unsigned( 9 downto 0  ) := (others => '0');
    signal blue_buffer   : unsigned( 8 downto 0  ) := (others => '0');


begin


    ---------------------------------------------------------
    --
    --                       FSM
    --
    ---------------------------------------------------------
    Process( clk )
    begin
        if clk'event and clk = '1' then
            if reset = '1' or ucam_on = '0' then
                fsm     <= 0;
            else
                case fsm is
                    when  0 => if ( new_data_in = '1'                                    -- get new pixel
                              and   pxl_cnt_r > width )
                              or    pxl_cnt_r = NB_PIXEL       then fsm <=  1; end if;  
                    when  1 =>                                      fsm <=  2;          -- get pixel 1
                    when  2 =>                                      fsm <=  3;          -- get pixel 2
                    when  3 =>                                      fsm <=  4;          -- get pixel 3
                    when  4 =>                                      fsm <=  5;          -- get pixel 4
                    when  5 =>                                      fsm <=  6;          -- get pixel 5
                    when  6 =>                                      fsm <=  7;          -- get pixel 6
                    when  7 =>                                      fsm <=  8;          -- get pixel 7
                    when  8 =>                                      fsm <=  9;          -- get pixel 8
                    when  9 =>                                      fsm <= 10;          -- get pixel 9
                    when 10 =>                                      fsm <= 11;          -- calc pixel_filtered
                    when 11 => if ( pxl_cnt_r = NB_PIXEL                                -- outpute data & increase X/Y pos
                              and   pxl_cnt_s = NB_PIXEL - 1 ) then fsm <=  12;          
                              else                                  fsm <=   0; end if;
                    when 12 =>                                      fsm <=   0;          -- reset counters
                end case;
            end if;
        end if;
    end process;




    ---------------------------------------------------------
    --
    --                       RAM
    --
    ---------------------------------------------------------
    Process( clk )
    begin
        if clk'event and clk = '1' then
            if reset = '1' or ucam_on = '0' or fsm = 12 then
                pxl_cnt_r <= 0;
                pxl_cnt_s <= 0;
            elsif fsm = 0 and new_data_in = '1' then    -- a new pixel is received
                pixels( (2 * WIDTH + 2) downto 1 )  <= pixels( (2 * WIDTH + 2) - 1 downto 0 );
                pixels( 0 ) <= data_in;
                pxl_cnt_r <= pxl_cnt_r + 1;
            elsif fsm = 0 and pxl_cnt_r = NB_PIXEL then -- no new pixel
                pixels( (2 * WIDTH + 2) downto 1 )  <= pixels( (2 * WIDTH + 2) - 1 downto 0 );
                pixels( 0 ) <= (others => '0');
            elsif fsm = 11 then                         -- a new pixel is sent
                    pxl_cnt_s <= pxl_cnt_s + 1;
            end if;
        end if;
    end process;

    Process( clk )
    begin
        if clk'event and clk = '1' then
            if reset = '1' or ucam_on = '0' then
                red_buffer   <= (others => '0');
                green_buffer <= (others => '0');
                blue_buffer  <= (others => '0');
            else 
                if ( X_pos /= WIDTH - 2 and X_pos /= WIDTH - 1 and Y_pos /= 0 and Y_pos /= HEIGHT - 1 ) then -- do not apply filter on border
                    case fsm is
                        when  0 => red_buffer   <= (others => '0');
                                   green_buffer <= (others => '0');
                                   blue_buffer  <= (others => '0');

                        when  1 => red_buffer   <= red_buffer   + ("0000" & unsigned( pixels( 2 * WIDTH + 2 )( 15 downto 11 ) ));
                                   green_buffer <= green_buffer + ("0000" & unsigned( pixels( 2 * WIDTH + 2 )( 10 downto  5 ) ));
                                   blue_buffer  <= blue_buffer  + ("0000" & unsigned( pixels( 2 * WIDTH + 2 )(  4 downto  0 ) ));

                        when  2 => red_buffer   <= red_buffer   + ("000"  & unsigned( pixels( 2 * WIDTH + 1 )( 15 downto 11 ) ) & "0");
                                   green_buffer <= green_buffer + ("000"  & unsigned( pixels( 2 * WIDTH + 1 )( 10 downto  5 ) ) & "0");
                                   blue_buffer  <= blue_buffer  + ("000"  & unsigned( pixels( 2 * WIDTH + 1 )(  4 downto  0 ) ) & "0");

                        when  3 => red_buffer   <= red_buffer   + ("0000" & unsigned( pixels( 2 * WIDTH     )( 15 downto 11 ) ));
                                   green_buffer <= green_buffer + ("0000" & unsigned( pixels( 2 * WIDTH     )( 10 downto  5 ) ));
                                   blue_buffer  <= blue_buffer  + ("0000" & unsigned( pixels( 2 * WIDTH     )(  4 downto  0 ) ));

                        when  4 => red_buffer   <= red_buffer   + ("000"  & unsigned( pixels(     WIDTH + 2 )( 15 downto 11 ) ) & "0");
                                   green_buffer <= green_buffer + ("000"  & unsigned( pixels(     WIDTH + 2 )( 10 downto  5 ) ) & "0");
                                   blue_buffer  <= blue_buffer  + ("000"  & unsigned( pixels(     WIDTH + 2 )(  4 downto  0 ) ) & "0");

                        when  5 => red_buffer   <= red_buffer   + ("0"    & unsigned( pixels(     WIDTH + 1 )( 15 downto 11 ) ) & "00");
                                   green_buffer <= green_buffer + ("0"    & unsigned( pixels(     WIDTH + 1 )( 10 downto  5 ) ) & "00");
                                   blue_buffer  <= blue_buffer  + ("0"    & unsigned( pixels(     WIDTH + 1 )(  4 downto  0 ) ) & "00");

                        when  6 => red_buffer   <= red_buffer   + ("000"  & unsigned( pixels(     WIDTH     )( 15 downto 11 ) ) & "0");
                                   green_buffer <= green_buffer + ("000"  & unsigned( pixels(     WIDTH     )( 10 downto  5 ) ) & "0");
                                   blue_buffer  <= blue_buffer  + ("000"  & unsigned( pixels(     WIDTH     )(  4 downto  0 ) ) & "0");

                        when  7 => red_buffer   <= red_buffer   + ("0000" & unsigned( pixels(             2 )( 15 downto 11 ) ));
                                   green_buffer <= green_buffer + ("0000" & unsigned( pixels(             2 )( 10 downto  5 ) ));
                                   blue_buffer  <= blue_buffer  + ("0000" & unsigned( pixels(             2 )(  4 downto  0 ) ));

                        when  8 => red_buffer   <= red_buffer   + ("000"  & unsigned( pixels(             1 )( 15 downto 11 ) ) & "0");
                                   green_buffer <= green_buffer + ("000"  & unsigned( pixels(             1 )( 10 downto  5 ) ) & "0");
                                   blue_buffer  <= blue_buffer  + ("000"  & unsigned( pixels(             1 )(  4 downto  0 ) ) & "0");

                        when  9 => red_buffer   <= red_buffer   + ("0000" & unsigned( pixels(             0 )( 15 downto 11 ) ));
                                   green_buffer <= green_buffer + ("0000" & unsigned( pixels(             0 )( 10 downto  5 ) ));
                                   blue_buffer  <= blue_buffer  + ("0000" & unsigned( pixels(             0 )(  4 downto  0 ) ));
                        
                        when 10 => red_buffer   <= red_buffer;
                                   green_buffer <= green_buffer;
                                   blue_buffer  <= blue_buffer;

                        when 11 => red_buffer   <= red_buffer;
                                   green_buffer <= green_buffer;
                                   blue_buffer  <= blue_buffer;

                        when 12 => red_buffer   <= (others => '0');
                                   green_buffer <= (others => '0');
                                   blue_buffer  <= (others => '0');
                    end case;
                else
                    red_buffer   <= unsigned( pixels( WIDTH + 1 )( 15 downto 11 ) ) & "0000";
                    green_buffer <= unsigned( pixels( WIDTH + 1 )( 10 downto  5 ) ) & "0000";
                    blue_buffer  <= unsigned( pixels( WIDTH + 1 )(  4 downto  0 ) ) & "0000";
                end if;
            end if;
        end if;
    end process;

    Calc_filtered_pixel : Process( clk )
    begin
        if clk'event and clk = '1' then
            if reset = '1' or ucam_on = '0' then
                pixel_filtered <= (others => '0');
            elsif fsm = 10 then
                    pixel_filtered <= std_logic_vector( red_buffer( 8 downto 4 ) & green_buffer( 9 downto 4 ) & blue_buffer( 8 downto 4 ) );
            end if;
        end if;
    end process;


    ---------------------------------------------------------
    --
    --                      Outputs
    --
    ---------------------------------------------------------
    Process( clk )
    begin
        if clk'event and clk = '1' then
            if reset = '1' or ucam_on = '0' then
                new_data_out <= '0';
                data_out     <= (others => '0');
            elsif fsm = 11 then
                new_data_out <= '1';
                data_out     <= pixel_filtered;
            else
                new_data_out <= '0';
            end if;
        end if;
    end process;

    
    X_coord <= std_logic_vector( to_unsigned( X_pos, 8 ) );
    Y_coord <= std_logic_vector( to_unsigned( Y_pos, 7 ) );

    -- X and Y counters
    Process( clk )
    begin
        if clk'event and clk = '1' then
            if reset = '1' or ucam_on = '0' or fsm = 12 then
                X_pos       <= 0;
                Y_pos       <= 0;
            elsif fsm = 11 and pxl_cnt_s > 0 then
                if X_pos = WIDTH - 1 then
                    X_pos <= 0;
                    if Y_pos = HEIGHT - 1 then
                        Y_pos <= 0;
                    else
                        Y_pos <= Y_pos + 1;
                    end if;
                else 
                    X_pos <= X_pos + 1;
                end if;
            end if;
        end if;
    end process;


end Behavioral;
