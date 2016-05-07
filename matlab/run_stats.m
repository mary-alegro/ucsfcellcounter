function stats = run_stats(dir_imorig,dir_mask,dir_csv,cnt_rules)

%
% DIR_CSV: full dir path of the counted cell csv files. CSV file names must be exactly the same for csv, mask and image files
% DIR_IMORIG: dir path to original fluorescenc images (i.e. original size, which in principle will match the size of the counted images)
% DIR_MASK: dir path to segmentation masks (will probably be smaller than
% the original images)
% CNT_RULES: csv file name + rules describing how the image was counted. 
%            Ex. {''}
%
%

if dir_imorig(end) ~= '/'
    dir_imorig = [dir_imorig '/'];
end

if dir_mask(end) ~= '/'
    dir_mask = [dir_mask '/'];
end

if dir_csv(end) ~= '/'
    dir_csv = [dir_csv '/'];
end

nFiles = length(cnt_rules);

stats = zeros(nFiles,5);
nError = 0;
for i=1:nFiles
    
    cnt_cell = cnt_rules{i};
    file_name = cnt_cell{1,1};
    rule = cnt_cell{1,2};
    
    csv_name = strcat(dir_csv,file_name);
    img_name = strcat(dir_imorig,changeExt(file_name,'tif')); %original image
    mask_name = strcat(dir_mask,'seg2_',changeExt(file_name,'tif'));
    
    csv = csvread(csv_name);
    img = imread(img_name);
    mask = imread(mask_name);
    
    fprintf('------ **** File %s (%d of %d) **** -----\n',file_name,i,nFiles);
    try
        [TP, FP, FN, PA, TC, P, R, F1] = compute_stats(img,mask,csv,rule);

        stats(i,1) = length(TP);
        stats(i,2) = length(FP);
        stats(i,3) = length(FN);
        stats(i,4) = PA;
        stats(i,5) = P;
        stats(i,6) = R;
        stats(i,7) = F1;
    catch ME
        nError = nError + 1;
        fprintf('\n### Error in file: %s###\n',file_name);
        msg = getReport(ME);
        fprintf(msg);
    end
    
end

fprintf('There were %d errors.\n',nError);

end

%
% ex: ext = 'jpg'
%
function new_name = changeExt(name,ext)

    idx = strfind(name,'.');
    idx = idx(end);
    
    new_name = strcat(name(1:idx),ext);
end
    