-- Project      : Microwave Generator
-- Design       : Nicklas Wright
-- Verification : 
-- Reviewers    : Nicklas Wright, Galo Sanchez 
-- Module       : trigger.vhdl
-- Parent       : wrapper
-- Children     : none
-- Description  : Outputs a trig signal to the host when the pulse program is complete 

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity trigger is
    generic (DATA_WIDTH : positive := 16);
    port(clk            : in    std_logic;
         rst            : in    std_logic;
         pulse_done     : in    std_logic;
         start          : in    std_logic;
         rate           : in    std_logic_vector(13 downto 0);
         pulses         : in    std_logic_vector(DATA_WIDTH-1 downto 0);
         trig           : out   std_logic;
         enable         : out   std_logic);     -- Start signal for pulse width control block
end entity trigger;

architecture arch of trigger is

    constant MAX          : positive := 4098361;   -- Max counter value for repetition rate, gives 10 ms (clk_period = 2.44 ns)
    constant SCALE_FACTOR : positive := 410;       -- Scales desired wait time to roughly accurate number of clock cycles, given period = 2.44 ns

    signal program_done : std_logic;    -- Flag that is high when all pulses have been outputted
    signal trigger      : std_logic;    -- HIGH when program is finished after waiting 400 us
    signal start_count  : std_logic;    -- HIGH when program is waiting
    signal pulse_count  : integer range 0 to (2**16-1);
    signal wait_count   : integer range 0 to MAX-1;
    signal max_count    : integer range 0 to MAX-1;

 begin
    trig <= trigger;

    MAX_COUNT_REG: process(clk)
    begin
        if (rising_edge(clk)) then
            if (rst = '1') then
                max_count <= 0;
            else
                max_count <= to_integer(unsigned(rate)) * SCALE_FACTOR;
            end if;
        end if;
    end process;

    -- Counter for pulse program
    program_counter: process(clk)
    begin
        if (rising_edge(clk)) then
            if (rst = '1') then
                pulse_count <= 0;
                enable <= '0';
                program_done <= '0';
            elsif (start = '1') then
                enable <= '1';
            else
                if (pulse_done = '1') then
                    if (pulse_count = (to_integer(unsigned(pulses)))-1) then
                        pulse_count <= 0;
                        program_done <= '1';
                        enable <= '0';
                    else 
                        pulse_count <= pulse_count + 1;
                        enable <= '1';
                    end if;
                else
                    program_done <= '0';
                end if;
            end if;
        end if;
    end process program_counter;

    -- Counter for when program is done and is waiting for 400 us
    wait_proc: process(clk)
    begin
        if (rising_edge(clk)) then
            if (rst = '1') then
                wait_count <= 0;
                start_count <= '0';
                trigger <= '0';
            else
                if (program_done = '1') then
                    start_count <= '1';
                    trigger <= '0';
                elsif (start_count = '1') then
                        if (wait_count = max_count) then
                            wait_count <= 0;
                            start_count <= '0';
                            trigger <= '1';
                        else
                            wait_count <= wait_count + 1;
                            trigger <= '0';
                        end if;
                else
                    trigger <= '0';
                end if;
            end if;
        end if;
    end process wait_proc;

end architecture arch;