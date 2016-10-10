function stats = leave_1_out_classify(GT)

%
% Test cell classification
%

SHOW = 1;

nFiles = length(GT);
idx_all = 1:nFiles;

stats = [];
for i=1:nFiles
    
    %skip files that don't have ground truth data, they can't be
    %validated
    if isempty(GT(i).red) && isempty(GT(i).red) && isempty(GT(i).red) 
        continue;
    end
    
    file_name = GT(i).img_file;
    
    fprintf('*** Processing (%d): %s ***\n',i,file_name);
    
    img_name = strcat(GT(i).img_dir,file_name);
    mask_name = strcat(GT(i).seg_dir,'seg2_',file_name);
    mask_orig_name = strcat(GT(i).mask_orig_dir,file_name);
    out_name = strcat(GT(i).seg_dir,'seg3_',file_name);
    
    %---
    %load files in original size
    %---
    img = imread(img_name);
    [rows cols N] = size(img);
    mask_orig = imread(mask_orig_name);
    mask = imread(mask_name);
    mask = imresize(mask,[rows cols]);

    idx = setdiff(idx_all,i);
    GT_train = GT(idx);
    samples = train_classify(GT_train);
    %samples=load('samples.mat');
    samples = samples.samples;
    
    %run classification
    %[mask_class mask_class1 mask_class2 mask_class3] = posproc_classify(img,mask,mask_orig,samples);
    %imwrite(mask_class,out_name);
    
    if SHOW == 1
        display = 1;
        try
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
        catch
            fprintf('Error displaying image.\n');
            display = 0;
        end
    end

    %compute correct classification rate
    [rcount wcount TP] = correct_rate(GT(i),mask_class);
    total = length(TP);
    RC = length(rcount);
    WC = length(wcount);
    
    if SHOW == 1
        [r_RC,c_RC] = ind2sub([rows cols],rcount);
        [r_WC,c_WC] = ind2sub([rows cols],wcount);
        if display == 1
            %figure,
            %imshow(img);
            %hold on,
            plot(c_RC,r_RC,'mo','MarkerSize', 10);
            plot(c_WC,r_WC,'ro','MarkerSize', 10);
        end
    end
    
    pRight = RC/total;
    pWrong = WC/total;
    
    fprintf('Total counted: %d\n',total);
    fprintf('Correct classification: %f (%d of %d)\n',pRight,RC,total);
    fprintf('Wrong classification: %f (%d of %d)\n\n',pWrong,WC,total);
    
    stat = [total RC WC];
    stats = cat(1,stats,stat);
    
    
      
end

end


function [rcount wcount TP] = correct_rate(GT,mask_class)

    [labels nL] = bwlabel(mask_class);
    se = strel('disk',3);
    [R C N] = size(mask_class);
   
    g_set = [];
    r_set = [];
    y_set = [];
    
    if ~isempty(GT.green)
        g_set = GT.green(:,5);
    end
    
    if ~isempty(GT.red)
        r_set = GT.red(:,5);
    end
    
    if ~isempty(GT.yellow)
        y_set = GT.yellow(:,5);
    end
      
    TP = [];
    rcount = [];
    wcount = [];
    for l=1:nL
        
        Ug = [];
        Ur = [];
        Uy = [];
        
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
        Ug = intersect(g_set,idx_set);
        if ~isempty(Ug) 
            if fclass == 2
                rcount = [rcount; Ug]; %right count
            else
                wcount = [wcount; Ug]; %wrong count
            end
        end
        %search red
        Ur = intersect(r_set,idx_set);
        if ~isempty(Ur) 
            if fclass == 1
                rcount = [rcount; Ur]; %right count
            else
                wcount = [wcount; Ur]; %wrong count
            end
        end
        %search yellow
        Uy = intersect(y_set,idx_set);
        if ~isempty(Uy) 
            if fclass == 3
                rcount = [rcount; Uy]; %right count
            else
                wcount = [wcount; Uy]; %wrong count
            end
        end
        
        TP = [TP; Ug; Ur; Uy];
    end
    
%     total = length(TP);
%     CC = length(rcount);
%     WC = length(wcount);
end





