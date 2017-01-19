% ABSTRACTTAB  Ancestor of all tabs available in Color Thresholder
%
%    This class is simply a part of the tool-strip infrastructure.

% Copyright 2014 The MathWorks, Inc.

classdef AbstractTab < handle
    
    properties(Access = private)
        Parent
        ToolTab
    end
    
    %----------------------------------------------------------------------
    methods
        % Constructor
        function this = AbstractTab(tool,tabname,title)
            this.Parent = tool;
            this.ToolTab = toolpack.desktop.ToolTab(tabname,title);
        end
        % getToolTab
        function tooltab = getToolTab(this)
            tooltab = this.ToolTab;
        end
    end
    
    %----------------------------------------------------------------------
    methods (Access = protected)
        % getParent
        function parent = getParent(this)
            parent = this.Parent;
        end
    end
    
    methods(Static)
        %--------------------------------------------------------------------------
        function section = createSection(nameId, tag)
            section = toolpack.desktop.ToolSection(tag, getString(message(nameId)));
        end
        
        %--------------------------------------------------------------------------
        % Sets tool tip text for labels, buttons, and other components
        %--------------------------------------------------------------------------
        function setToolTipText(component, toolTipID, varargin)
            component.Peer.setToolTipText(getString(message(toolTipID, varargin{:})));
        end
    end
    
end
