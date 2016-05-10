function mask_final = posproc_mask_ws(img,mask)

mask2 = imfill(mask,'holes');
se = strel('disk',2);
mask3 = imopen(mask2,se);

img_gry = rgb2gray(img);
img_gry = adapthisteq(img_gry);

hy = fspecial('sobel');
hx = hy';
Iy = imfilter(double(img_gry), hy, 'replicate');
Ix = imfilter(double(img_gry), hx, 'replicate');
gradmag = sqrt(Ix.^2 + Iy.^2);
% figure,
% imshow(gradmag,[]), title('Gradient magnitude (gradmag)');

I = img_gry;
I(mask3 == 0) = 0;

se = strel('disk', 2);
Io = imopen(I, se);
% figure,
% imshow(Io), title('Opening (Io)');

Ie = imerode(I, se);
Iobr = imreconstruct(Ie, I);
% figure,
% imshow(Iobr), title('Opening-by-reconstruction (Iobr)');

Ioc = imclose(Io, se);
% figure,
% imshow(Ioc), title('Opening-closing (Ioc)');

Iobrd = imdilate(Iobr, se);
Iobrcbr = imreconstruct(imcomplement(Iobrd), imcomplement(Iobr));
Iobrcbr = imcomplement(Iobrcbr);
% figure,
% imshow(Iobrcbr), title('Opening-closing by reconstruction (Iobrcbr)');

fgm = imregionalmax(Iobrcbr);
% figure,
% imshow(fgm), title('Regional maxima of opening-closing by reconstruction (fgm)');

I2 = I;
I2(fgm) = 255;

se2 = strel(ones(2,2));
fgm2 = imclose(fgm, se2);
fgm3 = imerode(fgm2, se2);

fgm4 = bwareaopen(fgm3, 2);
I3 = I;
I3(fgm4) = 255;
% figure,
% imshow(I3)
% title('Modified regional maxima superimposed on original image (fgm4)')


fgm4 = fgm;


bw = im2bw(Iobrcbr, graythresh(Iobrcbr));
% figure,
% imshow(bw), title('Thresholded opening-closing by reconstruction (bw)');

D = bwdist(bw);
DL = watershed(D);
bgm = DL == 0;
% figure,
% imshow(bgm), title('Watershed ridge lines (bgm)')

%gradmag2 = imimposemin(gradmag, bgm | fgm4);

mdist = bwdist(~mask3);


%gradmag2 = imimposemin(mdist, bgm | fgm4);
%gradmag2 = imimposemin(imcomplement(mdist), fgm4);
gradmag2 = imimposemin(imcomplement(mdist), bgm |fgm4);
%gradmag2 = imimposemin(Iobrcbr, bgm | fgm4);
L = watershed(gradmag2);

mask_final = zeros(size(mask));
%mask_final((L == 0) | bgm | fgm4) = 255;
mask_final(L == 0) = 255;


%close all;
figure,
overlay = imoverlay(img,mask_final,[0 1 0]);
imshow(overlay);

mask_final = mask3;
mask_final(L==0) = 0;

B = img(:,:,3);
h = imhist(B);
P = percentile2i(h,0.70);
Bmask = im2bw(B,P);
mask_final(Bmask > 0) = 0; 

figure,
overlay = imoverlay(img,bwperim(mask_final),[0.80 0 0.80]);
imshow(overlay);





