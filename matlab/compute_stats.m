function labels = compute_stats(img_orig,mask_seg,csv)

%
% IMG_ORIG: original image, with original size = image used for counting w/
% photoshop
% MASK_SEG: segmentation mask with classes (usually smaller than IMG_ORIG)
% CSV: photoshop CSV, counted on IMG_ORIG
%


[r c N] = size(img_orig);
mask2 = logical(mask_seg);
mask2 = imresize(mask2,[r c]);

csv = cleanCSV(csv);

center = regionprops(mask2,'Centroid');
nCells = length(center);

center = cat(1,center.Centroid);

idx = find(csv(:,1) == 0); %all
pts_a = round(csv(idx,2:3));

[tr tc tN] = size(pts_a);
a_set = sub2ind([r c],pts_a(:,2),pts_a(:,1));

idx = find(csv(:,1) == 1); %red
pts_r = round(csv(idx,2:3));
r_set = sub2ind([r c],pts_r(:,2),pts_r(:,1));

idx = find(csv(:,1) == 2); %green
pts_g = round(csv(idx,2:3));
g_set = sub2ind([r c],pts_g(:,2),pts_g(:,1));

idx = find(csv(:,1) == 3); %yellow
pts_y = round(csv(idx,2:3));
y_set = sub2ind([r c],pts_y(:,2),pts_y(:,1));

[labels nL] = bwlabel(mask2);

fprintf('Number of red: %d\n',length(r_set));
fprintf('Number of green: %d\n',length(g_set));
fprintf('Number of yellow: %d\n',length(y_set));
fprintf('\nNumber of segmented cells: %d\n',nL);

se = strel('disk',15);

mask3 = zeros(r,c);

%compute true and false positives
TP = zeros(nL,1);
FP = zeros(nL,1);
for l=1:nL   
    m1 = logical(zeros(r,c));
    idx = find(labels == l);
    m1(idx) = 1;
    
    m2 = imdilate(m1,se);
    idx_set = find(m2 == 1);
    
    mask3(m2 == 1) = 1;
    
    %Ua = intersect(idx_set,a_set);
    Ur = intersect(idx_set,r_set);
    Ug = intersect(idx_set,g_set);
    Uy = intersect(idx_set,y_set);
    
    if ~isempty(Ur) || ~isempty(Ug) || ~isempty(Uy)
        TP(l) = 1;
    else
        FP(l) = 1;
    end
    
    %fprintf('\nCell %d\n',l);
    %fprintf('all: %d | red: %d | green: %d | yellow: %d\n',length(Ua),length(Ur),length(Ug),length(Uy));
    %fprintf('red: %d | green: %d | yellow: %d\n',length(Ur),length(Ug),length(Uy));
end

%compute false negatives
m_set = find(mask3 == 1);

nP = length(g_set);
FN_g = zeros(nP,1);
for p=1:nP
    u = intersect(g_set(p),m_set);
    if isempty(u)
        FN_g(p) = 1;
    end
end

nP = length(r_set);
FN_r = zeros(nP,1);
for p=1:nP
    u = intersect(r_set(p),m_set);
    if isempty(u)
        FN_r(p) = 1;
    end
end

nP = length(y_set);
FN_y = zeros(nP,1);
for p=1:nP
    u = intersect(y_set(p),m_set);
    if isempty(u)
        FN_y(p) = 1;
    end
end

fprintf('True positives: %d\n',sum(TP));
fprintf('False positives: %d\n',sum(FP));
fprintf('False negatives: %d\n',sum(FN_r) + sum(FN_g));
fprintf('    R: %d\n',sum(FN_r));
fprintf('    G: %d\n',sum(FN_g));
fprintf('    Y: %d\n',sum(FN_y));



end



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



