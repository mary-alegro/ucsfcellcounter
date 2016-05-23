function mask_final = seg_mask(img,mask_orig,Eb,Ef,T)

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
se = strel('disk',4);
Bmask = imdilate(Bmask,se);
idx_backB = find(Bmask == 1);

E = abs(Ef-Eb);
m = zeros(size(E));
m(Ef < Eb) = 1;
E(m == 0) = 0;
% E2 = gscale(E);
% 
% h = fspecial('gaussian',5,4);
% E2 = imfilter(E2,h,'replicate');
% 
% H = imhist(E2);
% H(1) = 0;
% level = triangle_th(H,256);
% mask_final = im2bw(E2,level);
% mask_final(mask == 0) = 0;

Req = double(adapthisteq(R));
Geq = double(adapthisteq(G));
R2 = Req.*E;
G2 = Geq.*E;
RG = R2+G2;
RG = RG./max(RG(:));

E2 = E/max(E(:));

se = strel('disk',3);
Ee = imerode(E2,se);
M = imreconstruct(Ee,E);
Mc = imcomplement(M);
Mce = imerode(Mc,se);
M2 = imcomplement(imreconstruct(Mce,Mc));
M2 = gscale(M2);
H = imhist(M2);
H(1) = 0;
level = percentile2i(H,T);
mask_final = im2bw(M2,level);
mask_final(mask_orig == 0) = 0;
mask_final(idx_backB) = 0;