function mask_final = posproc_mask(img,mask,mask_orig)

se = strel('disk',2);
mask2 = imdilate(mask,se);
dims = [2 3 4];
for d=dims
   se2 = strel('disk',d);
   mask2 = imclose(imopen(mask2,se2),se2);
end

mask2(mask_orig == 0) = 0;
mask_final = mask2;
