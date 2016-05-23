function mask_final = seg_mask_strategy2(img,mask_orig,mask_stack,Eb,Ef,T)

R = img(:,:,1);
G = img(:,:,2);
B = img(:,:,3);

%clean blue high values (which are holes and artifacts)
Beq = adapthisteq(B);
Hb = imhist(Beq);
Hb(1) = 0;
l = percentile2i(Hb,0.85);
Bmask = im2bw(B,l);
Bmask = imfill(Bmask,'holes');
se = strel('disk',3);
Bmask = imdilate(Bmask,se);
idx_backB = find(Bmask == 1);

nMasks = size(mask_stack,3);

E = abs(Ef-Eb);
m = zeros(size(E));
m(Ef < Eb) = 1;
E(m == 0) = 0;
E2 = E/max(E(:));
se = strel('disk',3);

mask_final = zeros(size(mask_orig));
for i=1:nMasks
    mt = mask_stack(:,:,i);
    Et = E2;
    Et(mt == 0) = 0;
    
    Ee = imerode(Et,se);
    M = imreconstruct(Ee,E);
    Mc = imcomplement(M);
    Mce = imerode(Mc,se);
    M2 = imcomplement(imreconstruct(Mce,Mc));
    M2 = gscale(M2);
    H = imhist(M2);
    H(1) = 0;
    level = percentile2i(H,T);
    
    tmp = im2bw(M2,level);
    tmp(mask_orig == 0) = 0;
    tmp(idx_backB) = 0;
    
    mask_final = mask_final | tmp;
end
