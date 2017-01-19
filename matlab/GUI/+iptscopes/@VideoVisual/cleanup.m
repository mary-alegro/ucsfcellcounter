function cleanup(this, hVisParent)
%CLEANUP Clean up the visual's HG components

%   Copyright 2007-2015 The MathWorks, Inc.

cleanupAxes(this, hVisParent);

% Make sure that the scroll panel is deleted.  Deleting the axes will not
% delete it.  Deleting the scrollpanel will not delete the axes.
if ishghandle(this.ScrollPanel)
    delete(this.ScrollPanel);
end

% [EOF]