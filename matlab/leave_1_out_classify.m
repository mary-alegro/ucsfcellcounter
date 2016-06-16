function leave_1_out_classify(GT)

%
% Test cell classification
%

nFiles = length(GT);
idx_all = 1:nFiles;

CC = [];
WC = [];

for i=1:nFiles
    
    %skip files that don't have ground truth data, they can't be
    %validated
    if isempty(GT(i).red) && isempty(GT(i).red) && isempty(GT(i).red) 
        continue;
    end
    
    file_name = GT(i).img_file;
    img_name = strcat(GT(i).img_dir,file_name);
    mask_name = strcat(GT(i).seg_dir,'seg2_',file_name);
    mask_orig_name = strcat(GT(i).mask_orig_dir,file_name);
    out_name = strcat(GT(i).seg_dir,'seg3_',file_name);
    
    %load files
    img = imread(img_name);
    [rows cols N] = size(img);
    mask_orig = imread(mask_orig_name);
    mask = imread(mask_name);
    mask = imresize(mask,[rows cols]);
    
    idx = setdiff(idx_all,i);
    GT_train = GT(idx);
    %samples = train_classify(GT_train);
    samples=load('samples.mat');
    samples = samples.samples;
    
    %run classification
    [mask_class mask_class1 mask_class2 mask_class3] = posproc_classify(img,mask,mask_orig,samples);
    imwrite(mask_class,out_name);
    
    masks = cat(3,bwperim(mask_class1),bwperim(mask_class2),bwperim(mask_class3));
    colors = cat(1,[1 0 0],[0 1 0],[1 1 0]);
    overlay = imoverlaymult(img, masks, colors); 
    imshow(overlay);
    hold on,
    csv = GT(i).red(:,2:3);
    plot(csv(:,1),csv(:,2),'r*','MarkerSize', 10);
    csv = GT(i).green(:,2:3);
    plot(csv(:,1),csv(:,2),'g*','MarkerSize', 10);
    csv = GT(i).yellow(:,2:3);
    plot(csv(:,1),csv(:,2),'y*','MarkerSize', 10);
    
    
    [CC WC total] = correct_rate(GT(i),mask_class);
      
end

end


function [CC WC total] = correct_rate(GT,mask_class)

    [labels nL] = bwlabel(mask_class);
    se = strel('disk',3);
    [R C N] = size(mask_class);
   
    g_set = GT.green(:,5);
    r_set = GT.red(:,5);
    y_set = GT.yellow(:,5);
      
    TP = [];
    for l=1:nL
        
        
        m = zeros(R,C);
        idx_set = find(labels == l);
        m(idx_set) = mask_class(idx_set);
       
        if m(idx_set(1)) == 90 %red
            fclass = 1;
        elseif m(idx_set(1)) == 190 %green
            fclass = 2;
        elseif m(idx_set(1)) == 250 %yellow
            fclass = 3;
        end
        
        m = imdilate(m,se);
        idx_set = find(m ~= 0);
        
        %search green
        g_set = GT.green(:,5);
        Ug = intersect(g_set,idx_set);
        %search red
        r_set = GT.red(:,5);
        Ur = intersect(r_set,idx_set);
        %search yellow
        y_set = GT.yellow(:,5);
        Uy = intersect(y_set,idx_set);
        
        TP = [TP; Ug; Ur; Uy];
   
    end
    
    total = length(TP);
end





