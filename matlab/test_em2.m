function [mask,R2,G2,B2,centersX,centersY,types] = test_em2(R,G,B,pts_fore,pts_back,origR,origC,resized)

if isa(R,'uint16') || isa(R,'double')
    R = gscale(R);
    G = gscale(G);
    B = gscale(B);
end

R2 = double(R);
G2 = double(G);
B2 = double(B);

size_orig = size(R2);

if resized ~= 1
    R = imresize(R,0.25);
    G = imresize(G,0.25);
    B = imresize(B,0.25);
end
%img = cat(3,R,G,B);

do_init = 0;
ws = 9;
if ~isempty(pts_fore) && ~isempty(pts_back) %init gmm with pre selected points
    do_init = 1;
end

[imgRows imgCols imgN] = size(R);


%%% segment background using EM
%segment RED channel
data = double(R(:));
options = statset('Display','final');

if do_init == 1       
    [muF, covF] = init_gmm(ws,pts_fore,double(R));
    [muB, covB] = init_gmm(ws,pts_back,double(R));
    init_obj.mu = [muF; muB];
    init_obj.Sigma = cat(3,covF,covB);
    
    obj = gmdistribution.fit(data,2,'Replicates',1,'Options',options,'Start',init_obj);
else
    obj = gmdistribution.fit(data,2,'Replicates',2,'Options',options);
end
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

%segment GREEN channel
if do_init == 1   
    [muF, covF] = init_gmm(ws,pts_fore,double(G));
    [muB, covB] = init_gmm(ws,pts_back,double(G));
    init_obj.mu = [muF; muB];
    init_obj.Sigma = cat(3,covF,covB);
    
    obj = gmdistribution.fit(data,2,'Replicates',1,'Options',options,'Start',init_obj);
else
    obj = gmdistribution.fit(data,2,'Replicates',2,'Options',options);
end
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
types = zeros(nLabels,1);
rRows = origR/imgRows;
rCols = origC/imgCols;
for l = 1:nStats
    xy = round(stats(l).Centroid);
    %centersX(l) = xy(1);
    %centersY(l) = xy(2);
    centersX(l) = round(xy(1)*rCols);
    centersY(l) = round(xy(2)*rRows);
    types(l) = analyse_channels(R2,G2,B2,xy);
end
mask = mask4;

end


function t = analyse_channels(R,G,B,xy)
    
    close all;

    wsize = 11;
    ind = sub2ind(size(R),xy(2),xy(1));
    wR = getwindow(ind,R,wsize);
    wG = getwindow(ind,G,wsize);
    th = 0.15;

    mR = mean(wR(:));
    mG = mean(wG(:));
    
    hR = hist(wR(:),256);
    hG = hist(wG(:),256);
    
    sR = skewness(hR);
    sG = skewness(hG);
    
    %bar(hR(:)); figure, bar(hG(:));

    d = abs(mR-mG);
    
    t = 2; %always init as orange (overlap)
    
    if (mR < mG) && ((d >= (th*mR)) && (d >= (th*mG)) )
        t = 1; %green
    elseif (mG < mR) && ((d >= (th*mG)) && (d >= (th*mR)))
        t = 0; %red    
    end
    
    fprintf('R: %f G: %f dif: %f skew R: %f skew G: %f type: %d\n', mR,mG,d,sR,sG,t);

end


function [mu covar] = init_gmm_rgb(wsize,points,img)

    [rows cols] = size(points);
    
    R = img(:,:,1);
    G = img(:,:,2);
    B = img(:,:,3);

    uI = [];
    uQ = [];
    for p = 1:rows
         mupT = points(p,:);
         ct = sub2ind(size(R),mupT(1), mupT(2));
         wI = getwindow(ct,R,wsize);
         wQ = getwindow(ct,G,wsize);     
         uI = [uI; wI(:)];
         uQ = [uQ; wQ(:)];
    end    
     mu = [mean(uI(:)) mean(uQ(:))];
     cIQ = cat(2,uI,uQ);
     covar = cov(cIQ);
end

function [mu covar] = init_gmm(wsize,points,channel)

    [rows cols] = size(points);

    uI = [];
    uQ = [];
    for p = 1:rows
         mupT = points(p,:);
         ct = sub2ind(size(channel),mupT(1), mupT(2));
         wI = getwindow(ct,channel,wsize);
         %wQ = getwindow(ct,G,wsize);     
         uI = [uI; wI(:)];
         %uQ = [uQ; wQ(:)];
    end    
     %mu = [mean(uI(:)) mean(uQ(:))];
     mu = mean(uI(:));
     %cIQ = cat(2,uI,uQ);
     cIQ = uI;
     covar = cov(cIQ);
end
