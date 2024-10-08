-- Project      : Microwave Generator
-- Design       : Nicklas Wright
-- Verification : Nicklas Wright
-- Reviewers    : Galo Sanchez, Hampus Lang, Simon Jansson
-- Module       : inc_idx.vhdl
-- Parent       : width_contrl.vhdl
-- Children     : counter.vhdl

-- Description: Index incrementing module. Increments index when trig signal is read from counter module. 
-- Assumes pulse width > 2 us, if 1 us is desired the clock will handle indexing directly in the wrapper file. 

-- NOTE: Resulting pulse width depends on clock frequency and number of samples in waveform memory. Default is 300 MHz clock and 300 samples,
-- which results in 1 us pulse width minimum, with 1 us time resolution.

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity inc_idx is
    generic(ARR_SIZE : positive); 
    port(  clk             : in std_logic;
           rst             : in std_logic;
           increment       : in std_logic;
           done            : out std_logic;
           index           : out std_logic_vector(8 downto 0));
end entity;


architecture arch of inc_idx is
    -- signal
    signal idx       : integer range 0 to ARR_SIZE-1;

    -- Begin architecture
begin

    out_reg: process(clk) 
    begin
        if (rising_edge(clk)) then
            if (rst = '1') then
                index <= (others => '0');
            else
                index <= std_logic_vector(to_unsigned(idx, index'length));
            end if;
        end if;
    end process out_reg;

    idx_proc: process(clk)
    begin
        if (rising_edge(clk)) then
            if (rst = '1') then
                idx <= 0;
                done <= '0';
            elsif (increment = '1') then
                if (idx = ARR_SIZE-1) then
                    idx <= 0;
                    done <= '1';
                else
                    idx <= idx + 1;
                    done <= '0';
                end if;
            else 
                done <= '0';
            end if;
        end if;
    end process idx_proc;

end architecture arch;
    