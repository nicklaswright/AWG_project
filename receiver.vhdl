-- Project      : Microwave Generator
-- Design       : Nicklas Wright
-- Verification : Nicklas Wright, Galo Sanchez
-- Reviewers    : Galo Sanchez, Hampus Lang
-- Module       : receiver.vhdl
-- Parent       : none
-- Children     : uart_rx.vhd

-- Description: Receiver module that desciphers incoming UART messages and sends them to correct ports. The module consists of two FSMs, one that handles 
-- the control parameters received, and one for handling the loading of the waveform memory. A UART message should always be preceeded by a 7-bit command
-- which tells the FSMs which operation should be performed, followed by the actual data. When waveform data should be loaded the load signal is set
-- to HIGH and the parameter FSM halts, while the second FSM leaves its IDLE state. The "busy" signal is set to HIGH, and is only set to LOW when the entire
-- waveform has been loaded, which depends on the number of samples (needs to be specified before synthesis). One sample (16 bits) is clocked out every clock period
-- from this module, and the "load" output signal is HIGH during this time. Once all desired parameters and/or waveform have
-- been recieved, an ENABLE command should be sent which tells the program so set the "ready" signal to HIGH, and all signals are loaded to output registers synchronously. 


library ieee;
use ieee.std_logic_1164.all;
use ieee.std_logic_misc.all;
use ieee.numeric_std.all;

entity receiver is
    generic(DATA_WIDTH : positive := 16);
    port( clk           : in std_logic;
          rst           : in std_logic;
          uart_rxd_rx   : in std_logic;                     -- UART wire
          load          : out std_logic;                    -- Flag for loading waveform, pulled high during loading
          start         : out std_logic;                    -- High when program may start
          write_data    : out std_logic;                    -- Trig signal that is pulled high when a new 16-bit word is ready to be written to SRAM
          freq_off_dir  : out std_logic;
          freq_offset   : out std_logic_vector(9 downto 0); -- Input parameters for controller modules
          phase_idx     : out std_logic_vector(9 downto 0);
          resolution    : out std_logic_vector(3 downto 0);
          amp_step      : out std_logic_vector(8 downto 0);
          pulse_width   : out std_logic_vector(7 downto 0);
          pulses        : out std_logic_vector(DATA_WIDTH-1 downto 0);  -- Number of pulses in program
          rate          : out std_logic_vector(13 downto 0);  -- Repetition rate (us) between programs
          write_addr    : out std_logic_vector(8 downto 0);
          waveform_data : out std_logic_vector(DATA_WIDTH-1 downto 0));   
end entity receiver;


architecture receiver_arch of receiver is
-- Component declarations
    -- UART RX
    component uart is
        port (  uart_clk         : in std_logic;                     -- 100 MHz clock
                uart_rst         : in std_logic;                     -- reset
                uart_rxd_rx      : in std_logic;                     -- rx wire
                uart_rx_data     : out std_logic_vector(7 downto 0); -- caputured data
                uart_wr_en       : out std_logic);
    end component uart;

-- constants
    -- command values
    constant LOAD_CMD   : std_logic_vector(7 downto 0) := "00000001";
    constant FREQ_CMD   : std_logic_vector(7 downto 0) := "00000010";
    constant PHASE_CMD  : std_logic_vector(7 downto 0) := "00000100";
    constant RES_CMD    : std_logic_vector(7 downto 0) := "00001000";
    constant AMP_CMD    : std_logic_vector(7 downto 0) := "00010000";
    constant WIDTH_CMD  : std_logic_vector(7 downto 0) := "00100000";
    constant ENABLE_CMD : std_logic_vector(7 downto 0) := "01000000";
    constant PULSES_CMD : std_logic_vector(7 downto 0) := "10000000";
    constant RATE_CMD   : std_logic_vector(7 downto 0) := "11000000";

    -- number of waveform data samples, needs to be specified, 100 samples (200 bytes) now as test
    constant SAMPLES : positive := 409; 
    constant MAX_CNT : positive := SAMPLES-1;

