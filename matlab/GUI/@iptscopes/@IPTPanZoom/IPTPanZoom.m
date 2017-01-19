function this = IPTPanZoom(varargin)
%IPTPANZOOM Construct an IPTPANZOOM object

%   Copyright 2007-2014 The MathWorks, Inc.

this = iptscopes.IPTPanZoom;

this.initTool(varargin{:});

propertyChanged(this, 'FitToView');

this.hVisualChangedListener = addlistener(this.Application,'VisualChanged', @(h,ed) onVisualChanged(this));...
    

function onVisualChanged(h)

hUI = getGUI(h.Application);
if images.internal.isFigureAvailable()
    hBtn = hUI.findchild('Base/Toolbars/Main/Tools/Zoom/Mag/MagCombo');
    hBtn.ScrollPanelAPI = [];
end

% [EOF]
