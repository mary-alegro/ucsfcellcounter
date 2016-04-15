function run_seg(direc)

if direc(end) ~= '/'
    direc = [direc '/'];
end

wsize = 11;

dir_mask = strcat(direc,'masks/');
dir_img = strcat(direc,'proc/');
dir_seg = strcat(direc,'seg/'); 

files = dir(strcat(dir_mask,'*_mask.tif'));
nFiles = length(files);

for f=1:nFiles
    name = files(f).name;
    
    fprintf('Segmenting %s\n',name);
    
    idx = strfind(name,'_mask.tif');
    name2 = name(1:idx-1);
    name2 = strcat(name2,'.tif');
    name_img = strcat(dir_img,name2);
    name_seg = strcat(dir_seg,name2);
    
    mask_orig = imread(strcat(dir_mask,name));
    img = imread(name_img);
    R = img(:,:,1);
    G = img(:,:,2);
    B = img(:,:,3);
    
    mask = test_DL4(R,G,B,mask_orig,wsize);
    
    imwrite(mask,name_seg,'TIFF'); 
    
end

