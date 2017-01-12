function img2 =  soft_thresh(img,T,type)


if type == 1
    idx1 = find(abs(img) <= T);
    img2 = ((abs(img) - T).*img)./abs(img);
    img2(idx1) = 0;
end

if type == 2
    
end