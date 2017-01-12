function hPropDb = getPropertyDb
%GETPROPERTYDB Get the propertyDb.

%   Copyright 2007 The MathWorks, Inc.

hPropDb = extmgr.PropertyDb;

hPropDb.add('NewIMTool', 'bool', true);

% [EOF]
