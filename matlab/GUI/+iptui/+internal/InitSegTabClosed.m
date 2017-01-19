classdef InitSegTabClosed < event.EventData
    
    % Copyright 2014, The MathWorks Inc.
    
    properties
        AcceptPressed
        Selection
        Metadata
    end
    methods
        function eventData = InitSegTabClosed(accept,varargin)
            
            eventData.AcceptPressed = accept;
            
            if nargin>1
                eventData.Selection = varargin{1};
                eventData.Metadata  = varargin{2};
            end
        end
    end
    
end