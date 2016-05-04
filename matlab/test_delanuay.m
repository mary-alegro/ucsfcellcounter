function  test_delanuay(img,GT)

[r c N] = size(img);
[R1,C1] = ind2sub([r c],GT(1).set);
[R2,C2] = ind2sub([r c],GT(2).set);
[R3,C3] = ind2sub([r c],GT(3).set);
[R4,C4] = ind2sub([r c],GT(4).set);

R = [R1; R2; R3; R4];
C = [C1; C2; C3; C4];

nPts = length(R);
adjM = zeros(nPts,nPts);

%
% closest pair of points problem: can be solved in O(nlogn) in 2D using
% Delanuay triangulation: closest pair will have the smallest edge
%
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
[p1c,p2c] = find(edgeM > 0 & edgeM < 20); %[rows, cols] are indices in R and C

edgeM2 = zeros(size(edgeM));
edgeM2(edgeM > 0 & edgeM < 20) = 1;

[rm2 cm2] = find(edgeM2 == 1);

vEdges = unique([rm2; cm2]);
nEdges = length(vEdges);
visEdges = zeros(nEdges,2);
visEdges(:,1) = vEdges;
nClusters = 0;
clusterPts = [];

%gets one single point from each cluster
%uses BFS to traverse each cluster points
for n=1:nEdges  
    if visEdges(n,2) == 1
        continue;
    end
    v = visEdges(n,1);
    [points, visEdges] = BSF(edgeM2,visEdges,v);  %gets all points in a cluster
    clusterPts = [clusterPts points(end)]; %gets only one point, could be random
    nClusters = nClusters+1;  
end

R1c = R(p1c);
C1c = C(p1c);
R2c = R(p2c);
C2c = C(p2c);
Rc = [R1c; R2c];
Cc = [C1c; C2c];

Rp = R(clusterPts);
Cp = C(clusterPts);

imshow(img); hold on;
plot(C,R,'wo','MarkerSize',10);
plot(Cc,Rc,'yo','MarkerSize',10);
plot(Cp,Rp,'m*','MarkerSize',10);


end



%breadeth first search
function [vert, vEdges] = BSF(edgM,vEdges,e)

    vert = [];
    Q = [];
    Q = [Q e]; %queue: FIFO
    vert = [vert e];
    ie = find(vEdges(:,1) == e);
    vEdges(ie,2) = 1;
    while(~isempty(Q))
        i = Q(1);
        Q = Q(2:end);
        adj = edgM(i,:);
        adj = find(adj == 1);
        for a=adj          
            ia = find(vEdges(:,1) == a);
            if vEdges(ia,2) ~= 1
                Q = [Q a];
                vEdges(ia,2) = 1;
                vert = [vert a];
            end
        end
    end

end

















