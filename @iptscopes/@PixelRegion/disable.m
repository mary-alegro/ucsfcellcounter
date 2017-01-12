function disable(this)
%DISABLE  Disable the listeners and close the pixel region window.

%   Copyright 2007-2008 The MathWorks, Inc.

% Make sure that all listeners and the pixel region GUI are destroyed.
if isa(this.CloseListener, 'handle.listener') || isa(this.CloseListener, 'event.listener')
    delete(this.CloseListener);
    this.CloseListener = [];
end

if isa(this.VisibleListener, 'handle.listener') || isa(this.VisibleListener, 'event.listener')
    delete(this.VisibleListener);
    this.VisibleListener = [];
end

if ishghandle(this.PixelRegion)
    delete(this.PixelRegion);
    this.PixelRegion = -1;
end

% [EOF]
