%
% Help functions
%

function csv2 = cleanCSV(csv,R,C)

[r c N] = size(csv);
rows = 1:r;
toremove = [];
    for i=1:r
        if csv(i,2) < 0 || csv(i,3) < 0
            toremove = [toremove i];
        elseif csv(i,2) > C || csv(i,3) > R
            toremove = [toremove i];
        end
    end
    rows2 = setxor(rows,toremove);
    csv2 = csv(rows2,:);    
    
end
