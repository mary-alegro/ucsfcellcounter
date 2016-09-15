function stats = run_stats(GT)

%
% Computes cell segmentation stats
%
%

nFiles = length(GT);

stats = zeros(nFiles,8);
nError = 0;

FID = fopen('counter_segstats.txt','w');

for i=1:nFiles

    currGT = GT(i); % current file ground truth data
    file_name = GT(i).img_file;
    
    if isempty(currGT.red) && isempty(currGT.green) && isempty(currGT.yellow)
        fprintf('Skipping file %s - no ground truth data -\n',file_name);
        continue;
    end
    
    img_name = strcat(GT(i).img_dir,file_name); %original image
    mask_name = strcat(GT(i).seg_dir,'seg2_',file_name);
    
    img = imread(img_name);
    mask = imread(mask_name);
    
    fprintf('------ **** File %s (%d of %d) **** -----\n',file_name,i,nFiles);
    fprintf(FID,'\n**** File %s (%d of %d) ****\n',file_name,i,nFiles);
    try
        %[T,TP, FP, FN, P, R, F1,] = compute_stats(img,mask,currGT);
        [T,nTP, nFP, nFN, P, R, F1,] = compute_stats(img,mask,currGT);
        close all;
        
%         nTP = length(TP);
%         nFP = length(FP);
%         nFN = length(FN);

        stats(i,1) = T;
        stats(i,2) = nTP;
        stats(i,3) = nFP;
        stats(i,4) = nFN;
        stats(i,5) = P;
        stats(i,6) = R;
        stats(i,7) = F1;
        stats(i,8) = i;
        
        fprintf(FID,'Total: %d TP: %d FP: %d FN: %d Prec.: %f Rec: %f F1: %f \n',T,nTP,nFP,nFN,P,R,F1);
        fprintf(FID,'TP rate: %f FP rate: %d FN rate: %f\n',nTP/T, nFP/T, nFN/T);
  
    catch ME
        nError = nError + 1;
        fprintf('\n### Error in file: %s###\n',file_name);
        fprintf(FID,'\n### Error in file: %s###\n',file_name);
        msg = getReport(ME);
        fprintf(msg);
    end
    
end

fprintf('There were %d errors.\n',nError);

fprintf(FID,'Num. errors: %d.\n',nError);
fprintf(FID,'END\n');
fclose(FID);

end

% %
% % ex: ext = 'jpg'
% %
% function new_name = changeExt(name,ext)
% 
%     idx = strfind(name,'.');
%     idx = idx(end);
%     
%     new_name = strcat(name(1:idx),ext);
% end
    
