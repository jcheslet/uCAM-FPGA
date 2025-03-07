library IEEE;
use IEEE.STD_LOGIC_1164.all;
use IEEE.NUMERIC_STD.all;

-- use IEEE.math_real."ceil";
-- use IEEE.math_real."log2";

-- Add a clear memory option ?
entity decoder_ram is
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
end decoder_ram;

architecture Behavioral of decoder_ram is

    -- Graphic RAM type to store image from uCAM-III
    type GRAM is array (0 to width * height - 1) of std_logic_vector(8 * byte_per_pixel - 1 downto 0);

    signal image         : GRAM; -- Memory representation of the image
    signal i_addr        : integer range 0 to width * height - 1             := 0; -- Internal memory addr 
    signal i_data        : std_logic_vector(8 * byte_per_pixel - 1 downto 0) := (others => '0');
    signal write         : std_logic                                         := '0'; -- Write i_data in memory when i_data is ready
    signal write_impulse : std_logic                                         := '0'; -- Make write signal an impulse

    --------------------------------------------------------------------------
    -- signals relative to the current image
    --------------------------------------------------------------------------
    signal render    : std_logic := '0'; -- '1' when an image is being transmitted
    signal new_pixel : std_logic := '0'; -- '1' to increment pixel coordinate when pixel info is complete (for 16bits pixels)

begin

    -- Start/Stop rendering
    process (clk)
    begin
        if clk'event and clk = '1' then
            if reset = '1' then
                render <= '0';
            elsif i_addr = width * height - 1 then
                render <= '0';
            elsif new_image = '1' then
                render <= '1';
            end if;
        end if;
    end process;

    -- New pixel trigger
    New_pixel_trig : process (clk)
    begin
        if clk'event and clk = '1' then
            if reset = '1' then
                new_pixel <= '0';
            elsif render = '0' then
                new_pixel <= '0';
            elsif render = '1' then
                case byte_per_pixel is
                    when 1 => new_pixel <= '1';
                    when 2 =>   if new_data = '1' then
                                    new_pixel <= not(new_pixel);
                                end if;
                end case;
            end if;
        end if;
    end process;

    -- Pixel counter
    ADDR_counter : process (clk)
    begin
        if clk'event and clk = '1' then
            if reset = '1' or render = '0' then
                i_addr <= 0;
            elsif render = '1' then
                if new_data = '1' and new_pixel = '1' then
                    if i_addr = width * height - 1 then
                        i_addr <= 0;
                    else
                        i_addr <= i_addr + 1;
                    end if;
                end if;
            end if;
        end if;
    end process;

    ---------------------------------------------------------
    --
    --      Pixel data management
    --
    ---------------------------------------------------------

    -- Get new byte
    Get_byte : process (clk)
    begin
        if clk'event and clk = '1' then
            if reset = '1' then
                i_data <= (others => '0');
            elsif render = '1' then
                if new_data = '1' then
                    case byte_per_pixel is
                        when 1 => i_data <= data_in;
                        when 2 => i_data <= i_data(7 downto 0) & data_in;
                    end case;
                end if;
            end if;
        end if;
    end process;

    ---------------------------------------------------------
    --
    --      RAM management
    --
    ---------------------------------------------------------
    Enable_write : process (clk)
    begin
        if clk'event and clk = '1' then
            if reset = '1' then
                write         <= '0';
                write_impulse <= '0';
            elsif new_data = '1' and new_pixel = '1' and write_impulse = '0' then
                write         <= '1';
                write_impulse <= '1';
            elsif new_data = '0' and write_impulse = '1' then
                write         <= '0';
                write_impulse <= '0';
            else
                write <= '0';
            end if;
        end if;
    end process;
    -- Acces RAM / image memory
    -- Double acces : - first one to write pixel data into memory
    --                - second one to allow the user to read the image however he wants (can't modify it) 
    process (clk)
    begin
        if clk'event and clk = '1' then
            data_out <= image(to_integer(unsigned(addr)));
            if write = '1' then
                image(i_addr) <= i_data;
            end if;
        end if;
    end process;

end Behavioral;