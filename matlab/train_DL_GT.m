function [Df,Db] = train_DL_GT(dir_img, dir_mask, dir_csv, csv_lst)

%
% Run Dictionary Learning training. Uses points marked on the PSD file to
% grab traning patches.
% DIR_ROOT: full path of the directory where the training images are stored
% Df = dictionary learned from foreground data
% Db = dictionary learned from background data
%

if dir_img(end) ~= '/'
    dir_root = [dir_root '/'];
end

wsize = 40;

mask_dir = strcat(dir_root,'masks/');
img_dir = strcat(dir_root,'proc/');

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
    imgname = strcat(img_dir,newname,'.tif');
    img = double(imread(imgname));
    
    R = img(:,:,1); G = img(:,:,2); B = img(:,:,3);  
    R = R./255; G = G./255; B = B./255;

    img = cat(3,R,G,B);
    
    [data_tmp,labels_tmp] = get_patches_par_DL_GT(img,mask,wsize,1);

    data = cat(1,data,data_tmp);
    clear data_tmp;
    labels = cat(1,labels,labels_tmp);
    clear labels_tmp;
       
end

    %finish par pool
 delete(parobj);


idxFore = find(labels == 1);
idxBack = find(labels == 0);
dataFore = data(idxFore,:);
dataBack = data(idxBack,:);

clear data;

dataFore = dataFore';
dataBack = dataBack';

fprintf('Starting dictionary training.\n');

%train dictionary
param.K=256;  % learns a dictionary with 100 elements
param.lambda=0.15;
param.numThreads=-1; % number of threads
param.batchsize=400;
param.verbose=false;
param.iter=1000;  % let us see what happens after 1000 iterations.

tic
Df = mexTrainDL(dataFore,param);
t=toc;
fprintf('DL foreground: %f\n',t);
Df_name = strcat(num2str(wsize),'_Df.mat');
save(Df_name,'Df');

tic
Db = mexTrainDL(dataBack,param);
t=toc;
fprintf('DL background: %f\n',t);
Db_name = strcat(num2str(wsize),'_Db.mat');
save(Db_name,'Db'); 








