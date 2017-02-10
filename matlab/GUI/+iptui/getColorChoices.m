function colors = getColorChoices
%getColorChoices Returns a structure containing several high-contrast colors.
%   COLORS = getColorChoices returns a structure containing several colors
%   defined as RGB triplets.

%   Copyright 2005-2011 The MathWorks, Inc.
%   

% First color in the list will be the default.
temp = {getString(message('images:roiContextMenuUIString:lightRedColorChoiceContextMenuLabel')),   [248  79  79]/255
        getString(message('images:roiContextMenuUIString:greenColorChoiceContextMenuLabel')),      [ 72 248  72]/255
        getString(message('images:roiContextMenuUIString:yellowColorChoiceContextMenuLabel')),     [248 246  74]/255};
    
tagStrings = {'light red cmenu item'
              'green cmenu item'
              'yellow cmenu item'};    
    
colors = struct('Label', temp(:,1), 'Color', temp(:,2), 'Tag',tagStrings(:));
