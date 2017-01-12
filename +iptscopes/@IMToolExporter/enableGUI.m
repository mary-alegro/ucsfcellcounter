function enableGUI(this, enabState)
%ENABLEGUI Enable/disable the UI widgets.

%   Copyright 2007-2015 The MathWorks, Inc.

hui = getGUI(this.Application);

set(hui.findchild('Base/Menus/File/Export/IMToolExporter'), 'Enable', enabState);
set(hui.findchild('Base/Toolbars/Main/Export/IMToolExporter'), 'Enable', enabState);

% [EOF]