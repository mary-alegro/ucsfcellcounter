classdef RefineTabClosed < event.EventData
    
    % Copyright 2014, The MathWorks Inc.
    
    properties
        AcceptPressed
        ClearBorder
        FillHoles
        MinSize
        MaxSize
        MinFilter
        MaxFilter
    end
    methods
        function eventData = RefineTabClosed(accept,varargin)
            
            eventData.AcceptPressed = accept;
            
            if nargin>1
                eventData.ClearBorder   = varargin{1};
                eventData.FillHoles     = varargin{2};
                eventData.MinSize       = varargin{3};
                eventData.MaxSize       = varargin{4};
                eventData.MinFilter     = varargin{5};
                eventData.MaxFilter     = varargin{6};
            end
        end
    end
    
end