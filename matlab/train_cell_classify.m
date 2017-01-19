function [red, green, yellow] = train_cell_classify(dir_imorig,dir_csv,doBal)


if dir_imorig(end) ~= '/'
    dir_imorig = [dir_imorig '/'];
end

if dir_csv(end) ~= '/'
    dir_csv = [dir_csv '/'];
end

wsize = 5;

files = dir(strcat(dir_imorig,'*.tif'));
nFiles = length(files);

red = [];
green = [];
yellow = [];

for i=1:nFiles
    
    gcsv =[];
    rcsv = [];
    ycsv = [];
    
    file_name = files(i).name;
    
    fprintf('Image %d: %s.\n',i,file_name);
    
    img = imread(strcat(dir_imorig,file_name));
    green_name = strcat(dir_csv,'green_',changeExt(file_name,'txt'));
    red_name = strcat(dir_csv,'red_',changeExt(file_name,'txt'));
    yellow_name = strcat(dir_csv,'yellow_',changeExt(file_name,'txt'));
    
    try
        gcsv = csvread(green_name);
    catch
        fprintf('%s not found.\n',green_name);
    end
    try
        rcsv = csvread(red_name);
    catch
        fprintf('%s not found.\n',red_name);
    end
    try
        ycsv = csvread(yellow_name);
    catch
        fprintf('%s not found.\n',yellow_name);
    end
    
    [R C N] = size(img);
    lab = rgb2lab(img);
    %lab = rgb2hsv(img);
    %lab = img;
    L = lab(:,:,1); A = lab(:,:,2); B = lab(:,:,3);
    %normalizes Lab channels to [0,1] range
    L = (L - min(L(:)))/(max(L(:)) - min(L(:)));
    A = (A - min(A(:)))/(max(A(:)) - min(A(:)));
    B = (B - min(B(:)))/(max(B(:)) - min(B(:)));
    
    %get green samples
    if ~isempty(gcsv)
        gcsv = cleanCSV(gcsv,R,C);
        nPts = size(gcsv,1);
        
        for p=1:nPts
            x = round(gcsv(p,2)); %col
            y = round(gcsv(p,3)); %row
            idx = sub2ind([R C],y,x);
            w1 = getwindow(idx,L,wsize);
            w2 = getwindow(idx,A,wsize);
            w3 = getwindow(idx,B,wsize);
            
            w = [mean(w1(:)) mean(w2(:)) mean(w3(:))];
            green = cat(1,green,w); 
        end
    end
    
    %get red samples
    if ~isempty(rcsv)
        rcsv = cleanCSV(rcsv,R,C);
        nPts = size(rcsv,1);
        
        for p=1:nPts
            x = round(rcsv(p,2)); %col
            y = round(rcsv(p,3)); %row
            idx = sub2ind([R C],y,x);
            w1 = getwindow(idx,L,wsize);
            w2 = getwindow(idx,A,wsize);
            w3 = getwindow(idx,B,wsize);
            
            w = [mean(w1(:)) mean(w2(:)) mean(w3(:))];
            red = cat(1,red,w); 
        end
    end
    
    %get yellow samples
    if ~isempty(ycsv)
        ycsv = cleanCSV(ycsv,R,C);
        nPts = size(ycsv,1);
        
        for p=1:nPts
            x = round(ycsv(p,2)); %col
            y = round(ycsv(p,3)); %row
            idx = sub2ind([R C],y,x);
            w1 = getwindow(idx,L,wsize);
            w2 = getwindow(idx,A,wsize);
            w3 = getwindow(idx,B,wsize);
            
            w = [mean(w1(:)) mean(w2(:)) mean(w3(:))];
            yellow = cat(1,yellow,w); 
        end
    end

end

if doBal == 1 %balance data set
    nG = size(green,1);
    nR = size(red,1);
    nY = size(yellow,1);   
    
    nSamp = min([nG nR nY]);
    idx = randperm(nSamp);
    green = green(idx,:);
    red = red(idx,:);
    yellow = yellow(idx,:);
end

