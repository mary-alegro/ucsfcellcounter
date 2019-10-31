function iptstandardhelp(helpmenu)
%iptstandardhelp Add Toolbox, Demos, and About to help menu.
%   iptstandardhelp(HELPMENU) adds Image Processing Toolbox Help,
%   Demos, and About Image Processing Toolbox to HELPMENU, which is a
%   uimenu object.

%   Copyright 1993-2011 The MathWorks, Inc.

mapFileLocation = fullfile(docroot, 'toolbox', 'images', 'images.map');

toolboxItem = uimenu(helpmenu,...
    'Label', getString(message('images:commonUIString:imageProcessingToolboxHelpLabel')), ...
                     'Callback', ...
                     @(varargin) helpview(mapFileLocation, 'ipt_roadmap_page'));
                 
demosItem = uimenu(helpmenu,...
    'Label', getString(message('images:commonUIString:imageProcessingDemosLabel')), ...
                   'Callback', @(varargin) demo('toolbox','image processing'), ...
                   'Separator', 'on');
               
aboutItem = uimenu(helpmenu,...
    'Label', getString(message('images:commonUIString:aboutImageProcessingToolboxLabel')), ...
                   'Callback', @iptabout, ...
                   'Separator', 'on');