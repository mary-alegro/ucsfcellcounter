function hPropDb = getPropertyDb
%GETPROPERTYDB Get the propertyDb.

%   Copyright 2007 The MathWorks, Inc.

hPropDb = extmgr.PropertyDb;

% Add properties for the zoom which are not set from the options dialog.
% These properties are set as the zoom object is used.  We store them in
% the property database so they can be saved in the instrumentation sets.
hPropDb.add('FitToView',     'bool',   false);
hPropDb.add('Magnification', 'double', 1);

% [EOF]
