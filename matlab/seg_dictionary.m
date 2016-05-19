function [mask_final,Ef,Eb] = seg_dictionary(R,G,B,mask_orig,wsize)


if isempty(wsize) || wsize == 0
    wsize = 11;
end

Df_name = strcat(num2str(wsize),'_Df.mat');
Db_name = strcat(num2str(wsize),'_Db.mat');
Df = load(Df_name);
Df = Df.Df;
Db = load(Db_name);
Db = Db.Db;

%displayPatches(Df); figure, displayPatches(Db);

%remove highly correlated vectors from our basis dictionary
  De = abs(Db'*Df);
  [Ur Uc] = find(De > 0.99);
  U = unique([Ur; Uc]);
  nV = size(Db,2); %number of vectors
  vectors = 1:nV;
  toKeep = setdiff(vectors,U);
  
 %Dtf = Df(:,U);
 %Dtb = Db(:,U);
 
 %figure, displayPatches(Dtf); figure, displayPatches(Dtb);
  
 Df = Df(:,toKeep);
 Db = Db(:,toKeep);
 nV = size(Db,2); %number of vectors
 
 %figure, displayPatches(Df); figure, displayPatches(Db);


if isa(R,'uint16') || isa(R,'double')
    R = gscale(R);
    G = gscale(G);
    B = gscale(B);
end

if size(mask_orig,3) > 1
    mask_orig = mask_orig(:,:,1);
end

R2 = double(R);
G2 = double(G);
B2 = double(B);

%clean blue high values (which are holes and artifacts)
Beq = adapthisteq(B);
Hb = imhist(Beq);
Hb(1) = 0;
l = percentile2i(Hb,0.85);
Bmask = im2bw(B,l);
Bmask = imfill(Bmask,'holes');
se = strel('disk',4);
Bmask = imdilate(Bmask,se);
idx_backB = find(Bmask == 1);

mask = zeros(size(G));
mask(mask_orig > 0) = 1;
%mask(idx_backB) = 0;

%open parallel pool
%parobj = parpool('local'); 

%train dictionary parameters
%param.K=256;  % learns a dictionary with K elements
param.K = nV;
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
    mask2(idx_backB) = 0; %don't consider holes
    
    %mask2 = 255*ones(size(mask2));
    
    idxFore = find(mask2 == 255);
    nFore = length(idxFore);
    mask3 = zeros(size(mask2));
    class_mask3 = zeros(nFore,1);
    errorB = zeros(nFore,1);
    errorF = zeros(nFore,1);
    
    fprintf('Running patch sparse coding.\n');
    
    R2 = R2./255; G2 = G2./255; B2 = B2./255;

    lab = rgb2lab(cat(3,R2,G2,B2));
    L = lab(:,:,1); A = lab(:,:,2); b = lab(:,:,3);
    L = (L - min(L(:)))/(max(L(:)) - min(L(:)));
    A = (A - min(A(:)))/(max(A(:)) - min(A(:)));
    b = (b - min(b(:)))/(max(b(:)) - min(b(:)));
    
    parfor p=1:nFore
    %for p=1:nFore
        
        ii = idxFore(p);
%         w1 = getwindowmod(ii,R2,wsize);
%         w2 = getwindowmod(ii,G2,wsize);
%         w3 = getwindowmod(ii,B2,wsize);
         w1 = getwindowmod(ii,L,wsize);
         w2 = getwindowmod(ii,A,wsize);
         w3 = getwindowmod(ii,b,wsize);

        %w = [w1(:); w2(:); w3(:)]; 
        
        %x = [w1(:); w2(:)]; 
        x = [w1(:); w2(:); w3(:)]; 

        alphaf = mexLasso(x,Df,param);
        alphab = mexLasso(x,Db,param);
        
        Rf = costDL(Df,[],x,alphaf,param);
        Rb = costDL(Db,[],x,alphab,param);
        
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

Ef = zeros(size(mask4));
Eb = zeros(size(mask4));
Ef(idxFore(:)) = errorF(:);
Eb(idxFore(:)) = errorB(:);

mask_final = zeros(size(mask4)); 
mask_final(Ef < Eb) = 1;
mask_final(mask == 0) = 0;
%mask_final(idx_backB) = 0;
mask_final = bwareaopen(mask_final,7);
mask_final = imfill(mask_final,'holes');

end




