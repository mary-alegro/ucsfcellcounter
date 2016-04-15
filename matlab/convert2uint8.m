function saveasuint8(dir_root)

if dir_root(end) ~= '/'
    dir_root = [dir_root '/'];
end

files = dir(strcat(dir_root,'*.tif'));
nFiles = length(files);

for f=1:nFiles  
    
    try
    
    name = files(f).name;
    fullname = strcat(dir_root,name);
    name2 = strcat('uint8_',name);
    fullname2 = strcat(dir_root,name2);
    
    [img, R, G, B] = load_img(fullname,0);
    
    imwrite(img,fullname2,'TIFF'); 
    
    catch
        fprintf('Could not read file %s\n',name);
    end
end

