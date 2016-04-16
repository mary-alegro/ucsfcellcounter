function leave_v_out(list_imgs, list_masks)

nDiv = 7;
nFiles = length(list_imgs);
nMasks = length(list_masks);

seg_dir = '/home/maryana/storage/Posdoc/Microscopy/images/toprocess/seg';

if nFiles ~= nMasks
    error('Leave-v-out: Number of images and number of masks must agree.');
end

ridx = randperm(nFiles);
nElem = nFiles/nDiv;
nBlocks = nFiles/nElem;
idx = 1:nFiles;

list_imgs = list_imgs(ridx);
list_masks = list_masks(ridx);

for b=1:nElem:nFiles %iterate each block
    
    test_idx = b:b+nElem-1;
    train_idx = setdiff(idx,test_idx);
    
    test_imgs = list_imgs(test_idx);
    test_masks = list_masks(test_idx);
    
    train_imgs = list_imgs(train_idx);
    train_masks = list_masks(train_idx); 
    
    %dictionary learning
    train_dictionary(train_imgs,train_masks);
    
    %segmentation by sparse coding
    test_dictionary(test_imgs,test_masks,seg_dir);
    
end