-- FSMs types and signals

    -- Parameter FSM
    type state_type is (IDLE, READ_CMD, PULSE_STATE, RATE_STATE, STORE, LOAD_WAVE, FREQ, PHASE, RES, AMP, FIRST_BYTE, GET_BYTE, WAIT_BYTE, SECOND_BYTE, P_WIDTH, CHECK, COUNT, STOP, ENABLE);
    signal state, next_state : state_type;

    -- Waveform loading FSM
    signal load_state, next_load_state : state_type;

-- UART RX signals
    signal uart_wr_en   : std_logic;
    signal uart_rx_data : std_logic_vector(7 downto 0);

-- signals for received data
    signal command : std_logic_vector(7 downto 0);   

-- signals for storing controller data
    signal freq_offset_reg      : std_logic_vector(DATA_WIDTH-1  downto 0);
    signal phase_idx_reg        : std_logic_vector(DATA_WIDTH-1  downto 0);
    signal resolution_reg       : std_logic_vector(3 downto 0);
    signal amp_step_reg         : std_logic_vector(DATA_WIDTH-1 downto 0);
    signal pulse_width_reg      : std_logic_vector(7 downto 0);
    signal waveform_data_reg    : std_logic_vector(DATA_WIDTH-1 downto 0);
    signal rate_reg             : std_logic_vector(DATA_WIDTH-1 downto 0);
    signal pulses_reg           : std_logic_vector(DATA_WIDTH-1 downto 0);

-- flags for keeping track of received data 
    signal data_count       : integer range 0 to MAX_CNT;
    signal done             : std_logic;    -- High when all waveform is being loaded
    signal ready            : std_logic;    -- Flag that is high when all parameters have been loaded
    signal load_word        : std_logic;    -- Indicates new 16 bit word is ready to be loaded
    signal load_enable      : std_logic;    -- Pulled high while waveform is being loaded

    ---constant MAX_COUNT_BIN  : unsigned(8 downto 0):="110011001";
    
begin

-- Control signals
    write_data <= load_word;
    load <= load_enable;
    --start <= ready;
    start <= not load_enable;

    
 -- UART receiver component instantiation
 uart_inst: component uart
     port map( uart_clk        => clk,
               uart_rst        => rst,                      
               uart_rxd_rx     => uart_rxd_rx,                      
               uart_rx_data    => uart_rx_data,    
               uart_wr_en      => uart_wr_en );
    
-- Output register for storing signal values from FSMs
OUTPUT_REG: process(clk)
begin
    if (rising_edge(clk)) then
        if (rst = '1') then
            freq_offset   <= "0000110010";
            freq_off_dir  <= '0';
            phase_idx     <= (others => '0');
            resolution    <= "1111";
            amp_step      <= (others => '1');
            pulse_width   <= "00000001";
            waveform_data <= (others => '0');
            pulses        <= (others => '1');
            rate          <= (others => '1');
        elsif (ready = '1') then        -- Load control paramters
            freq_offset  <= freq_offset_reg(9 downto 0);
            freq_off_dir <= freq_offset_reg(10);
            phase_idx    <= phase_idx_reg (9 downto 0);
            resolution   <= resolution_reg;
            amp_step     <= amp_step_reg(8 downto 0);    -- Discard unused bits
            pulse_width  <= pulse_width_reg;
            pulses       <= pulses_reg;
            rate         <= rate_reg(13 downto 0);
        elsif (load_word = '1') then
            waveform_data  <= waveform_data_reg;   -- Load one 16-bit waveform sample
        end if;
    end if;
end process OUTPUT_REG;

-------------------------------------------------------------------------------------------------------------------------------------
-- Moore FSM for decoding incoming messages for the control parameters
-------------------------------------------------------------------------------------------------------------------------------------
SYNC_PROC: process(clk) 
begin
    if (rising_edge(clk)) then
        if (rst = '1') then
            state <= IDLE;
        else
            state <= next_state;
        end if;
    end if;
end process SYNC_PROC;

