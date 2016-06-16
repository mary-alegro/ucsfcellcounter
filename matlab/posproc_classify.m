function [mask_class mask_class1 mask_class2 mask_class3] = posproc_classify(img,mask,mask_orig,samples)

[red green yellow] = pack_samples(samples);

[r c N] = size(mask);
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

%normalizes Lab channels to [0,1] range
L = (L - min(L(:)))/(max(L(:)) - min(L(:)));
A = (A - min(A(:)))/(max(A(:)) - min(A(:)));
B = (B - min(B(:)))/(max(B(:)) - min(B(:)));

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
    
    ll = L(idx);
    aa = A(idx);
    bb = B(idx);
    
    P = [mean(ll) mean(aa) mean(bb)];

    D(1) = mahal(P,red);
    D(2) = mahal(P,green);
    D(3) = mahal(P,yellow);
   
    C = find(D == min(D));
    
    if C == 1 %RED
        mask_class1(m_bkp == 1) = 90;
        mask_class(m_bkp == 1) = 90;
    elseif C == 2 %GREEN
        mask_class2(m_bkp == 1) = 190;
        mask_class(m_bkp == 1) = 190;
    else %BLUE
        mask_class3(m_bkp == 1) = 250;
        mask_class(m_bkp == 1) = 250;
    end
   
end

masks = cat(3,bwperim(mask_class1),bwperim(mask_class2),bwperim(mask_class3));
colors = cat(1,[1 0 0],[0 1 0],[1 1 0]);
overlay = imoverlaymult(img, masks, colors); imshow(overlay);

end


%
% Helper functions
%
function [red green yellow] = pack_samples(samples)

    nFiles = length(samples);
    red = [];
    green = [];
    yellow = [];

    for i=1:nFiles
        red = cat(1,red,samples(i).red);
        green = cat(1,green,samples(i).green);
        yellow = cat(1,yellow,samples(i).yellow);
    end

    %balance data
    nG = size(green,1);
    nR = size(red,1);
    nY = size(yellow,1);   
    nSamp = min([nG nR nY]);
    idx = randperm(nSamp);
    green = green(idx,:);
    red = red(idx,:);
    yellow = yellow(idx,:);
    
end

