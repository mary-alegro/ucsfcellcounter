function GD = load_ground_truth(dir_imorig,dir_csv,dir_seg,dir_mask_orig,img_list)


%
% Loads gorund truth data from CSV files generated using Photoshop
%

if dir_imorig(end) ~= '/'
    dir_imorig = [dir_imorig '/'];
end

if dir_csv(end) ~= '/'
    dir_csv = [dir_csv '/'];
end

if dir_seg(end) ~= '/'
    dir_seg = [dir_seg '/'];
end

if dir_mask_orig(end) ~='/'
    dir_mask_orig = [dir_mask_orig '/'];
end

nFiles = length(img_list);
for i=1:nFiles
    
    gcsv =[];
    rcsv = [];
    ycsv = [];
    
    file_name = img_list{i};
    
    fprintf('Image %d: %s.\n',i,file_name);
  
    GD(i).img_file = file_name;
    GD(i).img_dir = dir_imorig;
    GD(i).csv_dir = dir_csv;
    GD(i).seg_dir = dir_seg;
    GD(i).mask_orig_dir = dir_mask_orig;

    img_name = strcat(dir_imorig,file_name);
    img = imread(img_name);
    [R C N] = size(img);
    green_name = strcat(dir_csv,'green_',changeExt(file_name,'txt'));
    red_name = strcat(dir_csv,'red_',changeExt(file_name,'txt'));
    yellow_name = strcat(dir_csv,'yellow_',changeExt(file_name,'txt'));
    
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
        x = gcsv(:,2); %col
        y = gcsv(:,3); %row
        xysub = sub2ind([R C],y,x);
        gcsv = cat(2,gcsv,xysub);
    end
    if ~isempty(rcsv)
        rcsv = round(rcsv);
        x = rcsv(:,2); %col
        y = rcsv(:,3); %row
        xysub = sub2ind([R C],y,x);
        rcsv = cat(2,rcsv,xysub);
    end
    if ~isempty(ycsv)
        ycsv = round(ycsv);
        x = ycsv(:,2); %col
        y = ycsv(:,3); %row
        xysub = sub2ind([R C],y,x);
        ycsv = cat(2,ycsv,xysub);
    end

    GD(i).yellow = ycsv;
    GD(i).green = gcsv;
    GD(i).red = rcsv;
 
end

