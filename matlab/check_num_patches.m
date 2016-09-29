function check_num_patches

%
% compute the number of total cells from the GT 
%

dir_root='/Volumes/SUSHI_HD/SUSHI/CellCounter/toprocess/masks/';
rrate = 0.25;

files = dir(strcat(dir_root,'*.tif'));
nFiles = length(files);
count = 0;
for f=1:nFiles
    name = files(f).name;
    mask = imread(strcat(dir_root,name));
    [r c N] = size(mask);
    if N > 1
        mask = mask(:,:,1);
    end
    mask = imresize(mask,rrate);
    idx = find(mask > 0 & mask < 254);
    nPts = length(idx);
    count = count + nPts;
end
fprintf('Total number of patches: %d\n',count);
