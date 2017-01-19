function enableGUI(this, enabState)
%ENABLEGUI Enable/disable the UI widgets.

%   Copyright 2007 The MathWorks, Inc.

hui = getGUI(this.Application);

set(hui.findchild('Base/Menus/File/Export/IMToolExport'), 'Enable', enabState);
set(hui.findchild('Base/Toolbars/Main/Export/IMToolExport'), 'Enable', enabState);

% [EOF]
