function [x_dft, freq, fig_han] = plot_dft(X, S, varargin)
%PLOT_DFT() Plots the discrete Fourier transform with the analog frequency.
%   I always forget how to do this, so here's a function for doing it.
%   
%   PLOT_DFT(X,S) will plot the DFT of X assuming the S is an integer, and
%   that integer represents the time-domain sampling frequency of X.
% 
%   PLOT_DFT(X,T) will plot the DFT of X assuming the array T is the time
%   vector that X was sampled at. T must be the same length as X. If using
%   MATLAB 2020b or above and T vector will work. If using below that
%   version, the sampling period of T must be uniform.

below_2020b = ~strcmp(version('-release'), '2020b');

p = inputParser;
addRequired(p, 'X')
addRequired(p, 'S')
addParameter(p, 'scale', 'log', @(x) any(validatestring(x, {'log', 'linear'})))
addParameter(p, 'sided', 'two', @(x) any(validatestring(x, {'one', 'two'})))
addParameter(p, 'location', 'away', @(x) any(validatestring(x, {'zero', 'away'})))

parse(p, X, S, varargin{:})

N = length(p.Results.X); % Number of samples.

%% Find sampling period (if there is one)
if (isinteger(S) || all((mod(S, 1) == 0))) && (length(S) == 1)
    freq = p.Results.S;
else % If not given the sampling frequency
    assert(length(p.Results.S) == length(p.Results.X));
    if below_2020b
        % Tolerance cause floating-point :confounded:
        if all( abs(diff(p.Results.S) - diff(p.Results.S(1:2))) < (1E-5 * diff(p.Results.S(1:2))) )
            % If uniformly sampled, all is good.
            freq = 1 / diff(p.Results.S(1:2)); % Hz
        else
            % If non-uniform fft is not available, resample it uniformly.
            % Uses spline cause why not. Looks like poop tbh what whatever.
            [X, S] = resample(p.Results.X, p.Results.S, 'spline');
            freq = 1 / diff(p.Results.S(1:2));
        end
    end
end

%% Calculate DFT
if exist('freq', 'var')
    x_dft = fft(X);
    non_u = false;
else
    x_dft = nufft(X, S);
    non_u = true;
end

%% Create analog frequency vector.
if exist('freq', 'var')
    freq = 0:(freq / N):((N - 1) * freq / N);
else
    % I'm not sure how to calculate the analog domain of the nufft. So it
    % just slaps it to the digital frequency
    freq = 0:(1 / N):((N - 1) / N); % ??
end

%% Organize DFT for gain placement and sidedness
if strcmp(p.Results.sided, 'one')
    % One-sided DFT. Just need to smack away the right-hand side and done.
    % One-sided will put the gain at 0 no matter what.
    freq = freq(1:(floor(length(x_dft) / 2)) + 1); % Hz - adjusted domain.
    
    x_dft = fftshift(x_dft);
    x_dft = x_dft((floor(length(x_dft) / 2)) + 1:end);
    
elseif strcmp(p.Results.location, 'zero')
    % If the DC gain will be placed at zero for the two-sided, need to
    % shift.
    x_dft = fftshift(x_dft);
    
    freq = freq - freq(end)/2; % Hz - Adjusted domain. This works I think.
end

%% Plot the (magnitude) data.

fig_han = figure();

% Selects Y scale
if strcmp(p.Results.scale, 'log')
    semilogy(freq, abs(x_dft))
else
    plot(freq, abs(x_dft))
end

% If non-uniform label the x correctly
if non_u
    xlabel('Digital Frequency (F)')
else
    xlabel('Frequency (Hz)')
end

ylabel('|X[F]|')
title('Fourier transform of x[n]')
grid