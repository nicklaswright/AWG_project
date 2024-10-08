function sweep_freq_offset(port, freq_off_dir, fclk, steps, start_val, end_val)
% Sweeps the frequency offset from the carrier in steps defined by
% "steps" from "start_val" to "end_val" entered in MHz.
FREQ_CMD   = 0x2;
ENABLE_CMD = 0x40;

for i = start_val:steps:end_val
    % Convert to FSW
    fc_offset = i;
    fsw = (fc_offset*1e6*2^(10))/fclk;

    % Store freq_off_dir in MSB of freq_offset
    fsw_bin = dec2bin(fsw, 16);
    freq_off_dir_bin = dec2bin(freq_off_dir);
    freq_message = strcat(freq_off_dir_bin, fsw_bin(7:16));
    fsw = bin2dec(freq_message);

    [word1, word2] = byte_split(fsw);  % split into 2 bytes

    write(port, FREQ_CMD, "uint8");
    pause(0.01);
    write(port, word1, "uint8");
    pause(0.01);
    write(port, word2, "uint8");
    pause(0.01);
    write(port, ENABLE_CMD, "uint8");
    pause(1);
end

for i = end_val:-steps:start_val
    % Convert to FSW
    fc_offset = i;
    fsw = (fc_offset*1e6*2^(10))/fclk;

    % Store freq_off_dir in MSB of freq_offset
    fsw_bin = dec2bin(fsw, 16);
    freq_off_dir_bin = dec2bin(freq_off_dir);
    freq_message = strcat(freq_off_dir_bin, fsw_bin(7:16));
    fsw = bin2dec(freq_message);

    [word1, word2] = byte_split(fsw);  % split into 2 bytes

    write(port, FREQ_CMD, "uint8");
    pause(0.01);
    write(port, word1, "uint8");
    pause(0.01);
    write(port, word2, "uint8");
    pause(0.01);
    write(port, ENABLE_CMD, "uint8");
    pause(1);
end
end