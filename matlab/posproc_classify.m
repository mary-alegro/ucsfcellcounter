function mask_class = posproc_classify(img,mask,mask_orig)

[r c o] = size(mask);
[labels nL] = bwlabel(mask);
mask_orig = imresize(mask_orig,[r c]);

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

%reference LAB points
labR = lab_R(); %[L A B]
labG = lab_G();
labY = lab_Y();

tmp_mask = zeros(r,c);
mask_class1 = zeros(r,c);
mask_class2 = zeros(r,c);
mask_class3 = zeros(r,c);
mask_class = zeros(r,c);
for l = 1:nL
    
    D = [0 0 0];
    
    idx = find(labels == l);
    m = zeros(r,c);
    m(idx) = 1;
    m_bkp = m;
    
    m(b_dE < 0.2) = 0;
    idx = find(m == 1);
    if isempty(idx) || length(idx) < 5
        continue;
    end
    
    tmp_mask(idx) = 1;
    
    %ll = L(idx);
    aa = A(idx);
    bb = B(idx);
    
    %ml = mean(ll);
    ma = mean(aa);
    mb = mean(bb);
    
    D(1) = sqrt((labR(2)-ma)^2 + (labR(3)-mb)^2); %distance from RED
    D(2) = sqrt((labG(2)-ma)^2 + (labG(3)-mb)^2); %distance from GREEN
    D(3) = sqrt((labY(2)-ma)^2 + (labY(3)-mb)^2); %distance from YELLOW
    
    [mind class] = min(D);
    
    if class == 1 %RED
        mask_class1(m_bkp == 1) = 90;
        mask_class(m_bkp == 1) = 90;
    elseif class == 2 %GREEN
        mask_class2(m_bkp == 1) = 120;
        mask_class(m_bkp == 1) = 120;
    elseif class == 3 %YELLOW
        mask_class3(m_bkp == 1) = 200;
        mask_class(m_bkp == 1) = 200;
    end
    

end

masks = cat(3,bwperim(mask_class1),bwperim(mask_class2),bwperim(mask_class3));
colors = cat(1,[1 0 0],[0 1 0],[1 1 0]);
overlay = imoverlaymult(img, masks, colors); imshow(overlay);


end


function p = lab_R()
    p = rgb2lab([255 127 0]);
end

function p = lab_G()
    p = rgb2lab([127 255 0]);
end

function p = lab_Y()
    p = rgb2lab([255 255 0]);
end
