-- Project      : Microwave Generator
-- Design       : Nicklas Wright
-- Verification : Nicklas Wright
-- Reviewers    : Galo Sanchez, Hampus Lang, Simon Jansson
-- Module       : counter.vhdl
-- Parent       : inc_idx.vhdl
-- Children     : none

-- Description: Counter module 

library ieee;
use ieee.std_logic_1164.all;
use ieee.std_logic_misc.all;
use ieee.numeric_std.all;

entity counter is
    port (  clk        : in std_logic;
            rst        : in std_logic;
            enable     : in std_logic;
            max_count  : in std_logic_vector(7 downto 0); -- pulse width, assumes > 1 us (otherwise clock handles indexing directly)
            trig       : out std_logic);
end counter;

architecture arch of counter is
    signal max_cnt      : unsigned(7 downto 0);
    signal count        : unsigned(7 downto 0);

begin

    -- Register for storing max count
    max_cnt_reg: process(clk) 
    begin
        if rising_edge(clk) then
            if (rst = '1') then
                max_cnt <= (others => '0');
            else
                if (max_count <= "00000001") then
                    max_cnt <= to_unsigned(2, max_cnt'length);
                else
                    max_cnt <= unsigned(max_count);
                end if;
            end if;
        end if;
    end process max_cnt_reg;

    cnt_proc: process(clk)
    begin
        if (rising_edge(clk)) then
            if (rst = '1') then
                count  <= (others =>'0');
                trig <= '0';
            else
                if (enable = '1') then
                    if (count = max_cnt-1) then
                        count <= (others => '0');
                        trig <= '1';
                     else
                        count <= count + 1;
                        trig <= '0';
                    end if;
                else 
                    trig <= '0';
                end if;
            end if;
        end if;
    end process cnt_proc;

end architecture arch;
