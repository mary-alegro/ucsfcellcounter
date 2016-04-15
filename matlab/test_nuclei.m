function [mask] = test_nuclei(img,mask)

R = img(:,:,1);
G = img(:,:,2);
B = img(:,:,3);


%%% segment background using EM
%segment RED channel

idx_fore = find(mask ~= 255);

Rf = double(R(idx_fore));
Gf = double(G(idx_fore));
Bf = double(B(idx_fore));

data = cat(2,Rf(:),Gf(:),Bf(:));

options = statset('Display','final');
obj = gmdistribution.fit(data,3,'Replicates',3,'Options',options);
idx = cluster(obj,data);
clusters = zeros(size(R));
clusters(idx_fore) = idx;

mask = clusters;
