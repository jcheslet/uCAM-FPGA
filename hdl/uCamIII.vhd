library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;


entity uCamIII is
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
end uCamIII;

architecture Behavioral of uCamIII is

   --------------------------------------------------------------------------
   -- functions
   --------------------------------------------------------------------------
    function set_WIDTH( RESOLUTION : integer ;
                        MODE       : integer )
             return integer is

        variable WIDTH : integer;
    begin
        if MODE = 0 or MODE = 1 then -- raw  : 0 => 80x60;   1 => 160x120; 2 => 128x128; 3 => 128x96.
            case RESOLUTION is
                when 0 => WIDTH :=  80;
                when 1 => WIDTH := 160;
                when 2 => WIDTH := 128;
                when 3 => WIDTH := 128;
                when others => null;
            end case;
        elsif MODE = 2 then          -- jpeg : 0 => 160x128; 1 => 320x240; 2 => 640x480.
            case RESOLUTION is
                when 0 => WIDTH := 160;
                when 1 => WIDTH := 320;
                when 2 => WIDTH := 640;
                when others => null;
            end case;
        end if;

        return WIDTH;
    end function;

    function set_HEIGHT( RESOLUTION : integer ;
                         MODE       : integer ) 
             return integer is

        variable HEIGHT : integer;
    begin
        if MODE = 0 or MODE = 1 then -- raw  : 0 => 80x60;   1 => 160x120; 2 => 128x128; 3 => 128x96.
            case RESOLUTION is
                when 0 => HEIGHT :=  60;
                when 1 => HEIGHT := 120;
                when 2 => HEIGHT := 128;
                when 3 => HEIGHT := 96;
                when others => null;
            end case;
        elsif MODE = 2 then          -- jpeg : 0 => 160x128; 1 => 320x240; 2 => 640x480.
            case RESOLUTION is
                when 0 => HEIGHT := 128;
                when 1 => HEIGHT := 240;
                when 2 => HEIGHT := 480;
                when others => null;
            end case;
        end if;

        return HEIGHT;
    end function;

    function set_init_parameter( RESOLUTION : integer;
                                 MODE       : integer )
             return std_logic_vector is

        variable init_parameter    : std_logic_vector( 23 downto 0 );
        variable format, raw, jpeg : std_logic_vector(  7 downto 0 );
    begin
        case MODE is
            when 0 => format := x"06";
            when 1 => format := x"03";
            when 2 => format := x"07";
            when others => null;
        end case;
        
        if MODE = 0 or MODE = 1 then
            jpeg := x"00";
            case RESOLUTION is
                when 0 => raw := x"01";
                when 1 => raw := x"03";
                when 2 => raw := x"09";
                when 3 => raw := x"0B";
                when others => null;
            end case;
        elsif MODE = 2 then
            raw := x"00";
            case RESOLUTION is
                when 0 => jpeg := x"03";
                when 1 => jpeg := x"05";
                when 2 => jpeg := x"07";
                when others => null;
            end case;
        end if;

        init_parameter := format & raw & jpeg;

        return init_parameter;
    end function;

    function set_get_picture_parameter( RESOLUTION      : integer ;
                                        MODE            : integer;
                                        enable_snapshot : std_logic )
             return std_logic_vector is

        variable get_picture_parameter : std_logic_vector( 7 downto 0 );
    begin

        if enable_snapshot = '1' then
            get_picture_parameter := x"01";
        else
            case MODE is
                when 2      => get_picture_parameter := x"05";
                when others => get_picture_parameter := x"02";
            end case;
        end if;

        return get_picture_parameter;
    end function;

    function set_snapshot_parameter( RESOLUTION : integer ;
                                     MODE       : integer )
             return std_logic_vector is

        variable snapshot_parameter : std_logic_vector( 7 downto 0 );
    begin
        if MODE = 0 then
            snapshot_parameter     := x"01";
        elsif MODE = 1 then
            snapshot_parameter     := x"01";
        else
            snapshot_parameter     := x"00";
        end if;

        return snapshot_parameter;
    end function;


   --------------------------------------------------------------------------
   -- signals(constants) to manage Resolution
   --------------------------------------------------------------------------
    constant WIDTH  : integer := set_WIDTH ( RESOLUTION => RESOLUTION, MODE => MODE );
    constant HEIGHT : integer := set_HEIGHT( RESOLUTION => RESOLUTION, MODE => MODE );
    constant PACKAGE_SIZE : integer range 64 to 512 := 512; -- internal default package size : 64. 
    
    constant enable_snapshot : std_logic := '0';

    constant init_parameter        : std_logic_vector( 23 downto 0 ) := set_init_parameter(        RESOLUTION => RESOLUTION, MODE => MODE );
    constant get_picture_parameter : std_logic_vector(  7 downto 0 ) := set_get_picture_parameter( RESOLUTION => RESOLUTION, MODE => MODE, enable_snapshot => enable_snapshot);
    constant snapshot_parameter    : std_logic_vector(  7 downto 0 ) := set_snapshot_parameter(    RESOLUTION => RESOLUTION, MODE => MODE );

   --------------------------------------------------------------------------
   -- signals to manage baudrate (Also configure commands' timeout (see below))
   --------------------------------------------------------------------------
    constant TIME_PREC     : integer := 100;
    constant clkfrequ_int  : integer := CLK_FREQU / TIME_PREC;
    constant auto_baudrate : integer :=    921600 / TIME_PREC; -- auto-baud detect :  921600 ( => max auto-baud detect for uCAM )
    constant high_baudrate : integer :=   3686400 / TIME_PREC; -- max-baudrate     : 3686400
    signal   baudrate_int  : integer range auto_baudrate to high_baudrate := auto_baudrate; -- uart baudrate

   --------------------------------------------------------------------------
   -- Main FSM associadted signals
   --------------------------------------------------------------------------
    type t_fsm is ( hw_reset, hw_reset_dly, sync, stabilize_2s, init, set_baudrate, set_baudrate_dly,
                    set_packages_size, idle, set_options, set_light, set_sleep,
                    snapshot, snapshot_dly, get_picture, short_sync );

    signal state                : t_fsm := hw_reset;

    -- Main FSM output signals
    signal generic_command : std_logic := '0';
    signal command         : std_logic_vector( 39 downto 0 ) := (others => '0');
    
   --------------------------------------------------------------------------
   -- TIMERS
   --------------------------------------------------------------------------
    constant HW_RESET_TIMER     : integer := CLK_FREQU * 4 / 5; -- 800ms
    constant BAUDRATE_DLY       : integer := CLK_FREQU / 2000;  -- 500us
    constant SYNC_RETRIES_TIMER : integer := CLK_FREQU /   20;  -- 50ms
    constant STABILIZE_TIMER    : integer := 2 * CLK_FREQU;     -- 2s
    constant READ_COMMAND_TIMER : integer := CLK_FREQU /   10;  -- 100ms
    constant SHUTTER_TIMER      : integer := CLK_FREQU /    4;  -- 250ms
    constant TAKE_PICTURE_TIMER : integer := 2 * CLK_FREQU;     -- 2s

    signal cnt           : integer range 0 to TAKE_PICTURE_TIMER := 0; -- Max is calculed according to the 
    signal timeout_timer : integer range 0 to TAKE_PICTURE_TIMER := 0; -- longest timer
    signal timeout       : std_logic := '0';

   --------------------------------------------------------------------------
   -- FSM sync command
   --------------------------------------------------------------------------
    type t_sync_fsm is ( off, send, read_ack, compare_ack, compare_ack_dly, read_sync, compare_sync, compare_sync_dly, 
                         send_ack, end_sync, issue );
    signal sync_state : t_sync_fsm := off;
    signal sync_retry_cnt : integer range 0 to 127 := 0;

   --------------------------------------------------------------------------
   -- FSM generic command
   --------------------------------------------------------------------------
    type t_gen_com_fsm is ( off, send, read_ack, compare_ack, compare_ack_dly, end_gen, issue );
    signal gene_state : t_gen_com_fsm := off;

   --------------------------------------------------------------------------
   -- get_picture command
   --------------------------------------------------------------------------
    type t_pict_fsm is ( off, send, read_ack, compare_ack, compare_ack_dly, read_data, compare_data, compare_data_dly,
                         get_data, send_ack, send_JPEG_ack, get_JPEG_data, send_JPEG_last_ack, end_pict, issue );
    signal pict_state : t_pict_fsm := off;
    
    --constant IMAGE_SIZE : integer := WIDTH * HEIGHT * BYTES_PER_PIXEL;
    constant MAX_SIZE    : integer := WIDTH * HEIGHT * BYTES_PER_PIXEL; -- note : max jpeg image size => 600 packages (maybe not enough in some rare cases)
    signal image_size    : integer range 0 to MAX_SIZE := 1;
    signal pict_byte_cnt : integer range 0 to MAX_SIZE := 0;
    
    signal package_cnt      : unsigned( 15 downto 0 ) := (others => '0');
    signal package_byte_cnt : integer range 0 to PACKAGE_SIZE := 0;

    -- Coordinates
    signal X_pos    : integer range 0 to WIDTH - 1  := 0;  -- pixel X coordinate
    signal Y_pos    : integer range 0 to HEIGHT - 1 := 0;  -- pixel Y coordinate
    signal temp_pos : std_logic := '0';                    -- Temporize 1 clock cycle at the beginning to update the pixel's position 
    -- Color
    signal pixel_buffer    : std_logic_vector( 8 * BYTES_PER_PIXEL - 1 downto 0 ) := (others => '0');
    signal pixel_bytes_cnt : integer range 0 to BYTES_PER_PIXEL := 0;
    
   -- Graphic RAM type to store image from uCAM-III
    type GRAM is array ( 0 to WIDTH * HEIGHT - 1) of std_logic_vector( 8 * BYTES_PER_PIXEL - 1 downto 0 );
        
    signal image       : GRAM;                                         -- Memory representation of the image
    signal ram_out_buf : std_logic_vector( 8 * BYTES_PER_PIXEL - 1 downto 0 ) := (others => '0');
    signal i_addr      : integer range 0 to width * height - 1 := 0;   -- Internal memory addr 

   --------------------------------------------------------------------------
   -- signals to parse the command to send through uart
   --------------------------------------------------------------------------
    signal byte_sent             : integer range 0 to 6 := 0;
    signal parsing_bsy           : std_logic := '0';     -- a command is being parsed and sent when '1'
    signal start_parsing_command : std_logic := '0';
    signal command_send          : std_logic_vector( 39 downto 0 ) := (others => '0');

   --------------------------------------------------------------------------
   -- Build commands signals
   --------------------------------------------------------------------------
    signal byte_read     : integer range 0 to 6 := 0;
    signal build_command : std_logic := '0';
    signal recv_command  : std_logic_vector( 47 downto 0 ) := (others => '0');

   --------------------------------------------------------------------------
   -- Compare commands signals
   --------------------------------------------------------------------------
    signal ack_ok : std_logic := '0'; -- '1' when signals compared are OK

   --------------------------------------------------------------------------
   -- signals to manage UART SEND
   --------------------------------------------------------------------------
   -- Internal signals
    signal send_div_cnt    : integer range 0 to ( clkfrequ_int + high_baudrate );
    signal send_bitcounter : integer range 0 to 10;
    signal send_shift_reg  : std_logic_vector( 8 downto 0 );
   -- Inputs & Output
    signal send_din : std_logic_vector( 7 downto 0 ) := (others => '0'); -- Byte to send through uart
    signal send_den : std_logic := '0';                                  -- '1' for 1 period to start sending send_data_in
    signal send_bsy : std_logic := '0';                                  -- '1' when thransfering a byte

   --------------------------------------------------------------------------
   -- signals to manage UART RECEIVE
   --------------------------------------------------------------------------
   -- Internal signals
    signal recv_div_cnt    : integer range -clkfrequ_int/2 to ( clkfrequ_int + high_baudrate );
    signal recv_bitcounter : integer range 0 to 9;
    signal recv_shift_reg  : std_logic_vector( 7 downto 0 );
    signal recv_RX_sampled : std_logic;
    signal recv_new_bit    : std_logic;
   -- Outputs
    signal recv_dout       : std_logic_vector( 7 downto 0 ) := (others => '0'); -- Output byte of uart receiver
    signal recv_den        : std_logic := '0';           -- Output signal of uart receiver, high for 1 period when new date is available


begin
    ---------------------------------------------------------
    --
    --      Main command FSM
    --
    ---------------------------------------------------------

    -- FSM state update
    Main_FSM : Process( clk )
    begin
        if clk'event and clk = '1' then
            if reset = '1' then
                state <= hw_reset;
            elsif sync_state = issue or gene_state = issue or pict_state = issue then
                state <= hw_reset;
            else
                case state is
                    when hw_reset           =>                                   state <= hw_reset_dly;
                    when hw_reset_dly       => if cnt = HW_RESET_TIMER      then state <= sync;              end if;
                    when sync               => if sync_state = end_sync     then state <= stabilize_2s;      end if;
                    when stabilize_2s       => if cnt = STABILIZE_TIMER     then state <= init;              end if;
                    when init               => if gene_state = end_gen      then state <= set_sleep;         end if;
                    when set_sleep          => if gene_state = end_gen      then state <= set_baudrate;      end if;
                    when set_baudrate       => if gene_state = end_gen      then state <= set_baudrate_dly;  end if;
                    when set_baudrate_dly   => if  cnt = BAUDRATE_DLY then 
                                                   if MODE = 2              then state <= set_packages_size;         -- If jpeg then set an higher packgage size
                                                   else                          state <= idle;              end if;
                                               end if;
                    when set_packages_size  => if gene_state = end_gen      then state <= idle;              end if;   

                    when idle               => if take_pict = '1'           then state <= get_picture;       end if;

                                            -- elsif set_opt = '1'             then state <= set_options;
                                            -- elsif set_slp = '1'             then state <= set_sleep;
                                            -- elsif set_lit = '1'             then state <= set_light;
                                            -- elsif take_snap = '1'           then state <= snapshot;
                                            -- elsif cnt = TAKE_PICTURE_TIMER  then state <= short_sync;        end if;

                    when get_picture        => if pict_state = end_pict     then state <= idle;              end if;

                    -- Configure the uCAM-III (not used)
                    when set_options        => if gene_state = end_gen      then state <= idle;              end if;
                    when set_light          => if gene_state = end_gen      then state <= idle;              end if;
                    when short_sync         => if sync_state = end_sync     then state <= idle;              end if;

                    when snapshot           => if gene_state = end_gen      then state <= snapshot_dly;      end if;
                    when snapshot_dly       => if cnt = SHUTTER_TIMER       then state <= idle;              end if; -- 200ms wait
                end case;
            end if;
        end if;
    end process;


    Main_FSM_output : Process( state )
    begin
        case state is
            when hw_reset | hw_reset_dly    => reset_hw         <= '0'; -- low reset
                                               uCAM_on          <= '0';
                                               available        <= '0';
                                               generic_command  <= '0';

            when sync                       => reset_hw         <= '1';
                                               uCAM_on          <= '0';
                                               available        <= '0';
                                               generic_command  <= '0';

            when short_sync                 => reset_hw         <= '1';
                                               uCAM_on          <= '1';
                                               available        <= '0';
                                               generic_command  <= '0';

            when init                       => reset_hw         <= '1';
                                               uCAM_on          <= '1';
                                               available        <= '0';
                                               generic_command  <= '1';

            when set_sleep                  => reset_hw         <= '1';
                                               uCAM_on          <= '1';
                                               available        <= '0';
                                               generic_command  <= '1';

            when set_baudrate               => reset_hw         <= '1';
                                               uCAM_on          <= '1';
                                               available        <= '0';
                                               generic_command  <= '1';

            when set_baudrate_dly           => reset_hw         <= '1';
                                               uCAM_on          <= '1';
                                               available        <= '0';
                                               generic_command  <= '0';

            when set_packages_size          => reset_hw         <= '1';
                                               uCAM_on          <= '1';
                                               available        <= '0';
                                               generic_command  <= '1';

            when idle                       => reset_hw         <= '1';
                                               uCAM_on          <= '1';
                                               available        <= '1';
                                               generic_command  <= '0';

            when get_picture                => reset_hw         <= '1';
                                               uCAM_on          <= '1';
                                               available        <= '0';
                                               generic_command  <= '0';

            -- when set_options                => reset_hw         <= '1';
            --                                    uCAM_on          <= '1';
            --                                    available        <= '0';
            --                                    generic_command  <= '1';

            -- when set_light                  => reset_hw         <= '1';
            --                                    uCAM_on          <= '1';
            --                                    available        <= '0';
            --                                    generic_command  <= '1';

            when others                     => reset_hw         <= '1';
                                               uCAM_on          <= '1';
                                               available        <= '0';
                                               generic_command  <= '0';
        end case;
    end process;


    ---------------------------------------------------------
    --
    --      COMMAND SELECTION
    --
    ---------------------------------------------------------
    Process( state, command, sync_state, pict_state, package_cnt )
    begin
        case state is
            when sync | short_sync  => if sync_state = send_ack then command <= x"0E0D000000"; -- ack
                                       else                          command <= x"0D00000000"; end if;
            when init               =>                               command <= x"0100" & init_parameter;
            when set_baudrate       =>                               command <= x"0700000000";      -- For a baud rate of 3686400.
            when set_packages_size  =>                               command <= x"0608000200";        -- For a package size of 512 bits
            when get_picture        => if pict_state = send_ack then command <= x"0E0A000000";         -- ack
                                    elsif pict_state = send_JPEG_ack
                                       or pict_state = send_JPEG_last_ack then command <= x"0E0000" & std_logic_vector( package_cnt( 7 downto 0 ) ) & std_logic_vector( package_cnt( 15 downto 8 ) );
                                       else                          command <= x"04" & get_picture_parameter & x"000000"; end if;

            when set_options        =>                               command <= x"1402000000";        -- For default values
            when set_light          =>                               command <= x"1300000000";        -- For light frequency 50Hz
            when set_sleep          =>                               command <= x"1500000000";        -- For sleep = 0s (=> no sleep)
            when snapshot           =>                               command <= x"05" & snapshot_parameter & x"000000";        -- For raw image

            when others             =>                               command <= x"0000000000";
        end case;
    end process;

    ---------------------------------------------------------
    --
    --      SYNC COMMAND
    --
    ---------------------------------------------------------
    Sync_FSM : process( clk )
    begin
        if clk'event and clk = '1' then
            if reset = '1' or state = hw_reset then
                sync_state <= off;
            else
                case sync_state is
                    when off              => if state = sync or state = short_sync then sync_state <= send;            end if;
                    when send             => if byte_sent = 6                      then sync_state <= read_ack;        end if;
                    when read_ack         => if byte_read = 6                      then sync_state <= compare_ack;
                                          elsif sync_retry_cnt = 127               then sync_state <= issue;                   --issue
                                          elsif cnt >= SYNC_RETRIES_TIMER          then sync_state <= send;            end if; -- sync failed
                    when compare_ack      =>                                            sync_state <= compare_ack_dly; 
                    when compare_ack_dly  => if ack_ok = '1'                       then sync_state <= read_sync;
                                             else                                       sync_state <= issue;           end if; --issue
                    when read_sync        => if byte_read = 6                      then sync_state <= compare_sync;    
                                          elsif timeout = '1'                      then sync_state <= issue;           end if; --issue
                    when compare_sync     =>                                            sync_state <= compare_sync_dly;   
                    when compare_sync_dly => if ack_ok = '1'                       then sync_state <= send_ack;
                                             else                                       sync_state <= issue;           end if; --issue
                    when send_ack         => if byte_sent = 6                      then sync_state <= end_sync;        end if;
                    when end_sync         =>                                            sync_state <= off;
                    when issue            =>                                            sync_state <= off;                     --issue
                end case;
            end if;
        end if;
    end process;

    -- Count number of retries to reset hardware if sync doesn't work
    Process( clk )
    begin
        if clk'event and clk = '1' then
            if reset = '1' or state = hw_reset or sync_state = off then
                sync_retry_cnt <= 0;
            elsif cnt >= SYNC_RETRIES_TIMER then
                if sync_retry_cnt = 127 then
                    sync_retry_cnt <= 0;
                else
                    sync_retry_cnt <= sync_retry_cnt + 1;
                end if;
            end if;
        end if;
    end process;

    ---------------------------------------------------------
    --
    --      INIT, SET_BAUDRATE, ... COMMAND  -> GENERIC BLOCK
    --
    ---------------------------------------------------------
    Generic_command_FSM : process( clk )
    begin
        if clk'event and clk = '1' then
            if reset = '1' or state = hw_reset then
                gene_state <= off;
            else
                case gene_state is
                    when off             => if generic_command = '1' then gene_state <= send;            end if;
                    when send            => if byte_sent = 6         then gene_state <= read_ack;        end if;
                    when read_ack        => if byte_read = 6         then gene_state <= compare_ack;
                                         elsif timeout = '1'         then gene_state <= issue;           end if; --issue
                    when compare_ack     =>                               gene_state <= compare_ack_dly;
                    when compare_ack_dly => if ack_ok = '1'          then gene_state <= end_gen;
                                            else                          gene_state <= issue;           end if; --issue
                    when end_gen         =>                               gene_state <= off;
                    when issue           =>                               gene_state <= off;
                end case;
            end if;
        end if;
    end process;

    ---------------------------------------------------------
    --
    --      GET_PICTURE RAW COMMAND
    --
    ---------------------------------------------------------
    Get_picture_FSM : process( clk )
    begin
        if clk'event and clk = '1' then
            if reset = '1' or state = hw_reset then
                pict_state <= off;
            else
                case pict_state is
                    when off              => if state = get_picture        then pict_state <= send;             end if;
                    when send             => if byte_sent = 6              then pict_state <= read_ack;         end if;
                    when read_ack         => if byte_read = 6              then pict_state <= compare_ack;
                                          elsif timeout = '1'              then pict_state <= issue;            end if; -- issue
                    when compare_ack      =>                                    pict_state <= compare_ack_dly; 
                    when compare_ack_dly  => if ack_ok = '1'               then pict_state <= read_data;
                                             else                               pict_state <= issue;            end if; -- issue
                    when read_data        => if byte_read = 6              then pict_state <= compare_data;
                                          elsif timeout = '1'              then pict_state <= issue;            end if; -- issue
                    when compare_data     =>                                    pict_state <= compare_data_dly;
                    when compare_data_dly => if ack_ok = '1' and MODE /= 2 then pict_state <= get_data;
                                          elsif ack_ok = '1' and MODE = 2  then pict_state <= send_JPEG_ack;
                                             else                               pict_state <= issue;            end if; -- issue
                    -- RAW images
                    when get_data         => if pict_byte_cnt = image_size then pict_state <= send_ack;
                                          elsif timeout = '1'              then pict_state <= issue;            end if; -- issue
                    when send_ack         => if byte_sent = 6              then pict_state <= end_pict;         end if;
                    -- JPEG images
                    when send_JPEG_ack    => if byte_sent = 6              then pict_state <= get_JPEG_data; end if;
                    when get_JPEG_data    => if   pict_byte_cnt  = image_size + 2   
                                             or ( pict_byte_cnt >= image_size 
                                            and package_byte_cnt = PACKAGE_SIZE)then pict_state <= send_JPEG_last_ack;
                                          elsif package_byte_cnt = PACKAGE_SIZE then pict_state <= send_JPEG_ack;
                                          elsif timeout = '1'                   then pict_state <= issue;       end if; -- issue
                    when send_JPEG_last_ack => if byte_sent = 6            then pict_state <= end_pict;         end if;
                    -- End of gene_fsm
                    when end_pict         =>                                    pict_state <= off;
                    when issue            =>                                    pict_state <= off;                      -- issue
                end case;
            end if;
        end if;
    end process;

    -- Byte counter for image data
    Process( clk )
    begin
        if clk'event and clk = '1' then
            if reset = '1' or state = hw_reset then
                pict_byte_cnt    <= 0;
                package_byte_cnt <= 0;
            -- RAW bytes counter
            elsif pict_state = get_data then
                if pict_byte_cnt = image_size then
                    pict_byte_cnt <= 0;
                elsif recv_den = '1' then
                    pict_byte_cnt <= pict_byte_cnt + 1;
                end if;
            -- JPEG bytes counters
            elsif pict_state = send_JPEG_last_ack then
                pict_byte_cnt    <= 0;
                package_byte_cnt <= 0;
            elsif ( pict_state = get_JPEG_data or pict_state = send_JPEG_ack ) then
                if package_byte_cnt = PACKAGE_SIZE then
                    package_byte_cnt <= 0;
                elsif recv_den = '1' and package_byte_cnt > 3 and package_byte_cnt < PACKAGE_SIZE - 2 then
                    pict_byte_cnt    <= pict_byte_cnt + 1;
                    package_byte_cnt <= package_byte_cnt + 1;
                elsif recv_den = '1' then
                    package_byte_cnt <= package_byte_cnt + 1;
                end if;
            else
                pict_byte_cnt    <= 0;
                package_byte_cnt <= 0;
            end if;
        end if;
    end process;

    JPEG_manag : Process( clk )
    begin
        if clk'event and clk = '1' then
            if reset = '1' or state = hw_reset then
                package_cnt <= (others => '0');
            elsif pict_state = off then
                package_cnt <= (others => '0');
            elsif package_byte_cnt = PACKAGE_SIZE then
                package_cnt <= package_cnt + 1;
            end if;
        end if;   
    end process;

    ---------------------------------------------------------
    --
    --      TIMER HANDLER / COUNTER
    --
    ---------------------------------------------------------
    Process( state, sync_state, gene_state, pict_state, timeout_timer )
    begin
        if state = hw_reset_dly then
            timeout_timer <= HW_RESET_TIMER;  -- 800ms
        elsif state = stabilize_2s then
            timeout_timer <= STABILIZE_TIMER; -- 2s
        elsif state = set_baudrate_dly then
            timeout_timer <= BAUDRATE_DLY;    -- 500us
        elsif sync_state = read_ack then
            timeout_timer <= SYNC_RETRIES_TIMER;
        elsif sync_state = read_sync or gene_state = read_ack or pict_state = read_ack then
            timeout_timer <= READ_COMMAND_TIMER;   -- 100ms
        elsif pict_state = read_data then
                timeout_timer <= SHUTTER_TIMER;  -- 250ms
        elsif pict_state = get_data or pict_state = get_JPEG_data or pict_state = send_JPEG_ack then
            timeout_timer <= TAKE_PICTURE_TIMER;   -- 2s
        -- elsif state = snapshop_dly then
        --     timeout_timer <= SHUTTER_TIMER;  -- 250ms
        else
            timeout_timer <= 0;
        end if;
    end process;

    Process( clk )
    begin
        if clk'event and clk = '1' then
            if reset = '1' or state = hw_reset then
                cnt     <= 0;
                timeout <= '0';
            elsif timeout = '1' then
                cnt     <= 0;
                timeout <= '0';
            elsif state = hw_reset_dly       or
                  state = stabilize_2s       or
                  state = set_baudrate_dly   or
                  sync_state = read_ack      or
                  sync_state = read_sync     or
                  gene_state = read_ack      or
                  pict_state = read_ack      or
                  pict_state = read_data     or
                  pict_state = get_data      or 
                  pict_state = get_JPEG_data or
                  pict_state = send_JPEG_ack then

                    if cnt >= timeout_timer then
                        cnt <= 0;
                        timeout <= '1';
                    else
                        cnt     <= cnt + 1;
                        timeout <= '0';
                    end if;
            else
                cnt     <= 0;
                timeout <= '0';
            end if;
        end if;
    end process;


    ---------------------------------------------------------
    --
    --      Regroup signals
    --
    ---------------------------------------------------------
    start_parsing_command <= '1' when ( gene_state = send
                                   or pict_state = send
                                   or pict_state = send_ack
                                   or pict_state = send_JPEG_ack
                                   or pict_state = send_JPEG_last_ack
                                   or sync_state = send
                                   or sync_state = send_ack ) and byte_sent < 6 else
                             '0';

    build_command <= '1' when gene_state = read_ack
                           or pict_state = read_ack
                           or sync_state = read_ack
                           or sync_state = read_sync
                           or gene_state = send
                           or pict_state = send
                           or pict_state = read_data else
                     '0';

    ---------------------------------------------------------
    --
    --      SELECT BYTE TO SEND
    --
    ---------------------------------------------------------
    Process( clk )
    begin
        if clk'event and clk ='1' then
            if reset = '1' or state = hw_reset then
                byte_sent    <= 0;
                command_send <= (others => '0');
                parsing_bsy  <= '0';
            elsif parsing_bsy = '0' then
                if start_parsing_command = '1' and send_bsy = '0' then
                    parsing_bsy  <= '1';
                    send_din     <= x"AA";
                    command_send <= command;
                    send_den     <= '1';
                    byte_sent    <= 1;
                else
                    parsing_bsy <= '0';
                    send_den    <= '0';
                end if;
            else
                if byte_sent = 6 then
                    byte_sent   <= 0;
                    parsing_bsy <= '0';
                else
                    if send_bsy = '0' and send_den = '0' then
                        send_din     <= command_send( 39 downto 32 );
                        command_send <= command_send( 31 downto 0 ) & (7 downto 0 => '0' );
                        send_den     <= '1';
                        byte_sent    <= byte_sent + 1;
                    else
                        send_den <= '0';
                    end if;
                end if;
            end if;
        end if;
    end process;

    ---------------------------------------------------------
    --
    --      Build command (receiver)
    --
    ---------------------------------------------------------
    process(clk)
    begin
        if clk'event and clk='1' then
            if reset = '1' or state = hw_reset then
                byte_read    <= 0;
                recv_command <= (others => '0');
            else
                if build_command = '1' then
                    if byte_read = 6 then
                        byte_read    <= 0;
                    elsif recv_den ='1' then
                        recv_command <= recv_command( 39 downto 0 ) & recv_dout;
                        byte_read    <= byte_read + 1;
                    end if;
                else
                    byte_read    <= 0;
                end if;
            end if;
        end if;
    end process;

    ---------------------------------------------------------
    --
    --      Compare command
    --
    ---------------------------------------------------------
    Process( clk )
    begin
        if clk'event and clk = '1' then
            if reset = '1' or state = hw_reset then
                ack_ok     <= '0';
                image_size <= 0;
            -- image data managment
            elsif pict_state = compare_data or pict_state = compare_data_dly then
                if recv_command( 47 downto 24 ) = x"AA0A" & command( 31 downto 24 ) then
                    ack_ok     <= '1';
                    image_size <= to_integer( unsigned( recv_command( 7 downto 0 ) ) & unsigned( recv_command( 15 downto 8 ) ) & unsigned( recv_command( 23 downto 16 ) ) );
                else
                    ack_ok <= '0';
                end if;
            -- Sync managment
            elsif sync_state = compare_sync or sync_state = compare_sync_dly then
                if recv_command = x"AA0D00000000"  then
                    ack_ok <= '1';
                else
                    ack_ok <= '0';
                end if;
            -- Ack managment
            elsif sync_state = compare_ack or gene_state = compare_ack or pict_state = compare_ack or sync_state = compare_ack_dly or gene_state = compare_ack_dly or pict_state = compare_ack_dly then
                if recv_command( 47 downto 24 ) = ( x"AA0E" & command( 39 downto 32 ) ) then
                    ack_ok <= '1';
                else 
                    ack_ok <= '0';
                end if;
            else
                ack_ok <= '0';
            end if;
        end if;
    end process;

    ---------------------------------------------------------
    --
    --      BAUDRATE MANAGEMENT
    --
    ---------------------------------------------------------
    Process( clk )
    begin
        if clk'event and clk = '1' then
            if reset = '1' or state = hw_reset then
                baudrate_int <= auto_baudrate;
            elsif state = set_baudrate_dly then
                baudrate_int <= high_baudrate;
            end if;
        end if;
    end process;

    ---------------------------------------------------------
    --
    --      UART SEND
    --
    ---------------------------------------------------------

    process( clk )
    begin
        if rising_edge( clk ) then
            if reset = '1' then
                send_bitcounter <= 0;
                send_div_cnt    <= 0;
                send_shift_reg  <= (8 downto 0 => '1');
                send_bsy        <= '0';
            elsif send_bitcounter=0 then
                if send_den = '1' then
                    send_bitcounter <= 10;
                    send_div_cnt    <= baudrate_int/2;
                    send_shift_reg  <= send_din & '0';
                    send_bsy        <= '1';
                else
                    send_bsy        <= '0';
                end if;
            elsif send_div_cnt >= clkfrequ_int then
                send_div_cnt    <= send_div_cnt - clkfrequ_int + baudrate_int;
                send_bitcounter <= send_bitcounter - 1;
                send_shift_reg  <= '1' & send_shift_reg(8 downto 1);
                if send_bitcounter = 1 then
                    send_bsy        <= '0';
                end if;
            else
                send_div_cnt    <= send_div_cnt + baudrate_int;
            end if;
        end if;
    end process;

    TX <= send_shift_reg(0);

    ---------------------------------------------------------
    --
    --      UART RECEIVE
    --
    ---------------------------------------------------------

    process(clk)
    begin
        if rising_edge(clk) then
            recv_RX_sampled <= RX;
            if reset = '1' then
                recv_bitcounter <= 0;
                recv_div_cnt    <= 0;
                recv_new_bit    <= '0';
            elsif recv_bitcounter=0 then
                if recv_RX_sampled = '0' then
                    recv_bitcounter <= 9;
                    recv_div_cnt    <= 3*baudrate_int + baudrate_int/2  - clkfrequ_int/2;
                end if;
                recv_new_bit    <= '0';
            elsif recv_div_cnt >= clkfrequ_int then
                recv_div_cnt    <= recv_div_cnt - clkfrequ_int + baudrate_int;
                recv_bitcounter <= recv_bitcounter - 1;
                recv_new_bit    <= '1';
            else
                recv_new_bit    <= '0';
                recv_div_cnt    <= recv_div_cnt + baudrate_int;
            end if;
        end if;
    end process;

    process(clk)
    begin
        if rising_edge(clk) then
            if reset = '1' then
                recv_shift_reg  <= (7 downto 0 => '0');
            elsif recv_new_bit = '1' then
                recv_shift_reg  <= recv_RX_sampled & recv_shift_reg(7 downto 1);
            end if;
        end if;
    end process;

    process(clk)
    begin
        if rising_edge(clk) then
            if reset = '1' then
                recv_dout   <= (7 downto 0 => '0');
                recv_den    <= '0';
            elsif recv_new_bit = '1' and recv_bitcounter = 0 then
                recv_dout   <= recv_shift_reg;
                recv_den    <= recv_RX_sampled;
            else
            recv_den    <= '0';
            end if;
        end if;
    end process;

    ---------------------------------------------------------
    --
    --      Output pixel process
    --
    ---------------------------------------------------------
    process(clk)
    begin
        if clk'event and clk='1' then
            if reset = '1' or state = hw_reset then
                Data_out        <= (others => '0');
                pixel_buffer    <= (others => '0');
                New_data        <= '0';
                pixel_bytes_cnt <= 0;
            else
                if pict_state = get_data or ( pict_state = get_JPEG_data and package_byte_cnt > 3 and package_byte_cnt < PACKAGE_SIZE - 2 ) then
                    if pixel_bytes_cnt = BYTES_PER_PIXEL then
                        pixel_bytes_cnt <= 0;
                        Data_out( 8 * BYTES_PER_PIXEL - 1 downto 0 ) <= pixel_buffer;
                        New_data        <= '1';
                    elsif recv_den = '1' then
                        case BYTES_PER_PIXEL is
                            when 1      => pixel_buffer <= recv_dout;
                            when others => pixel_buffer <= pixel_buffer( 7 downto 0 ) & recv_dout;
                        end case;
                        New_data        <= '0';
                        pixel_bytes_cnt <= pixel_bytes_cnt + 1;
                    else
                        New_data        <= '0';
                    end if;
                else
                    New_data        <= '0';
                    pixel_bytes_cnt <= 0;
                end if;
            end if;
        end if;
    end process;

    X_coord <= std_logic_vector( to_unsigned( X_pos, 8 ) );
    Y_coord <= std_logic_vector( to_unsigned( Y_pos, 7 ) );

    -- X and Y counters
    Coordinate_cnt : if COORDINATES = true generate
        Process( clk )
        begin
            if clk'event and clk = '1' then
                if reset = '1' or pict_state = off then
                    X_pos       <= 0;
                    Y_pos       <= 0;
                    temp_pos <= '0';
                elsif pict_state = get_data then
                    if pixel_bytes_cnt = BYTES_PER_PIXEL then
                        if temp_pos = '0' then
                            temp_pos <= '1';
                        else
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
                end if;
            end if;
        end process;
    end generate;

    Ram_out <= ram_out_buf;

    RAM : if INTERNAL_RAM = true generate
        process( clk )
        begin
            if clk'event and clk = '1' then
                if reset = '1' then
                    ram_out_buf <= (others => '0');
                    i_addr <=  0;
                else
                    ram_out_buf <= image( to_integer( unsigned( X_in )) + to_integer( unsigned( Y_in ) ) * 128 + to_integer( unsigned( Y_in ) ) * 32 );
                    if pict_state = get_data then
                        if pixel_bytes_cnt = BYTES_PER_PIXEL then
                            image( i_addr ) <= pixel_buffer;
                            if i_addr = WIDTH * HEIGHT - 1 then
                                i_addr <= 0;
                            else
                                i_addr <= i_addr + 1;
                            end if;
                        end if;
                    end if;
                end if;
            end if;
        end process;
    end generate;


end Behavioral;

