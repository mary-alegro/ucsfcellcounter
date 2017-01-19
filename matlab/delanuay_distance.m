function edgeM = delanuay_distance(img,pts)

%
% Compute the Delanuay triangulation between 2 points sets.
% Uses Delanuay + BFS for efficient computation.
% Delanuay is used to find the closes points pairs
%
% IMG: original microscopy image, can also be the labels or mask as long as
% it has the original image size
% PTS1: points set in indice form
% EDGEM: edge size matrix. Note that matrix indices are the same indices
% of the points in PTS.
%

[r c N] = size(img);
[R,C] = ind2sub([r c],pts);

%
% closest pair of points problem: can be solved in O(nlogn) in 2D using
% Delanuay triangulation: closest pair will have the smallest edge
%
nPts = length(R);
adjM = zeros(nPts,nPts);
tri = delaunay(C,R);
nTri = size(tri,1);

%computes edge sizes, build adjacency matrix
%accounts for edge symmetry (i.e p1-p2 == p2-p1)
for i=1:nTri
    p = tri(i,:);
    
    x1 = C(p(1)); y1 = R(p(1));
    x2 = C(p(2)); y2 = R(p(2));
    x3 = C(p(3)); y3 = R(p(3));
    
    %p1-p2
    if adjM(p(1),p(2)) == 0
        d1 = pdist([x1 y1; x2 y2]);
        adjM(p(1),p(2)) = d1; adjM(p(2),p(1)) = d1;
    end
    %p2-p3
    if adjM(p(2),p(3)) == 0
        d2 = pdist([x2 y2; x3 y3]);
        adjM(p(2),p(3)) = d2; adjM(p(3),p(2)) = d2;
    end
    %p3-p1
    if adjM(p(3),p(1)) == 0
        d3 = pdist([x3 y3; x1 y1]);
        adjM(p(3),p(1)) = d3; adjM(p(1),p(3)) = d3;
    end  
end

edgeM = triu(adjM);

end





