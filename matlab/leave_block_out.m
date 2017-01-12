function leave_block_out(list_imgs, list_masks)

nDiv = 7;
nFiles = length(list_imgs);
nMasks = length(list_masks);

if nFiles ~= nMasks
    error('Leave-v-out: Number of images and number of masks must agree.');
end

nBlocks = nFiles/nDiv;
nElem = nFiles/nBlocks;
idx = 1:nFiles;

for b=1:1+nElem:nBlocks %iterate each block
    
    test_idx = b:b+nElem;
    train_idx = setdiff(idx,test_idx);
    
    test_imgs = list_imgs(test_idx);
    test_masks = list_masks(test_idx);
    
    train_imgs = list_imgs(train_idx);
    train_masks = list_masks(train_idx); 
    
    train_dictionary(train_imgs,train_masks);
end



