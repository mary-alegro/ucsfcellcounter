classdef SegmentationBackend < handle
    % SegmentationBackend - class containing image data and methods for
    % image segmentation app.
    
    % Copyright 2014, The MathWorks Inc.
    
    properties
        Im
        
        % Cache mask when opening a new tab for 'Cancel' or for 'Reset'
        % after segmentation.
        InitialMask 
        
        % Cache mask loaded into Refine Tab.
        CleanupMask
        
        % Cache mask after imfill/imclearborder to prevent delays in slider
        % reaction.
        CleanedMask
        
        % Cache connected components on CleanedMask.
        CC
        
        Algorithm
        Smoothness
        ContractionBias
        Iterations
        
        % View controls
        hScrollpanel
        hFig
        ForegroundColor
        ForegroundOpacity
        ChangeHandles
        
    end
    
    properties (SetObservable = true)
        Mask
        CurrentIteration
    end
    
    properties (Dependent = true, SetAccess = private)
        Areas
    end
    
    properties (Access = private)
        Speed
        Evolver
        
        FreehandContainer
        PolygonContainer
        
        StopSegmentationFlag
    end
    
    % Constructor
    methods
        function self = SegmentationBackend(im,ChangeHandles)
            self.Im = im;
            
            % Defaults
            self.Mask           = false(size(im));
            self.Algorithm      = 'Chan-Vese';
            self.Iterations     = 100;
            self.Smoothness     = 0;
            self.ContractionBias   = 0;
            self.InitialMask    = self.Mask;
            self.CleanupMask    = self.Mask;
            self.CleanedMask    = self.Mask;
            
            self.ForegroundColor    = [0 1 0];
            self.ForegroundOpacity  = 60;
            self.ChangeHandles      = ChangeHandles;
            
            self.CurrentIteration = 1;
            self.StopSegmentationFlag = false;
        end
        
        function delete(self)
            
            % In graphics version 1, the figure may still be alive after
            % the destruction of the Backend class. So, we explicitly
            % delete it. We need to check that the figure handle is valid
            % before destroying it.
            if ~isempty(self.hFig) && ishandle(self.hFig)
                delete(self.hFig);
            end
        end
    end
    
    
    methods
        %------------------------------------------------------------------
        % Mask Initialization
        %------------------------------------------------------------------
        function initializeMask(self,varargin)
            %initializeMask - initialize mask with binary mask.
            
            if nargin>1
                self.Mask = varargin{1};
            else
                self.Mask = false(size(self.Im));
            end
            
        end
        
        function initializeMaskWithThreshold(self,level)
            %initializeMaskWithThreshold- create binary mask using
            % threshold.
            
            self.Mask = self.Im > level;
        end
        
        function initializeMaskWithGrid(self,nx,ny,length)
            %initializeMaskWithGrid - create binary mask containing a grid
            %of circles or squares.
            
            self.createCircleMask(length,nx,ny);
        end
        
        function initializeMaskWithROITools(self)
            %initializeMaskWithROITools - create binary mask with region of
            %interest specified by imfreehand/impoly objects.
            
            mask = false(size(self.Mask));
            
            if isValidFreehandContainer(self)
                freehands = self.FreehandContainer.hROI;
                freehands = freehands(isvalid(freehands));
                
                for n = 1 : numel(freehands)
                    mask = mask | createMask(freehands(n));
                end
            end
            
            if isValidPolygonContainer(self)
                polygons = self.PolygonContainer.hROI;
                polygons = polygons(isvalid(polygons));
                
                for n = 1 : numel(polygons)
                    mask = mask | createMask(polygons(n));
                end
            end
            
            deleteROITools(self);
            
            self.Mask = mask;
        end
        
        %------------------------------------------------------------------
        % Mask Updates
        %------------------------------------------------------------------
        function TF = isMaskEmpty(self)
            TF = ~any(self.Mask(:));
        end
        
        function cacheInitialMask(self)
            self.InitialMask = self.Mask;
        end
        
        function loadCachedInitialMask(self)
            self.Mask = self.InitialMask;
        end
        
        function loadCachedRefineMask(self)
            self.Mask = self.CleanupMask;
        end
        
        
        function stopSegmentationAlgorithm(self)
            
           self.StopSegmentationFlag = true; 
            
        end
        
        function runSegmentationAlgorithm(self)
           
            initializeSegmentationAlgorithm(self);
            
            % Turn off warning about empty contour. This will be handled
            % via a warning dialog.
            prevState = warning('off','images:activecontour:vanishingContour');
            
            % Cleanup may run at end of segmentButtonCallback or if user
            % closes app during computation.
            cleanUp = onCleanup(@() warning(prevState));
            
            for i = 1:self.Iterations
               
                self.CurrentIteration = i;
                updateSegmentation(self);
                updateSegmentationMask(self);
                
                % Flush event queue for listeners in view to process and
                % update graphics in response to changes in mask and
                % current iteration count.
                drawnow();
                
                if isMaskEmpty(self)
                   ME = MException('images:SegmentationBackend:emptyMask',...
                       'Mask has evolved to an all false state.');
                   throw(ME);
                    
                end

                if self.StopSegmentationFlag
                    break;
                end
                                
            end
            
        end
        
        
        %------------------------------------------------------------------
        % Mask Cleanup
        %------------------------------------------------------------------    
        function initCleanup(self)
            
            % Compute connected components for slider values.
            self.CC = bwconncomp(self.Mask);
            
            self.CleanupMask = self.Mask;
            self.CleanedMask = self.Mask;
        end
        
        function removeArtifacts(self,clearborder,fillholes)
            
            mask = self.CleanupMask;
            
            if clearborder
                mask = imclearborder(mask);
            end
            
            if fillholes
                mask = imfill(mask,'holes');
            end
            
            self.CleanedMask = mask;
            
            self.Mask = mask;
            self.CC = bwconncomp(mask);
        end
        
        function removeComponents(self,minsize,maxsize)
            %removeComponents - Remove connected components smaller than
            %minsize and larger than maxsize.
            
            regionsToKeep = (self.Areas>=minsize) & (self.Areas<=maxsize);
            idxToKeep = self.CC.PixelIdxList(regionsToKeep);
            idxToKeep = vertcat(idxToKeep{:});
            
            self.Mask = false(size(self.Mask));
            self.Mask(idxToKeep) = true;
        end
        
        %------------------------------------------------------------------
        % View Controls
        %------------------------------------------------------------------
        function addFreehandTool(self)
            %addFreehandTool - add imfreehand container and enter draw
            %mode.
            
            deleteROITools(self);
            
            if ~isValidFreehandContainer(self)
                hAx = findobj(self.hScrollpanel,'type','axes');
                self.FreehandContainer = iptui.internal.ImfreehandModeContainer(hAx);
            end
            
            disableViewControls(self);
            
            self.FreehandContainer.enableInteractivePlacement();
            
            addlistener(self.FreehandContainer,'hROI','PostSet',@(~,evt)colorPatch(self,evt));
        end
        
        function addPolygonTool(self)
            %addPolygonTool - add impoly container and enter draw mode.
            
            deleteROITools(self);
            
            if ~isValidPolygonContainer(self)
                hAx = findobj(self.hScrollpanel,'type','axes');
                self.PolygonContainer = iptui.internal.ImpolyModeContainer(hAx);
            end
            
            disableViewControls(self);
            
            self.PolygonContainer.enableInteractivePlacement();
            
            addlistener(self.PolygonContainer,'hROI','PostSet',@(~,evt)colorPatch(self,evt));
        end
        
        function colorPatch(self,evt)
            
            % Set color and opacity of ROI's to Foreground Color and
            % Opacity.
            src = evt.AffectedObject;
            if ~isempty(src.hROI) && isvalid(src.hROI(end))
                roi = src.hROI(end);
                hPatch = findobj(roi,'type','patch');
                if ~isempty(hPatch)
                    set(hPatch,'FaceColor',self.ForegroundColor);
                    set(hPatch,'FaceAlpha',self.ForegroundOpacity/100);
                end
            end
        end
        
        function deleteROITools(self)
            %deleteROITools - delete imfreehand/impoly instances on the
            %image and message panes.
            
            if isValidFreehandContainer(self)
                disableInteractivePlacement(self.FreehandContainer);
                
                freehands = self.FreehandContainer.hROI;
                freehands = freehands(isvalid(freehands));
                for n = 1 : numel(freehands)
                    delete(freehands(n));
                end
                
                delete(self.FreehandContainer);
            end
            
            if isValidPolygonContainer(self)
                disableInteractivePlacement(self.PolygonContainer);
                
                polygons = self.PolygonContainer.hROI;
                polygons = polygons(isvalid(polygons));
                for n = 1 : numel(polygons)
                    delete(polygons(n));
                end
                
                delete(self.PolygonContainer);
            end
            
            enableViewControls(self);
        end

    end
    
    % Set/Get property methods.
    methods
        %------------------------------------------------------------------
        % Set Methods
        %------------------------------------------------------------------
        function set.Algorithm(self,algName)
            algName = validatestring(algName,{'Chan-Vese','edge'});
            self.Algorithm = algName;
            setDefaults(self);
        end
        
        function set.Smoothness(self,smoothness)
            validateattributes(smoothness,{'numeric'},{'scalar'});
            self.Smoothness = double(smoothness);
        end
        
        function set.ContractionBias(self,ContractionBias)
            validateattributes(ContractionBias,{'numeric'},{'scalar'});
            self.ContractionBias = double(ContractionBias);
        end
        
        function set.Iterations(self,numiter)
            validateattributes(numiter,{'numeric'},{'scalar','positive','integer'});
            self.Iterations = double(numiter);
        end
        
        %------------------------------------------------------------------
        % Get Methods
        %------------------------------------------------------------------
        function areas = get.Areas(self)
            areas = cellfun('length',self.CC.PixelIdxList);
        end
    end
    
    % Methods for controlling algorithm
    methods (Access = private)
        
        function initializeSegmentationAlgorithm(self)
            
            % Setup speed function object.
            switch self.Algorithm
                case 'Chan-Vese'
                    foregroundweight = 1;
                    backgroundweight = 1;
                    self.Speed = images.activecontour.internal.ActiveContourSpeedChanVese(...
                        self.Smoothness,...
                        self.ContractionBias,...
                        foregroundweight,...
                        backgroundweight);
                case 'edge'
                    advectionweight = 1;
                    sigma = 2;
                    gradientnormfactor = 1;
                    edgeExponent = 1;
                    self.Speed = images.activecontour.internal.ActiveContourSpeedEdgeBased(...
                        self.Smoothness,...
                        self.ContractionBias,...
                        advectionweight,...
                        sigma,...
                        gradientnormfactor,...
                        edgeExponent);
            end
            
            % Create contour evolver object
            self.Evolver = images.activecontour.internal.ActiveContourEvolver(...
                self.Im,...
                self.Mask,...
                self.Speed);
            
            % Flag used to decide whether we need to halt algorithm
            self.StopSegmentationFlag = false;
        end
        
        function updateSegmentation(self)
            
            % Evolve contour for 1 iteration.
            self.Evolver = moveActiveContour(self.Evolver, 1, false);
        end
        
        function updateSegmentationMask(self)
            
            % Extract contour state
            self.Mask = self.Evolver.ContourState;
        end
        
    end
    
    
    % Helper methods
    methods (Access = private)
        function setDefaults(self)
            switch self.Algorithm
                case 'Chan-Vese'
                    self.Smoothness = 0;
                    self.ContractionBias = 0;
                case 'edge'
                    self.Smoothness = 1;
                    self.ContractionBias = 0.3;
            end
        end
        
        function createCircleMask(self,radius,nX,nY)
            
            [imX,imY] = size(self.Im);
            
            bw = false(imX,imY);
            
            if radius>0
                % Find centers of circles to be drawn
                centersx = round(linspace(1,imX,nX+2)); centersx = centersx(2:end-1);
                centersy = round(linspace(1,imY,nY+2)); centersy = centersy(2:end-1);
                
                % Create a circle mask
                circle = strel('disk',radius,0).getnhood();
                
                % Place circle at each center
                for x = 1 : nX
                    for y = 1 : nY
                        bw(centersx(x)-radius:centersx(x)+radius,centersy(y)-radius:centersy(y)+radius) = circle;
                    end
                end
            end
            self.Mask = bw;
        end
        
        function TF = isValidFreehandContainer(self)
            TF = isa(self.FreehandContainer,'iptui.internal.ImfreehandModeContainer') && isvalid(self.FreehandContainer);
        end
        
        function TF = isValidPolygonContainer(self)
            TF = isa(self.PolygonContainer,'iptui.internal.ImpolyModeContainer') && isvalid(self.PolygonContainer);
        end
        
        function enableViewControls(self)
            %enableViewControls - Enable Pan/Zoom and View tools on Segment
            %Tab.
            handles = [self.ChangeHandles.PanAndZoomHandles self.ChangeHandles.ViewSegmentationHandles];
            
            for n = 1 : numel(handles)
                handles{n}.Enabled = true;
            end
        end
        
        function disableViewControls(self)
            %disableViewControls - Disable Pan/Zoom and View tools on
            %Segment Tab while in freehand/polygon mode.
            handles = [self.ChangeHandles.PanAndZoomHandles self.ChangeHandles.ViewSegmentationHandles];
            
            for n = 1 : numel(handles)
                handles{n}.Enabled = false;
            end
        end
    end
end