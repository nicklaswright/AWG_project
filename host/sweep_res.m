function sweep_res(port, steps, start_val, end_val)
% sweep resolution in in bits from "start_val" to "end_val" in steps of
% "steps"

RES_CMD    = 0x8;
ENABLE_CMD = 0x40;

for i = start_val:steps:end_val
    bits = i;
    write(port, RES_CMD, "uint8");
    pause(0.01);
    write(port, bits, "uint8");
    pause(0.01);
    write(port, ENABLE_CMD, "uint8");
    pause(1);
end

for i = end_val:-steps:start_val
    bits = i;
    write(port, RES_CMD, "uint8");
    pause(0.01);
    write(port, bits, "uint8");
    pause(0.01);
    write(port, ENABLE_CMD, "uint8");
    pause(1);
end
end