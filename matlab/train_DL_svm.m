function [model] = train_DL_svm(dir_root,wsize)

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

Df_name = strcat(num2str(wsize),'_Df.mat');
Db_name = strcat(num2str(wsize),'_Db.mat');
Df = load(Df_name);
Df = Df.Df;
Db = load(Db_name);
Db = Db.Db;

%train dictionary parameters
param.K=256;  % learns a dictionary with 100 elements
param.lambda=0.15;
param.numThreads=1; % number of threads
param.batchsize=400;
param.verbose=false;
param.iter=1000;  % let us see what happens after 1000 iterations.

mask_dir = strcat(dir_root,'masks/');
files = dir(strcat(mask_dir,'*_mask.tif'));
nFiles = length(files);

data = [];
labels = [];

%open parallel pool
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
    img = double(imread(imgname));
    
    idxFore = find(mask == 255);
    idxBack1 = find(mask == 0);
    nFore = length(idxFore);
    nBack1 = length(idxBack1);

    if nFore >= nBack1
       rnd_idx = randperm(nFore);
    else
        rnd_idx = randperm(nBack1,nFore);
    end
    idxBack2 = idxBack1(rnd_idx);
    nBack = nFore;
    nChan = 3;
    %nWindow = wsize*wsize*nChan; 
    dSize = param.K;
       
    R = img(:,:,1); G = img(:,:,2); B = img(:,:,3);
    R = R./255; G = G./255; B = B./255;
    
    fprintf('Running patch sparse coding.\n');
    
    data_fore = zeros(nFore,dSize);
    labels_fore = zeros(nFore,1);
    parfor p=1:nFore
        
        ii = idxFore(p);
        w1 = getwindowmod(ii,R,wsize);
        w2 = getwindowmod(ii,G,wsize);
        w3 = getwindowmod(ii,B,wsize);
        %w = [w1(:); w2(:); w3(:)]; 
        
        %x = [w1(:); w2(:)]; 
        x = [w1(:); w2(:); w3(:)]; 

        alphaf = mexLasso(x,Df,param);
        %alphab = mexLasso(x,Db,param);
        
        data_fore(p,:) = alphaf(:);
        labels_fore(p) = 1;
        
    end 
    data = cat(1, data,data_fore);
    labels = cat(1, labels, labels_fore);
    
    data_back = zeros(nBack,dSize);
    labels_back = zeros(nBack,1);
    parfor p=1:nBack
        
        ii = idxBack2(p);
        w1 = getwindowmod(ii,R,wsize);
        w2 = getwindowmod(ii,G,wsize);
        w3 = getwindowmod(ii,B,wsize);
        %w = [w1(:); w2(:); w3(:)]; 
        
        %x = [w1(:); w2(:)]; 
        x = [w1(:); w2(:); w3(:)]; 

        alphaf = mexLasso(x,Df,param);
        %alphab = mexLasso(x,Db,param);
        
        data_back(p,:) = alphaf(:);
        labels_back(p) = 0;
        
    end
    data = cat(1, data,data_back);
    labels = cat(1, labels, labels_back);
    
    
end
    
%finish par pool
delete(parobj);


%train linear SVM
[r c N] = size(data);
rnd_idx = randperm(r);
data = cat(2,labels,data);
data = data(rnd_idx,:);
labels = double(data(:,1));
data = double(data(:,2:end));

%[data, mins, ranges] = rescale_data(data);

fprintf('Running SVM training.\n');

bestc = 1;
bestg = 2;

fprintf('Running SVM training.\n');

model = svmtrain(labels,data,['-t 2 -h 0 -m 200 -c' num2str(bestc) '-g ' num2str(bestg)]);