NEXT_STATE_DECODE: process(state, uart_wr_en, command, done)
begin
  --declare default state for next_state to avoid latches
    next_state <= state;

    case(state) is
        when IDLE =>
            if (uart_wr_en = '1') then
                next_state <= READ_CMD;
            end if;
        when READ_CMD =>                -- decode command
            if (uart_wr_en = '0') then  -- Wait until ready for data byte and make sure that waveform is not being loaded
                case(command) is
                    when FREQ_CMD =>
                        next_state <= FREQ;
                    when PHASE_CMD =>
                        next_state <= PHASE;
                    when RES_CMD =>
                        next_state <= RES;
                    when AMP_CMD =>
                        next_state <= AMP;
                    when WIDTH_CMD =>
                        next_state <= P_WIDTH;
                    when LOAD_CMD =>
                        next_state <= LOAD_WAVE;
                    when PULSES_CMD =>
                        next_state <= PULSE_STATE;
                    when RATE_CMD =>
                        next_state <= RATE_STATE;
                    when ENABLE_CMD  =>
                        next_state <= ENABLE;
                    when others =>
                end case;
            end if;
        when LOAD_WAVE =>
                if (done = '1') then
                    next_state <= IDLE;
                end if;
        when FREQ =>
            if (uart_wr_en = '1') then
                next_state <= WAIT_BYTE;
            end if;
        when PHASE =>
            if(uart_wr_en = '1') then
                next_state <= WAIT_BYTE;
            end if;
        when RES =>
            if(uart_wr_en = '1') then
                next_state <= STORE;
            end if;
        when AMP =>
            if (uart_wr_en = '1') then
                next_state <= WAIT_BYTE;
            end if;
        when WAIT_BYTE =>
            if (uart_wr_en = '0') then  
                next_state <= SECOND_BYTE;
            end if;
        when SECOND_BYTE =>
            if (uart_wr_en = '1') then
                next_state <= STORE;
            end if;
        when P_WIDTH =>
            if (uart_wr_en = '1') then
                next_state <= STORE;
            end if;
        when PULSE_STATE =>
            if (uart_wr_en = '1') then
                next_state <= WAIT_BYTE;
            end if;
        when RATE_STATE =>
            if (uart_wr_en = '1') then
                next_state <= WAIT_BYTE;
            end if;
        when STORE =>
            if (uart_wr_en = '0') then
                next_state <= IDLE;
            end if;
        when ENABLE =>
            next_state <= IDLE;
        when others => 
            next_state <= IDLE;
    end case;
end process NEXT_STATE_DECODE;


-- Output process, clocked to avoid latches
OUTPUT_PROC: process(clk, state)
begin
    if (rising_edge(clk)) then
        if (rst = '1') then
            freq_offset_reg <= (others => '0');
            phase_idx_reg   <= (others => '0');
            resolution_reg  <= (others => '0');
            amp_step_reg    <= (others => '0');
            pulse_width_reg <= (others => '0');
            pulses_reg      <= (others => '0');
            rate_reg        <= (others => '0');
            command <= (others => '0');
            ready <= '0';
            load_enable <= '0';
        else
            case(state) is
                when IDLE =>
                    load_enable <= '0';
                    ready <= '0';
                when READ_CMD =>
                    command <= uart_rx_data;    -- Load new command
                when LOAD_WAVE =>
                    load_enable <= '1';
                when FREQ =>
                    freq_offset_reg(DATA_WIDTH-1 downto 8) <= uart_rx_data; -- Store first byte (MSB first)
                when PHASE =>
                    phase_idx_reg(DATA_WIDTH-1 downto 8) <= uart_rx_data;
                when RES =>
                    resolution_reg <= uart_rx_data(3 downto 0);
                when AMP =>
                    amp_step_reg(DATA_WIDTH-1 downto 8) <= uart_rx_data;       -- Store first byte (MSB first)
                when SECOND_BYTE =>
                    case(command) is
                        when PULSES_CMD =>
                            pulses_reg(7 downto 0) <= uart_rx_data;
                        when RATE_CMD =>
                            rate_reg(7 downto 0) <= uart_rx_data;
                        when AMP_CMD =>
                            amp_step_reg(7 downto 0) <= uart_rx_data;  
                        when PHASE_CMD =>
                            phase_idx_reg(7 downto 0) <= uart_rx_data;  
                        when FREQ_CMD =>
                            freq_offset_reg(7 downto 0) <= uart_rx_data; 
                        when others =>
                    end case;
                when P_WIDTH =>
                    pulse_width_reg <= uart_rx_data;
                when PULSE_STATE =>
                    pulses_reg(DATA_WIDTH-1 downto 8) <= uart_rx_data;
                when RATE_STATE =>
                    rate_reg(DATA_WIDTH-1 downto 8) <= uart_rx_data;  -- Store first byte, disregard unused bits
                when ENABLE =>
                    ready <= '1';
                when others => 
                    load_enable <= '0';
            end case;
        end if;
    end if;
