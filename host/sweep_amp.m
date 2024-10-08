function sweep_amp(port, steps, start_val, end_val)
% Sweeps amplitude in steps defined of "steps" from 
% "start_val" to "end_val".

AMP_CMD = 0x10;
ENABLE_CMD = 0x40;

% sweep amplitude
for i = start_val:steps:end_val
    amp = i;
     [word1, word2] = byte_split(amp);
    write(port, AMP_CMD, "uint8");
    pause(0.01);
    write(port, word1, "uint8");
    pause(0.01);
    write(port, word2, "uint8");
    pause(0.01);
    write(port, ENABLE_CMD, "uint8");
    pause(0.01);
end
pause(0.1)

for i = end_val:-steps:start_val
    amp = i;
     [word1, word2] = byte_split(amp);
    write(port, AMP_CMD, "uint8");
    pause(0.01);
    write(port, word1, "uint8");
    pause(0.01);
    write(port, word2, "uint8");
    pause(0.01);
    write(port, ENABLE_CMD, "uint8");
    pause(0.01);
end
end