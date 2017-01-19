%Algoritmo da Dani
%Compares our ground truth with masks created by D. Ushizima method

%root_dir = '/Volumes/SUSHI_HD/SUSHI/CellCounter/';
root_dir = '/home/maryana/storage/Posdoc/Microscopy/images/';
dir_img = strcat(root_dir,'toprocess/images/');
dir_csv = strcat(root_dir,'toprocess/csv/');
dir_mask_orig = strcat(root_dir,'toprocess/masks/');
dir_seg = strcat(root_dir,'toprocess/seg/');


test3_mask = strcat(root_dir,'toprocess/tests_paper/test3/processed_images/');
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

GT = load_ground_truth(dir_img,dir_csv,dir_seg,dir_mask_orig,count_images);

nFiles = length(count_images);
stats = zeros(nFiles,10);
for i=1:nFiles

    currGT = GT(i); % current file ground truth data
    file_name = GT(i).img_file;
    
    if isempty(currGT.yellow) && isempty(currGT.green) && isempty(currGT.red) %no GT available
        continue;
    end
       
    img = imread(strcat(dir_img,file_name)); %load img  
    mask = imread(strcat(test3_mask,file_name,'mask.tif')); %load green mask
    mask = logical(mask);

    drn = imread(strcat(drn_dir,file_name));
    [r c N] = size(drn);
    if N > 1
        drn = drn(:,:,1);
    end
    mask = imresize(mask,[r c]);
    mask(drn <= 0) = 0; %removes everything outside the DRN region
    %mask = logical(mask);
    
    center = regionprops(mask,'Centroid');
    centroids = round(cat(1,center.Centroid));
    cells_drn = sub2ind([r c],centroids(:,2),centroids(:,1));

    
    fprintf('------ **** File %s (%d of %d) **** -----\n',file_name,i,nFiles);
    try
        %[T,TP, FP, FN, P, R, F1,] = compute_stats(img,mask,currGT);
        [T,nTP, nFP, nFN, nTN, P, R, F1, FPR] = compute_stats_delanuay(img,cells_drn,drn,currGT,mask);
        close all;
        
        stats(i,1) = T;
        stats(i,2) = nTP;
        stats(i,3) = nFP;
        stats(i,4) = nFN;
        stats(i,5) = nTN;
        stats(i,6) = P;
        stats(i,7) = R;
        stats(i,8) = F1;
        stats(i,9) = FPR;
        stats(i,10) = i;
  
    catch ME
        %fprintf('\n### Error in file: %s###\n',file_name);
        %fprintf(FID,'\n### Error in file: %s###\n',file_name);
    end 
    
end

save('stats.mat','stats')


