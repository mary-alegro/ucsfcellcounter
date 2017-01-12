function [img, R, G, B] = load_img(fullpath,doresize)

img = imread(fullpath);

if doresize == 1
    img = imresize(img,0.25);
end

R = img(:,:,1); 
G = img(:,:,2); 
B = img(:,:,3);
if isa(img,'uint16') || isa(img,'double')
    R = gscale(R);
    G = gscale(G);
    B = gscale(B);
end
img = cat(3,R,G,B);



