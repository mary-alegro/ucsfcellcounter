function [model mins ranges] = train_svm_model2(dir_root)

%
% Run SVM training
% DIR_ROOT: full path of the directory where the training images are stored
%

if dir_root(end) ~= '/'
    dir_root = [dir_root '/'];
end

wsize = 13;

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
  
    %clean blue high values (which are holes and artifacts)
    B = img(:,:,3);
    h = imhist(B);
    P = percentile2i(h,0.98);
    Bmask = im2bw(B,P);
    mask(Bmask == 1) = 100;
    
    %[data_tmp,labels_tmp] = get_patches(img,mask,wsize,1);
    [data_tmp,labels_tmp] = get_patches_par(img,mask,wsize,1);
    
    
    data = cat(1,data,data_tmp);
    labels = cat(1,labels,labels_tmp);
       
end

    %finish par pool
    delete(parobj);

%radomize training matridata = cat(2,labels,data);
[r c N] = size(data);
rnd_idx = randperm(r);
data = cat(2,labels,data);
data = data(rnd_idx,:);
labels = double(data(:,1));
data = double(data(:,2:end));

[data, mins, ranges] = rescale_data(data);

%train SVM
%bestc = 0.03125;
%bestg = 8;
bestc = 1;
bestg = 2;

fprintf('Running SVM training.\n');

model = svmtrain(labels,data,['-t 2 -h 0 -m 200 -c' num2str(bestc) '-g ' num2str(bestg)]);

save('model_svm2.mat','model');
save('mins_svm2.mat','mins');
save('ranges_svm2.mat','ranges'); 



