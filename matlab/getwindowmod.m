
function w = getwindowmod(center,m,ws)

%
% center = windows center
% m = image
% s = windows size
%

[rows cols N] =  size(m);
[rc cc] = ind2sub([rows cols], center);
s = floor(ws/2);

r1 = rc - s;  c1 = cc - s;
r2 = rc + s;  c2 = cc + s;

shift_row = 0;
shift_col = 0;

if (r1 < 1)
    %r1 = 1;
    shift_row = r1-1;
end
if (c1 < 1)
    shift_col = c1-1;
end
if (r2 > rows) 
    %r2 = rows;
    shift_row = r2-rows;
end
if(c2 > cols)
    shift_col = c2-cols;
end

if shift_row ~= 0 || shift_col ~= 0
    rc = rc - shift_row;
    cc = cc - shift_col;
    
    r1 = rc - s;  c1 = cc - s;
    r2 = rc + s;  c2 = cc + s;
end
  
w = m(r1:r2, c1:c2);    

end

