function run_test2
%
%  TEST 2: CellProfiler vs. Ground Truth 
%
% NOTES:
% 1) CellProfiler creates CSV file from which we get the processed images
% and X,Y coordinates of the detected cells. Files created:
% Experiments.csv, Image.csv, NucleiG.csv, NucleiR.csv
% 2) File processed_images.csv was manually created from Experiments.csv
% 3) Files green.csv and red.csv were created from NucleiG.csv and
% NucleiR.csv
% 4) Images were RESCALED TO 0.15 of the original size due to memory constraints
% 5) There might be repeated points so we have to clean the dataset first
% using distance information.
%

root_dir = '/Volumes/SUSHI_HD/SUSHI/CellCounter/';
%root_dir = '/home/maryana/storage/Posdoc/Microscopy/images/'
dir_img = strcat(root_dir,'toprocess/images/');
dir_csv = strcat(root_dir,'toprocess/csv/');
dir_mask_orig = strcat(root_dir,'toprocess/masks/');
dir_seg = strcat(root_dir,'toprocess/seg/');

test2_dir = strcat(root_dir,'toprocess/tests/test2/result_0.15/');
drn_dir = strcat(root_dir,'toprocess/masks/');

count_images(1) = {'11477.13_104_drn_final.tif'};
count_images(2) = {'11477.13_112_drn_final.tif'};
count_images(3) = {'11477.13_80_drn.tif'};
count_images(4) = {'11477.13_88_drn_2_final.tif'};
count_images(5) = {'11477.13_96_drn.tif'};
count_images(6) = {'3598.14_74_Merged_DRN.tif'};
count_images(7) = {'3598.14_82_Merged_DRN.tif'};
count_images(8) = {'3598.14_90_DRN.tif'};
count_images(9) = {'4453.13_102_drn.tif'};
count_images(10) = {'4453.13_86_drn.tif'};
count_images(11) = {'4453.13_94_drn.tif'};
count_images(12) = {'6785.13_72_drn.tif'};
count_images(13) = {'6785.13_80_drn.tif'};
count_images(14) = {'6785.13_88_drn.tif'};
count_images(15) = {'6931.12_72_drn-f.tif'};
count_images(16) = {'6931.12_80_drn-f.tif'};
count_images(17) = {'6931.12_88_drn-f.tif'};
count_images(18) = {'7678.13_104_drn_final.tif'};
count_images(19) = {'7678.13_112_drn_final.tif'};
count_images(20) = {'7678.13_86_drn.tif'};
count_images(21) = {'7678.13_94_drn_final.tif'};
count_images(22) = {'807.13_104_drn_f.tif'};
count_images(23) = {'807.13_80_drn_final.tif'};
count_images(24) = {'807.13_88_drn.tif'};
count_images(25) = {'807.13_96_drn-f.tif'};
count_images(26) = {'8886.13_drn_100_final.tif'};
count_images(27) = {'8886.13_drn_108.tif'};
count_images(28) = {'8886.13_drn_92.tif'};
count_images(29) = {'8886.13_drn_final_84.tif'};
count_images(30) = {'9428.13_78_drn.tif'};
count_images(31) = {'9428.13_86_drn_final.tif'};
count_images(32) = {'9777.12_138_drn-f.tif'};
count_images(33) = {'9777.12_146_drn-f.tif'};
count_images(34) = {'9777.12_154_drn-f.tif'};
count_images(35) = {'9777.12_162_drn-f.tif'};
count_images(36) = {'9890.13_56_drn_final.tif'};
count_images(37) = {'9890.13_64_drn_2_final.tif'};
count_images(38) = {'9890.13_72_drn_final.tif'};
count_images(39) = {'9890.13_80_drn_f.tif'};
count_images(40) = {'9890.13_88_drn_f.tif'};
count_images(41) = {'p2508_100_drn-f.tif'};
count_images(42) = {'p2508_76_DRN.tif'};
count_images(43) = {'p2508_84_drn-f.tif'};
count_images(44) = {'p2508_92_drn-f.tif'};
count_images(45) = {'p2540_106_drn-f.tif'};
count_images(46) = {'p2540_74_drn.tif'};
count_images(47) = {'p2540_82_drn.tif'};
count_images(48) = {'p2540_90_drn-f.tif'};
count_images(49) = {'p2540_98_drn-f.tif'};

