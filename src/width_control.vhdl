-- Project      : Microwave Generator
-- Design       : Nicklas Wright
-- Verification : Nicklas Wright
-- Reviewers    : Galo Sanchez, Hampus Lang
-- Module       : width_control.vhdl 
-- Parent       : receiver.vhdl
-- Children     : inc_idx.vhdl, counter.vhdl

-- Description: Wrapper file for the pulse width control. Pulse width minimum is 1 us, and time resolution is
-- also 1 us.

library ieee;
use ieee.std_logic_1164.all;
use ieee.std_logic_misc.all;
use ieee.numeric_std.all;

entity width_control is
    generic(DATA_WIDTH      : positive := 16;
            ADDR_LENGTH     : positive := 100);  -- Number of samples determines minimum pulse width (samples * tclk = min. pulse width)
    port( clk           : in  std_logic;
          rst           : in  std_logic;
          enable        : in  std_logic;
          pulse_width   : in  std_logic_vector(7 downto 0);
          pulse_done    : out std_logic;
          idx           : out std_logic_vector(8 downto 0));   -- Bits depend on waveform memory size
end entity width_control;

architecture width_arch of width_control is

    -- signals
    signal trig        : std_logic;
    signal count_trig  : std_logic;
    signal pulse_done_trig  : std_logic;
    signal count       : integer range 0 to ADDR_LENGTH-1;
    signal idx_temp    : std_logic_vector(8 downto 0);

    -- Component declarations
    component counter is
        port (  clk        : in  std_logic;
                rst        : in std_logic;
                enable     : in std_logic;
                max_count  : in std_logic_vector(7 downto 0);
                trig       : out std_logic);
    end component counter;

        -- Index incrementer
    component inc_idx is
        generic(ARR_SIZE   : positive := ADDR_LENGTH); 
        port (  clk             : in std_logic;
                rst             : in std_logic;
                increment       : in std_logic;
                done            : out std_logic;
                index           : out std_logic_vector(8 downto 0));
    end component inc_idx;

begin

    -- Component instantiations
    counter_inst: component counter
        port map (  clk       => clk,
                    rst       => rst,
                    enable    => enable,
                    max_count => pulse_width,
                    trig      => trig );

    inc_idx_inst: component inc_idx
        generic map(ARR_SIZE      => ADDR_LENGTH)
        port map(   clk           => clk,
                    rst           => rst, 
                    increment     => trig,
                    done          => pulse_done_trig,
                    index         => idx_temp );


------------------------------------------------------
-- Counter used for indexing if pulse width = 1 us
-------------------------------------------------------
count_proc: process(clk)
begin
    if (rising_edge(clk)) then
        if (rst = '1') then
            count <= 0;
            count_trig <= '0';
        else
            if (enable = '1') then
                if (count = ADDR_LENGTH-1) then
                    count <= 0;
                    count_trig <= '1';
                else
                    count <= count + 1;
                    count_trig <= '0';
                end if;
            end if;
        end if;
    end if;
end process count_proc;

-- Select index depending on pulse width
idx_sel: process(clk, pulse_width)
begin
    if (rising_edge(clk)) then
        if (pulse_width > "00000001") then
            idx <= idx_temp;
            pulse_done <= pulse_done_trig;
        else 
            idx <= std_logic_vector(to_unsigned(count, idx'length));
            pulse_done <= count_trig;
        end if;
    end if;
end process;

end architecture width_arch;