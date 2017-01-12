function [Df,Db] = train_DL1_yiq(dir_root,wsize)

%
% Run Dictionary Learning training
% DIR_ROOT: full path of the directory where the training images are stored
% Df = dictionary learned from foreground data
% Db = dictionary learned from background data
%

if dir_root(end) ~= '/'
    dir_root = [dir_root '/'];
end

if isempty(wsize) || wsize == 0
    wsize = 7;
end

Df_name = strcat(num2str(wsize), '_Df.mat');
Db_name = strcat(num2str(wsize), '_Db.mat');

mask_dir = strcat(dir_root,'masks/');

files = dir(strcat(mask_dir,'*_mask.tif'));
nFiles = length(files);

data = [];
labels = [];

 parobj = parpool('local'); 

for f=1:nFiles
    
    name = files(f).name;
    
    %load mask
    maskname = strcat(mask_dir,name);
    mask = imread(maskname);
    [rm cm Nm] = size(mask);
    if Nm > 1
        mask = mask(:,:,1);
    end
    
    %load image
    idx = strfind(name,'_mask.tif');
    newname = name(1:idx-1);
    imgname = strcat(dir_root,newname,'.tif');
    img = imread(imgname);
    img = double(img);
    
    yiq = rgb2ntsc(img);
    
    R = img(:,:,1); G = img(:,:,2); B = img(:,:,3);

    %clean blue high values (which are holes and artifacts)
    %h = imhist(B);
    %P = percentile2i(h,0.98);
    %Bmask = im2bw(B,P);
    %mask(Bmask == 1) = 100;
    
    R = R./255; G = G./255; B = B./255;
%     R = preproc_patch(R);
%     G = preproc_patch(G);
%     B = preproc_patch(B);
    
    img = cat(3,R,G,B);
    
    %[data_tmp,labels_tmp] = get_patches(img,mask,wsize,1);
    [data_tmp,labels_tmp] = get_patches_par_DL(yiq,mask,wsize,1);

    data = cat(1,data,data_tmp);
    labels = cat(1,labels,labels_tmp);
       
end

    %finish par pool
    delete(parobj);


idxFore = find(labels == 1);
idxBack = find(labels == 0);
dataFore = data(idxFore,:);
dataBack = data(idxBack,:);
dataFore = dataFore';
dataBack = dataBack';

%train dictionary
param.K=256;  % learns a dictionary with 100 elements
param.lambda=0.15;
param.numThreads=1; % number of threads
param.batchsize=400;
param.verbose=false;
param.iter=1000;  % let us see what happens after 1000 iterations.

tic
Df = mexTrainDL(dataFore,param);
t=toc;
fprintf('DL foreground: %f\n',t);


tic
Db = mexTrainDL(dataBack,param);
t=toc;
fprintf('DL background: %f\n',t);

save(Df_name,'Df');
save(Db_name,'Db');







