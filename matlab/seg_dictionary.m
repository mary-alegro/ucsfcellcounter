function [mask_final,ef,eb] = seg_dictionary(R,G,B,mask_orig,wsize,T)


if isempty(wsize) || wsize == 0
    wsize = 11;
end

Df_name = strcat(num2str(wsize),'_Df.mat');
Db_name = strcat(num2str(wsize),'_Db.mat');
Df = load(Df_name);
Df = Df.Df;
Db = load(Db_name);
Db = Db.Db;

%remove highly correlated vectors from our basis dictionary
 De = abs(Db'*Df);
 [Ur Uc] = find(De > 0.90);
 U = unique([Ur; Uc]);
% nV = size(Db,2); %number of vectors
% vectors = 1:nV;
% toKeep = setdiff(vectors,U);

%Df = Df(:,toKeep);
%Db = Db(:,toKeep);

if isa(R,'uint16') || isa(R,'double')
    R = gscale(R);
    G = gscale(G);
    B = gscale(B);
end

if size(mask_orig,3) > 1
    mask_orig = mask_orig(:,:,1);
end

%R = adapthisteq(R);
%G = adapthisteq(G);

R2 = double(R);
G2 = double(G);
B2 = double(B);

%clean blue high values (which are holes and artifacts)
h = imhist(B);
P = percentile2i(h,0.80);
Bmask = im2bw(B,P);

%Bmask(mask_orig == 20) = 1; %ignorar fundo segmentado na mao
%idx_nB = find(Bmask ~= 1);
idx_backB = find(Bmask == 1);

mask = zeros(size(G));
mask(mask_orig > 0) = 1;
mask(idx_backB) = 0;

%open parallel pool
%parobj = parpool('local'); 

%train dictionary parameters
param.K=256;  % learns a dictionary with 100 elements
param.lambda=0.15;
%param.lambda2=0.5;
param.numThreads=1; % number of threads
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
    errorB = zeros(nFore,1);
    errorF = zeros(nFore,1);
    
    fprintf('Running patch sparse coding.\n');
    
    R2 = R2./255; G2 = G2./255; B2 = B2./255;
%     R2 = preproc_patch(R2);
%     G2 = preproc_patch(G2);
%     B2 = preproc_patch(B2);
    
    parfor p=1:nFore
    %for p=1:nFore
        
        ii = idxFore(p);
        w1 = getwindowmod(ii,R2,wsize);
        w2 = getwindowmod(ii,G2,wsize);
        w3 = getwindowmod(ii,B2,wsize);
        %w = [w1(:); w2(:); w3(:)]; 
        
        %x = [w1(:); w2(:)]; 
        x = [w1(:); w2(:); w3(:)]; 

        alphaf = mexLasso(x,Df,param);
        alphab = mexLasso(x,Db,param);
        
        Rf = costDL(Df,U,x,alphaf,param);
        Rb = costDL(Db,U,x,alphab,param);
        
        %fprintf('Patch #%d. Rf = %f, Rb = %f.\n',p,Rf,Rb);
        
        
        if(Rf < Rb)
            class_mask3(p) = 255;
        else
            class_mask3(p) = 100;
        end
        
        errorB(p) = Rb;
        errorF(p) = Rf;
        
    end
    
    %finish par pool
%delete(parobj);

mask3(idxFore(:)) = class_mask3(:);
mask3(mask3 < 255) = 0;

mask4 = im2bw(mask3);
mask4(idx_backB) = 0;

ef = zeros(size(mask4));
eb = zeros(size(mask4));

ef(idxFore(:)) = errorF(:);
eb(idxFore(:)) = errorB(:);
E = abs(ef-eb);
E(mask4 == 0) = 0;
% E2 = gscale(E);
% 
% h = fspecial('gaussian',5,4);
% E2 = imfilter(E2,h,'replicate');
% 
% H = imhist(E2);
% H(1) = 0;
% level = triangle_th(H,256);
% mask_final = im2bw(E2,level);
% mask_final(mask == 0) = 0;

Req = double(adapthisteq(R));
Geq = double(adapthisteq(G));
R2 = Req.*E;
G2 = Geq.*E;
RG = R2+G2;
RG = RG./max(RG(:));

se = strel('disk',4);
Ee = imerode(RG,se);
M = imreconstruct(Ee,E);
Mc = imcomplement(M);
Mce = imerode(Mc,se);
M2 = imcomplement(imreconstruct(Mce,Mc));
M2 = gscale(M2);
H = imhist(M2);
level = percentile2i(H,T);
mask_final = im2bw(M2,level);
mask_final(mask == 0) = 0;


end




