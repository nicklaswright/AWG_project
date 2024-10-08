-- Project      : Microwave Generator
-- Design       : Nicklas Wright
-- Verification : Nicklas Wright
-- Reviewers    : Galo Sanchez, Hampus Lang, Simon Jansson
-- Module       : resolution_ctrl.vhd
-- Parent       : read_addr.vhd
-- Children     : none

-- Description: Resolution control module. This module assumes the waveform to be of 14-bit signed representation.
-- The user sets desired resolution, 13 bits down to 1 bit since the 14th bit is the signed bit. The module "dumps"
-- the undesired LSBs by bitmasking them with zeros. 

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity resolution_ctrl is
    generic (DATA_WIDTH : positive := 16);
    port( clk           : in std_logic; 
          rst           : in std_logic; 
          data_in       : in std_logic_vector(DATA_WIDTH-1 downto 0);
          resolution    : in std_logic_vector(3 downto 0);
          data_out      : out std_logic_vector(DATA_WIDTH-1 downto 0));
end entity;

architecture arch of resolution_ctrl is

type look_up_table is array (0 to DATA_WIDTH-2) of std_logic_vector(DATA_WIDTH-2 downto 0); -- Ignore MSB since signed representation
signal data_in_reg  : std_logic_vector(DATA_WIDTH-1 downto 0);
signal bits         : integer range 0 to DATA_WIDTH;

constant bit_mask : look_up_table := ( "100000000000000",
                                       "110000000000000",
                                       "111000000000000",
                                       "111100000000000",
                                       "111110000000000",
                                       "111111000000000",
                                       "111111100000000",
                                       "111111110000000",
                                       "111111111000000",
                                       "111111111100000",
                                       "111111111110000",
                                       "111111111111000",
                                       "111111111111100",
                                       "111111111111110",
                                       "111111111111111") ;
begin

INPUT_REG: process(clk)
begin
    if (rising_edge(clk)) then
        if (rst = '1') then
            data_in_reg <= (others => '0');
            bits        <= 1;
        else 
            bits        <= to_integer(unsigned(resolution));
            data_in_reg <= data_in;
        end if;
    end if;
end process INPUT_REG;

OUTPUT_REG: process(clk)
begin
    if rising_edge(clk) then
        if (rst = '1') then
            data_out <= (others => '0');
        else
            if (bits > 0) then
                -- Dump LSBs, ignore signed bit
                data_out <= data_in_reg(DATA_WIDTH-1) & (data_in_reg(DATA_WIDTH-2 downto 0) AND bit_mask(bits-1));
            else
                data_out <= (others => '0');
            end if;
        end if;
    end if;
end process;

end architecture;