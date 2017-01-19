function samples = train_classify(GD)

%
% Trains the cell classification (in RED, GREEN and YELLOW) step 
% Grab pixel samples from the fluorescence images using GT coordinates as a
% guide. Converts then to LAB. 
%
%

wsize = 5;

nFiles = length(GD);

for i=1:nFiles
    
    red = [];
    green = [];
    yellow = [];

    file_name = GD(i).img_file;
    dir_imorig = GD(i).img_dir;
    img = imread(strcat(dir_imorig,file_name));
    
    %fprintf('Image %d: %s.\n',i,file_name);

    gcsv = GD(i).green;
    rcsv = GD(i).red;
    ycsv = GD(i).yellow;

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
    
    samples(i).yellow = yellow;
    samples(i).red = red;
    samples(i).green = green;

end



