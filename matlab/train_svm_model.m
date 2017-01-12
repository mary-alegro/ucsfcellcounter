function [model mins ranges] = train_svm_model(dir_root)

%
% Run SVM training
% DIR_ROOT: full path of the directory where the training images are stored
%
%

if dir_root(end) ~= '/'
    dir_root = [dir_root '/'];
end

mask_dir = strcat(dir_root,'masks/');

files = dir(strcat(mask_dir,'*_mask.tif'));
nFiles = length(files);

data = [];
labels = [];
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
    
    R = img(:,:,1);
    G = img(:,:,2);
    B = img(:,:,3);
    
    %clean blue high values (which are holes and artifacts)
    h = imhist(B);
    P = percentile2i(h,0.99);
    Bmask = im2bw(B,P);
    mask(Bmask == 1) = 100;
    
    %get mask index
    idx_fore = find(mask == 255);
    idx_back1 = find(mask == 0);
    nFore = length(idx_fore);
    nBack1 = length(idx_back1);
    
    rnd_idx = randperm(nBack1,nFore);
    idx_back2 = idx_back1(rnd_idx);
        
    class_fore = ones(nFore,1);
    class_back = 0*class_fore;
    %data_fore = cat(2,R(idx_fore),G(idx_fore),B(idx_fore));
    %data_back = cat(2,R(idx_back2),G(idx_back2),B(idx_back2));
    
    data_fore = cat(2,R(idx_fore),G(idx_fore));
    data_back = cat(2,R(idx_back2),G(idx_back2));
        
    data = cat(1,data,data_fore,data_back);
    labels = cat(1,labels,class_fore,class_back);

end
clear data_fore;
clear data_back;

%radomize training matrix
data = cat(2,labels,data);
[r c N] = size(data);
rnd_idx = randperm(r);
data = data(rnd_idx,:);
labels = double(data(:,1));
data = double(data(:,2:end));

[data, mins, ranges] = rescale_data(data);

%train SVM
bestc = 0.03125;
bestg = 8;
model = svmtrain(labels,data,['-t 3 -h 0 -m 200 -c' num2str(bestc) '-g ' num2str(bestg)]);


