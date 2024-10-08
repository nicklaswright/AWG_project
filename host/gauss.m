function [time, signal] = gauss(fclk, tp, n_sigma)
% Computes and returns a Gaussian envelope of N samples, determined by the clock frequency fclk.
% The plot is restricted to the width of the number of standard deviations used
% determined by n_sigma. Desired pulse width is tp. 

%% PARAMETERS
ts = 1/fclk;
N = tp/ts;                  % Number of samples that fit within tp                 
dt = tp/(N+1);              % Time step
t = -tp/2+dt:dt:tp/2-dt;    % Time vector
%% GAUSSIAN PULSE

% Calculate standard deviation
sigma = tp/(2*n_sigma);                       % Pulse width = from -(n_sigma)*sigma to +(n_sigma)*3sigma
gaussian_pulse = exp(-t.^2 / (2*sigma^2));    % PDF of Gassian distribution
t = t + tp/2;                                 % Shift up to positive time

%% Return values
signal = gaussian_pulse;
time = t;
end