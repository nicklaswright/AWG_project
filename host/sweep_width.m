function sweep_width(port, steps, start_val, end_val)
WIDTH_CMD  = 0x20;
ENABLE_CMD = 0x40;

for i = start_val:steps:end_val
    tp = i;
    write(port, WIDTH_CMD, "uint8");
    pause(0.01);
    write(port, tp, "uint8");
    pause(0.01);
    write(port, ENABLE_CMD, "uint8");
    pause(1);
end

for i = end_val:-steps:start_val
    tp = i;
    write(port, WIDTH_CMD, "uint8");
    pause(0.01);
    write(port, tp, "uint8");
    pause(0.01);
    write(port, ENABLE_CMD, "uint8");
    pause(1);
end
end