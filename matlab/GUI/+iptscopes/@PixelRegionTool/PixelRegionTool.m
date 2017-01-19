classdef PixelRegionTool < matlabshared.scopes.tool.Tool
    %PixelRegionTool Class definition for PixelRegionTool
    
    %   Copyright 2015 The MathWorks, Inc.
    
    properties(Hidden=true)
        
        hPixelRegion = -1  % Hold the pixel region tool.  This is an HG handle.
        CloseListener
        VisibleListener
    end
    
    methods
        %Constructor
        function this = PixelRegionTool(varargin)
            
            this@matlabshared.scopes.tool.Tool(varargin{:});
            
        end
        
    end
    
    methods (Access=protected)
        
        enableGUI(this, enabState)
        
        plugInGUI = createGUI(this)
    end
end