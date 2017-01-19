function [mask,R2,G2,B2,centersX,centersY] = count_cells_em(R,G,B,min_size,max_size)

R = gscale(R);
G = gscale(G);
B = gscale(B);

R2 = double(R);
G2 = double(G);
B2 = double(B);

%%% segment background using EM
data = double(cat(2, R(:),G(:)));
options = statset('Display','final');
obj = gmdistribution.fit(data,2,'Replicates',3,'Options',options);
idx = cluster(obj,data);
clusters = zeros(size(R));

n1 = length(find(idx == 1));
n2 = length(find(idx == 2));
fore = 1;
if n1 > n2
    fore = 2;
end
clusters(idx == fore) = 255;
mask = clusters;

%%% refine segmentation using EM
idx_mask = find(mask == 255);

r = double(R(idx_mask));
g = double(G(idx_mask));
b = double(B(idx_mask));

data = cat(2,r(:),g(:));
obj = gmdistribution.fit(data,2,'Replicates',3,'Options',options);
idx = cluster(obj,data);

mean_c1 = mean(g(idx == 1));
mean_c2 = mean(g(idx == 2));

fore = 1;
if mean_c1 < mean_c2
    fore = 2;
end

clusters = zeros(size(r));
clusters(idx == fore) = 255;

mask2 = zeros(size(R));
mask2(idx_mask) = clusters;

se = strel('square',3);
mask3 = imopen(mask2,se);

%%% get rid of structures with high Blue signal because they are artifacts
[labels,nLabels] = bwlabel(mask3);
meanB = mean(B(:));
for l = 1:nLabels
    idx = find(labels == l);
    str = B(idx);
    meanStr = mean(str(:));
    if meanStr >= meanB
        mask3(idx) = 0; %erase structure
    end
end


%%% clean small spurious structures
mask4 = clean_mask_size(mask3,min_size,max_size);


%%% compute centroids of the final segmentations
[labels,nLabels] = bwlabel(mask4);
stats = regionprops(labels,'Centroid');
nStats = length(stats);

centersX = zeros(nLabels,1);
centersY = zeros(nLabels,1);
for l = 1:nStats
    xy = round(stats(l).Centroid);
    centersX(l) = xy(1);
    centersY(l) = xy(2);
end
mask = mask4;



