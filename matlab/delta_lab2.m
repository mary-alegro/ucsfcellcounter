function b_dE = delta_lab2(img,mL,mA,mB)

%IMG: original image


[r c N] = size(img);

% remove background from segmented cell region using delta LAB.
lab = rgb2lab(img);
L = lab(:,:,1); A = lab(:,:,2); B = lab(:,:,3);
meanL = mL * ones(r, c);
meanA = mA * ones(r, c);
meanB = mB * ones(r, c);
dL = L - meanL;
dA = A - meanA;
dB = B - meanB;
dE = sqrt(dL .^ 2 + dA .^ 2 + dB .^ 2);
b_dE = mat2gray(dE);
b_dE = im2double(b_dE); %background lab delta map


end

