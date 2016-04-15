    function  img2 = seg_microscopy(img, size_min, size_max)

% size_min = 70;
% size_max = 200;

%img = imresize(img,0.25);
R = img(:,:,1);
G = img(:,:,2);
%B = img(:,:,3);

[L A B] = RGB2Lab(img);
AB = A+B;

mask_R = seg_cells(R);
mask_G = seg_cells(G);
mask_AB = seg_cells(AB);

se = strel('square',2);

mask_R = imopen(mask_R,se);
mask_G = imopen(mask_G,se);
mask_AB = imopen(mask_AB,se);


mask2_R = clean_mask_size(mask_R,size_min,size_max);
mask2_G = clean_mask_size(mask_G,size_min,size_max);
mask2_AB = clean_mask_size(mask_AB,size_min,size_max);


[labels2 nLabels2] = bwlabel(mask2_R);
stats = regionprops(labels2,'Area','Perimeter','Centroid','Eccentricity');
thin = zeros(nLabels2,1);
circ = zeros(nLabels2,1);
ecc = zeros(nLabels2,1);

for l = 1:nLabels2
    A = stats(l).Area;
    P = stats(l).Perimeter;
    T = thinness(A,P);
    C = circularity(A,P);
    thin(l) = T;
    circ(l) = C;
    EC = stats(l).Eccentricity;
    ecc(l) = EC;
    
    if EC > 0.85 
        labels2(labels2 == l) = 0;
    end
end

img2 = labels2;

%plot(thin,circ,'b*');

overlay = imoverlay(img, img2, [.3 1 .8]);
imshow(overlay);

end

%-----------
% Help functions
%-----------



function image2 = clean_mask_size(image, size_min, size_max)
    [labels nLabels] = bwlabel(image);
    %clean small structures
    for l = 1:nLabels
        sizeL = length(labels(labels == l));
        if sizeL <= size_min || sizeL >= size_max
            labels(labels == l) = 0;
        end
    end
    image2 = labels;
    image2(image2 > 0) = 1;
end