%load ground truth
GT = load_ground_truth(dir_img,dir_csv,dir_seg,dir_mask_orig,count_images);

%find processed images indices in GT array
%reads the file name from the list of files processed by CellProfiler and
%finds its index in the list of ground truth images COUNT_IMAGES
%this step is necessary because cellprofiler saves all detected cells, from
%all images in a batch, in the same files (NucleiG.csv and NucleiR.csv) and indexes then by the index
%in file Experiments.csv. The only wat to be sure a point belongs to a
%particular file is follwing these indexes. 
idx_in_GT = [];
file_csv = strcat(test2_dir,'processed_images.csv');
FID = fopen(file_csv);
fline = fgetl(FID);
while fline ~= -1 %each line = one file name
    idx = strfind(fline,'/');
    idx = idx(end);
    file_name = fline(idx+1:end);
    
    idx_gt = strmatch(file_name,count_images); %index in GT
    idx_in_GT = [idx_in_GT; idx_gt];
      
    fline = fgetl(FID);
end
fclose(FID);

%
nFiles = length(idx_in_GT);
stats = zeros(nFiles,8);
for f=1:nFiles
    i = idx_in_GT(f);
    currGT = GT(i); % current file ground truth data
    
    if isempty(currGT.yellow) && isempty(currGT.green) && isempty(currGT.red) %no GT available
        continue;
    end
    
    file_name = GT(i).img_file;
    
    img = imread(strcat(dir_img,file_name)); %load original img
    
    idx = strfind(file_name,'.tif');
    file_name2 = file_name(1:idx-1);
    file_name2 = strcat(file_name2,'green_.tif');
    
    img_cp = imread(strcat(test2_dir,file_name2));
    
    [ro,co] = size(img); %original size
    [rcp,ccp] = size(img_cp);
    
    %compute resize rates
    rrate = ro/rcp; %Y rate
    crate = co/ccp; %X rate
    cells_cp = load_detected_cells(test2_dir,f); %[X,Y]
    cellsX = round(cells_cp(:,1)*crate); 
    cellsY = round(cells_cp(:,2)*rrate);
    cells_os = sub2ind([ro co], cellsY,cellsX);
    
    %remove points outside DRN 
    drn = imread(strcat(drn_dir,file_name));
    drn_set = find(drn > 0);
    cells_drn = intersect(cells_os,drn_set); %keep points that are inside the DRN mask
    %[cellsY,cellsX] = ind2sub([ro co],cells_drn);

    
    fprintf('------ **** File %s (%d of %d) **** -----\n',file_name,i,nFiles);
    try
        [T, nTP, nFP, nFN, P, R, F1] = compute_stats_delanuay(img,cells_drn,currGT);
        close all;

        stats(i,1) = T;
        stats(i,2) = nTP;
        stats(i,3) = nFP;
        stats(i,4) = nFN;
        stats(i,5) = P;
        stats(i,6) = R;
        stats(i,7) = F1;
        stats(i,8) = i;
  
    catch ME
        fprintf('\n### Error in file: %s###\n',file_name);
    end 
    
end

save('stats.mat','stats')


end


%
%
%

function cells = load_detected_cells(csv_root,img_ind)

% CSV format: file index, cell index, X, Y, ???
% IMG_IND = image index in Experiments.csv file

csv_file_R = strcat(csv_root,'red.csv');
csv_file_G = strcat(csv_root,'green.csv');
csv_R = csvread(csv_file_R);
csv_G = csvread(csv_file_G);
idxR = find(csv_R(:,1) == img_ind); 
idxG = find(csv_G(:,1) == img_ind); 
csv_R = csv_R(idxR,3:4);
csv_G = csv_G(idxG,3:4);

cells = cat(1,csv_R,csv_G);
end




