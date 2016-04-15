function  test_dictionary(list_imgs,list_masks,seg_dir)

if seg_dir(end) ~= '/'
    seg_dir = [seg_dir '/'];
end


nFiles = length(list_imgs);
nMasks = length(list_masks);

wsize = 11;

if nFiles ~= nMasks
    error('Test DL: number of images and masks must agree.'); 
end

%segment each test file
for f=1:nFiles

    nameimg = char(list_imgs(f));
    
    fprintf('Segmenting %s\n.', nameimg);
    
    idx = strfind(nameimg,'/');
    idx  = idx(end);
    name = nameimg(idx+1:end);
    
    namemask = char(list_masks(f));

    [img, R, G, B] = load_img(nameimg,1);
    mask = load_mask(namemask,1);
    
    mask = seg_dictionary(R,G,B,mask,wsize);
    seg1_name = strcat(seg_dir,'seg1_',name);
    imwrite(mask,seg1_name,'TIFF');
    close all;

    mask2 = posproc_mask_ws(img,mask);
    seg2_name = strcat(seg_dir,'seg2_',name);
    imwrite(mask2,seg2_name,'TIFF');
    close all;

    mask3 = posproc_chroma(img,mask2);
    seg3_name = strcat(seg_dir,'seg3_',name);
    imwrite(mask3,seg3_name,'TIFF');
    close all;
end


end


function m = load_mask(fullpath,doresize)
    m = imread(fullpath);
    [r c N] = size(m);
    if N > 1
        m = m(:,:,1);
    end
    if doresize == 1
        m = imresize(m,0.25);
    end
end