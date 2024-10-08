function send_parameters(port, fsw, phase, res, amp, tp, pulses, rate)

% Receiver commands. Constants for decoding UART messages, one-hot. Don't change!
FREQ_CMD   = 0x2;
PHASE_CMD  = 0x4;
RES_CMD    = 0x8;
AMP_CMD    = 0x10;
WIDTH_CMD  = 0x20;
ENABLE_CMD = 0x40;
PULSES_CMD = 0x80;
RATE_CMD   = 0xC0;

% Send amplitude
[word1, word2] = byte_split(amp);
write(port, AMP_CMD, "uint8");
pause(0.01);
write(port, word1, "uint8");
pause(0.01);
write(port, word2, "uint8");
pause(0.01);

% TODO: Add sweep transmission

% Send phase index
[word1, word2] = byte_split(phase);    % Split into two 8-bit words
write(port, PHASE_CMD, "uint8");
pause(0.01);
write(port, word1, "uint8");
pause(0.01);
write(port, word2, "uint8");

% Send resolution
write(port, RES_CMD, "uint8");
pause(0.01);
write(port, res, "uint8");
pause(0.01);

% Send pulse width
write(port, WIDTH_CMD, "uint8");
pause(0.1);
write(port, tp, "uint8");
pause(0.1);

% Send frequency offset
[word1, word2] = byte_split(fsw);    % Split into two 8-bit words
write(port, FREQ_CMD, "uint8");
pause(0.1)
write(port, word1, "uint8");
pause(0.1)
write(port, word2, "uint8");
pause(0.1);

% Send number of pulses
[word1, word2] = byte_split(pulses);
pause(0.1);
write(port, PULSES_CMD, "uint8");
pause(0.1);
write(port, word1, "uint8");
pause(0.1);
write(port, word2, "uint8");
pause(0.1);

% Send repetition rate
[word1, word2] = byte_split(rate);
pause(0.01);
write(port, RATE_CMD, "uint8");
pause(0.01);
write(port, word1, "uint8");
pause(0.01);
write(port, word2, "uint8");
pause(0.01);

% Load registers in FPGA
pause(0.01);
write(port, ENABLE_CMD, "uint8");
end