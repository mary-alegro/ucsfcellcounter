function enableGUI(this, enabState)
%ENABLEGUI Enable/disable the GUI widgets.

%   Copyright 2007-2009 The MathWorks, Inc.

hui = getGUI(this.Application);
set(hui.findchild('Base/Menus/Tools/VideoTools/PixelRegion'), 'Enable', enabState);
set(hui.findchild('Base/Toolbars/Main/Tools/Standard/PixelRegion'), 'Enable', enabState);

% Close down the pixel region when there is no data to display.
if strcmp(enabState, 'off')
    disable(this);
end

% [EOF]
