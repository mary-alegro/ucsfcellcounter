function [mask,R2,G2,B2,centersX,centersY,types] = test_svm2(R,G,B,origR,origC,doResize)

load model_svm2.mat;
load mins_svm2.mat;
load ranges_svm2.mat;

wsize = 13;

if isa(R,'uint16') || isa(R,'double')
    R = gscale(R);
    G = gscale(G);
    B = gscale(B);
end

R2 = double(R);
G2 = double(G);
B2 = double(B);

%size_orig = size(R2);

if doResize == 1
    R = imresize(R,0.25);
    G = imresize(G,0.25);
    B = imresize(B,0.25);
end
img = cat(3,R,G,B);
gry_img = rgb2gray(img);

[imgRows imgCols imgN] = size(R);


%clean blue high values (which are holes and artifacts)
h = imhist(B);
P = percentile2i(h,0.97);
Bmask = im2bw(B,P);

idx_black = find(gry_img < 1);
Bmask(idx_black) = 1; %use Bmask to also ignore black background
idx_nB = find(Bmask ~= 1);

%%% segment background using EM
%segment RED channel
data = double(R(idx_nB));
options = statset('Display','final');

%obj = gmdistribution.fit(data,2,'Replicates',3,'Options',options);
obj = gmdistribution.fit(data,2,'Replicates',2, 'SharedCov',true,'CovType','diagonal','Regularize', 0.00001,'Options',options);
idx = cluster(obj,data);
clusters = zeros(size(data));

n1 = length(find(idx == 1));
n2 = length(find(idx == 2));
fore = 1;
if n1 > n2
    fore = 2;
end
clusters(idx == fore) = 255;
maskR = zeros(size(R));
maskR(idx_nB) = clusters;

%segment GREEN channel
data = double(G(idx_nB));
options = statset('Display','final');

%obj = gmdistribution.fit(data,2,'Replicates',3,'Options',options);
obj = gmdistribution.fit(data,2,'Replicates',2, 'SharedCov',true,'CovType','diagonal','Regularize', 0.00001,'Options',options);
idx = cluster(obj,data);
clusters = zeros(size(data));

n1 = length(find(idx == 1));
n2 = length(find(idx == 2));
fore = 1;
if n1 > n2
    fore = 2;
end
clusters(idx == fore) = 255;
maskG = zeros(size(G));
maskG(idx_nB) = clusters;

%channel union
mask = maskR + maskG;
mask = im2bw(mask);

%open parallel pool
parobj = parpool('local'); 

%%% refine segmentation using SVM
    mask2 = uint8(mask);
    mask2(mask2 == 1) = 255;

    Rt = R;
    Gt = G;
    Bt = B;

    Rt(mask2 == 0) = 0;
    Gt(mask2 == 0) = 0;
    Bt(mask2 == 0) = 0;

    imgt = cat(3,Rt,Gt,Bt);
    
    [data,labels] = get_patches_par(imgt,mask2,wsize,0);
    labels = zeros(size(data,1),1);
    idx_mask = find(mask2 == 255); 
    %data = double(cat(2,Rt(idx_mask),Gt(idx_mask)));
    data = double(data);
    data = rescale_data(data,mins,ranges);
    
%finish par pool
delete(parobj);
    
    fprintf('Running SVM.\n');

    %segment using SVM
    [classes, precision, probs] = svmpredict(labels, data, model);

    mask3 = zeros(size(Rt));
    mask3(idx_mask) = classes;

%seg = mask3;

se = strel('disk',1);
mask4 = imclose(mask3,se);
mask4 = imopen(mask4,se);

%mask4 = mask3;

%%% get rid of structures with high Blue signal because they are artifacts
%%% also get rid of too small structures
[labels,nLabels] = bwlabel(mask4);
idx_fb = find(B > 1);
meanB = mean(double(B(idx_fb)));
stdB = std(double(B(idx_fb)));
for l = 1:nLabels
    idx = find(labels == l);
    str = B(idx);
    meanStr = mean(str(:));
    if meanStr >= meanB + (stdB/2);
        mask4(idx) = 0; %erase structure
    elseif length(idx) < 6
         mask4(idx) = 0; %erase structure
    end
end

[labels,nLabels] = bwlabel(mask4);
stats = regionprops(labels,'Centroid');
centersX = zeros(nLabels,1);
centersY = zeros(nLabels,1);
types = zeros(nLabels,1);
tmp_idx = ones(nLabels,1);

rRows = origR/imgRows;
rCols = origC/imgCols;

for l=1:nLabels
    idx = find(labels == l);
    s = length(idx);
    if s <= 5
      mask4(labels == l) = 0;
      tmp_idx(l) = -1;
    end

    xy = round(stats(l).Centroid);
    centersX(l) = round(xy(1)*rCols);
    centersY(l) = round(xy(2)*rRows);
    
    types(l) = analyse_channels(R2,G2,B2,xy);
end

idx = find(tmp_idx ~= -1);
centersX = centersX(idx);
centersY = centersY(idx);
types = types(idx);

mask= mask4;

end




%
% Find structure channel
%
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
    
    %sR = skewness(hR);
    %sG = skewness(hG);
    
    %bar(hR(:)); figure, bar(hG(:));

    d = abs(mR-mG);
    
    t = 2; %always init as orange (overlap)
    
    if (mR < mG) && ((d >= (th*mR)) && (d >= (th*mG)) )
        t = 1; %green
    elseif (mG < mR) && ((d >= (th*mG)) && (d >= (th*mR)))
        t = 0; %red    
    end
    
    %fprintf('R: %f G: %f dif: %f skew R: %f skew G: %f type: %d\n', mR,mG,d,sR,sG,t);

end
