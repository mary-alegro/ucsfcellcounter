function mask_final = posproc_mask(img,mask,nIter)

mask2 = imfill(mask,'holes');
se = strel('disk',2);
mask3 = imopen(mask2,se);

img_gry = rgb2gray(img);
mask_final = region_seg(img_gry,mask3,nIter);

close all;
overlay = imoverlay(img,bwperim(mask_final),[0 1 0]);
imshow(overlay);

[labels, nL] = bwlabel(mask_final);

nPix = zeros(1,nL);
meanB = zeros(1,nL);
B = img(:,:,3);
for i=1:nL
    idx = find(labels == i);
    nPix(i) = length(idx);
    b = B(idx);
    meanB(i) = mean(b);
end

mB = mean(meanB);
%stdB = std(meanB);
mP = mean(nPix);
%stdP = std(nPix);

labelsB = find(meanB > mB);
labelsP = find(nPix < mP);
toErase = union(labelsB,labelsP);
nE = length(toErase);
mask2 = mask_final;
for i=1:nE
    ll = toErase(i);
    mask2(labels == ll) = 0;
end

mask_final = mask2;

figure, 
overlay = imoverlay(img,bwperim(mask_final),[0 1 0]);
imshow(overlay);

% figure, bar(nPix);
% figure, bar(meanB);

