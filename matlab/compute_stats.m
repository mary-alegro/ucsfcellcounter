function [TP, FP, FN, PA, TC, P, Rec, F1] = compute_stats(img_orig,mask_seg,csv,rules)

%
% Computes segmentation statistic without considering classification in R,G
% or Y
%
% IMG_ORIG: original image, with original size = image used for counting w/
% photoshop
% MASK_SEG: segmentation mask with classes (usually smaller than IMG_ORIG)
% CSV: photoshop CSV, counted on IMG_ORIG. CSV must have 4 columns:
%       1: group number
%       2: X coord
%       3: Y coord
%       4: id inside group
%
% RULES: describes how the image was counted. Are in the same order the groups appear in the CSV file 
%           0: should ignore
%           1: red cells only
%           2: green cells only
%           3: yellow cells only
%           4: red + yellow cells are grouped together
%           5: green + yellow cells are grouped together
%

% rules constants
IG_ = 0; R_ = 1; G_ = 2; Y_ = 3; RY_ = 4; GY_ = 5;

[r c N] = size(img_orig);

%
%%% Process CSV
%
csv = cleanCSV(csv); %cleans points that may be outside the image area
groups = unique(csv(:,1));
nGroups = length(groups);
GT = [];
for j = 0:nGroups-1
    idx = find(csv(:,1) == j); 
    pts = round(csv(idx,2:3));
    GT(j+1).set = sub2ind([r c],pts(:,2),pts(:,1));
    GT(j+1).rule = parseRules(rules,j);
end

indGroups = []; %only includes groups that will not be ignored [R G Y]
incY = 0; %was yellow included in R and G countings?
gr = []; gg = []; gy = [];
fprintf('Ground truth (original):\n');
for g = 1:nGroups
    nPts = length(GT(g).set);
    switch GT(g).rule
        case IG_ %to ignore
            str = sprintf('Nuclei (#%d)',g);
        case R_ %R only
            gr = g;
            str = sprintf('R (#%d)',g);
        case G_ %G only
            gg = g;
            str = sprintf('G (#%d)',g);
        case Y_ %Y only
             gy = g;
            str = sprintf('Y (#%d)',g);
        case RY_ %R+Y
            gr = g;
            incY = 1;
            str = sprintf('R+Y (#%d)',g);
        case GY_ %G+Y
            gg = g;
            incY = 1;
            str = sprintf('G+Y (#%d)',g);
        otherwise %unknown rule
            str = 'Unknown';
    end
    
    fprintf(' %s: %d ',str,nPts);
end
indGroups = [gr gg gy];
%prune data to remove redundant points
gt_set = [];
if incY == 1
        gt_set = delanuay_cluster(img_orig,GT,indGroups);
else
    for i=2:nGroups
            gt_set = [gt_set; GT(i).set];
    end
end

fprintf('\nGround truth (clean): \n');
fprintf('    Num. cells: %d\n',length(gt_set));


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
fprintf('    Total: %d  ',nL);

%
% Compute all true positive
%
TP = computeTP(gt_set,labels,idx_centers,nL);

%
% Compute all false positive
%
FP = computeFP(gt_set,labels,idx_centers,nL);

%
% Compute all false negative
%
FN = computeFN(gt_set,mask2);

%%% show image
SHOW_IMG = 0;
if SHOW_IMG
    n = length(indGroups);
    overlay = imoverlay(img_orig,bwperim(mask2),[0 1 0]); 
    imshow(overlay);  hold on,
    for g=2:n
        gg = indGroups(g);
        [R,C] = ind2sub([r c],GT(gg).set);
        plot(C,R,'wo', 'MarkerSize',20);
    end
    [R,C] = ind2sub([r c],TP);
    plot(C,R,'w*', 'MarkerSize',12);
    [R,C] = ind2sub([r c],FP);
    plot(C,R,'y*', 'MarkerSize',12);
    [R,C] = ind2sub([r c],FN);
    plot(C,R,'m*', 'MarkerSize',12);

    close all;
end

fprintf(' TP: %d ',length(TP));
fprintf(' FP: %d ',length(FP));
fprintf(' FN: %d\n',length(FN));

PA = (length(TP)*100)/length(gt_set);
fprintf('** PA: %f   ',PA);

TC = (length(TP) - 0.5*length(FP))/length(gt_set);
fprintf('  TC: %f   ',TC);

P = length(TP)/(length(TP) + length(FP));
Rec = length(TP)/(length(TP) + length(FN));
F1 = (2*P*Rec)/(P+Rec);
fprintf('Precision: %f   Recal: %f   F1: %f **\n',P,Rec,F1);
end


function TP = computeTP(gt_set, labels, idx_centers, nL)

    [r c N] = size(labels);
    se = strel('disk',15);
    
    TP = [];
    for l=1:nL
        ctr = idx_centers(l);
        m1 = logical(zeros(r,c));
        idx = find(labels == l);
        m1(idx) = 1;
        m2 = imdilate(m1,se);
        idx_set = find(m2 == 1);
        
        U = intersect(gt_set,idx_set);
        if ~isempty(U)
            TP = [TP ctr];
        end
    end

end

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






