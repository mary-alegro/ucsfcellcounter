function [Total, nTP, nFP, nFN, P, Rec, F1] = compute_stats_delanuay(img_orig,seg_set,GT,mask)

%
% Computer segmentation statistics using Delanuay to find the distance
% between cell centroids
%
%
% IMG_ORIG: original image
% SEG_SET: segmented cells centroids, in INDICE form
% GT: ground truth struct
%


SHOW_IMG = 1;
[r c N] = size(img_orig);

FILTER_DIST = 30;

%
% %%% GROUND TRUTH
%
fprintf('Ground truth (original):\n');
r_set = [];
g_set = [];
y_set = [];

if ~isempty(GT.red)
    r_set = GT.red(:,5);
end
if ~isempty(GT.green)
    g_set = GT.green(:,5);
end
if ~isempty(GT.yellow)
    y_set = GT.yellow(:,5);
end

gt_set = cat(1,r_set,g_set,y_set);
%[sR,sC,gt_set,rmvR, rmvC] = delanuay_threshold(img_orig,gt_set,FILTER_DIST,mask); 
Total = length(gt_set);
% nRed = size(GT.red,1);
% nGreen = size(GT.green,1);
% nYellow = size(GT.yellow,1);
% fprintf('    Red: %d | Green: %d | Yellow: %d\n',nRed,nGreen,nYellow);
fprintf('Ground truth results:\n');
fprintf('    TOTAL: %d\n',Total);

%
%%% Process segmented set
%
%Total_s = length(seg_set);
[seg_R,seg_C,seg_set_f,rmvR,rmvC] = delanuay_threshold(img_orig,seg_set,20,mask); 
Total_s = length(seg_set_f);
fprintf('Segmentation results:\n');
fprintf('    TOTAL: %d  ',Total_s);

%
% Compute all true positive
%
%TP = computeTP(gt_set,labels,idx_centers,nL);
TP = computeTP(img_orig,gt_set,seg_set_f);
nTP = length(TP);

%
% Compute all false positive
%
%FP = computeFP(gt_set,labels,idx_centers,nL);

%
% Compute all false negative
%
%FN = computeFN(gt_set,mask2);
FN = setdiff(gt_set,TP);
nFN = length(FN);

%%% show image
if SHOW_IMG == 1

    imshow(img_orig);  hold on,
    %segmentation
    [R,C] = ind2sub([r c],seg_set_f);
    plot(C,R,'co', 'MarkerSize',12);
    %ground truth
    [R,C] = ind2sub([r c],gt_set);
    plot(C,R,'wo', 'MarkerSize',20);
    %true positive
    [R,C] = ind2sub([r c],TP);
    plot(C,R,'w*', 'MarkerSize',12);
%     %false positive
%     [R,C] = ind2sub([r c],FP);
%     plot(C,R,'y*', 'MarkerSize',12);
    %false negative
    [R,C] = ind2sub([r c],FN);
    plot(C,R,'m*', 'MarkerSize',12);
end
%close all;

%nFN = Total - nTP;
%nFP = length(FP);
nFP = Total_s - (nTP+nFN);
fprintf('TP: %d ',nTP);
fprintf('FP: %d ',nFP);
fprintf('FN: %d\n',nFN);

% compute precision and recall scores
P = nTP/(nTP + nFP);
Rec = nTP/(nTP + nFN);
F1 = (2*P*Rec)/(P+Rec);

fprintf('*** Total: %d     TP rate: %f    FP rate: %f    FN rate: %f ***\n',Total, nTP/Total, nFP/Total, nFN/Total);
fprintf('*** PRECISION: %f    RECALL: %f    F1: %f ***\n',P,Rec,F1);
end


function TP = computeTP(img,gt_set,seg_set)

TP = [];
MIN_DIST = 20;
[r c] = size(img);
nGT = length(gt_set);
nSeg = length(seg_set);
pts = cat(1,gt_set,seg_set); %[1:nGT] = GT, [nGT+1:end] = seg
edgeM = delanuay_distance(img,pts);
edges = zeros(size(edgeM));
edges(edgeM > 0 & edgeM < MIN_DIST) = 1;

for p = 1:nGT
    v = edges(p,:);
    if sum(v) > 0 %if there is a non-epty edge
        idx = find(v > 0);
        TP = [TP; gt_set(p)];
    end
end

end










