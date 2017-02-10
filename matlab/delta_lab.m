function b_dE = delta_lab(img,mask,mask_orig)

%IMG: original image
%MASK: mask used for DL training

[r c N] = size(img);
[ro co No] = size(mask_orig);
if ro ~= r || co ~= c
    mask_orig = imresize(mask_orig,[r c]);
end
back_mask = ones(size(mask));
back_mask(mask == 1) = 0; %remove cells
back_mask(mask_orig == 0) = 0; %remove regions that don't belong to the ROI
back_idx = find(back_mask == 1); %get background pixel indices

% remove background from segmented cell region using delta LAB.
lab = rgb2lab(img);
L = lab(:,:,1); A = lab(:,:,2); B = lab(:,:,3);
mL = mean(L(back_idx));
mA = mean(A(back_idx));
mB = mean(B(back_idx));
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

