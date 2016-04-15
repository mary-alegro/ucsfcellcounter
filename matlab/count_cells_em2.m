function [mask,R2,G2,B2,centersX,centersY] = count_cells_em2(R,G,B,min_size,max_size)

if isa(R,'uint16') || isa(R,'double')
    R = gscale(R);
    G = gscale(G);
    B = gscale(B);
end

R2 = double(R);
G2 = double(G);
B2 = double(B);

R = imresize(R,0.25);
G = imresize(G,0.25);
B = imresize(B,0.25);

img = cat(3,R,G,B);

size_orig = size(R2);
size_res = size(R);
rate = size_orig(2)/size_res(2);

%%% segment background using EM
data = double(R(:));
options = statset('Display','final');
obj = gmdistribution.fit(data,2,'Replicates',2,'Options',options);
%obj = gmdistribution.fit(data,2,'Options',options);
idx = cluster(obj,data);
clusters = zeros(size(R));

n1 = length(find(idx == 1));
n2 = length(find(idx == 2));
fore = 1;
if n1 > n2
    fore = 2;
end
clusters(idx == fore) = 255;
maskR = clusters;

data = double(G(:));
options = statset('Display','final');
obj = gmdistribution.fit(data,2,'Replicates',2,'Options',options);
%obj = gmdistribution.fit(data,2,'Options',options);
idx = cluster(obj,data);
clusters = zeros(size(R));

n1 = length(find(idx == 1));
n2 = length(find(idx == 2));
fore = 1;
if n1 > n2
    fore = 2;
end
clusters(idx == fore) = 255;
maskG = clusters;

%channel union
mask = maskR + maskG;
mask = im2bw(mask);


%%% refine segmentation using EM
%idx_mask = find(mask == 255);
idx_mask = find(mask == 1);

r = double(R(idx_mask));
g = double(G(idx_mask));
b = double(B(idx_mask));

data = cat(2,r(:),g(:));
obj = gmdistribution.fit(data,2,'Replicates',3, 'SharedCov',true,'CovType','diagonal','Regularize', 0.00001,'Options',options);
%obj = gmdistribution.fit(data,2,'Options',options);
idx = cluster(obj,data);

mean_g1 = mean(g(idx == 1));
mean_g2 = mean(g(idx == 2));
mean_r1 = mean(r(idx == 1));
mean_r2 = mean(r(idx == 2));

fore = 1;
if mean_g1 < mean_g2 || mean_r1 < mean_r2
    fore = 2;
end

clusters = zeros(size(r));
clusters(idx == fore) = 255;

mask2 = zeros(size(R));
mask2(idx_mask) = clusters;

se = strel('square',4);
mask3 = imopen(mask2,se);

%%% get rid of structures with high Blue signal because they are artifacts
[labels,nLabels] = bwlabel(mask3);
meanB = mean(double(B(:)));
stdB = std(double(B(:)));
for l = 1:nLabels
    idx = find(labels == l);
    str = B(idx);
    meanStr = mean(str(:));
    if meanStr >= meanB + (stdB/2);
        mask3(idx) = 0; %erase structure
    end
end

%%% clean small spurious structures
%mask4 = clean_mask_size(mask3,min_size,max_size);
mask4 = mask3;

%%% filter by eccentricity
[labels,nLabels] = bwlabel(mask4);
stats = regionprops(labels,'Eccentricity');
nS = length(stats);
for l=1:nS
    EC = stats(l).Eccentricity;
    if EC > 0.85 
        mask4(labels == l) = 0;
    end
end

mask4 = imresize(mask4,size_orig,'nearest');
mask4 = im2bw(mask4);

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





