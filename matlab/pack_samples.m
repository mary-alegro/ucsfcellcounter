function [red green yellow] = pack_samples(samples)

    nFiles = length(samples);
    red = [];
    green = [];
    yellow = [];

    for i=1:nFiles
        red = cat(1,red,samples(i).red);
        green = cat(1,green,samples(i).green);
        yellow = cat(1,yellow,samples(i).yellow);
    end

    %balance data
    nG = size(green,1);
    nR = size(red,1);
    nY = size(yellow,1);   
    nSamp = min([nG nR nY]);
    idx = randperm(nSamp);
    green = green(idx,:);
    red = red(idx,:);
    yellow = yellow(idx,:);
    
end

