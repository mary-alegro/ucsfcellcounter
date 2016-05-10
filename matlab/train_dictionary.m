function [Df,Db] = train_dictionary(list_imgs,list_masks)

%
% Run Dictionary Learning training
% LIST_IMGS: 
% LIST_MASKS: 
% Df = dictionary learned from foreground data
% Db = dictionary learned from background data
%

rrate = 0.25;
wsize = 11;

data = [];
labels = [];

nFiles = length(list_imgs);
nMasks = length(list_masks);

if nFiles ~= nMasks
    error('Number of images and number of masks must agree.');
end

%parobj = parpool('local');

for f=1:nFiles
    
    %name = files(f).name;
    name = char(list_imgs(f));
    
    %load mask
    maskname = char(list_masks(f));
    mask = imread(maskname);
    [rm cm Nm] = size(mask);
    if Nm > 1
        mask = mask(:,:,1);
    end
    
    %%% resize mask
    mask = imresize(mask,rrate);
 
    %load image
    img = double(imread(name));
    
    %%% resize image
    img = imresize(img,rrate);
    
    R = img(:,:,1); G = img(:,:,2); B = img(:,:,3);
    R = R./255; G = G./255; B = B./255;
    img = cat(3,R,G,B);
    
    %[data_tmp,labels_tmp] = get_patches(img,mask,wsize,1);
    [data_tmp,labels_tmp] = get_patches_par_DL(img,mask,wsize,1);

    data = cat(1,data,data_tmp);
    clear data_tmp;
    labels = cat(1,labels,labels_tmp);
    clear labels_tmp;
       
end

%finish par pool
%delete(parobj);


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
param.numThreads=6; % number of threads
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








