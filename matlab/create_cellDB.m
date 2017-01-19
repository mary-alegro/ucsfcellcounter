function create_cellDB(file_list,dest_dir)

%
% Create fluorescence cell patch for training CNNs
%

psize = 47;

dir_img = '/home/maryana/storage/Posdoc/Microscopy/images/toprocess/images/';
dir_csv = '/home/maryana/storage/Posdoc/Microscopy/images/csv/';


if dest_dir(end) ~= '/'
    dest_dir = [dest_dir '/'];
end

dest_red = strcat(dest_dir,'red/');
dest_green = strcat(dest_dir,'green/');
dest_yellow = strcat(dest_dir,'yellow/');

mkdir(dest_red);
mkdir(dest_green);
mkdir(dest_yellow);

nFiles = length(file_list);

gcsv = []; rcsv = []; ycsv = [];

for f=1:nFiles
    
    file_name = file_list{f};
    
    fprintf('Extracting patch from file %s (%d of %d)\n',file_name,f,nFiles);
    
    img_name = strcat(dir_img,file_name);
    img = imread(img_name);
    [R C N] = size(img);
    green_name = strcat(dir_csv,'green_',changeExt(file_name,'txt'));
    red_name = strcat(dir_csv,'red_',changeExt(file_name,'txt'));
    yellow_name = strcat(dir_csv,'yellow_',changeExt(file_name,'txt'));
    
    Red = img(:,:,1); Green = img(:,:,2); Blue = img(:,:,3);
    
    try
        gcsv = csvread(green_name);
        gcsv = cleanCSV(gcsv,R,C);
    catch
        fprintf('%s not found.\n',green_name);
    end
    try
        rcsv = csvread(red_name);
        rcsv = cleanCSV(rcsv,R,C);
    catch
        fprintf('%s not found.\n',red_name);
    end
    try
        ycsv = csvread(yellow_name);
        ycsv = cleanCSV(ycsv,R,C);
    catch
        fprintf('%s not found.\n',yellow_name);
    end
    
    if ~isempty(gcsv)
        gcsv = round(gcsv);
        nP = size(gcsv,1); %no. points
        for p=1:nP
            x = gcsv(p,2); %col
            y = gcsv(p,3); %row
            xysub = sub2ind([R C],y,x);
            w1 = getwindowmod(xysub,Red,psize);
            w2 = getwindowmod(xysub,Green,psize);
            w3 = getwindowmod(xysub,Blue,psize);
            patch = cat(3,w1,w2,w3);
            patch_name = sprintf('%sgreen_%03d_%s',dest_green,p,file_name);
            imwrite(patch,patch_name,'TIFF');
        end 
    end
    
    if ~isempty(rcsv)
        rcsv = round(rcsv);
        nP = size(rcsv,1); %no. points
        for p=1:nP
            x = rcsv(p,2); %col
            y = rcsv(p,3); %row
            xysub = sub2ind([R C],y,x);
            w1 = getwindowmod(xysub,Red,psize);
            w2 = getwindowmod(xysub,Green,psize);
            w3 = getwindowmod(xysub,Blue,psize);
            patch = cat(3,w1,w2,w3);
            patch_name = sprintf('%sred_%03d_%s',dest_red,p,file_name);
            imwrite(patch,patch_name,'TIFF');
        end 
    end
    
    if ~isempty(ycsv)
        ycsv = round(ycsv);
        nP = size(ycsv,1); %no. points
        for p=1:nP
            x = ycsv(p,2); %col
            y = ycsv(p,3); %row
            xysub = sub2ind([R C],y,x);
            w1 = getwindowmod(xysub,Red,psize);
            w2 = getwindowmod(xysub,Green,psize);
            w3 = getwindowmod(xysub,Blue,psize);
            patch = cat(3,w1,w2,w3);
            patch_name = sprintf('%syellow_%03d_%s',dest_yellow,p,file_name);
            imwrite(patch,patch_name,'TIFF');
        end 
    end
    
    gcsv = []; rcsv = []; ycsv = [];
    
end