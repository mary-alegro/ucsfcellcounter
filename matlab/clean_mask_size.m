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
