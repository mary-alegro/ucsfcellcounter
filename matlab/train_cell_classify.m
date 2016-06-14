function [red, green, yellow] = train_cell_classify(dir_imorig,dir_csv)


if dir_imorig(end) ~= '/'
    dir_imorig = [dir_imorig '/'];
end

if dir_csv(end) ~= '/'
    dir_csv = [dir_csv '/'];
end

files = dir(strcat(dir_imorig,'*.tif'));
nFiles = length(files);

red = [];
green = [];
yellow = [];

for i=1:nFiles
    
    file_name = files(i).name;
    img = imread(strcat(dir_imorig,file_name));
    gcsv = csvread(strcat(dir_csv,'green_',changeExt(file_name,'txt')));
    rcsv = csvread(strcat(dir_csv,'red_',changeExt(file_name,'txt')));
    ycsv = csvread(strcat(dir_csv,'yellow_',changeExt(file_name,'txt')));
    
    gcsv = cleanCSV(gcsv);
    rcsv = cleanCSV(rcsv);
    ycsv = cleanCSV(ycsv);
    
    print_points_csv(img,gcsv);
    print_points_csv(img,rcsv);
    print_points_csv(img,ycsv);
    
    % green
    
    

end