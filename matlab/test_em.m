function [img, R, G, B, mask] = test_em(fullpath)


[img,R,G,B] = load_img(fullpath);
hsv = rgb2hsv(double(img));

H = hsv(:,:,1);
S = hsv(:,:,2);
V = hsv(:,:,3);

% data = H;
% data = data(:);
data = double(cat(2, R(:),G(:)));
options = statset('Display','final');
obj = gmdistribution.fit(data,2,'Replicates',5,'Options',options);
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

[theta,rho] = cart2pol(double(B),double(G));

idx_mask = find(mask == 255);

%t1 = theta(idx_mask);
%r1 = rho(idx_mask);
r = double(R(idx_mask));
g = double(G(idx_mask));
b = double(B(idx_mask));

data = cat(2,r(:),g(:),b(:));
obj = gmdistribution.fit(data,2,'Options',options);
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

mask4 = clean_mask_size(mask3,30,800);

overlay = imoverlay(img,mask4, [.3 1 .3]); 
imshow(overlay);

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



