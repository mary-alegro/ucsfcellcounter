function save_tif_big(direc,outd,levels)

%
% Save tiff image
%

if direc(end) ~= '/'
    direc = [direc '/'];
end

if outd(end) ~= '/'
    outd = [outd '/'];
end
    

files = dir(strcat(direc,'*.tif'));
nFiles = length(files);
for f=1:nFiles
    name = files(f).name;
    fullname = strcat(direc,name);
    
    [img, R,G,B] = load_img(fullname,0);
    

    if levels == 1 %adjust histogram levels (contrast)
        Rc = compress_hist(R);
        Gc = compress_hist(G);
        Bc = compress_hist(B);
    end
    
    img = cat(3,Rc,Gc,Bc);
    
    idx = strfind(name,'.tif');
    name2 = name(1:idx-1);
    name2 = strcat(name2,'.tif');
    fullname2 = strcat(outd,name2);
    
    imwrite(img,fullname2,'TIFF');
end

