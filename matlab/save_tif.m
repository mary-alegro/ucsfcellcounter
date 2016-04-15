function save_tif(direc,outdir,levels)

%
% Save tiff image in smaller size
%

if direc(end) ~= '/'
    direc = [direc '/'];
end

if outdir(end) ~= '/'
    outdir = [outdir '/'];
end
    

files = dir(strcat(direc,'*.tif'));
nFiles = length(files);
for f=1:nFiles
    name = files(f).name;
    fullname = strcat(direc,name);
    
    fprintf('Saving %s\n',name);
    
    [img, R,G,B] = load_img(fullname,0);
    
    if levels == 1 %adjust histogram levels (contrast)
        Rc = compress_hist(R);
        Gc = compress_hist(G);
        Bc = compress_hist(B);
    end
    
    img = cat(3,Rc,Gc,Bc);
    
    img = imresize(img,0.25);
    
    idx = strfind(name,'.tif');
    name2 = name(1:idx-1);
    name2 = strcat(name2,'.tif');
    fullname2 = strcat(outdir,name2);
    
    imwrite(img,fullname2,'TIFF');
end

