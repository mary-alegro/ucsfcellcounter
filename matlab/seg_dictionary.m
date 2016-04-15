function [mask] = seg_dictionary(R,G,B,mask_orig,wsize)


if isempty(wsize) || wsize == 0
    wsize = 11;
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

R2 = double(R);
G2 = double(G);
B2 = double(B);

%clean blue high values (which are holes and artifacts)
h = imhist(B);
P = percentile2i(h,0.97);
Bmask = im2bw(B,P);

%Bmask(mask_orig == 20) = 1; %ignorar fundo segmentado na mao
%idx_nB = find(Bmask ~= 1);
idx_backB = find(Bmask == 1);

mask = zeros(size(G));
mask(mask_orig > 0) = 1;
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




