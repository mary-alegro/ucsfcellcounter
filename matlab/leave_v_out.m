function leave_v_out(img_dir,seg_dir,csv_dir,orig_mask_dir,img_list)

list_imgs = create_file_list(img_list,img_dir);
list_masks = create_file_list(img_list,orig_mask_dir);

%nDiv = 7;
nDiv = 49;
nFiles = length(list_imgs);
nMasks = length(list_masks);

%seg_dir = '/home/maryana/storage/Posdoc/Microscopy/images/toprocess/seg';
%orig_mask_dir = '/home/maryana/storage/Posdoc/Microscopy/images/toprocess/masks';



if nFiles ~= nMasks
    error('Leave-v-out: Number of images and number of masks must agree.');
end

ridx = randperm(nFiles);
nElem = nFiles/nDiv;
nBlocks = nFiles/nElem;
idx = 1:nFiles;

list_imgs = list_imgs(ridx);
list_masks = list_masks(ridx);
img_list = img_list(ridx);

%parobj = parpool('local'); 

%GT = load_ground_truth(img_dir,csv_dir,seg_dir,orig_mask_dir,img_list);
nError = 0;
for b=1:nElem:nFiles %iterate each block
    
    try
        test_idx = b:b+nElem-1; 
        train_idx = setdiff(idx,test_idx);

        %test_idx = 11;
        
        test_imgs = list_imgs(test_idx);
        test_masks = list_masks(test_idx);

        train_imgs = list_imgs(train_idx);
        train_masks = list_masks(train_idx); 

        %learn Df and Db dictionaries
        train_dictionary(train_imgs,train_masks);
        
        %learn classification samples (reg, green, yellow)
        %GT_train = GT(train_idx);
        %train_cell_class(GT_train);
        
        %run segmentation and classification
        test_dictionary(test_imgs,test_masks,seg_dir,orig_mask_dir);
    catch ME
        nError = nError + 1;
        msg = getReport(ME);
        fprintf(msg);
    end
    
end
fprintf('there were %d errors.\n',nError);

delete(parobj);

end


%
% --------------
%

function img_list = create_file_list(img_list,dir_root)
    nF = length(img_list);
    for f=1:nF
        name = img_list{f};
        name2 = strcat(dir_root,name);
        img_list(f) = {name2};
    end
end

