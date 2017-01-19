function m = load_mask(fullpath,doresize)
    m = imread(fullpath);
    [r c N] = size(m);
    if N > 1
        m = m(:,:,1);
    end
    if doresize == 1
        m = imresize(m,0.25);
    end
end