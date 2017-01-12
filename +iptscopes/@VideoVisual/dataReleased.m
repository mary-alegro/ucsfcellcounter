function dataReleased(this, ~, ~)
%DATARELEASED  React to the data source being uninstalled.

%   Copyright 2008-2015 The MathWorks, Inc.

hUIMgr = this.Application.getGUI;
hDims = hUIMgr.findchild({'StatusBar','StdOpts','iptscopes.VideoVisual Dims'});

% If we have no data, restore the default, which is Intensity 0x0.
emptyDataString = '';

if hDims.IsRendered
    hDims.WidgetHandle.Text = emptyDataString;
else
    hDims.setWidgetPropertyDefault('Text', emptyDataString);
end

sp_api = iptgetapi(this.ScrollPanel);
mag = sp_api.getMagnification();
sp_api.replaceImage(zeros(0, 0, 'uint8'));
sp_api.setMagnification(mag);

% [EOF]