library IEEE;
use IEEE.Std_logic_1164.all;
use IEEE.Numeric_Std.all;

entity uCamIII_tb is
end;

architecture bench of uCamIII_tb is

    component uCamIII is
        Generic ( CLK_FREQU       : integer              := 100000000;     -- default : 100MHz.
                  MODE            : integer range 0 to 2 :=         0;     -- 0: raw RGB ; 1: raw Gray ; 2: jpeg.
                  RESOLUTION      : integer range 0 to 3 :=         0;     -- raw  : 0 => 80x60;   1 => 160x120; 2 => 128x128; 3 => 128x96.
                                                                           -- jpeg : 0 => 160x128; 1 => 320x240; 2 => 640x480.
                  BYTES_PER_PIXEL : integer range 1 to 2 :=         2; 
                  COORDINATES     : boolean              :=      true;
                  INTERNAL_RAM    : boolean              :=     false);
        Port ( clk          : in  STD_LOGIC;
               reset        : in  STD_LOGIC;
    
               -- uCAM signals
               Rx           : in  STD_LOGIC;
               reset_hw     : out STD_LOGIC;
               Tx           : out STD_LOGIC;
    
               uCAM_on      : out STD_LOGIC;    -- High when uCAM is on/working
               available    : out STD_LOGIC;    -- High when uCAM can be commanded
               take_pict    : in  STD_LOGIC;
    
               LED          : out STD_LOGIC_VECTOR ( 13 downto 0 );
    
               -- Pixel
               New_data     : out STD_LOGIC;
               Data_out     : out STD_LOGIC_VECTOR ( 8 * BYTES_PER_PIXEL - 1 downto 0 );
    
               -- Coordinate interface
               X_coord      : out STD_LOGIC_VECTOR ( 7 downto 0 );
               Y_coord      : out STD_LOGIC_VECTOR ( 6 downto 0 );
    
               -- RAM interface
               X_in         : in  STD_LOGIC_VECTOR ( 7 downto 0 );
               Y_in         : in  STD_LOGIC_VECTOR ( 6 downto 0 );
               Ram_out      : out STD_LOGIC_VECTOR ( 8 * BYTES_PER_PIXEL - 1 downto 0 ));
    end component;

    component UART_RECV_generic is
        Generic (CLK_FREQU : integer := 100000000;
                 BAUDRATE  : integer :=  33333333;
                 TIME_PREC : integer :=    100000;
                 DATA_SIZE : integer := 8);
        Port ( clk   : in STD_LOGIC;
               reset : in STD_LOGIC;
               RX    : in STD_LOGIC;
               dout  : out STD_LOGIC_VECTOR (DATA_SIZE - 1 downto 0);
               den   : out STD_LOGIC);
    end component;

    component UART_SEND_generic is
        Generic (CLK_FREQU : integer := 100000000;
             BAUDRATE  : integer :=  33333333;
             TIME_PREC : integer :=    100000;
             DATA_SIZE : integer := 8);
    Port ( clk   : in  STD_LOGIC;
           reset : in  STD_LOGIC;
           TX    : out STD_LOGIC;
           din   : in  STD_LOGIC_VECTOR (DATA_SIZE - 1 downto 0);
           den   : in  STD_LOGIC;
           bsy   : out STD_LOGIC);
    end component;

    ------------------------------------------------------------------------------------
    ------------------------------------------------------------------------------------

    constant CLK_FREQU       : integer              := 100000000;
    constant MODE            : integer range 0 to 2 :=         2;
    constant RESOLUTION      : integer range 0 to 3 :=         0; 
    constant BYTES_PER_PIXEL : integer range 1 to 2 :=         2; 
    constant COORDINATES     : boolean              :=      true;
    constant INTERNAL_RAM    : boolean              :=     false;

    constant BAUDRATE        : integer              :=   3686400;
    constant DATA_SIZE       : integer              :=         8;

    ------------------------------------------------------------------------------------
    ------------------------------------------------------------------------------------
    signal clk   : std_logic;
    signal reset : std_logic;

    signal Rx           : std_logic;
    signal reset_hw     : std_logic;
    signal Tx           : std_logic;

    signal uCAM_on      : std_logic;    -- High when uCAM is on/working
    signal available    : std_logic;    -- High when uCAM can be commanded
    signal take_picture    : std_logic;

    signal LED          : std_logic_vector ( 13 downto 0 );

    -- Pixel
    signal New_data     : std_logic;
    signal Data_out     : std_logic_vector ( 8 * BYTES_PER_PIXEL - 1 downto 0 );

    -- Coordinate interfac
    signal X_coord      : std_logic_vector ( 7 downto 0 );
    signal Y_coord      : std_logic_vector ( 6 downto 0 );

    -- RAM interface
    signal X_in         : std_logic_vector ( 7 downto 0 );
    signal Y_in         : std_logic_vector ( 6 downto 0 );
    signal Ram_out      : std_logic_vector ( 8 * BYTES_PER_PIXEL - 1 downto 0 );


    signal command : std_logic_vector( 47 downto 0 );

    signal RX_recv   : std_logic;
    signal dout_recv : std_logic_vector( DATA_SIZE - 1 downto 0 );
    signal den_recv  : std_logic;
    
    signal recv_cnt : integer;

    signal TX_send  : std_logic;
    signal din_send : std_logic_vector( DATA_SIZE - 1 downto 0 );
    signal den_send : std_logic;
    signal bsy_send : std_logic;
    ------------------------------------------------------------------------------------

    constant clock_period : time := 10 ns;

    signal i : integer := 0;
    signal j : integer := 0;
  
