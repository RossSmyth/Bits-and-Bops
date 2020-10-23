function out = dft(x_input)
%DFT Discrete Fourier tranform
%    DFT(X) is the discrete Fourier transform (DFT) of vector X.
%
%	 I made this for my Digital signal Processing class and it is neat cause 
%	 it has no loops in it.
N = length(x_input);

mat = cumsum(ones(N, N)) - 1;
mat = exp(mat .* mat' * -1j * pi * 2 / N);

out = mat * x_input;
end

