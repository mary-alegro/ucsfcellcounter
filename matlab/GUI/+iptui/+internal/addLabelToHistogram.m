function addLabelToHistogram(hAx, label)
%addLabelToHistogram   Place label next to a histogram.

%   Copyright 2013-2015 The MathWorks, Inc.

% Create the text label.
xLim = double(get(hAx, 'XLim'));
yLim = double(get(hAx, 'YLim'));
hText = text(xLim(1), yLim(2), label, 'parent', hAx);
set(hText, 'FontSize', 14)
set(hText, 'FontWeight', 'bold')

% Place the text label just outside the axes.
extent = get(hText, 'extent');
pos = get(hText, 'position');
pos(1) = pos(1) - extent(3)*1.1;
pos(2) = pos(2) - extent(4);
set(hText, 'position', pos)

end
