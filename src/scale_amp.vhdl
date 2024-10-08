-- Project      : Microwave Generator
-- Design       : Nicklas Wright
-- Verification : Nicklas Wright
-- Reviewers    : Galo Sanchez, Hampus Lang, Simon Jansson
-- Module       : scale_amp.vhd
-- Parent       : none
-- Children     : none

-- Description: amplitude control module. Fixed-point signed multiplication of input data with fraction amp_step/512, where "amp_step" is the 
-- 9-bit amplitude control input (0-511) from the host. The multiplication concatenates a '0' to the MSB of amp_step, since the scaling factor 
-- always is positive. Finally, rounding to an integer value per sample is done by the common practice of assigning the LSB of the product 
-- to the MSB of the discarded fractional bits. 

-- Input data is stored in a register, the resulting product each multiplication is stored in a register the following clock cycle, and the output signal is stored after that.
-- Given the 3 registers, a change in input data takes 3 clock cycles before the result can be read at the output register. Pipelined design, so throughput is 1/clk cycle.

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity scale_amp is
generic( DATA_WIDTH : positive := 16); 
    port ( clk         : in std_logic;
           rst         : in std_logic; 
           amp_step    : in std_logic_vector(8 downto 0); -- 0 to 511 amplitudes, 9 bits
           data_in     : in std_logic_vector(DATA_WIDTH-1 downto 0);
           data_out    : out std_logic_vector(DATA_WIDTH-1 downto 0));
end entity;

architecture arch of scale_amp is

signal scaled_input : signed(25 downto 0); -- Fixed-point: 16.0 * 1.9 = 17.9 format = 26 bits
signal data_in_reg  : std_logic_vector(DATA_WIDTH-1 downto 0);
signal amp_step_reg : std_logic_vector(8 downto 0);

begin
-- Input register
INPUT_REG: process(clk)
begin
    if (rising_edge(clk)) then
        if (rst = '1') then
            data_in_reg  <= (others => '0');
            amp_step_reg <= (others => '0');
        else
            data_in_reg  <= data_in;
            amp_step_reg <= amp_step;
        end if;
    end if;
end process INPUT_REG;

-- Product register for storing result
PRODUCT_REG: process(clk)
begin
    if (rising_edge(clk)) then
        if (rst = '1') then
            scaled_input <= (others => '0');
        else 
            scaled_input <= signed(data_in_reg) * signed('0' & amp_step_reg);   -- Effectively: data_in * amp_steps/512 (fixed-point)
        end if;
    end if;
end process PRODUCT_REG;

-- Output product register
OUTPUT_REG: process(clk) 
begin
    if (rising_edge(clk)) then
        if (rst = '1') then
            data_out <= (others => '0');
        else
            data_out <= std_logic_vector(scaled_input(24 downto 10) & scaled_input(9)); -- dump MSB (extra signed bit) and truncate to 14 integer bits
        end if;
    end if;
end process OUTPUT_REG;

end architecture;