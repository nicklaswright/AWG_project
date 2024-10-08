function [byte1, byte2] = byte_split(value)
%This function takes a 14 bit binary input and splits it into
% two separate 7-bit words

bin_word = dec2bin(value, 16);              % Convert into binary representation
bin_word = mat2cell(bin_word, 1, [8, 8]);   % Split by row (1) into two 1-by-8 arrays and store in cell

word_1 = bin_word(1);
word_2 = bin_word(2);

% Convert back to decimal and return values
byte1 = bin2dec(word_1);
byte2 = bin2dec(word_2);
end