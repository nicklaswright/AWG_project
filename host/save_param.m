function save_param(amp, phase, tp, res, f_offset)
% Stores the test parameters used for the AWG in a text file

fileID = fopen('test_parameters.txt', 'w');
fprintf(fileID, "AWG Parameters Used During Test:\n\n");
fprintf(fileID, "Amplitude (%): ");
fprintf(fileID, '%d\n', amp);
fprintf(fileID, "Pulse width (us): ");
fprintf(fileID, '%d\n', tp);
fprintf(fileID, "Phase (rad): ");
fprintf(fileID, '%d\n', phase);
fprintf(fileID, "Resolution (bits): ");
fprintf(fileID, '%d\n', res);
fprintf(fileID, "Carrier offset (MHz): ");
fprintf(fileID, '%d\n', f_offset);

fclose(fileID);
end