function [mask,R2,G2,B2,centersX,centersY,types] = test_DL3(R,G,B,origR,origC,doResize,wsize)


if isempty(wsize) || wsize == 0
    wsize = 7;
end

Df_name = strcat(num2str(wsize),'_Df.mat');
Db_name = strcat(num2str(wsize),'_Db.mat');
Df = load(Df_name);
Df = Df.Df;
Db = load(Db_name);
Db = Db.Db;

if isa(R,'uint16') || isa(R,'double')
    R = gscale(R);
    G = gscale(G);
    B = gscale(B);
end

%size_orig = size(R2);

if doResize == 1
    R = imresize(R,0.25);
    G = imresize(G,0.25);
    B = imresize(B,0.25);
end
%img = cat(3,R,G,B);

R2 = double(R);
G2 = double(G);
B2 = double(B);

[imgRows imgCols imgN] = size(R);


%clean blue high values (which are holes and artifacts)
h = imhist(B);
P = percentile2i(h,0.97);
Bmask = im2bw(B,P);

idx_nB = find(Bmask ~= 1);


%%% segment background using EM
%segment RED channel
data = double(R(idx_nB));
options = statset('Display','final');

obj = gmdistribution.fit(data,2,'Replicates',3,'Options',options);
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

obj = gmdistribution.fit(data,2,'Replicates',3,'Options',options);

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

%train dictionary parameters
param.K=256;  % learns a dictionary with 100 elements
param.lambda=0.15;
param.numThreads=1; % number of threads
param.batchsize=400;
param.verbose=false;
param.iter=1000;  % let us see what happens after 1000 iterations.

%param2.L=10; % not more than 10 non-zeros coefficients
param2.eps=1; % squared norm of the residual should be less than 0.1
param2.numThreads=1; % number of processors/cores to use; the default choice is -1

%%% refine segmentation using Dictionary Learning
    mask2 = uint8(mask);
    mask2(mask2 == 1) = 255;
    
    %mask2 = 255*ones(size(mask2));
    
    idxFore = find(mask2 == 255);
    nFore = length(idxFore);
    mask3 = zeros(size(mask2));
    class_mask3 = zeros(nFore,1);
    
    fprintf('Running patch sparse coding.\n');
    
    R2 = R2./255; G2 = G2./255; B2 = B2./255;
%     R2 = preproc_patch(R2);
%     G2 = preproc_patch(G2);
%     B2 = preproc_patch(B2);
    
    parfor p=1:nFore
        
        ii = idxFore(p);
        w1 = getwindowmod(ii,R2,wsize);
        w2 = getwindowmod(ii,G2,wsize);
        w3 = getwindowmod(ii,B2,wsize);
        %w = [w1(:); w2(:); w3(:)]; 
        
        %x = [w1(:); w2(:)]; 
        x = [w1(:); w2(:); w3(:)]; 

        %alphaf = mexLasso(x,Df,param);
        %alphab = mexLasso(x,Db,param);
        
        alphaf = mexOMP(x,Df,param2)
        alphab = mexOMP(x,Db,param2)
        
        Rf = costDL(Df,x,alphaf,param);
        Rb = costDL(Db,x,alphab,param);
        
        %fprintf('Patch #%d. Rf = %f, Rb = %f.\n',p,Rf,Rb);
        
        
        if(Rf < Rb)
            class_mask3(p) = 255;
        else
            class_mask3(p) = 100;
        end
        
    end
    
    %finish par pool
delete(parobj);

mask3(idxFore(:)) = class_mask3(:);
mask3(mask3 < 255) = 0;

mask4 = im2bw(mask3);

types = [];
centersX = [];
centersY = [];

mask = mask4;
return;

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
    elseif length(idx) <= 8
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


