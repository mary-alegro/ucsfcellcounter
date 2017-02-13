function  [timeDL, timeP] = test_dictionary(list_imgs,list_masks,seg_dir,orig_mask_dir)

if seg_dir(end) ~= '/'
    seg_dir = [seg_dir '/'];
end

if orig_mask_dir(end) ~= '/'
    orig_mask_dir = [orig_mask_dir '/'];
end

nFiles = length(list_imgs);
nMasks = length(list_masks);

wsize = 11;

if nFiles ~= nMasks
    error('Test DL: number of images and masks must agree.'); 
end

%segment each test file
nError = 0;
timeDL = zeros(1,nFiles);
timeP = zeros(1,nFiles);
for f=1:nFiles

    nameimg = char(list_imgs(f));
    
    fprintf('Segmenting %s\n.', nameimg);
    
    idx = strfind(nameimg,'/');
    idx  = idx(end);
    name = nameimg(idx+1:end);
    
    namemask_orig = strcat(orig_mask_dir,name);
    namemask = char(list_masks(f));

    [img, R, G, B] = load_img(nameimg,1);
    mask = load_mask(namemask,1);
    mask_orig = imread(namemask_orig);
    if size(mask_orig,3) > 1
        mask_orig = mask_orig(:,:,1);
    end
    
    try
         %%%% 
         %segmentation
         %%%%
         tic;
         [mask, Ef, Eb] = seg_dictionary(R,G,B,mask,wsize);
         seg1_name = strcat(seg_dir,'seg1_',name);
         imwrite(mask,seg1_name,'TIFF');
         close all;
         time1 = toc;
         timeDL(f) = time1;
         
          %%%%  
          %mask refinement
          %%%%
          %mask_seg = imread(seg1_name);
          tic;
          mask_seg = mask;
          mask_seg = posproc_mask(img,mask_seg,mask);
          mask2 = posproc_mask_ws_old(img,mask_seg);
          close all;
          
          %%%%
          %posproc filter
          %%%%
          img_g = imgaussfilt(img,1.5);
          dE = delta_lab(img_g,mask2,mask_orig);
          dE(mask2 < 1) = 0;
          pix = dE(dE > 0);
          t =  prctile(pix,75); %Q3
          dE(dE <= t) = 0;
          mask2(dE == 0) = 0;
          
%            dE = delta_lab2(img_g,8.5,0.01,0.01);
%            dE(mask2 < 1) = 0;
%            pix = dE(dE > 0);
%            t =  prctile(pix,25); %Q1
%            dE(dE <= t) = 0;
%            mask2(dE == 0) = 0;
%              
%           [labels, nL] = bwlabel(mask2);
%           props = regionprops(labels,'Area','Eccentricity','ConvexArea','Solidity');
%           %remove small fragments
%           area = [props.Area];
%           skew = skewness(area);
%           if(abs(0-skew) > 1)
%               qa = prctile(area,5);
%               l = find(area <= qa);
%               idx = find(ismember(labels,l));
%               mask2(idx) = 0; 
%           end
%           %ecc = [props.Eccentricity];
%           %remove convex objects
%           sol = [props.Solidity];
%           skew = skewness(sol);
%           if(abs(0-skew) > 1)
%               qs = prctile(sol,10);
%               l = find(sol <= qs);
%               idx = find(ismember(labels,l));
%               mask2(idx) = 0;
%           end
          time2 = toc;
          timeP(f) = time2;
    
          seg2_name = strcat(seg_dir,'seg2_',name);
          imwrite(mask2,seg2_name,'TIFF');
          close all;
          
          %%%%
          % classification
          %%%%
% %          seg2_name = strcat(seg_dir,'seg2_',name);
% %          mask2 = imread(seg2_name);
% %          %mask3 = posproc_chroma(img,mask2);
%             samples=load('cell_samples.mat');
%             samples = samples.samples;
%             [mask_class mask_class1 mask_class2 mask_class3] = posproc_classify(img,mask2,mask_orig,samples);
%             seg3_name = strcat(seg_dir,'seg3_',name);
%             seg3_name_c1 = strcat(seg_dir,'seg3_c1_',name);
%             seg3_name_c2 = strcat(seg_dir,'seg3_c2_',name);
%             seg3_name_c3 = strcat(seg_dir,'seg3_c3_',name);
%             imwrite(mask_class,seg3_name,'TIFF');
%             imwrite(mask_class1,seg3_name_c1,'TIFF');
%             imwrite(mask_class2,seg3_name_c2,'TIFF');
%             imwrite(mask_class3,seg3_name_c3,'TIFF');
%           close all;
    catch ME
        nError = nError + 1;
        msg = getReport(ME);
        fprintf(msg);
        close all;
    end
end


end


