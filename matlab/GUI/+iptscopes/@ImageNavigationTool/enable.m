function enable(this)
%ENABLE   Enable the extension.

%   Copyright 2007-2015 The MathWorks, Inc.

hSrc = this.Application.DataSource;

if isempty(hSrc) || ~isDataLoaded(hSrc)
    enab = 'off';
else
    enab = 'on';
end

enableGUI(this, enab);

% [EOF]