%function [Total, TP, FP, FN, P, Rec, F1] = compute_stats(img_orig,mask_seg,GT)
function [Total, nTP, nFP, nFN, P, Rec, F1] = compute_stats(img_orig,mask_seg,GT)

SHOW_IMG = 1;
[r c N] = size(img_orig);

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
Total = length(gt_set);
nRed = size(GT.red,1);
nGreen = size(GT.green,1);
nYellow = size(GT.yellow,1);
fprintf('    Red: %d | Green: %d | Yellow: %d\n',nRed,nGreen,nYellow);
fprintf('    TOTAL: %d\n',Total);

%
%%% Process mask
%
mask2 = logical(mask_seg);
mask2 = imresize(mask2,[r c]);

center = regionprops(mask2,'Centroid');
centroids = cat(1,center.Centroid);
centroids = round(centroids);
idx_centers = sub2ind([r c],centroids(:,2),centroids(:,1));

[labels nL] = bwlabel(mask2);

fprintf('Segmentation results:\n');
fprintf('    TOTAL: %d  ',nL);

%
% Compute all true positive
%
%TP = computeTP(gt_set,labels,idx_centers,nL);
TP = computeTP(gt_set,mask2);

%
% Compute all false positive
%
FP = computeFP(gt_set,labels,idx_centers,nL);

%
% Compute all false negative
%
FN = computeFN(gt_set,mask2);

%%% show image
if SHOW_IMG == 1
    overlay = imoverlay(img_orig,bwperim(mask2),[0 1 0]); 
    imshow(overlay);  hold on,
    %ground truth
    [R,C] = ind2sub([r c],gt_set);
    plot(C,R,'wo', 'MarkerSize',20);
    %true positive
    [R,C] = ind2sub([r c],TP);
    plot(C,R,'w*', 'MarkerSize',12);
    %false positive
    [R,C] = ind2sub([r c],FP);
    plot(C,R,'y*', 'MarkerSize',12);
    %false negative
    [R,C] = ind2sub([r c],FN);
    plot(C,R,'m*', 'MarkerSize',12);
end
%close all;

nTP = length(TP); 
nFN = length(FN);
%nFP = length(FP);
nFP = nL - (nTP+nFN);
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


function TP = computeTP(gt_set, mask)

    se = strel('disk',15);
    mask = imdilate(mask,se);
    idx_set = find(mask == 1);
    TP = intersect(gt_set,idx_set);

end



% function TP = computeTP(gt_set, labels, idx_centers, nL)
% 
%     [r c N] = size(labels);
%     se = strel('disk',5);
%     
%     TP = [];
%     for l=1:nL
%         ctr = idx_centers(l);
%         m1 = logical(zeros(r,c));
%         idx = find(labels == l);
%         m1(idx) = 1;
%         m2 = imdilate(m1,se);
%         idx_set = find(m2 == 1);
%         
%         U = intersect(gt_set,idx_set);
%         if ~isempty(U)
%             TP = [TP ctr];
%         end
%     end
% 
% end

function FP = computeFP(gt_set, labels, idx_centers, nL)

    [r c N] = size(labels);
    se = strel('disk',15);
    
    FP = [];
    for l=1:nL
        ctr = idx_centers(l);
        m1 = logical(zeros(r,c));
        idx = find(labels == l);
        m1(idx) = 1;
        m2 = imdilate(m1,se);
        idx_set = find(m2 == 1);
        
        U = intersect(gt_set,idx_set);
        if isempty(U)
            FP = [FP ctr];
        end
    end
     
end


function FN = computeFN(gt_set, mask)

    se = strel('disk',15);
    mask2 = imdilate(mask,se);
    idx_set = find(mask2 == 1);
    FN = setdiff(gt_set,idx_set);

end