begin

  -- Insert values for generic parameters !!
    cam: uCamIII generic map ( CLK_FREQU       => CLK_FREQU,
                                 MODE            => MODE,
                                 RESOLUTION      => RESOLUTION,
                                 BYTES_PER_PIXEL => BYTES_PER_PIXEL,
                                 COORDINATES     => COORDINATES,
                                 INTERNAL_RAM    => INTERNAL_RAM)
                   port    map ( clk          => clk,
                                 reset        => reset,
    
                                 Rx           => Rx,
                                 reset_hw     => reset_hw,
                                 Tx           => Tx,
    
                                 uCAM_on      => uCAM_on,
                                 available    => available,
                                 take_pict    => take_picture,
    
                                 LED          => LED,
    
                                 New_data     => New_data,
                                 Data_out     => Data_out,
    
                                 X_coord      => X_coord,
                                 Y_coord      => Y_coord,
    
                                 X_in         => X_in,
                                 Y_in         => Y_in,
                                 Ram_out      => Ram_out);

    receiver : UART_RECV_generic generic map ( CLK_FREQU => CLK_FREQU,
                                               BAUDRATE  => BAUDRATE,
                                               TIME_PREC => 100,
                                               DATA_SIZE => DATA_SIZE)
                                 port    map ( clk   => clk,
                                               reset => reset,
                                               RX    => RX_recv,
                                               dout  => dout_recv,
                                               den   => den_recv);

    send     : UART_SEND_generic generic map ( CLK_FREQU => CLK_FREQU,
                                               BAUDRATE  => BAUDRATE,
                                               TIME_PREC => 100,
                                               DATA_SIZE => DATA_SIZE)
                                 port    map ( clk   => clk,
                                               reset => reset,
                                               TX    => TX_send,
                                               din   => din_send,
                                               den   => den_send,
                                               bsy   => bsy_send);

    Rx      <= TX_send;
    RX_recv <= TX;

    stimulus: process
    begin

    -- Put initialisation code here

    reset <= '1';
    take_picture <= '0';
    X_in <= (others => '0');
    Y_in <= (others => '0');

    command  <= (others => '0');

    recv_cnt <= 0;

    din_send <= (others => '0');
    den_send <= '0';

    wait for 15 ns;
    reset <= '0';
    wait for 5 ns;

    ----------------------------------------
    --           HW_reset
    ----------------------------------------
    --wait for 1sms;

    ----------------------------------------
    --           Sync
    ----------------------------------------
    wait for 2ms;
        wait for clock_period;
        while den_recv = '0' loop
            wait for clock_period;
        end loop;
        wait for clock_period;
        while den_recv = '0' loop
            wait for clock_period;
        end loop;
        wait for clock_period;
        while den_recv = '0' loop
            wait for clock_period;
        end loop;
        wait for clock_period;
        while den_recv = '0' loop
            wait for clock_period;
        end loop;
        wait for clock_period;
        while den_recv = '0' loop
            wait for clock_period;
        end loop;
        wait for clock_period;
        while den_recv = '0' loop
            wait for clock_period;
        end loop;
        wait for clock_period;
               
        -- SEND ACK
        command <= x"AA0E0D000000";
        wait for 2 * clock_period;
        --1
        din_send <= command( 47 downto 40 );
        den_send <= '1';
        wait for clock_period;
        den_send <= '0';
        command <= command( 39 downto 0 ) & (7 downto 0 => '0');
        while bsy_send = '1' loop
            wait for clock_period;
        end loop;
        -- 2
        din_send <= command( 47 downto 40 );
        den_send <= '1';
        wait for clock_period;
        den_send <= '0';
        command <= command( 39 downto 0 ) & (7 downto 0 => '0');
        while bsy_send = '1' loop
            wait for clock_period;
        end loop;
        --3
        din_send <= command( 47 downto 40 );
        den_send <= '1';
        wait for clock_period;
        den_send <= '0';
        command <= command( 39 downto 0 ) & (7 downto 0 => '0');
        while bsy_send = '1' loop
            wait for clock_period;
        end loop;
        -- 4
        din_send <= command( 47 downto 40 );
        den_send <= '1';
        wait for clock_period;
        den_send <= '0';
        command <= command( 39 downto 0 ) & (7 downto 0 => '0');
        while bsy_send = '1' loop
            wait for clock_period;
        end loop;
        -- 5
        din_send <= command( 47 downto 40 );
        den_send <= '1';
        wait for clock_period;
        den_send <= '0';
        command <= command( 39 downto 0 ) & (7 downto 0 => '0');
        while bsy_send = '1' loop
            wait for clock_period;
        end loop;
        -- 6
        din_send <= command( 47 downto 40 );
        den_send <= '1';
        wait for clock_period;
        den_send <= '0';
        command <= command( 39 downto 0 ) & (7 downto 0 => '0');
        while bsy_send = '1' loop
            wait for clock_period;
        end loop;

        -- SEND SYNC
        command <= x"AA0D00000000";
        wait for 100 * clock_period;
        --1
        din_send <= command( 47 downto 40 );
        den_send <= '1';
        wait for clock_period;
        den_send <= '0';
        command <= command( 39 downto 0 ) & (7 downto 0 => '0');
        while bsy_send = '1' loop
            wait for clock_period;
        end loop;
        -- 2
        din_send <= command( 47 downto 40 );
        den_send <= '1';
        wait for clock_period;
        den_send <= '0';
        command <= command( 39 downto 0 ) & (7 downto 0 => '0');
        while bsy_send = '1' loop
            wait for clock_period;
        end loop;
        --3
        din_send <= command( 47 downto 40 );
        den_send <= '1';
        wait for clock_period;
        den_send <= '0';
        command <= command( 39 downto 0 ) & (7 downto 0 => '0');
        while bsy_send = '1' loop
            wait for clock_period;
        end loop;
        -- 4
        din_send <= command( 47 downto 40 );
        den_send <= '1';
        wait for clock_period;
        den_send <= '0';
        command <= command( 39 downto 0 ) & (7 downto 0 => '0');
        while bsy_send = '1' loop
            wait for clock_period;
        end loop;
        -- 5
        din_send <= command( 47 downto 40 );
        den_send <= '1';
        wait for clock_period;
        den_send <= '0';
        command <= command( 39 downto 0 ) & (7 downto 0 => '0');
        while bsy_send = '1' loop
            wait for clock_period;
        end loop;
        -- 6
        din_send <= command( 47 downto 40 );
        den_send <= '1';
        wait for clock_period;
        den_send <= '0';
        command <= command( 39 downto 0 ) & (7 downto 0 => '0');
        while bsy_send = '1' loop
            wait for clock_period;
        end loop;

        -- RECEIVE ACK FROM MODULE
        wait for clock_period;
        while den_recv = '0' loop
            wait for clock_period;
        end loop;
        wait for clock_period;
        while den_recv = '0' loop
            wait for clock_period;
        end loop;
        wait for clock_period;
        while den_recv = '0' loop
            wait for clock_period;
        end loop;
        wait for clock_period;
        while den_recv = '0' loop
            wait for clock_period;
        end loop;
        wait for clock_period;
        while den_recv = '0' loop
            wait for clock_period;
        end loop;
        wait for clock_period;
        while den_recv = '0' loop
            wait for clock_period;
        end loop;
        wait for clock_period;


    ----------------------------------------
    --           Init
    ----------------------------------------
        
        wait for clock_period;
        while den_recv = '0' loop
            wait for clock_period;
        end loop;
        wait for clock_period;
        while den_recv = '0' loop
            wait for clock_period;
        end loop;
        wait for clock_period;
        while den_recv = '0' loop
            wait for clock_period;
        end loop;
        wait for clock_period;
        while den_recv = '0' loop
            wait for clock_period;
        end loop;
        wait for clock_period;
        while den_recv = '0' loop
            wait for clock_period;
        end loop;
        wait for clock_period;
        while den_recv = '0' loop
            wait for clock_period;
        end loop;
        wait for clock_period;

        -- SEND ACK
        command <= x"AA0E01000000";
        wait for 2 * clock_period;
        --1
        din_send <= command( 47 downto 40 );
        den_send <= '1';
        wait for clock_period;
        den_send <= '0';
        command <= command( 39 downto 0 ) & (7 downto 0 => '0');
        while bsy_send = '1' loop
            wait for clock_period;
        end loop;
        -- 2
        din_send <= command( 47 downto 40 );
        den_send <= '1';
        wait for clock_period;
        den_send <= '0';
        command <= command( 39 downto 0 ) & (7 downto 0 => '0');
        while bsy_send = '1' loop
            wait for clock_period;
        end loop;
        --3
        din_send <= command( 47 downto 40 );
        den_send <= '1';
        wait for clock_period;
        den_send <= '0';
        command <= command( 39 downto 0 ) & (7 downto 0 => '0');
        while bsy_send = '1' loop
            wait for clock_period;
        end loop;
        -- 4
        din_send <= command( 47 downto 40 );
        den_send <= '1';
        wait for clock_period;
        den_send <= '0';
        command <= command( 39 downto 0 ) & (7 downto 0 => '0');
        while bsy_send = '1' loop
            wait for clock_period;
        end loop;
        -- 5
        din_send <= command( 47 downto 40 );
        den_send <= '1';
        wait for clock_period;
        den_send <= '0';
        command <= command( 39 downto 0 ) & (7 downto 0 => '0');
        while bsy_send = '1' loop
            wait for clock_period;
        end loop;
        -- 6
        din_send <= command( 47 downto 40 );
        den_send <= '1';
        wait for clock_period;
        den_send <= '0';
        command <= command( 39 downto 0 ) & (7 downto 0 => '0');
        while bsy_send = '1' loop
            wait for clock_period;
        end loop;

        wait for 10 * clock_period;
    ----------------------------------------
    --           set_sleep
    ----------------------------------------

    ----------------------------------------
    --           set_baudrate
    ----------------------------------------

    ----------------------------------------
    --           set_package_size
    ----------------------------------------
        
        wait for clock_period;
        while den_recv = '0' loop
            wait for clock_period;
        end loop;
        wait for clock_period;
        while den_recv = '0' loop
            wait for clock_period;
        end loop;
        wait for clock_period;
        while den_recv = '0' loop
            wait for clock_period;
        end loop;
        wait for clock_period;
        while den_recv = '0' loop
            wait for clock_period;
        end loop;
        wait for clock_period;
        while den_recv = '0' loop
            wait for clock_period;
        end loop;
        wait for clock_period;
        while den_recv = '0' loop
            wait for clock_period;
        end loop;
        wait for clock_period;

        -- SEND ACK
        command <= x"AA0E06000000";
        wait for 10 * clock_period;
        --1
        din_send <= command( 47 downto 40 );
        den_send <= '1';
        wait for clock_period;
        den_send <= '0';
        command <= command( 39 downto 0 ) & (7 downto 0 => '0');
        while bsy_send = '1' loop
            wait for clock_period;
        end loop;
        -- 2
        din_send <= command( 47 downto 40 );
        den_send <= '1';
        wait for clock_period;
        den_send <= '0';
        command <= command( 39 downto 0 ) & (7 downto 0 => '0');
        while bsy_send = '1' loop
            wait for clock_period;
        end loop;
        --3
        din_send <= command( 47 downto 40 );
        den_send <= '1';
        wait for clock_period;
        den_send <= '0';
        command <= command( 39 downto 0 ) & (7 downto 0 => '0');
        while bsy_send = '1' loop
            wait for clock_period;
        end loop;
        -- 4
        din_send <= command( 47 downto 40 );
        den_send <= '1';
        wait for clock_period;
        den_send <= '0';
        command <= command( 39 downto 0 ) & (7 downto 0 => '0');
        while bsy_send = '1' loop
            wait for clock_period;
        end loop;
        -- 5
        din_send <= command( 47 downto 40 );
        den_send <= '1';
        wait for clock_period;
        den_send <= '0';
        command <= command( 39 downto 0 ) & (7 downto 0 => '0');
        while bsy_send = '1' loop
            wait for clock_period;
        end loop;
        -- 6
        din_send <= command( 47 downto 40 );
        den_send <= '1';
        wait for clock_period;
        den_send <= '0';
        command <= command( 39 downto 0 ) & (7 downto 0 => '0');
        while bsy_send = '1' loop
            wait for clock_period;
        end loop;
        
        wait for 10 * clock_period;
    ----------------------------------------
    --           Idle
    ----------------------------------------
        wait for 10 * clock_period;
        Take_picture <= '1';
        wait for 10 * clock_period;
    ----------------------------------------
    --           get_picture
    ----------------------------------------
        -- command
        
        wait for clock_period;
        while den_recv = '0' loop
            wait for clock_period;
        end loop;
        wait for clock_period;
        while den_recv = '0' loop
            wait for clock_period;
        end loop;
        wait for clock_period;
        while den_recv = '0' loop
            wait for clock_period;
        end loop;
        wait for clock_period;
        while den_recv = '0' loop
            wait for clock_period;
        end loop;
        wait for clock_period;
        while den_recv = '0' loop
            wait for clock_period;
        end loop;
        wait for clock_period;
        while den_recv = '0' loop
            wait for clock_period;
        end loop;
        wait for clock_period;

        -- ack
        -- SEND ACK
        command <= x"AA0E04000000";
        wait for 10 * clock_period;
        --1
        din_send <= command( 47 downto 40 );
        den_send <= '1';
        wait for clock_period;
        den_send <= '0';
        command <= command( 39 downto 0 ) & (7 downto 0 => '0');
        while bsy_send = '1' loop
            wait for clock_period;
        end loop;
        -- 2
        din_send <= command( 47 downto 40 );
        den_send <= '1';
        wait for clock_period;
        den_send <= '0';
        command <= command( 39 downto 0 ) & (7 downto 0 => '0');
        while bsy_send = '1' loop
            wait for clock_period;
        end loop;
        --3
        din_send <= command( 47 downto 40 );
        den_send <= '1';
        wait for clock_period;
        den_send <= '0';
        command <= command( 39 downto 0 ) & (7 downto 0 => '0');
        while bsy_send = '1' loop
            wait for clock_period;
        end loop;
        -- 4
        din_send <= command( 47 downto 40 );
        den_send <= '1';
        wait for clock_period;
        den_send <= '0';
        command <= command( 39 downto 0 ) & (7 downto 0 => '0');
        while bsy_send = '1' loop
            wait for clock_period;
        end loop;
        -- 5
        din_send <= command( 47 downto 40 );
        den_send <= '1';
        wait for clock_period;
        den_send <= '0';
        command <= command( 39 downto 0 ) & (7 downto 0 => '0');
        while bsy_send = '1' loop
            wait for clock_period;
        end loop;
        -- 6
        din_send <= command( 47 downto 40 );
        den_send <= '1';
        wait for clock_period;
        den_send <= '0';
        command <= command( 39 downto 0 ) & (7 downto 0 => '0');
        while bsy_send = '1' loop
            wait for clock_period;
        end loop;
    
        wait for 10 * clock_period;

        -- data
        command <= x"AA0A055A0400"; -- 1114 bytes
        wait for 10 * clock_period;
        --1
        din_send <= command( 47 downto 40 );
        den_send <= '1';
        wait for clock_period;
        den_send <= '0';
        command <= command( 39 downto 0 ) & (7 downto 0 => '0');
        while bsy_send = '1' loop
            wait for clock_period;
        end loop;
        -- 2
        din_send <= command( 47 downto 40 );
        den_send <= '1';
        wait for clock_period;
        den_send <= '0';
        command <= command( 39 downto 0 ) & (7 downto 0 => '0');
        while bsy_send = '1' loop
            wait for clock_period;
        end loop;
        --3
        din_send <= command( 47 downto 40 );
        den_send <= '1';
        wait for clock_period;
        den_send <= '0';
        command <= command( 39 downto 0 ) & (7 downto 0 => '0');
        while bsy_send = '1' loop
            wait for clock_period;
        end loop;
        -- 4
        din_send <= command( 47 downto 40 );
        den_send <= '1';
        wait for clock_period;
        den_send <= '0';
        command <= command( 39 downto 0 ) & (7 downto 0 => '0');
        while bsy_send = '1' loop
            wait for clock_period;
        end loop;
        -- 5
        din_send <= command( 47 downto 40 );
        den_send <= '1';
        wait for clock_period;
        den_send <= '0';
        command <= command( 39 downto 0 ) & (7 downto 0 => '0');
        while bsy_send = '1' loop
            wait for clock_period;
        end loop;
        -- 6
        din_send <= command( 47 downto 40 );
        den_send <= '1';
        wait for clock_period;
        den_send <= '0';
        command <= command( 39 downto 0 ) & (7 downto 0 => '0');
        while bsy_send = '1' loop
            wait for clock_period;
        end loop;
    
        wait for 10 * clock_period;


        -- JPEG ack
        
        wait for clock_period;
        while den_recv = '0' loop
            wait for clock_period;
        end loop;
        wait for clock_period;
        while den_recv = '0' loop
            wait for clock_period;
        end loop;
        wait for clock_period;
        while den_recv = '0' loop
            wait for clock_period;
        end loop;
        wait for clock_period;
        while den_recv = '0' loop
            wait for clock_period;
        end loop;
        wait for clock_period;
        while den_recv = '0' loop
            wait for clock_period;
        end loop;
        wait for clock_period;
        while den_recv = '0' loop
            wait for clock_period;
        end loop;
        wait for clock_period;

        -- JPEG data 1
        wait for 4 * clock_period;
        i <= 0;
        while i < 512 loop
            wait for 5 * clock_period;
            i <= i + 1;
            --1
            din_send <= x"A1";
            den_send <= '1';
            wait for clock_period;
            den_send <= '0';
            while bsy_send = '1' loop
                wait for clock_period;
            end loop;
        end loop;

        -- JPEG ack
        
        wait for clock_period;
        while den_recv = '0' loop
            wait for clock_period;
        end loop;
        wait for clock_period;
        while den_recv = '0' loop
            wait for clock_period;
        end loop;
        wait for clock_period;
        while den_recv = '0' loop
            wait for clock_period;
        end loop;
        wait for clock_period;
        while den_recv = '0' loop
            wait for clock_period;
        end loop;
        wait for clock_period;
        while den_recv = '0' loop
            wait for clock_period;
        end loop;
        wait for clock_period;
        while den_recv = '0' loop
            wait for clock_period;
        end loop;
        wait for clock_period;
        wait for 10 * clock_period;
        
        -- JPEG data 2
        i <= 0;
        wait for 4 * clock_period;
        while i < 512 loop
            wait for 5 * clock_period;
            i <= i + 1;
            din_send <= x"F6";
            den_send <= '1';
            wait for clock_period;
            den_send <= '0';
            while bsy_send = '1' loop
                wait for clock_period;
            end loop;
        end loop;

        -- JPEG ack
        
        wait for clock_period;
        while den_recv = '0' loop
            wait for clock_period;
        end loop;
        wait for clock_period;
        while den_recv = '0' loop
            wait for clock_period;
        end loop;
        wait for clock_period;
        while den_recv = '0' loop
            wait for clock_period;
        end loop;
        wait for clock_period;
        while den_recv = '0' loop
            wait for clock_period;
        end loop;
        wait for clock_period;
        while den_recv = '0' loop
            wait for clock_period;
        end loop;
        wait for clock_period;
        while den_recv = '0' loop
            wait for clock_period;
        end loop;
        wait for clock_period;
        wait for 10 * clock_period;

        -- JPEG data 3
        i <= 0;
        wait for 4 * clock_period;
        while i < 108 loop
            wait for 5 * clock_period;
            i <= i + 1;
            --1
            din_send <= x"18";
            den_send <= '1';
            wait for clock_period;
            den_send <= '0';
            while bsy_send = '1' loop
                wait for clock_period;
            end loop;
        end loop;

        -- JPEG ack
        
        wait for clock_period;
        while den_recv = '0' loop
            wait for clock_period;
        end loop;
        wait for clock_period;
        while den_recv = '0' loop
            wait for clock_period;
        end loop;
        wait for clock_period;
        while den_recv = '0' loop
            wait for clock_period;
        end loop;
        wait for clock_period;
        while den_recv = '0' loop
            wait for clock_period;
        end loop;
        wait for clock_period;
        while den_recv = '0' loop
            wait for clock_period;
        end loop;
        wait for clock_period;
        while den_recv = '0' loop
            wait for clock_period;
        end loop;
        wait for clock_period;
        wait for 10 * clock_period;

        wait;

        -- JPEG data 4
        i <= 0;
        wait for 4 * clock_period;
        while i < 512 loop
            wait for 5 * clock_period;
            i <= i + 1;
            --1
            din_send <= x"23";
            den_send <= '1';
            wait for clock_period;
            den_send <= '0';
            while bsy_send = '1' loop
                wait for clock_period;
            end loop;
        end loop;

        -- JPEG ack
        wait for clock_period;
        while den_recv = '0' loop
            wait for clock_period;
        end loop;
        wait for clock_period;
        while den_recv = '0' loop
            wait for clock_period;
        end loop;
        wait for clock_period;
        while den_recv = '0' loop
            wait for clock_period;
        end loop;
        wait for clock_period;
        while den_recv = '0' loop
            wait for clock_period;
        end loop;
        wait for clock_period;
        while den_recv = '0' loop
            wait for clock_period;
        end loop;
        wait for clock_period;
        while den_recv = '0' loop
            wait for clock_period;
        end loop;
        wait for clock_period;
        wait for 10 * clock_period;

        -- JPEG data 5
        i <= 0;
        wait for 4 * clock_period;
        while i < 512 loop
            wait for 5 * clock_period;
            i <= i + 1;
            --1
            din_send <= x"A1";
            den_send <= '1';
            wait for clock_period;
            den_send <= '0';
            while bsy_send = '1' loop
                wait for clock_period;
            end loop;
        end loop;
        

    


    wait;

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