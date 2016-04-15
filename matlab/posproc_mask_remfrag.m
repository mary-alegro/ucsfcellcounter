function mask_rem = posproc_mask_remfrag(mask)

[labels nL] = bwlabel(mask);
sizeL = zeros(1,nL);
for l = 1:nL
    n = find(labels == l);
    n = length(n);
    sizeL(l) = n;
end


m = median(sizeL);
ll = find(sizeL < m);
sizes = unique(sizeL);
ls = length(sizes);
histoS = zeros(1,ls);

for i = 1:ls
    s = sizes(i);
    n = find(sizeL == s);
    n = length(n);
    histoS(i) = n;
end


%plot(sizes,histoS,'b*');

m = median(sizes);
ll = find(sizeL < m);
for i=ll
    labels(labels == i) = 0;
end


mask_rem = logical(labels);
