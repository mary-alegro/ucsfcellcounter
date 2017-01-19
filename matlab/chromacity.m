function [r g b] = chromacity(img)

%
% IMG: must be uint8
%

img = double(img);

R = img(:,:,1);
G = img(:,:,2);
B = img(:,:,3);

% r = 255*(R./(R+G+B));
% g = 255*(G./(R+G+B));
% b = 255*(B./(R+G+B));

r = (R./(R+G+B));
g = (G./(R+G+B));
b = (B./(R+G+B));

