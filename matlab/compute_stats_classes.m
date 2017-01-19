function GT = compute_stats_classes(img_orig,mask_seg,csv,rules)

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

indGroups = zeros(1,nGroups); %[ignore R G Y] always in this order
incY = 0; %was yellow included in R and G countings?


fprintf('Ground truth:\n');
for g = 1:nGroups
    nPts = length(GT(g).set);
    switch GT(g).rule
        case IG_ %to ignore
            indGroups(1) = g;
            str = 'Nuclei ';
        case R_ %R only
            indGroups(2) = g;
            str = 'R';
        case G_ %G only
            indGroups(3) = g;
            str = 'G';
        case Y_ %Y only
             indGroups(4) = g;
            str = 'Y';
        case RY_ %R+Y
            indGroups(2) = g;
            incY = 1;
            str = 'R(R+Y)';
        case GY_ %G+Y
            indGroups(3) = g;
            incY = 1;
            str = 'G(G+Y)';
        otherwise %unknown rule
            str = 'Unknown';
    end
    
    fprintf(' %s: %d ',str,nPts);
end


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


fprintf('\nSegmentation results:\n');
fprintf(' Total: %d ',nL);

%
% Compute all true positive
%
TP = computeTP(GT,labels, nGroups, idx_centers,nL,incY);

%
% Compute all false positive
%
FP = computeFP(GT,labels, nGroups, idx_centers,nL,incY);

%
% Compute all false negative
%



%%% show image
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

close all;




fprintf(' TP: %d ',length(TP));
fprintf(' FP: %d ',length(FP));


end



%
% Help functions
%

function csv2 = cleanCSV(csv)

[r c N] = size(csv);
rows = 1:r;
toremove = [];

    for i=1:r
        if csv(i,2) < 0 || csv(i,3) < 0
            toremove = [toremove i];
        end
    end

    rows2 = setxor(rows,toremove);
    
    csv2 = csv(rows2,:);    
end

function r = parseRules(rules,group)
%
% ex. RULES = {{'00'} {'14'} {'23'}}
%
    nG = length(rules);
    for i=1:nG
        c = rules{1,i};
        cc = char(c);
        g = str2num(cc(1));
        if g == group
            r = str2num(cc(2));
            break;
        end
    end

end


function TP = computeTP(GT, labels, nGroups, idx_centers, nL, incY)

    IG_ = 0; R_ = 1; G_ = 2;
    Y_ = 3; RY_ = 4; GY_ = 5;

    [r c N] = size(labels);
    se = strel('disk',15);
    TP = [];
    
    for l=1:nL

        ir = []; ig = []; iy = [];
        ctr = idx_centers(l);
        m1 = logical(zeros(r,c));
        idx = find(labels == l);
        m1(idx) = 1;
        m2 = imdilate(m1,se);
        idx_set = find(m2 == 1);

        for j=1:nGroups
            gt_set = GT(j).set;
            switch GT(j).rule
                case IG_
                    continue;
                case {R_,RY_}
                    ir = [ir; intersect(gt_set,idx_set)]; 
                case {G_,GY_}
                    ig = [ig; intersect(gt_set,idx_set)];
                case Y_
                    iy = [iy; intersect(gt_set,idx_set)];
            end    
        end
        II = [];
        if incY > 0 %this counting included Y in R and G groups thus no need to include Y indexes
            II = [ir; ig];
        else
            II = [ir; ig; iy];
        end

        if ~isempty(II) %there is some overlapping, thus this centroid is TP
            TP = [TP ctr];
        end
    end
end

function FP = computeFP(GT, labels, nGroups, idx_centers, nL, incY)

    IG_ = 0; R_ = 1; G_ = 2;
    Y_ = 3; RY_ = 4; GY_ = 5;

    [r c N] = size(labels);
    se = strel('disk',15);
    FP = [];
    
    for l=1:nL

        ir = []; ig = []; iy = [];
        ctr = idx_centers(l);
        m1 = logical(zeros(r,c));
        idx = find(labels == l);
        m1(idx) = 1;
        m2 = imdilate(m1,se);
        idx_set = find(m2 == 1);

        for j=1:nGroups
            gt_set = GT(j).set;
            switch GT(j).rule
                case IG_
                    continue;
                case {R_,RY_}
                    ir = [ir; intersect(gt_set,idx_set)]; 
                case {G_,GY_}
                    ig = [ig; intersect(gt_set,idx_set)];
                case Y_
                    iy = [iy; intersect(gt_set,idx_set)];
            end    
        end
        II = [];
        if incY > 0 %this counting included Y in R and G groups thus no need to include Y indexes
            II = [ir; ig];
        else
            II = [ir; ig; iy];
        end

        if isempty(II) %there is some overlapping, thus this centroid is TP
            FP = [FP ctr];
        end
    end
end


function FN = computeFN(GT, labels, nGroups, idx_centers, nL, incY)

    



end







