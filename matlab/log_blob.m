function blobs = log_blob(img, min_s, max_s)

%
% Uses laplacian of gaussians to detect blobs
%

img = compress_hist(img);
img2 = imcomplement(img);
sigma = min_s:max_s;
cube = [];

for s = sigma
    h = fspecial('log',100,s);
    f = imfilter(img2,h);
    cube = cat(3,cube,f);
end

blobs = mean(cube,3);
%overlay = imoverlay(img,blobs, [.3 1 .3]);
%imshow(overlay);