end process OUTPUT_PROC;

----------------------------------------------------------------------------------------------------------------------------------------------------
-- Moore FSM for loading waveform memory. Only leaves IDLE state when LOAD_CMD is read.
----------------------------------------------------------------------------------------------------------------------------------------------------
LOAD_SYNC_PROC: process(clk) 
begin
    if (rising_edge(clk)) then
        if (rst = '1') then
            load_state <= IDLE;
        else
            load_state <= next_load_state;
        end if;
    end if;
end process LOAD_SYNC_PROC;

-- Loads two bytes of data (14 bit per sample) a number of times specified by the number 
-- incoming samples
LOAD_STATE_DECODE: process(load_state, uart_wr_en, load_enable, data_count)
begin
    --declare default state for next_state to avoid latches
    next_load_state <= load_state;
    case(load_state) is
        when IDLE =>
            if (uart_wr_en = '1' AND load_enable = '1') then
                next_load_state <= FIRST_BYTE;
            end if;
        when FIRST_BYTE =>                          -- Read first byte
            if (uart_wr_en = '0') then
                next_load_state <= WAIT_BYTE;
            end if;
        when WAIT_BYTE =>
            if (uart_wr_en = '1') then
                next_load_state <= SECOND_BYTE;
            end if;
        when SECOND_BYTE =>                         -- Read second byte
            if (uart_wr_en = '0') then
                next_load_state <= CHECK;
            end if;
        when CHECK =>
            if (data_count = MAX_CNT) then          -- Check if counter done
                next_load_state <= STOP;
            else
                next_load_state <= COUNT;
            end if;
        when COUNT =>
            next_load_state <= GET_BYTE;            -- Increment counter
        when GET_BYTE =>
            if (uart_wr_en = '1') then
                next_load_state <= FIRST_BYTE;      -- Read next new first byte
            end if; 
        when STOP =>
            next_load_state <= IDLE;
        when others =>
            next_load_state <= IDLE;
    end case;
end process LOAD_STATE_DECODE;


-- Output process, clocked to avoid latches
LOAD_OUT_PROC: process(clk, load_state)
begin
    if (rising_edge(clk)) then
        if (rst = '1') then
            waveform_data_reg <= (others => '0');
            load_word <= '0';
            done <= '0';
        else
            case(load_state) is
                when IDLE =>
                    load_word <= '0';
                    waveform_data_reg <= (others => '0');
                    done <= '0';
                when FIRST_BYTE =>
                    load_word <= '0';
                    done <= '0';
                    waveform_data_reg(DATA_WIDTH-1 downto 8) <= uart_rx_data;     -- Load first byte (MSB first). 
                when SECOND_BYTE =>
                    waveform_data_reg(7 downto 0) <= uart_rx_data;      -- Load second byte
                    done <= '0';
                when COUNT =>
                    load_word <= '1';   -- increment counter
                    done <= '0';
                when GET_BYTE =>
                    load_word <= '0';
                    done <= '0';
                when STOP =>
                    done <= '1';
                when others => -- do nothing
            end case;
        end if;
    end if;
end process LOAD_OUT_PROC;

-- Counter
count_proc: process(clk)
begin
    if (rising_edge(clk)) then
        if (rst = '1') then
            data_count <= 0;
        elsif (done = '1') then
                data_count <= 0;
        elsif (load_word = '1') then
                data_count <= data_count+1;
        end if;
    end if;
end process count_proc;

write_addr <= std_logic_vector(to_unsigned(data_count,write_addr'length));
    
end architecture receiver_arch;