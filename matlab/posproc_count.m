function nCells = posproc_count(mask)

[labels nL] = bwlabel(mask);

nCells = nL;



