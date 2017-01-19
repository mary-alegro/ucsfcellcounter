function [mask] = test_DL4(R,G,B,mask_orig,wsize)


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

if size(mask_orig,3) > 1
    mask_orig = mask_orig(:,:,1);
end

%size_orig = size(R2);

% if doResize == 1
%     R = imresize(R,0.25);
%     G = imresize(G,0.25);
%     B = imresize(B,0.25);
% end
%img = cat(3,R,G,B);

R2 = double(R);
G2 = double(G);
B2 = double(B);

%[imgRows imgCols imgN] = size(R);

%run_em = 0;

% if run_em == 1
%clean blue high values (which are holes and artifacts)
h = imhist(B);
P = percentile2i(h,0.97);
Bmask = im2bw(B,P);

%Bmask(mask_orig == 20) = 1; %ignorar fundo segmentado na mao
%idx_nB = find(Bmask ~= 1);
idx_backB = find(Bmask == 1);

% 
% %%% segment background using EM
% %segment RED channel
% data = double(R(idx_nB));
% options = statset('Display','final');
% 
% obj = gmdistribution.fit(data,2,'Replicates',3,'Options',options);
% idx = cluster(obj,data);
% clusters = zeros(size(data));
% 
% n1 = length(find(idx == 1));
% n2 = length(find(idx == 2));
% fore = 1;
% if n1 > n2
%     fore = 2;
% end
% clusters(idx == fore) = 255;
% maskR = zeros(size(R));
% maskR(idx_nB) = clusters;
% 
% %segment GREEN channel
% data = double(G(idx_nB));
% options = statset('Display','final');
% 
% obj = gmdistribution.fit(data,2,'Replicates',3,'Options',options);
% 
% idx = cluster(obj,data);
% clusters = zeros(size(data));
% 
% n1 = length(find(idx == 1));
% n2 = length(find(idx == 2));
% fore = 1;
% if n1 > n2
%     fore = 2;
% end
% clusters(idx == fore) = 255;
% maskG = zeros(size(G));
% maskG(idx_nB) = clusters;
% 
% %channel union
% mask = maskR + maskG;
% mask = im2bw(mask);
% 
% end

mask = zeros(size(G));
mask(mask_orig ~= 20) = 1;
mask(idx_backB) = 0;

%open parallel pool
parobj = parpool('local'); 

%train dictionary parameters
param.K=256;  % learns a dictionary with 100 elements
param.lambda=0.15;
%param.lambda2=0.5;
param.numThreads=6; % number of threads
param.batchsize=400;
param.verbose=false;
param.mode = 2;
param.iter=1000;  % let us see what happens after 1000 iterations.


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

        alphaf = mexLasso(x,Df,param);
        alphab = mexLasso(x,Db,param);
        
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
mask4(idx_backB) = 0;

mask = mask4;


end




%
% Find structure channel
%
function t = analyse_channels(R,G,B,xy)
    
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


