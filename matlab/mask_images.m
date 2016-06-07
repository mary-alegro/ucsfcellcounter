function mask_images(root_dir)

if root_dir(end) ~= '/'
    root_dir = [door_dir '/'];
end

mask_dir = strcat(root_dir,'seg/');
img_dir = strcat(root_dir,'images/');
out_dir = strcat(root_dir,'segrgb/');

files = dir(strcat(mask_dir,'seg1_*'));
nFiles = length(files);

for i=1:nFiles
    
    name = files(i).name;
    mask_name = strcat(mask_dir,name);
    idx = strfind(name,'seg1_');
    img_name = name(idx+5:end);
    out_name = strcat(out_dir,img_name);
    over_name = strcat(out_dir,'over_',img_name);
    img_name = strcat(img_dir,img_name);
    
    
    img = imread(img_name); 
    mask = imread(mask_name);
    [r c N] = size(img);
    mask = imresize(mask,[r c]);
    
    R = img(:,:,1); G = img(:,:,2); B = img(:,:,3);
    R(mask == 0) = 0;
    G(mask == 0) = 0;
    B(mask == 0) = 0;
    
    img2 = cat(3,R,G,B);
    perim = bwperim(mask);
    se = strel('disk',2);
    perim = imdilate(perim,se);
    overlay = imoverlay(img,perim,[1 0 1]);
    
    imwrite(img2,out_name);
    imwrite(overlay,over_name);
    
end
