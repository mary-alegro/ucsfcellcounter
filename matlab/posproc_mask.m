function mask_final = posproc_mask(img,mask,mask_orig)

dims = [2 3 4];
se = strel('disk',2);

mask = imdilate(mask,se);
for d=dims
   se2 = strel('disk',d);
   mask = imclose(imopen(mask,se2),se2);
end

%stack = cat(3,bwperim(mask),bwperim(mask_orig));

%overlay = imoverlaymult(img,stack,[1 0 1; 1 1 1]); imshow(overlay);
mask_final = mask;
