function split_channels

root_dir = '/Volumes/SUSHI_HD/SUSHI/CellCounter/';
%root_dir = '/home/maryana/storage/Posdoc/Microscopy/images/';
dir_img = strcat(root_dir,'toprocess/images/');
dir_csv = strcat(root_dir,'toprocess/csv/');
dir_mask_orig = strcat(root_dir,'toprocess/masks/');
dir_seg = strcat(root_dir,'toprocess/seg/');

test4_mask = strcat(root_dir,'toprocess/tests_paper/test4/masks/');
test4_chan_R = strcat(root_dir,'toprocess/tests_paper/test4/channels/R/');
test4_chan_G = strcat(root_dir,'toprocess/tests_paper/test4/channels/G/');
drn_dir = strcat(root_dir,'toprocess/masks/');

files = dir(strcat(dir_img,'*.tif'));
nFiles = length(files);
for i=1:nFiles
    file_name = files(i).name;
    img = imread(strcat(dir_img,file_name));
    R = img(:,:,1);
    G = img(:,:,2);
    
    imwrite(R,strcat(test4_chan_R,'red_',file_name));
    imwrite(G,strcat(test4_chan_G,'green_',file_name));
    
end