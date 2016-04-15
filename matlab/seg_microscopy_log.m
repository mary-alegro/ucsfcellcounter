    function  [img2, centersX, centersY] = seg_microscopy_log(R,G,B, size_min, size_max, sigma_min, sigma_max)

% size_min = 70;
% size_max = 200;

%img = imresize(img,0.25);
% R = img(:,:,1);
% G = img(:,:,2);
% B = img(:,:,3);

if isa(R,'uint16') || isa(R,'double')
    R = gscale(R);
    G = gscale(G);
    B = gscale(B);
    
    img = cat(3,R,G,B);
end

%blobs = log_blob(R+G,sigma_min,sigma_max);
blobs1 = log_blob(R,sigma_min,sigma_max);
blobs2 = log_blob(G,sigma_min,sigma_max);

mask1 = clean_mask_size(blobs1,size_min,size_max);
mask2 = clean_mask_size(blobs2,size_min,size_max);

mask = mask1 + mask2;

[labels,nLabels] = bwlabel(mask);
stats = regionprops(labels,'Area','Perimeter','Centroid','Eccentricity');
thin = zeros(nLabels,1);
circ = zeros(nLabels,1);
ecc = zeros(nLabels,1);
centersX = zeros(nLabels,1);
centersY = zeros(nLabels,1);

for l = 1:nLabels
    A = stats(l).Area;
    P = stats(l).Perimeter;
    T = thinness(A,P);
    C = circularity(A,P);
    thin(l) = T;
    circ(l) = C;
    EC = stats(l).Eccentricity;
    ecc(l) = EC;
    xy = round(stats(l).Centroid);
    centersX(l) = xy(1);
    centersY(l) = xy(2);
    
    if EC > 0.85 
        labels(labels == l) = 0;
    end
end

img2 = labels;

%plot(thin,circ,'b*');

overlay = imoverlay(img, img2, [.3 1 .8]);
imshow(overlay);

end





