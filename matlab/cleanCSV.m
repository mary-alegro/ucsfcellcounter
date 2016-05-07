%
% Help functions
%

function csv2 = cleanCSV(csv)

[r c N] = size(csv);
rows = 1:r;
toremove = [];
    for i=1:r
        if csv(i,2) < 0 || csv(i,3) < 0
            toremove = [toremove i];
        end
    end
    rows2 = setxor(rows,toremove);
    csv2 = csv(rows2,:);    
    
end
