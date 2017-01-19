function I = percentile2i ( h , P )
%UNTITLED Summary of this function goes here
%   Detailed explanation goes here

%Check value of P . 
if P < 0 || P > 1
error( 'The percentile must be in the range [O, 1].')
end
% Normalized the histogram to unit area. If it is already normalized
% the following computation has no effect.
h = h/sum(h);
% Cumulative distribution . 
C = cumsum(h);
% Calculations.
idx = find(C >= P, 1, 'first');
% Subtract 1 from idx because indexing starts at 1 , but intensities % start at O.
% Also, normalize to the range [O, 1 ) .
I = (idx - 1)/(numel(h) - 1);

end

