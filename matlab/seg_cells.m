
function image2 = seg_cells(image)
    w = [-1 -1 -1; -1 8 -1; -1 -1 -1];
    %Rs = gscale(anisodiff2D(image,10,1/7,10,2));
    Rs = image;
    Rs = tofloat(Rs);
    lap = abs(imfilter(Rs, w, 'replicate'));
    lap = lap/max(lap(:));
    h = imhist(lap);
    a = percentile2i(h, 0.995) ;
    markerimage = lap > a;
    fp = Rs.*markerimage;
    hp = imhist(fp);
    hp(1) = 0;
    T = otsuthresh(hp) ;
    image2 = im2bw(Rs, T);
end