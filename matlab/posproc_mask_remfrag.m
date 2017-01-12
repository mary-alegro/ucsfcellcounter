function mask_rem = posproc_mask_remfrag(mask,T)

[labels nL] = bwlabel(mask);
sizeL = zeros(1,nL);
for l = 1:nL
    n = find(labels == l);
    n = length(n);
    sizeL(l) = n;
end

ll = find(sizeL <= T);
mask_rem = labels;
for l=ll
    mask_rem(labels == l) = 0;
end

mask_rem = logical(mask_rem);
