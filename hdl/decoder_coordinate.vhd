library IEEE;
use IEEE.STD_LOGIC_1164.all;
use IEEE.NUMERIC_STD.all;
entity decoder_coordinate is
    generic (
        CLK_FREQ       : integer              := 100000000; -- default : 100MHz 
        byte_per_pixel : integer range 1 to 2 := 2; -- default : 16-bit image
        width          : integer              := 80; -- Width of the picture according to cam config
        height         : integer              := 60); -- Height of the picture according to cam config
    port (
        clk   : in std_logic;
        reset : in std_logic;

        new_image   : in std_logic;
        new_data_in : in std_logic;
        data_in     : in std_logic_vector (7 downto 0);

        new_data_out : out std_logic;
        data_out     : out std_logic_vector (8 * byte_per_pixel - 1 downto 0);
        X_coord      : out std_logic_vector (7 downto 0);
        Y_coord      : out std_logic_vector (6 downto 0));
end decoder_coordinate;

architecture Behavioral of decoder_coordinate is

    --------------------------------------------------------------------------
    -- signals relative to an image
    --------------------------------------------------------------------------
    signal render             : std_logic                             := '0'; -- Enable rendering when new_image = '1'
    signal pixel_cnt          : integer range 0 to width * height - 1 := 0; -- Count the number of pixel treated
    signal new_data_to_output : std_logic                             := '0'; -- Make new_data_out an impulse

    --------------------------------------------------------------------------
    -- signals relative to the current pixel
    --------------------------------------------------------------------------
    signal new_pixel : std_logic := '0'; -- High when a new pixel is completed
    -- Coordinate
    signal X_pos : integer range 0 to width - 1  := 0; -- pixel X coordinate
    signal Y_pos : integer range 0 to height - 1 := 0; -- pixel Y coordinate
    -- Color
    signal i_pixel_buffer : std_logic_vector(8 * byte_per_pixel - 1 downto 0) := (others => '0');

    signal pos_tempo : std_logic := '0';

begin

    -- Start / Stop rendering
    Rendering : process (clk)
    begin
        if clk'event and clk = '1' then
            if reset = '1' then
                render <= '0';
            elsif pixel_cnt = width * height - 1 then
                render <= '0';
            elsif new_image = '1' then
                render <= '1';
            end if;
        end if;
    end process;
    -- Get new byte
    Get_byte : process (clk)
    begin
        if clk'event and clk = '1' then
            if reset = '1' or render = '0' then
                i_pixel_buffer <= (others => '0');
            elsif render = '1' then
                if new_data_in = '1' then
                    case byte_per_pixel is
                        when 1 => i_pixel_buffer <= data_in;
                        when 2 => i_pixel_buffer <= i_pixel_buffer(7 downto 0) & data_in;
                    end case;
                end if;
            end if;
        end if;
    end process;
    -- New pixel trigger
    New_pixel_trig : process (clk)
    begin
        if clk'event and clk = '1' then
            if reset = '1' or render = '0' then
                new_pixel <= '0';
            elsif render = '1' then
                case byte_per_pixel is
                    when 1 => new_pixel <= '1';
                    when 2 =>   if new_data_in = '1' then
                                    new_pixel <= not(new_pixel);
                                end if;
                end case;
            end if;
        end if;
    end process;

    -- pixel counter
    Pixel_counter : process (clk)
    begin
        if clk'event and clk = '1' then
            if reset = '1' or render = '0' then
                pixel_cnt <= 0;
                pos_tempo <= '0';
            elsif render = '1' then
                if new_data_in = '1' and new_pixel = '1' and pos_tempo = '0' then
                    pos_tempo <= '1';
                elsif new_data_in = '1' and new_pixel = '1' and pos_tempo = '1' then
                    if pixel_cnt = width * height - 1 then
                        pixel_cnt <= 0;
                        pos_tempo <= '0';
                    else
                        pixel_cnt <= pixel_cnt + 1;
                    end if;
                end if;
            end if;
        end if;
    end process;
    process (clk)
    begin
        if clk'event and clk = '1' then
            if reset = '1' or render = '0' then
                new_data_out       <= '0';
                new_data_to_output <= '0';
            elsif render = '1' then
                if new_data_in = '1' and new_pixel = '1' and new_data_to_output = '0' then
                    new_data_out       <= '1';
                    new_data_to_output <= '1';
                elsif new_data_in = '0' and new_data_to_output = '1' then
                    new_data_out       <= '0';
                    new_data_to_output <= '0';
                else
                    new_data_out <= '0';
                end if;
            end if;
        end if;
    end process;

    data_out <= i_pixel_buffer;
    ---------------------------------------------------------
    --
    --      Pixel coordinate managment
    --
    ---------------------------------------------------------

    X_coord <= std_logic_vector(to_unsigned(X_pos, 8));
    Y_coord <= std_logic_vector(to_unsigned(Y_pos, 7));

    -- X and Y counters
    Coordinate_cnt : process (clk)
    begin
        if clk'event and clk = '1' then
            if reset = '1' or render = '0' then
                X_pos <= 0;
                Y_pos <= 0;
            elsif render = '1' then
                if new_pixel = '1' and new_data_in = '1' and pos_tempo = '1' then
                    if X_pos = width - 1 then
                        X_pos <= 0;
                        if Y_pos = height - 1 then
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
    end process;


end Behavioral;