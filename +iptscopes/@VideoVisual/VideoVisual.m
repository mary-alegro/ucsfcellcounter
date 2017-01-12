classdef VideoVisual < matlabshared.scopes.visual.Visual
    %VIDEOVISUAL Class definition for VideoVisual class
    
    %   Copyright 2015 The MathWorks, Inc.
    
    properties(SetAccess=protected)
        ColorMap
        VideoInfo
        Image = -1
        ScrollPanel = -1
        MaxDimensions
        Axes = -1
    end
    
    properties(SetAccess=protected,Dependent)
        DataType
        IsIntensity
    end
    
    properties(Access=protected)
        ScalingChangedListener
        DataSourceChangedListener
        DataLoadedListener
        Extension
        OldDimensions
    end
    
    methods
        %Constructor
        function this = VideoVisual(varargin)
            
            this@matlabshared.scopes.visual.Visual(varargin{:});
            
            % Create the Video Information dialog.
            this.VideoInfo = matlabshared.scopes.visual.VideoInformation(this.Application);
            update(this.VideoInfo);
            
            this.DataLoadedListener = event.listener(this.Application, ...
                'DataReleased', @this.dataReleased);
            this.DataSourceChangedListener = event.listener(this.Application, ...
                'DataSourceChanged', @this.dataSourceChanged);
        end
    end
    
    methods
        function dataType = get.DataType(this)
            dataType = this.ColorMap.DataType;
        end
        
        function isIntensity = get.IsIntensity(this)
            isIntensity = this.ColorMap.IsIntensity;
        end
        
        function this = set.DataType(this,dataType)
            
            if ~isempty(this.ColorMap)
                this.ColorMap.DataType = dataType;
                displayType = this.ColorMap.DisplayDataType;
            else
                displayType = dataType;
            end
            
            if ~isempty(this.VideoInfo)
                this.VideoInfo.DataType        = dataType;
                this.VideoInfo.DisplayDataType = displayType;
            end
            
        end
        
        function this = set.IsIntensity(this,isIntensity)
            
            if ~isempty(this.ColorMap)
                this.ColorMap.IsIntensity = isIntensity;
            end
            
            if ~isempty(this.VideoInfo)
                if isIntensity
                    colorSpace = 'Intensity';
                else
                    colorSpace = 'RGB';
                end
                this.VideoInfo.ColorSpace = colorSpace;
            end
            
        end
    end
    
    methods (Access = protected)
        cleanup(this, hVisParent)
        hInstall = createGUI(this)
    end
    methods(Static)
        propSet = getPropertySet
    end

end