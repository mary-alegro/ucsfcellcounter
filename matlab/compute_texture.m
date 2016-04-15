function [t1 t2 t3 t4 t5] = compute_texture(img)

wsize = 7;
[rows cols N] = size(img);
if N > 1
    img = rgb2gray(img);
end
nPix = rows*cols;

t1 = zeros(rows,cols);
t2 = zeros(rows,cols);
t3 = zeros(rows,cols);
t4 = zeros(rows,cols);
t5 = zeros(rows,cols);

for p=1:nPix
    w = getwindow(p,img,wsize);
    glcm = graycomatrix(w,'Offset',[0 1]);
    stats = graycoprops(glcm,{'contrast','correlation','energy','homogeneity'});
    t1(p) = stats.Contrast;
    t2(p) = stats.Correlation;
    t3(p) = stats.Energy;
    t4(p) = stats.Homogeneity;
    t5(p) = PTPSA(w);
end

