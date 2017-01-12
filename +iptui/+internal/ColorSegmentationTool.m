classdef ColorSegmentationTool < handle

%   Copyright 2013-2015 The MathWorks, Inc.
    
    
    properties (Hidden = true, SetAccess = private)
    % Data members must be public for current testing methodology.
    % This is an implementation detail of the class, not truly public data
    % members. That is why they are hidden.
       
        % Unique name assigned to toolgroup
        GroupName
        
        % Handle to figures docked in toolstrip
        FigureHandles
        
        % Handle to current figure docked in toolstrip
        hFigCurrent
        
        % binary image that current defines mask
        mask
        
        % Cached colorspace representations of image data
        imRGB
        
        %Handle to mask opacity slider
        hMaskOpacitySlider
        
        % Image preview handle.
        ImagePreviewDisplay 
    end

    properties (Access = private)
        
        %ToolGroup
        hToolGroup
        
        % Tabs
        ThresholdTab
        MultiColorSpaceTab
        ImageCaptureTab
        
        %imscrollpanel that contains overlay view
        hScrollpanel
        
        % Sections
        LoadImageSection
        ThresholdControlsSection
        ColorSpacesSection
        ManualSelectionSection
        PanZoomSection
        ViewSegmentationSection
        ExportSection
                
        % Handles to buttons in toolstrip
        hColorSpacesButton
        hShowBinaryButton
        hZoomInButton
        hZoomOutButton
        hPanButton
        hInvertMaskButton
        hOverlayColorButton
        hApplyROIsButton
                        
        % Handles to buttons in toolstrip that are enabled/distabled based
        % on whether data has been loaded into app.
        hChangeUIComponentHandles
        lassoSensitiveComponentHandles
                        
        % Cached knowledge of current opacity so that
        % we can flip back and forth from "Show Binary" toggle mode
        currentOpacity
        
        % We cache ClientActionListener on ToolGroup so that we can
        % disable/enable it at specific times.
        ClientActionListener
        
        % We cache the listener for whether or not a colorspace has been
        % selected in iptui.internal.ColorSpaceMontageView so that we don't
        % continue listening for a color space selection if the
        % colorSegmentor app is destroyed.
        colorspaceSelectedListener
        
        % We cache listeners to state changed on buttons so that we can
        % disable/enable button listeners when a new image is loaded and we
        % restore the button states to an initialized state.
        binaryButonStateChangedListener
        invertMaskItemStateChangedListener
        sliderMovedListener
        
        %Handle to current open iptui.internal.ColorSpaceMontageView
        %instance
        hColorSpaceMontageView
        
        % Cache knowledge of whether we normalized double input data so
        % that we can have thresholds in "generate function" context match
        % image data. Do the same for massaging of image data to handle
        % Nans and Infs appropriately.
        normalizedDoubleData
        massageNansInfs
        
        % Handles of selected regions
        hFreehandROIs
        freehandManager
        hFreehandListener
        preLassoPanZoomState
        preLassoToolstripState
        
    end
    
    
    methods
               
        function self = ColorSegmentationTool(varargin)
            
            % Each tool instance needs a unique name, use tempname
            [~, name] = fileparts(tempname);
            self.GroupName = name;
            self.hToolGroup = toolpack.desktop.ToolGroup(self.GroupName, getString(message('images:colorSegmentor:appName')));
            
            % Create Threshold Tab
            self.ThresholdTab = self.hToolGroup.addTab(getString(message('images:colorSegmentor:ThresholdTabName')), getString(message('images:colorSegmentor:thresholdTab')));
            
            % Initialize the camera preview instance.
            self.ImagePreviewDisplay = [];
            
            % Remove view Tab.
            self.removeViewTab();
            
            % Remove Quick Access Bar (QAB).
            self.removeQuickAccessBar()
            
            % Disable interactive tiling in app. We want to enforce layout
            % so that multiple color space segmentation documents cannot be
            % viewed at one time. An assumption of the design is that only
            % one imscrollpanel is visible at a time.
            self.disableInteractiveTiling();
            
            self.hToolGroup.open
            imageslib.internal.apputil.ScreenUtilities.setInitialToolPosition(self.GroupName);
            
            % Add Sections to Threshold Tab
            self.LoadImageSection = self.ThresholdTab.addSection('LoadImage',getString(message('images:colorSegmentor:loadImage')));
            self.ColorSpacesSection       = self.ThresholdTab.addSection('ColorSection',getString(message('images:colorSegmentor:colorSpaces')));
            self.ManualSelectionSection = self.ThresholdTab.addSection('ManualSelectionSection', getString(message('images:colorSegmentor:colorSelection')));
            self.ThresholdControlsSection = self.ThresholdTab.addSection('ThresholdControlsSection',getString(message('images:colorSegmentor:thresholdControls')));
            self.PanZoomSection = self.ThresholdTab.addSection('PanZoomSection',getString(message('images:colorSegmentor:zoomAndPan')));
            self.ViewSegmentationSection     = self.ThresholdTab.addSection('ViewSegmentationSection',getString(message('images:colorSegmentor:viewSegmentation')));
            self.ExportSection  = self.ThresholdTab.addSection('Export',getString(message('images:colorSegmentor:export')));
            
            % Layout Panels/Buttons within each section
            self.layoutLoadImageSection();
            self.layoutColorSpacesSection();
            self.layoutManualSelectionSection();
            self.layoutThresholdControlsSection();
            self.layoutPanZoomSection();
            self.layoutViewSegmentationSection();
            self.layoutExportSection();
            
            % Disable ui controls in app until data is loaded
            self.setControlsEnabled(false);
                        
            imageslib.internal.apputil.manageToolInstances('add', 'colorThresholder', self);
            
            % Hide Data Browser in Tab
            md = com.mathworks.mlservices.MatlabDesktopServices.getDesktop;
            md.hideClient('DataBrowserContainer',self.GroupName);
            
            % Disable "Hide" option in tabs.
            g = self.hToolGroup.Peer.getWrappedComponent;
            g.putGroupProperty(com.mathworks.widgets.desk.DTGroupProperty.PERMIT_DOCUMENT_BAR_HIDE, false);
            
            disableDragDropOnToolGroup(self);
            
            % If image data was specified, load it into the app
            if nargin > 0
                im = varargin{1};
                self.importImageData(im);
            end
            
            % Listen for changes in Active/Closing figures in the ToolGroup
            self.ClientActionListener = addlistener(self.hToolGroup,...
                'ClientAction',@(hobj,evt) clientActionCB(self,hobj,evt));
            
            % We want to destroy the current
            % iptui.internal.ColorSegmentationTool instance if a user
            % interactively closes the toolgroup associated with this
            % instance.
            addlistener(self.hToolGroup, 'GroupAction', ...
                @(~,ed) doClosingSession(self,ed));
            
        end
        
    end
    
    methods
        
       % Methods provided for testing.
       function viewSpecifiedColorspace(self,colorSpaceString)
           %viewSpecifiedColorSpace Initialize app with RGB
           %image and load specified color space document into app.
           %
           % h.viewSpecifiedColorSpace(RGB,colorSpaceString) creates a
           % segmentation view in the color space specified by
           % colorSpaceString ('RGB','HSV','L*a*b*','YCbCr').
           
          cdata = computeColorspaceRepresentation(self,colorSpaceString);
          self.createColorspaceSegmentationView(cdata,colorSpaceString);
          % Enable UI controls
          self.setControlsEnabled(true);
          
          % Each time a new color space is loaded the app manages the state
          % of specific UI controls.
          self.manageControlsOnNewColorspace();

            
       end
        
    end
    
    methods 
        % This is used both by the app internally and is used in testing,
        % so it needs to be public
        function initializeAppWithRGBImage(self,im)
                        
            % Cache knowledge of RGB representation of image.
            self.imRGB = im;
            
            % Initialize mask
            self.mask = true(size(im,1),size(im,2));
            
            % Enable colorspaces button
            self.hColorSpacesButton.Enabled = true;
            
        end
        
    end
    
    % Assorted utility methods used by app
    methods (Access = private)
                
        function [self,im] = normalizeDoubleDataDlg(self,im)
            
            self.normalizedDoubleData = false;
            self.massageNansInfs      = false;
            
            % Check if image has NaN,Inf or -Inf valued pixels.
            finiteIdx       = isfinite(im(:));
            hasNansInfs     = ~all(finiteIdx);
            
            % Check if image pixels are outside [0,1].
            isOutsideRange  = any(im(finiteIdx)>1) || any(im(finiteIdx)<0);
            
            % Offer the user the option to normalize and clean-up data if
            % either of these conditions is true.
            if isOutsideRange || hasNansInfs
                
                buttonname = questdlg(getString(message('images:colorSegmentor:normalizeDataDlgMessage')),...
                    getString(message('images:colorSegmentor:normalizeDataDlgTitle')),...
                    getString(message('images:colorSegmentor:normalizeData')),...
                    getString(message('images:commonUIString:cancel')),...
                    getString(message('images:colorSegmentor:normalizeData')));
                
                if strcmp(buttonname,getString(message('images:colorSegmentor:normalizeData')))
                    
                    % First clean-up data by removing NaN's and Inf's.
                    if hasNansInfs
                        % Replace nan pixels with 0.
                        im(isnan(im)) = 0;
                        
                        % Replace inf pixels with 1.
                        im(im== Inf)   = 1;
                        
                        % Replace -inf pixels with 0.
                        im(im==-Inf)   = 0;
                        
                        self.massageNansInfs = true;
                    end
                    
                    % Normalize data in [0,1] if outside range.
                    if isOutsideRange
                        im = im ./ max(im(:));
                        
                        self.normalizedDoubleData = true;
                    end
                    
                    
                else
                    im = [];
                end
                
            end
        end    
        
        function cdata = computeColorspaceRepresentation(self,csname)
            
            switch (csname)
                
                case 'RGB'
                    cdata = self.imRGB;
                case 'HSV'
                    cdata = rgb2hsv(self.imRGB);
                case 'YCbCr'
                    cdata = rgb2ycbcr(self.imRGB);
                case 'L*a*b*'
                    cdata = images.internal.sRGB2Lab(self.imRGB);
                    
                otherwise
                    assert('Unknown colorspace name specified.');
            end
            
        end
        
        function doClosingSession(self, event)
            if strcmp(event.EventData.EventType, 'CLOSING')
                % Remove the Camera tab if exist.
                if isCameraPreviewInApp(self)
                    % Close the preview window.
                    self.ImageCaptureTab.closePreviewWindowCallback;
                end
                imageslib.internal.apputil.manageToolInstances('remove', 'colorThresholder', self);
                delete(self);                     
            end
        end
                
        function clientActionCB(self,~,evt)
            
            hFig = evt.EventData.Client;
                                     
            if strcmpi(evt.EventData.EventType,'ACTIVATED');
                % Re-parent scrollpanel to the activated figure.
                
                clientTitle = evt.EventData.ClientTitle;
                existingTabs = self.hToolGroup.TabNames;
                
                % Special case Camera preview tab before others.
                if strcmpi(clientTitle, getString(message('images:colorSegmentor:MainPreviewFigure')))
                    % If image capture tab is not in the toolgroup, add it and bring
                    % focus to it.
                    if ~any(strcmpi(existingTabs, getString(message('images:colorSegmentor:ImageCaptureTabName'))))
                        add(self.hToolGroup, getToolTab(self.ImageCaptureTab), 2);
                    end
                    % Select the capture tab. 
                    self.hToolGroup.SelectedTab = getString(message('images:colorSegmentor:ImageCaptureTabName'));
                    % Set it as the current figure. 
                    self.hFigCurrent = hFig;
                elseif self.validColorspaceFiguresInApp()
                    % This conditional is necessary because an event fires
                    % when the last figure in the desktop is closed and
                    % hFig is no longer valid.
                    
                    if ~isequal(hFig, self.hFigCurrent) && ~isempty(self.freehandManager)
                        self.disableLassoRegion()
                        self.freehandManager = [];
                    end
                    
                    hLeftPanel = findobj(hFig,'tag','LeftPanel');
                    layoutScrollpanel(self,hLeftPanel);
                    
                    % Need to know current colorspace representation of image
                    % here. Use appdata for now. This is making an extra copy
                    % of the CData that we will want to avoid.
                    hRightPanel = findobj(hFig,'tag','RightPanel');
                    cData = getappdata(hRightPanel,'ColorspaceCData');
                    histHandles = getappdata(hRightPanel,'HistPanelHandles');
                    
                    self.updateMask(cData,histHandles{:});
                    
                    self.hFigCurrent = hFig;
                    
                    self.hideOtherROIs()
                    
                    % Remove the contextual tab and show Threshold tab.
                    if any(strcmp(existingTabs, getString(message('images:colorSegmentor:ImageCaptureTabName'))))
                        removeTab(self.hToolGroup, getString(message('images:colorSegmentor:ImageCaptureTabName')));
                    end
                    self.hToolGroup.SelectedTab = getString(message('images:colorSegmentor:ThresholdTabName'));
                end
                
            end
            
            % When the last figure in the app has been closed, disable the
            % appropriate UI controls.
            if strcmpi(evt.EventData.EventType,'CLOSED')
                appDeleted = ~isvalid(self) || ~isvalid(self.hToolGroup);
                if ~appDeleted
                    if ~self.validColorspaceFiguresInApp()
                        self.setControlsEnabled(false);
                    end
                end
            end
            
        end
        
        function updateMask(self,cData,hChan1Hist,hChan2Hist,hChan3Hist)
            
            channel1Lim = hChan1Hist.currentSelection;
            channel2Lim = hChan2Hist.currentSelection;
            channel3Lim = hChan3Hist.currentSelection;
            
            firstPlane  = cData(:,:,1);
            secondPlane = cData(:,:,2);
            thirdPlane  = cData(:,:,3);
            
            % The hue channel can have a min greater than max, so that
            % needs special handling. We could special case the H channel,
            % or we can build a mask treating every channel like H.
            if isa(hChan1Hist,'iptui.internal.InteractiveHistogramHue') && (channel1Lim(1) >= channel1Lim(2) )
                BW = bsxfun(@ge,firstPlane,channel1Lim(1)) | bsxfun(@le,firstPlane,channel1Lim(2)); 
            else
                BW = bsxfun(@ge,firstPlane,channel1Lim(1)) & bsxfun(@le,firstPlane,channel1Lim(2));
            end
            
            BW = BW & bsxfun(@ge,secondPlane,channel2Lim(1)) & bsxfun(@le,secondPlane,channel2Lim(2));
            BW = BW & bsxfun(@ge,thirdPlane,channel3Lim(1)) & bsxfun(@le,thirdPlane,channel3Lim(2));
                        
            % We decide whether or not to return BW or ~BW based on state
            % of invert toggle button.
            if self.hInvertMaskButton.Selected
                self.mask = ~BW;
            else
                self.mask = BW;
            end
            
            % Now update graphics in scrollpanel.
            self.updateMaskOverlayGraphics();
            
        end
        
        function updateMaskOverlayGraphics(self)
            
            hIm = findobj(self.hScrollpanel,'type','image');
            if self.hShowBinaryButton.Selected
                set(hIm,'CData',self.mask);
            else
                alphaData = ones(size(self.mask,1),size(self.mask,2));
                alphaData(~self.mask) = 1-self.hMaskOpacitySlider.Value/100;
                set(hIm,'AlphaData',alphaData);
            end
            
        end
                    
        function self = setTSButtonIconFromImage(self,TSButtonObj,im)
            % This method allows an image matrix IM to be set as the icon
            % of a TSButton. There is no direct support for setting a
            % TSButton icon from a image buffer in memory in the toolstrip
            % API.
            overlayColorButtonJavaPeer = TSButtonObj.Peer;
            javaImage = im2java(im);
            icon = javax.swing.ImageIcon(javaImage);
            overlayColorButtonJavaPeer.setIcon(icon);
            
        end
        
        function manageControlsOnNewColorspace(self)
           % This method puts the Show Binary, Invert mask, and Opacity
           % Slider back to their default state whenever a new image is
           % loaded or a new colorspace document is created.
           
           self.hShowBinaryButton.Selected = false;
           self.hInvertMaskButton.Selected = false;
           self.hMaskOpacitySlider.Value  = 100;
           self.hApplyROIsButton.Enabled = false;
        end
        
        function manageControlsOnImageLoad(self)
           % We can reuse logic from manageControlsOnNewColorspace, but we also have to disable
           % and re-enable listeners that are coupled to existence of
           % scrollpanel, because scrollpanel is blown away and recreated
           % when you load a new image.
            
           % Disable listeners
           self.binaryButonStateChangedListener.Enabled = false;
           self.invertMaskItemStateChangedListener.Enabled = false;
           self.sliderMovedListener.Enabled = false;
           
           self.manageControlsOnNewColorspace();
           
           % Additionally, we want to reset zoom and background color space
           % when we load a new image
           self.hZoomInButton.Selected = false;
           self.hZoomOutButton.Selected = false;
           self.hPanButton.Selected = false;
           self.setTSButtonIconFromImage(self.hOverlayColorButton,zeros(16,16,'uint8'));

           % This drawnow is necessary to allow state of buttons to settle before
           % re-enabling the listeners.
           drawnow;
           
           % Enable listeners
           self.binaryButonStateChangedListener.Enabled = true;
           self.invertMaskItemStateChangedListener.Enabled = true;
           self.sliderMovedListener.Enabled = true;
            
        end
        
        function setControlsEnabled(self,TF)
            % This button manages the enabled/disabled state of UIControls
            % in the toolstrip based on whether or not an image has been
            % loaded into the app.
            for i = 1:length( self.hChangeUIComponentHandles )
                self.hChangeUIComponentHandles{i}.Enabled = TF;
            end
            
        end
        
    end
    
    % The following methods gets called from ImageCaptureTab Class.
    methods (Access = public)
        function importImageData(self,im)
            
            if isa(im,'double');
                [self,im] = normalizeDoubleDataDlg(self,im);
                if isempty(im)
                    return;
                end
            end
            
            self.initializeAppWithRGBImage(im);
            
            % Bring up colorspace montage view
            self.compareColorSpaces();
            
        end       
        
        function TF = validColorspaceFiguresInApp(self)
            
            TF = self.hToolGroup.isClientShowing('RGB') ||...
                self.hToolGroup.isClientShowing('HSV') ||...
                self.hToolGroup.isClientShowing('YCbCr') ||...
                self.hToolGroup.isClientShowing('L*a*b*');
            
        end
        
        function TF = isCameraPreviewInApp(self)
            TF = self.hToolGroup.isClientShowing(getString(message('images:colorSegmentor:MainPreviewFigure')));
        end
        
        function toolGroup = getToolGroup(self)
            toolGroup = self.hToolGroup;
        end
        
        
        % Method is used by both import from file and import from workspace
        % callbacks.
        function user_canceled = showImportingDataWillCauseDataLossDlg(self, msg, msgTitle)
            
            user_canceled = false;

            if self.validColorspaceFiguresInApp();
                
                buttonName = questdlg(msg, msgTitle, ...
                    getString(message('images:commonUIString:yes')),...
                    getString(message('images:commonUIString:cancel')),...
                    getString(message('images:commonUIString:cancel')));
                
                if strcmp(buttonName,getString(message('images:commonUIString:yes')))
                    
                    % Each time a new colorspace document is added, we want to
                    % revert the Show Binary, Invert Mask, and Mask Opacity ui
                    % controls back to their initialized state.
                    self.manageControlsOnImageLoad();
                    self.hColorSpacesButton.Enabled = false;

                    validFigHandles = ishandle(self.FigureHandles);
                    if ismember(getString(message('images:colorSegmentor:MainPreviewFigure')), get(self.FigureHandles(validFigHandles), 'Name')) % do not remove camera document tab.
                        % Remove Camera figure handle from valid list of
                        % figure handles.
                        validFigHandles(1) = 0;
                        close(self.FigureHandles(validFigHandles));
                        self.FigureHandles = self.FigureHandles(1);
                    else
                        close(self.FigureHandles(validFigHandles));                        
                        self.FigureHandles = [];
                    end
                else
                    user_canceled = true;
                end
                
            end
        end        
    end
    % Methods used to create each color space segmentation figure/document
    methods (Access = private)
        
        function hFig = createColorspaceSegmentationView(self,im,csname)
            
            % We don't want creation of a new figure in the ToolGroup to
            % trigger the ClientAction callback as the new figure is
            % enabled. Temporarily disable listener as we add new figure to
            % the ToolGroup.
            self.ClientActionListener.Enabled = false;
            
            if isempty(im) % We are in preview/camera mode.
                if isempty(self.ImagePreviewDisplay)
                    self.ImagePreviewDisplay = ...
                        iptui.internal.ImagePreview;
                    self.FigureHandles(end+1) = self.ImagePreviewDisplay.Fig;
                    self.hToolGroup.addFigure(self.ImagePreviewDisplay.Fig);
                end
                hFig = self.ImagePreviewDisplay.Fig;
            else          
                hFig = figure('NumberTitle', 'off',...
                    'Name',csname,'Colormap',gray(2),...
                    'IntegerHandle','off');
                
                % Set the WindowKeyPressFcn to a non-empty function. This is
                % effectively a no-op that executes everytime a key is pressed
                % when the App is in focus. This is done to prevent focus from
                % shifting to the MATLAB command window when a key is typed.
                hFig.WindowKeyPressFcn = @(~,~)[];
                
                self.FigureHandles(end+1) = hFig;
                self.hToolGroup.addFigure(hFig);
            end
            
            % Unregister image in drag and drop gestures when figures are
            % docked in toolgroup.
            self.hToolGroup.getFiguresDropTargetHandler.unregisterInterest(hFig);
            
            iptPointerManager(hFig);
            
            if ~isempty(im)
                hLeftPanel  = uipanel('Parent',hFig,'Position',[0 0 0.6 1],'BorderType','none','tag','LeftPanel');
                hRightPanel = uipanel('Parent',hFig,'Position',[0.6 0 0.4 1],'BorderType','none','tag','RightPanel');

                layoutInteractiveHistograms(self,hRightPanel,im,csname);
                layoutScrollpanel(self,hLeftPanel);
            
                % Update mask
                histHandles = getappdata(hRightPanel,'HistPanelHandles');
                self.updateMask(im,histHandles{:});
            end
            
            % Prevent MATLAB graphics from being drawn in figures docked
            % within app.
            set(hFig,'HandleVisibility','callback');
            
            % Now that we are done setting up new color space figure,
            % Enable client action listener to manage state as user
            % switches between existing figures.
            self.ClientActionListener.Enabled = true;
            
            self.hFigCurrent = hFig;
            
        end
        
        function layoutScrollpanel(self,hLeftPanel)
            
            if isempty(self.hScrollpanel) || ~ishandle(self.hScrollpanel)
                
                hAx   = axes('Parent',hLeftPanel);
                
                % Figure will be docked before imshow is invoked. We want
                % to avoid warning about fit mag in context of a docked
                % figure.
                warnState = warning('off','images:imshow:magnificationMustBeFitForDockedFigure');
                hIm  = imshow(self.imRGB,'Parent',hAx);
                warning(warnState);
                
                self.hScrollpanel = imscrollpanel(hLeftPanel,hIm);
                set(self.hScrollpanel,'Units','normalized',...
                    'Position',[0 0 1 1])
                
                % We need to ensure that graphics objects related to the
                % scrollpanel are constructed before we set the
                % magnification of the tool.
                drawnow; drawnow
                
                api = iptgetapi(self.hScrollpanel);
                api.setMagnification(api.findFitMag());
                
                % Turn on axes visibility
                hAx = findobj(self.hScrollpanel,'type','axes');
                set(hAx,'Visible','on');
                
                % Initialize Overlay color by setting axes color.
                set(hAx,'Color','black');
                
                % Turn off axes gridding
                set(hAx,'XTick',[],'YTick',[]);
                
            else
                % If scrollpanel has already been created, we simply want
                % to reparent it to the current figure that is being
                % created/in view.
                set(self.hScrollpanel,'Parent',hLeftPanel);
            end
            
            
        end
        
        function [hChan1Hist,hChan2Hist,hChan3Hist] = layoutInteractiveHistograms(self,hPanel,im,csname)
            
            import iptui.internal.InteractiveHistogram;
            import iptui.internal.InteractiveHistogramHue;
            
            margin = 5;
            hFigFlowSliders = uiflowcontainer('v0',...
                'Parent', hPanel,...
                'FlowDirection', 'TopDown', ...
                'Margin', margin);
            
            switch csname
                
                case 'RGB'
                    hChan1Hist = InteractiveHistogram(hFigFlowSliders, im(:,:,1), 'ramp', {[0 0 0], [1 0 0]}, 'R');
                    hChan2Hist = InteractiveHistogram(hFigFlowSliders, im(:,:,2), 'ramp', {[0 0 0], [0 1 0]}, 'G');
                    hChan3Hist = InteractiveHistogram(hFigFlowSliders, im(:,:,3), 'ramp', {[0 0 0], [0 0 1]}, 'B');
                    
                case 'HSV'
                    ratios = [0.5 0.25 0.25];
                    drawnow; drawnow; drawnow %TODO: This is probably overkill. - jmather, 18 Sept 2013
                    [hPanelTop, hPanelMiddle, hPanelBottom] = createThreePanels(hPanel, ratios, margin);
                    hChan1Hist = InteractiveHistogramHue(hPanelTop, im(:,:,1));
                    hChan2Hist = InteractiveHistogram(hPanelMiddle, im(:,:,2), 'saturation');
                    hChan3Hist = InteractiveHistogram(hPanelBottom, im(:,:,3), 'BlackToWhite', 'V');
                    
                case 'L*a*b*'
                    hChan1Hist = InteractiveHistogram(hFigFlowSliders, im(:,:,1), 'LStar', 'L*');
                    hChan2Hist = InteractiveHistogram(hFigFlowSliders, im(:,:,2), 'aStar');
                    hChan3Hist = InteractiveHistogram(hFigFlowSliders, im(:,:,3), 'bStar');
                    
                case 'YCbCr'
                    hChan1Hist = InteractiveHistogram(hFigFlowSliders, im(:,:,1), 'BlackToWhite', 'Y');
                    hChan2Hist = InteractiveHistogram(hFigFlowSliders, im(:,:,2), 'Cb');
                    hChan3Hist = InteractiveHistogram(hFigFlowSliders, im(:,:,3), 'Cr');
                    
                otherwise
                    hChan1Hist = InteractiveHistogram(hFigFlowSliders, im(:,:,1));
                    hChan2Hist = InteractiveHistogram(hFigFlowSliders, im(:,:,2));
                    hChan3Hist = InteractiveHistogram(hFigFlowSliders, im(:,:,3));
                    
            end
            
            addlistener(hChan1Hist,'currentSelection','PostSet',...
                @(~,~) updateMask(self, im, hChan1Hist, hChan2Hist, hChan3Hist));
            
            addlistener([hChan2Hist,hChan3Hist],'currentSelection', 'PostSet',...
                @(~,~) updateMask(self, im, hChan1Hist, hChan2Hist, hChan3Hist));
            
            histograms = {hChan1Hist, hChan2Hist, hChan3Hist};
            
            setappdata(hPanel,'HistPanelHandles',histograms);
            setappdata(hPanel,'ColorspaceCData',im);
            
        end
        
    end
        
    % Methods used to layout each section of app
    methods (Access = private)
        
        function layoutLoadImageSection(self)
            
            % Create Panel to hold button in Load Image section
            loadImagePanel = toolpack.component.TSPanel('f:p','f:p');
            loadImagePanel.Name = 'panelLoadImage';
            self.LoadImageSection.add(loadImagePanel);
            
            loadImageButton = toolpack.component.TSSplitButton(getString(message('images:colorSegmentor:loadImageSplitButtonTitle')), ...
                toolpack.component.Icon.IMPORT_24);
            addlistener(loadImageButton, 'ActionPerformed', @(hobj,evt) self.loadImageFromFile(hobj,evt) );
            loadImageButton.Orientation = toolpack.component.ButtonOrientation.VERTICAL;
            setToolTipText(loadImageButton,getString(message('images:colorSegmentor:loadImageTooltip')));
            loadImageButton.Name = 'btnLoadImage';
            
            % This style tells TSDropDownPopup to show just text and the
            % icon. We could also use 'text_only'.
            style = 'icon_text';
            
            loadImageButton.Popup = toolpack.component.TSDropDownPopup(...
                getLoadOptions(), style);
            loadImageButton.Popup.Name = 'Load Image Popup';
            
            % Add listener for processing load image options
            addlistener(loadImageButton.Popup, 'ListItemSelected',...
                @self.openImageSplitButtonCallback);
            
            loadImagePanel.add(loadImageButton, 'xy(1,1)' );
            
            self.lassoSensitiveComponentHandles{end+1} = loadImageButton;
            
            % -----------------------------------------------------------------
            function items = getLoadOptions()
                % defining the option entries appearing on the popup of the
                % Load Split Button.
                
                items(1) = struct(...
                    'Title', getString(message('images:colorSegmentor:loadImageFromFile')), ...
                    'Description', '', ...
                    'Icon', toolpack.component.Icon.IMPORT_16, ...
                    'Help', [], ...
                    'Header', false);
                items(2) = struct(...
                    'Title', getString(message('images:colorSegmentor:loadImageFromWorkspace')), ...
                    'Description', '', ...
                    'Icon', toolpack.component.Icon.IMPORT_16, ...
                    'Help', [], ...
                    'Header', false);
                loadFromCameraIcon = toolpack.component.Icon(...
                    fullfile(matlabroot, 'toolbox', 'images', 'icons', 'color_thresholder_load_camera_16.png'));
                items(3) = struct(...
                    'Title', getString(message('images:colorSegmentor:loadImageFromCamera')), ...
                    'Description', '', ...
                    'Icon', loadFromCameraIcon, ...
                    'Help', [], ...
                    'Header', false);                
            end
            
        end
        
        function layoutColorSpacesSection(self)
            
            % Create Panel to hold button in COLOR SPACES section
            colorSpacesPanel = toolpack.component.TSPanel('f:p','f:p');
            colorSpacesPanel.Name = 'panelColorSpaces';
            self.ColorSpacesSection.add(colorSpacesPanel);
            
            newColorspaceIcon = toolpack.component.Icon(...
                fullfile(matlabroot,'/toolbox/images/icons/NewColorSpace_24px.png'));
            self.hColorSpacesButton = toolpack.component.TSButton(getString(message('images:colorSegmentor:newColorspace')), ...
                newColorspaceIcon);
            self.hColorSpacesButton.Name = 'btnNewColorspace';
            
            addlistener(self.hColorSpacesButton, 'ActionPerformed', @(hobj,evt) self.compareColorSpaces(hobj,evt) );
            self.hColorSpacesButton.Orientation = toolpack.component.ButtonOrientation.VERTICAL;
            self.hColorSpacesButton.Enabled = false;
            setToolTipText(self.hColorSpacesButton,getString(message('images:colorSegmentor:addNewColorspaceTooltip')));
            
            colorSpacesPanel.add(self.hColorSpacesButton, 'xy(1,1)' );
            
            self.lassoSensitiveComponentHandles{end+1} = self.hColorSpacesButton;
            
        end
        
        function layoutManualSelectionSection(self)
            
            % Selection Tools: Freehand and apply buttons
            selectionToolsPanel = toolpack.component.TSPanel('f:p,f:p', 'f:p');
            selectionToolsPanel.Name = 'selectionToolsPanel';
            self.ManualSelectionSection.add(selectionToolsPanel)
            
            lassoButtonIcon = toolpack.component.Icon(fullfile(matlabroot,'/toolbox/images/icons/Freehand_24px.png'));
            lassoButton = toolpack.component.TSButton(getString(message('images:colorSegmentor:addRegion')), lassoButtonIcon);
            lassoButton.Name = 'btnAddRegion';
            lassoButton.Orientation = toolpack.component.ButtonOrientation.VERTICAL;
            lassoButton.Enabled = true;
            addlistener(lassoButton, 'ActionPerformed', @(hobj, evt) lassoRegion(self));
            setToolTipText(lassoButton, getString(message('images:colorSegmentor:addRegionTooltip')))
                        
            selectionToolsPanel.add(lassoButton, 'xy(1,1)')

            self.hChangeUIComponentHandles{end+1} = lassoButton;

            % Apply and Close buttons.
            applyButton = toolpack.component.TSButton(getString(message('images:colorSegmentor:apply')), toolpack.component.Icon.RUN_24);
            applyButton.Name = 'btnApply';
            applyButton.Orientation = toolpack.component.ButtonOrientation.VERTICAL;
            applyButton.Enabled = false;
            addlistener(applyButton, 'ActionPerformed', @(hobj, evt) applyROIs(self));
            setToolTipText(applyButton, getString(message('images:colorSegmentor:applyTooltip')))
            
            selectionToolsPanel.add(applyButton, 'xy(2,1)')

            self.hApplyROIsButton = applyButton;
            
            self.lassoSensitiveComponentHandles{end+1} = lassoButton;
            self.lassoSensitiveComponentHandles{end+1} = applyButton;
            
        end
        
        function layoutThresholdControlsSection(self)
            
            panel = toolpack.component.TSPanel('f:p','f:p');
            self.ThresholdControlsSection.add(panel);
            panel.Name = 'panelThresholdControls';
            
            invertMaskIcon = toolpack.component.Icon(...
                fullfile(matlabroot,'/toolbox/images/icons/InvertMask_24px.png'));
            self.hInvertMaskButton = toolpack.component.TSToggleButton(getString(message('images:colorSegmentor:invertMask')),...
                invertMaskIcon);
            self.hInvertMaskButton.Name = 'btnInvertMask';
            
            self.invertMaskItemStateChangedListener = addlistener(self.hInvertMaskButton, 'ItemStateChanged', @(hobj,evt) self.invertMaskButtonPress(hobj,evt) );
            setToolTipText(self.hInvertMaskButton,getString(message('images:colorSegmentor:invertMaskTooltip')));
            
            self.hChangeUIComponentHandles{end+1} = self.hInvertMaskButton;
            
            self.hInvertMaskButton.Orientation = toolpack.component.ButtonOrientation.VERTICAL;
            
            panel.add(self.hInvertMaskButton,'xy(1,1)');
            
        end
        
        function layoutPanZoomSection(self)
            
            
            zoomPanPanel = toolpack.component.TSPanel( ...
                'f:p', ... % columns
                'f:p:g,f:p:g,f:p:g');  % rows
            
            zoomPanPanel.Name = 'panelZoomPan';
            
            self.PanZoomSection.add(zoomPanPanel);
            
            self.hZoomInButton = toolpack.component.TSToggleButton(getString(message('images:commonUIString:zoomInTooltip')),...
                toolpack.component.Icon.ZOOM_IN_16);
            addlistener(self.hZoomInButton, 'ItemStateChanged', @(hobj,evt) self.zoomIn(hobj,evt) );
            self.hZoomInButton.Orientation = toolpack.component.ButtonOrientation.HORIZONTAL;
            self.hChangeUIComponentHandles{end+1} = self.hZoomInButton;
            setToolTipText(self.hZoomInButton,getString(message('images:commonUIString:zoomInTooltip')));
            self.hZoomInButton.Name = 'btnZoomIn';
            
            self.hZoomOutButton = toolpack.component.TSToggleButton(getString(message('images:commonUIString:zoomOutTooltip')),...
                toolpack.component.Icon.ZOOM_OUT_16);
            addlistener(self.hZoomOutButton, 'ItemStateChanged', @(hobj,evt) self.zoomOut(hobj,evt) );
            self.hZoomOutButton.Orientation = toolpack.component.ButtonOrientation.HORIZONTAL;
            self.hChangeUIComponentHandles{end+1} = self.hZoomOutButton;
            setToolTipText(self.hZoomOutButton,getString(message('images:commonUIString:zoomOutTooltip')));
            self.hZoomOutButton.Name = 'btnZoomOut';
            
            self.hPanButton = toolpack.component.TSToggleButton(getString(message('images:colorSegmentor:pan')),...
                toolpack.component.Icon.PAN_16 );
            addlistener(self.hPanButton, 'ItemStateChanged', @(hobj,evt) self.panImage(hobj,evt) );
            self.hPanButton.Orientation = toolpack.component.ButtonOrientation.HORIZONTAL;
            self.hChangeUIComponentHandles{end+1} = self.hPanButton;
            setToolTipText(self.hPanButton,getString(message('images:colorSegmentor:pan')));
            self.hPanButton.Name = 'btnPan';
            
            zoomPanPanel.add(self.hZoomInButton, 'xy(1,1)' );
            zoomPanPanel.add(self.hZoomOutButton,'xy(1,2)' );
            zoomPanPanel.add(self.hPanButton,'xy(1,3)' );
            
            self.lassoSensitiveComponentHandles{end+1} = self.hZoomInButton;
            self.lassoSensitiveComponentHandles{end+1} = self.hZoomOutButton;
            self.lassoSensitiveComponentHandles{end+1} = self.hPanButton;
            
        end
        
        function layoutViewSegmentationSection(self)
            
%             viewSegmentationPanel = toolpack.component.TSPanel( ...
%                 'f:p,f:p,f:p,40dlu', ... % columns
%                 'f:p:g,f:p:g,f:p:g');  % rows
            
            viewSegmentationPanel = toolpack.component.TSPanel( ...
                'f:p,40dlu,f:p,f:p,f:p', ... % columns
                'f:p:g,f:p:g,f:p:g');  % rows
            
            self.ViewSegmentationSection.add(viewSegmentationPanel);
            viewSegmentationPanel.Name = 'panelViewSegmentation';
            
            ShowBinaryIcon = toolpack.component.Icon(...
                fullfile(matlabroot,'/toolbox/images/icons/ShowBinary_24px.png'));
            self.hShowBinaryButton = toolpack.component.TSToggleButton(getString(message('images:colorSegmentor:showBinary')),...
                ShowBinaryIcon);
            self.binaryButonStateChangedListener = addlistener(self.hShowBinaryButton, 'ItemStateChanged', @(hobj,evt) showBinaryPress(self,hobj,evt) );
            self.hShowBinaryButton.Orientation = toolpack.component.ButtonOrientation.VERTICAL;
            self.hChangeUIComponentHandles{end+1} = self.hShowBinaryButton;
            setToolTipText(self.hShowBinaryButton,getString(message('images:colorSegmentor:viewBinaryTooltip')));
            self.hShowBinaryButton.Name = 'btnShowBinary';
            
            self.hMaskOpacitySlider = toolpack.component.TSSlider(0,100,100);
            self.hMaskOpacitySlider.MinorTickSpacing = 0.1;
            self.sliderMovedListener = addlistener(self.hMaskOpacitySlider,'StateChanged',@(hobj,evt) opacitySliderMoved(self,hobj,evt) );
            self.hChangeUIComponentHandles{end+1} = self.hMaskOpacitySlider;
            setToolTipText(self.hMaskOpacitySlider,getString(message('images:colorSegmentor:sliderTooltip')));
            self.hMaskOpacitySlider.Name = 'sliderMaskOpacity';
            
            overlayColorLabel   = toolpack.component.TSLabel(getString(message('images:colorSegmentor:backgroundColor')));
            overlayColorLabel.Name = 'labelOverlayColor';
            overlayOpacityLabel = toolpack.component.TSLabel(getString(message('images:colorSegmentor:backgroundOpacity')));
            overlayOpacityLabel.Name = 'labelOverlayOpacity';
            
            % There is no MCOS interface to set the icon of a TSButton
            % directly from a uint8 buffer.
            self.hOverlayColorButton = toolpack.component.TSButton();
            self.setTSButtonIconFromImage(self.hOverlayColorButton,zeros(16,16,'uint8'));
            addlistener(self.hOverlayColorButton,'ActionPerformed',@(hobj,evt) self.chooseOverlayColor(hobj,evt) );
            self.hChangeUIComponentHandles{end+1} = self.hOverlayColorButton;
            setToolTipText(self.hOverlayColorButton,getString(message('images:colorSegmentor:backgroundColorTooltip')));
            self.hOverlayColorButton.Name = 'btnOverlayColor';
                        
            viewSegmentationPanel.add(overlayColorLabel,'xy(1,1)');
            viewSegmentationPanel.add(self.hOverlayColorButton,'xy(2,1,''l,c'')');
            viewSegmentationPanel.add(self.hMaskOpacitySlider,'xywh(2,2,2,1)');
            viewSegmentationPanel.add(overlayOpacityLabel,'xy(1,2)');
            viewSegmentationPanel.add(self.hShowBinaryButton,'xywh(5,1,1,3)');
            
        end
        
        function layoutExportSection(self)
            
            createMaskPanel = toolpack.component.TSPanel('f:p','f:p');
            self.ExportSection.add(createMaskPanel);
            createMaskPanel.Name = 'panelExport';
            
            createMaskIcon = toolpack.component.Icon(...
                fullfile(matlabroot,'/toolbox/images/icons/CreateMask_24px.png'));
            
            exportButton = toolpack.component.TSSplitButton(getString(message('images:colorSegmentor:export')), ...
                createMaskIcon);
            addlistener(exportButton, 'ActionPerformed',@(hobj,evt) self.exportDataToWorkspace() );
            exportButton.Orientation = toolpack.component.ButtonOrientation.VERTICAL;
            exportButton.Name = 'btnExport';
            setToolTipText(exportButton,getString(message('images:colorSegmentor:exportButtonTooltip')));

            % This style tells TSDropDownPopup to show just text and the
            % icon. We could also use 'text_only'.
            style = 'icon_text';
            
            exportButton.Popup = toolpack.component.TSDropDownPopup(...
                getExportOptions(), style);
            exportButton.Popup.Name = 'Export Popup';
            
            % Add listener for processing load image options
            addlistener(exportButton.Popup, 'ListItemSelected',...
                @self.exportSplitButtonCallback);
            
            createMaskPanel.add(exportButton, 'xy(1,1)' );
            
            self.hChangeUIComponentHandles{end+1} = exportButton;
            
            self.lassoSensitiveComponentHandles{end+1} = exportButton;
            
            % -----------------------------------------------------------------
            function items = getExportOptions(~)
                % defining the option entries appearing on the popup of the
                % Export Split Button.
                
                exportDataIcon = toolpack.component.Icon(...
                    fullfile(matlabroot,'/toolbox/images/icons/CreateMask_16px.png'));
                
                exportFunctionIcon = toolpack.component.Icon(...
                    fullfile(matlabroot,'/toolbox/images/icons/GenerateMATLABScript_Icon_16px.png'));
                
                items(1) = struct(...
                    'Title', getString(message('images:colorSegmentor:exportImages')), ...
                    'Description', '', ...
                    'Icon', exportDataIcon, ...
                    'Help', [], ...
                    'Header', false);
                                
                items(2) = struct(...
                    'Title', getString(message('images:colorSegmentor:exportFunction')), ...
                    'Description', '', ...
                    'Icon', exportFunctionIcon, ...
                    'Help', [], ...
                    'Header', false);
            end
            
        end
        
    end
    
    % Region selection functionality
    methods (Access = private)

        %------------------------------------------------------------------
        function lassoRegion(self)
            %lassoRegion  Add freehand ROI to current colorspace figure.

            % Keep track of the state of the toolstrip buttons, and disable
            % tools that could interfere with region selection.
            self.preLassoPanZoomState = self.getStateOfPanZoomMode(); 
            self.preLassoToolstripState = self.getStateOfLassoSensitiveTools();
            self.setStateOfPanZoomMode('off') % Do this ...
            self.disableLassoSensitiveTools() % ... before this.
            
            hAx = findobj(self.hScrollpanel, 'type', 'axes');
            self.freehandManager = iptui.internal.ImfreehandModeContainer(hAx);
            self.freehandManager.enableInteractivePlacement()
            
            self.hFreehandListener = addlistener(self.freehandManager, 'hROI', 'PostSet', ...
                @(obj,evt) self.freehandedAdded(obj, evt) );
        end

        %------------------------------------------------------------------
        function freehandedAdded(self, ~, ~)
            %freehandedAdded  Callback that fires when a hROI changes.
            
            self.disableLassoRegion()
            
            hFree = self.freehandManager.hROI;
            self.freehandManager = [];

            self.addROIHandleToCollection(hFree)
            self.updateFreehandDeleteFcn(hFree)
        end
        
        %------------------------------------------------------------------
        function disableLassoRegion(self)
            self.freehandManager.disableInteractivePlacement()
            
            self.enableLassoSensitiveTools(self.preLassoToolstripState) % Do this ...
            self.setStateOfPanZoomMode(self.preLassoPanZoomState) % ... before this.
            self.hApplyROIsButton.Enabled = true;
            self.hFreehandListener = [];
        end

        %------------------------------------------------------------------
        function updateFreehandDeleteFcn(self, hFree)
            %updateFreehandDeleteFcn  Callback adapter for ROI DeleteFcn.
            
            origDeleteFcn = get(hFree, 'DeleteFcn');
            set(hFree, 'DeleteFcn', @(obj,evt) newFreehandDeleteFcn(self, obj, evt, origDeleteFcn) )
        end

        %------------------------------------------------------------------
        function newFreehandDeleteFcn(self, obj, evt, origDeleteFcn)
            %newFreehandDeleteFcn  Delete ROI and remove from collection.
            
            % (1) Call the original delete function.
            if isgraphics(obj)
                origDeleteFcn(obj, evt);
            end

            if ~isvalid(self)
                % App is being destroyed...
                return
            end
            
            % (2) Remove the handle from the collection of imfreehand objects.
            % *Find the row in the table.
            figuresWithROIs = [self.hFreehandROIs{:,1}];
            idx = find(figuresWithROIs == self.hFigCurrent, 1);
            
            % Remove the handle from the row (or the whole row if the
            % figure is being deleted).
            if ~isvalid(self.hFigCurrent) || strcmpi(self.hFigCurrent.Name, getString(message('images:colorSegmentor:MainPreviewFigure')))
                self.hFreehandROIs(idx,:) = [];
                self.hApplyROIsButton.Enabled = false;
                return
            end
            currentROIs = self.hFreehandROIs{idx,2};
            idxArray = arrayfun(@(h) isequal(get(h, 'BeingDeleted'), 'on'), currentROIs);
            currentROIs(idxArray) = [];
            self.hFreehandROIs{idx,2} = currentROIs;
            
            % (3) Disable the "Apply" button if there are no more ROIs.
            if isempty(currentROIs)
                self.hApplyROIsButton.Enabled = false;
            end
        end
        
        %------------------------------------------------------------------
        function addROIHandleToCollection(self, newROIHandle)
            %addROIHandleToCollection  Keep track of the new ROI.
            
            % Special case for first ROI of the app.
            if isempty(self.hFreehandROIs)
                self.hFreehandROIs = {self.hFigCurrent, newROIHandle};
                return
            end
            
            % Add this ROI's handle to a new or existing row in the table.
            idx = self.findFigureIndexInCollection(self.hFigCurrent);
            if isempty(idx)
                self.hFreehandROIs(end+1,:) = {self.hFigCurrent, newROIHandle};
            else
                self.hFreehandROIs{idx,2} = [self.hFreehandROIs{idx,2}, newROIHandle];
            end
        end

        %------------------------------------------------------------------
        function hROIs = findROIs(self, hFig)
            %findROIs  Get handles to ROIs in specified figure.
            
            idx = self.findFigureIndexInCollection(hFig);
            if isempty(idx)
                hROIs = [];
            else
                hROIs = self.hFreehandROIs{idx,2};
                hROIs = hROIs(isvalid(hROIs));
            end
        end
        
        %------------------------------------------------------------------
        function idx = findFigureIndexInCollection(self, hFig)
            %findFigureIndexInCollection  Find specified figure in collection.
            
            figuresWithROIs = [self.hFreehandROIs{:,1}];
            idx = find(figuresWithROIs == hFig, 1);
        end
        
        %------------------------------------------------------------------
        function applyROIs(self)
            
            % Get the handles to the histograms.
            hRightPanel = findobj(self.hFigCurrent, 'tag', 'RightPanel');
            histHandles = getappdata(hRightPanel, 'HistPanelHandles');
            
            if ~self.hasValidROIs(self.hFigCurrent)
                return
            end
            
            % Get the new selection from the ROI values.
            cData = getappdata(hRightPanel, 'ColorspaceCData');
            [lim1, lim2, lim3] = colorStats(self, cData);
            
            if (isempty(lim1) || isempty(lim2) || isempty(lim3))
                return
            end
            
            % Update the histograms' current selection and mask.
            histHandles{1}.currentSelection = lim1;
            histHandles{1}.updateHistogram();
            histHandles{2}.currentSelection = lim2;
            histHandles{2}.updateHistogram();
            histHandles{3}.currentSelection = lim3;
            histHandles{3}.updateHistogram();
            
            self.updateMask(cData, histHandles{:})
        end
        
        %------------------------------------------------------------------
        function [lim1, lim2, lim3] = colorStats(self, cData)
            %colorStats  Compute limits of colors within ROIs
            
            % Create a mask of pixels under the ROIs.
            hROIs = self.findROIs(self.hFigCurrent);
            
            imgSize = size(cData);
            bw = false(imgSize(1:2));
            
            for p = 1:numel(hROIs)
                if isvalid(hROIs(p))
                    bw = bw | hROIs(p).createMask;
                end
            end
            
            % Compute color min and max for pixels under the mask.
            samplesInROI = samplesUnderMask(cData, bw);
            
            lim1 = computeHLim(samplesInROI(:,1));
            lim2 = [min(samplesInROI(:,2)), max(samplesInROI(:,2))];
            lim3 = [min(samplesInROI(:,3)), max(samplesInROI(:,3))];
        end
        
        %------------------------------------------------------------------
        function TF = hasValidROIs(self, hFig)
            %hasValidROIs  Does specified figure have any ROIs?
            
            TF = false;
            if isempty(self.hFreehandROIs)
                return
            end
            
            idx = self.findFigureIndexInCollection(hFig);
            hROIs = self.hFreehandROIs{idx,2};
            for p = 1:numel(hROIs)  %TODO: TF = any(isvalid(hROIs))
                TF = TF || isvalid(hROIs(p));
            end
        end

        %------------------------------------------------------------------
        function hideOtherROIs(self)
            %hideOtherROIs  Hide ROIs not attached to current figure.

            % Keep track of whether any ROIs were activated. If not,
            % disable the "Apply ROI" button.
            activated = false;
            
            % Hide ROIs that aren't part of the current figure.
            if ~isempty(self.hFreehandROIs)
                figuresWithROIs = [self.hFreehandROIs{:,1}];
                idx = figuresWithROIs == self.hFigCurrent;
                hROIs = self.hFreehandROIs(~idx,2);
                for p = 1:numel(hROIs)
                    tmp = hROIs{p};
                    for q = 1:numel(tmp)
                        if isvalid(tmp(q))
                            set(tmp(q), 'Visible', 'off')
                            set(findall(tmp(q)), 'HitTest', 'off')
                        end
                    end
                end
                hROIs = self.hFreehandROIs(idx,2);
                for p = 1:numel(hROIs)
                    tmp = hROIs{p};
                    for q = 1:numel(tmp)
                        if isvalid(tmp(q))
                            set(tmp(q), 'Visible', 'on')
                            set(findall(tmp(q)), 'HitTest', 'on')
                            activated = true;
                        end
                    end
                end
            end
            
            % Set Apply button state depending on whether ROIs were enabled.
            if activated
                self.hApplyROIsButton.Enabled = true;
            else
                self.hApplyROIsButton.Enabled = false;
            end
        end

        %------------------------------------------------------------------
        function stateVec = getStateOfLassoSensitiveTools(self)
            vecLength = numel(self.lassoSensitiveComponentHandles);
            stateVec = false(1, vecLength);
            
            for idx = 1:vecLength
                stateVec(idx) = self.lassoSensitiveComponentHandles{idx}.Enabled;
            end
        end
        
        %------------------------------------------------------------------
        function disableLassoSensitiveTools(self)
            vecLength = numel(self.lassoSensitiveComponentHandles);
            
            for idx = 1:vecLength
                self.lassoSensitiveComponentHandles{idx}.Enabled = false;
            end
        end

        %------------------------------------------------------------------
        function enableLassoSensitiveTools(self, stateVec)
            vecLength = numel(self.lassoSensitiveComponentHandles);
            
            for idx = 1:vecLength
                self.lassoSensitiveComponentHandles{idx}.Enabled = stateVec(idx);
            end
        end
        
        %------------------------------------------------------------------
        function panZoomState = getStateOfPanZoomMode(self)
            %getStateOfPanZoomMode  Determine state of pan/zoom tools.
            
            panZoomState = {...
                self.hZoomInButton,   self.hZoomInButton.Selected
                self.hZoomOutButton,  self.hZoomOutButton.Selected
                self.hPanButton,      self.hPanButton.Selected};
        end
        
        %------------------------------------------------------------------
        function setStateOfPanZoomMode(self, panZoomState)
            %setPanZoomState  Adjust state of pan/zoom tools.
            
            if isequal(panZoomState, 'off')
                self.hZoomInButton.Selected = false;
                self.hZoomOutButton.Selected = false;
                self.hPanButton.Selected = false;
            else
                for idx=1:size(panZoomState,1)
                    obj = panZoomState{idx,1};
                    obj.Selected = panZoomState{idx,2};
                end
            end
        end
    end
    
    % Callback functions used by uicontrols in colorSegmentor app
    methods (Access = private)
        
        
        function openImageSplitButtonCallback(self, src, ~)
            
            % from save options popup
            if src.SelectedIndex == 1         % Open Image From File
                self.loadImageFromFile();
            elseif src.SelectedIndex == 2     % Load Image From Workspace
                self.loadImageFromWorkspace();
            elseif src.SelectedIndex == 3      % Load Image from Camera
                self.loadImageFromCamera();
            end
        end
        
        function loadImageFromFile(self,varargin)
            
            user_canceled_import = ...
                self.showImportingDataWillCauseDataLossDlg(...
                            getString(message('images:colorSegmentor:loadingNewImageMessage')), ...
                            getString(message('images:colorSegmentor:loadingNewImageTitle')));
            if ~user_canceled_import
                
                % Remove the Camera tab if exist.
                if isCameraPreviewInApp(self)
                    % Close the preview window.
                    self.ImageCaptureTab.closePreviewWindowCallback;
                end
                
                filename = imgetfile();
                if ~isempty(filename)
                    
                    im = imread(filename);
                    if ~iptui.internal.ColorSegmentationTool.isValidRGBImage(im)
                        hdlg = errordlg(getString(message('images:colorSegmentor:nonTruecolorErrorDlgText')),...
                            getString(message('images:colorSegmentor:nonTruecolorErrorDlgTitle')),'modal');
                        % We need error dlg to be blocking, otherwise
                        % loadImageFromFile() is invoked before dlg
                        % finishes setting itself up and becomes modal.
                        uiwait(hdlg);
                        % Drawnow is necessary so that imgetfile dialog will
                        % enforce modality in next call to imgetfile that
                        % arrises from recursion.
                        drawnow
                        self.loadImageFromFile();
                        return;
                    end
                    
                    self.importImageData(im);

                end
            end
        end
                    
        function loadImageFromWorkspace(self,varargin)
            
            user_canceled_import = ...
                self.showImportingDataWillCauseDataLossDlg(...
                            getString(message('images:colorSegmentor:loadingNewImageMessage')), ...
                            getString(message('images:colorSegmentor:loadingNewImageTitle')));

            if ~user_canceled_import
                 
                % Remove the Camera tab if exist.
                if isCameraPreviewInApp(self)
                    % Close the preview window.
                    self.ImageCaptureTab.closePreviewWindowCallback;
                end
                                
                [im,~,~,~,user_canceled_dlg] = iptui.internal.imgetvar([],true);
                if ~user_canceled_dlg
                    self.importImageData(im);
                end
                
            end
            
        end

        function loadImageFromCamera(self, varargin)
            
            if isCameraPreviewInApp(self)
                existingTabs = self.hToolGroup.TabNames;
                
                % If image capture tab is not in the toolgroup, add it and bring
                % focus to it.
                if ~any(strcmp(existingTabs, getString(message('images:colorSegmentor:ImageCaptureTabName'))))
                    % Add the tab to tool group.
                    add(self.hToolGroup, getToolTab(self.ImageCaptureTab), 2);
                end
                
                % Create Preview Figure - pass an empty image. 
                self.createColorspaceSegmentationView([], getString(message('images:colorSegmentor:MainPreviewFigure')));
                
                self.hToolGroup.SelectedTab = getString(message('images:colorSegmentor:ImageCaptureTabName'));
                
                % Set it as the current figure.
                self.hFigCurrent = self.FigureHandles(1);
                
                return;
            end
            
            user_canceled_import = ...
                self.showImportingDataWillCauseDataLossDlg(...
                            getString(message('images:colorSegmentor:takingNewSnapshotMessage')), ...
                            getString(message('images:colorSegmentor:takeNewSnapshotTitle')));
            
            if ~user_canceled_import
                existingTabs = self.hToolGroup.TabNames;

                % If image capture tab is not in the toolgroup, add it and bring
                % focus to it.
                if ~any(strcmp(existingTabs, getString(message('images:colorSegmentor:ImageCaptureTabName'))))
                    % Create the contextual tab.
                    self.ImageCaptureTab = iptui.internal.ImageCaptureTab(self);
                    if (~self.ImageCaptureTab.LoadTab)
                        self.ImageCaptureTab = [];
                        return;
                    end
                    % Add the tab to tool group.
                    add(self.hToolGroup, getToolTab(self.ImageCaptureTab), 2);
                end

                % Create Preview Figure - pass an empty image. 
                self.createColorspaceSegmentationView([], getString(message('images:colorSegmentor:MainPreviewFigure')));

                % Create the device and launch preview.
                self.ImageCaptureTab.createDevice;

                self.hToolGroup.SelectedTab = getString(message('images:colorSegmentor:ImageCaptureTabName'));

                % Show camera preview.
                self.ImagePreviewDisplay.makeFigureVisible();
            end
        end
        
        function compareColorSpaces(self,varargin)
            
            % We need to force the desktop to complete its layout before
            % using getGroupLocation to compute the positioning of the
            % color space montage view, otherwise the position of the
            % montage view is sporadically wrong.
            drawnow;
            md = com.mathworks.mlservices.MatlabDesktopServices.getDesktop;
            pos = md.getGroupLocation(self.GroupName);
            
            dlgPos = [pos.getFrameX(), pos.getFrameY(), pos.getFrameWidth(), pos.getFrameHeight()];
            dlgPos = double(dlgPos);
            dlgPos = dlgPos + [50 50 -100 -100];
            
            hasCurrentValidMontageInstance = isa(self.hColorSpaceMontageView,'iptui.internal.ColorSpaceMontageView') &&...
                    isvalid(self.hColorSpaceMontageView);
            if hasCurrentValidMontageInstance
                self.hColorSpaceMontageView.bringToFocusInSpecifiedPosition(dlgPos);
            else
                self.hColorSpaceMontageView = iptui.internal.ColorSpaceMontageView(self,self.imRGB,dlgPos);
                % We maintain the reference to a listener for
                % SelectedColorSpace PostSet in ColorSegmentationTool so that
                self.colorspaceSelectedListener = event.proplistener(self.hColorSpaceMontageView,...
                    self.hColorSpaceMontageView.findprop('SelectedColorSpace'),...
                    'PostSet',@(hobj,evt) self.colorSpaceSelectedCallback(evt));
                
            end
                                     
        end
        
        function colorSpaceSelectedCallback(self,evt)
            
            % Add another segmentation document to toolgroup
            selectedColorSpace = evt.AffectedObject.SelectedColorSpace;
            selectedColorspaceData = self.computeColorspaceRepresentation(selectedColorSpace);
            self.createColorspaceSegmentationView(selectedColorspaceData,selectedColorSpace);
            
            % Enable UI controls
            self.setControlsEnabled(true);
            
            % Each time a new colorspace document is added, we want to
            % revert the Show Binary, Invert Mask, and Mask Opacity ui
            % controls back to their initialized state.
            self.manageControlsOnNewColorspace();
            
            % Hide currently visible ROIs.
            self.hideOtherROIs()
        end
        
        function invertMaskButtonPress(self,~,~)
            
            self.mask = ~self.mask;
                        
            % Now update graphics in scrollpanel.
            self.updateMaskOverlayGraphics();
                        
        end
        
        function zoomIn(self,hToggle,~)
            
            hIm = findobj(self.hScrollpanel,'type','image');
            if hToggle.Selected
                self.hZoomOutButton.Selected = false;
                self.hPanButton.Selected = false;
                warnstate = warning('off','images:imuitoolsgate:undocumentedFunction');
                zoomInFcn = imuitoolsgate('FunctionHandle', 'imzoomin');
                warning(warnstate);
                set(hIm,'ButtonDownFcn',zoomInFcn);
                glassPlus = setptr('glassplus');
                iptSetPointerBehavior(hIm,@(hFig,~) set(hFig,glassPlus{:}));
            else
                if ~(self.hZoomOutButton.Selected || self.hPanButton.Selected)
                    set(hIm,'ButtonDownFcn','');
                    iptSetPointerBehavior(hIm,[]);
                end
            end
            
        end
        
        function zoomOut(self,hToggle,~)
            
            hIm = findobj(self.hScrollpanel,'type','image');
            if hToggle.Selected
                self.hZoomInButton.Selected = false;
                self.hPanButton.Selected    = false;
                warnstate = warning('off','images:imuitoolsgate:undocumentedFunction');
                zoomOutFcn = imuitoolsgate('FunctionHandle', 'imzoomout');
                warning(warnstate);
                set(hIm,'ButtonDownFcn',zoomOutFcn);
                glassMinus = setptr('glassminus');
                iptSetPointerBehavior(hIm,@(hFig,~) set(hFig,glassMinus{:}));
            else
                if ~(self.hZoomInButton.Selected || self.hPanButton.Selected)
                    set(hIm,'ButtonDownFcn','');
                    iptSetPointerBehavior(hIm,[]);
                end
            end
            
        end
        
        function panImage(self,hToggle,~)
            
            hIm = findobj(self.hScrollpanel,'type','image');
            if hToggle.Selected
                self.hZoomOutButton.Selected = false;
                self.hZoomInButton.Selected = false;
                warnstate = warning('off','images:imuitoolsgate:undocumentedFunction');
                panFcn = imuitoolsgate('FunctionHandle', 'impan');
                warning(warnstate);
                set(hIm,'ButtonDownFcn',panFcn);
                handCursor = setptr('hand');
                iptSetPointerBehavior(hIm,@(hFig,~) set(hFig,handCursor{:}));
            else
                if ~(self.hZoomInButton.Selected || self.hZoomOutButton.Selected)
                    set(hIm,'ButtonDownFcn','');
                    iptSetPointerBehavior(hIm,[]);
                    
                end
            end
            
        end
        
        function showBinaryPress(self,hobj,~)
            
            hIm = findobj(self.hScrollpanel,'type','image');
            if hobj.Selected
                set(hIm,'AlphaData',1);
                self.updateMaskOverlayGraphics();
                self.hMaskOpacitySlider.Enabled = false;
            else
                set(hIm,'CData',self.imRGB);
                self.updateMaskOverlayGraphics();
                self.hMaskOpacitySlider.Enabled = true;
            end
            
        end
        
        function chooseOverlayColor(self,TSButtonObj,~)
            
            rgbColor = uisetcolor(getString(message('images:colorSegmentor:selectBackgroundColor')));
            
            colorSelectionCanceled = isequal(rgbColor, 0);
            if ~colorSelectionCanceled
                iconImage = zeros(16,16,3);
                iconImage(:,:,1) = rgbColor(1);
                iconImage(:,:,2) = rgbColor(2);
                iconImage(:,:,3) = rgbColor(3);
                iconImage = im2uint8(iconImage);
                
                self.setTSButtonIconFromImage(TSButtonObj,iconImage);
                
                % Set imscrollpanel axes color to apply chosen overlay color.
                set(findobj(self.hScrollpanel,'type','axes'),'Color',rgbColor);
                
            end
            
        end
        
        function opacitySliderMoved(self,varargin)
            
            self.updateMaskOverlayGraphics();
            
        end
        
        function exportSplitButtonCallback(self, src, ~)
            
            if src.SelectedIndex == 1 
                self.exportDataToWorkspace();
            elseif src.SelectedIndex == 2
                self.generateCode();
            end

        end
        
        % Used by exportMask button in export section
        function exportDataToWorkspace(self)
            
            maskedRGBImage = self.imRGB;
            
            % Set background pixels where BW is false to zero.
            maskedRGBImage(repmat(~self.mask,[1 1 3])) = 0;
            
            export2wsdlg({getString(message('images:colorSegmentor:binaryMask')),...
                          getString(message('images:colorSegmentor:maskedRGBImage')), ...
                          getString(message('images:colorSegmentor:inputRGBImage'))}, ...
                          {'BW','maskedRGBImage', 'inputImage'},{self.mask, maskedRGBImage, self.imRGB});
            
        end
                
        % Used by export function button in export section
        function generateCode(self)
            
            codeGenerator = iptui.internal.CodeGenerator();
            
            self.addFunctionDeclaration(codeGenerator)
            codeGenerator.addReturn()
            codeGenerator.addHeader('colorThresholder')
                        
            % If we normalized Double data, insert normalization into
            % generated code
            if isa(self.imRGB,'double') && (self.massageNansInfs)
                codeGenerator.addComment('Replace nan values with 0');
                codeGenerator.addLine('RGB(isnan(RGB)) = 0;');
                
                codeGenerator.addComment('Replace inf values with 1');
                codeGenerator.addLine('RGB(RGB==Inf) = 1;');
                
                codeGenerator.addComment('Replace -inf values with 0');
                codeGenerator.addLine('RGB(RGB==-Inf) = 0;');
            end
            
            if isa(self.imRGB,'double') && (self.normalizedDoubleData)
                codeGenerator.addComment('Normalize double input data to range [0 1]');
                codeGenerator.addLine('RGB = RGB ./ max(RGB(:));');
            end
            
            % Convert image to current selected color space
            codeGenerator.addComment('Convert RGB image to chosen color space');
            codeGenerator.addLine(getColorspaceConversionString());
            
            % Define thresholds per channel
            codeGenerator.addComment('Define thresholds for channel 1 based on histogram settings');
            
            hRightPanel = findobj(self.hFigCurrent,'tag','RightPanel');
            histHandles = getappdata(hRightPanel,'HistPanelHandles');
            hChanHist = histHandles{1};
            histLimits1 = hChanHist.currentSelection;
            codeGenerator.addLine(sprintf('channel1Min = %3.3f;',histLimits1(1)));
            codeGenerator.addLine(sprintf('channel1Max = %3.3f;',histLimits1(2)));
            
            codeGenerator.addComment('Define thresholds for channel 2 based on histogram settings');
            hChanHist = histHandles{2};
            histLimits2 = hChanHist.currentSelection;
            codeGenerator.addLine(sprintf('channel2Min = %3.3f;',histLimits2(1)));
            codeGenerator.addLine(sprintf('channel2Max = %3.3f;',histLimits2(2)));
            
            codeGenerator.addComment('Define thresholds for channel 3 based on histogram settings');
            hChanHist = histHandles{3};
            histLimits3 = hChanHist.currentSelection;
            codeGenerator.addLine(sprintf('channel3Min = %3.3f;',histLimits3(1)));
            codeGenerator.addLine(sprintf('channel3Max = %3.3f;',histLimits3(2)));
            
            codeGenerator.addComment('Create mask based on chosen histogram thresholds');
            
            if strcmp(get(self.hFigCurrent,'Name'),'HSV') && (histLimits1(1) >= histLimits1(2))
                % Handle circular behavior of H channel in HSV as a special
                % case
                codeGenerator.addLine('BW = ( (I(:,:,1) >= channel1Min) | (I(:,:,1) <= channel1Max) ) & ...');
            else
                % For every other colorspace and for HSV when H does not
                % span the discontinuity around red.
                codeGenerator.addLine('BW = (I(:,:,1) >= channel1Min ) & (I(:,:,1) <= channel1Max) & ...');
            end
            codeGenerator.addLine('  (I(:,:,2) >= channel2Min ) & (I(:,:,2) <= channel2Max) & ...');
            codeGenerator.addLine('  (I(:,:,3) >= channel3Min ) & (I(:,:,3) <= channel3Max);');
            
            % Honor state of Invert Mask button by complementing mask if
            % necessary
            if self.hInvertMaskButton.Selected
                codeGenerator.addComment('Invert mask');
                codeGenerator.addLine('BW = ~BW;');
            end
            
            % Add code to form 2nd LHS argument containing masked RGB
            % image.
            codeGenerator.addComment('Initialize output masked image based on input image.');
            codeGenerator.addLine('maskedRGBImage = RGB;');
            codeGenerator.addComment('Set background pixels where BW is false to zero.');
            codeGenerator.addLine('maskedRGBImage(repmat(~BW,[1 1 3])) = 0;');
            
            % Terminate the file with carriage return
            codeGenerator.addReturn();
            
            % Output the generated code to the MATLAB editor
            %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
            codeGenerator.putCodeInEditor();
            
            %-------------------------------------------
            function str = getColorspaceConversionString
                
                switch(get(self.hFigCurrent,'Name'))
                    
                    case 'RGB'
                        str = 'I = RGB;';
                    case 'HSV'
                        str = 'I = rgb2hsv(RGB);';
                    case 'YCbCr'
                        str = 'I = rgb2ycbcr(RGB);';
                    case 'L*a*b*'
                        str = sprintf('RGB = im2double(RGB); \n  cform = makecform(''srgb2lab'', ''AdaptedWhitePoint'', whitepoint(''D65'')); \n I = applycform(RGB,cform);');
                        
                end
                
            end
            
        end
        
        function addFunctionDeclaration(~,generator)
            fcnName = 'createMask';
            inputs = {'RGB'};
            outputs = {'BW', 'maskedRGBImage'};
            
            h1Line = ' Threshold RGB image using auto-generated code from colorThresholder app.';
            
            description = ['thresholds image RGB using auto-generated code' ...
                ' from the colorThresholder App. The colorspace and' ...
                ' minimum/maximum values for each channel of the colorspace' ...
                ' were set in the App and result in a binary mask BW and a' ...
                ' composite image maskedRGBImage, which shows the original' ...
                ' RGB image values under the mask BW.'];
            
            generator.addFunctionDeclaration(fcnName,inputs,outputs,h1Line);
            generator.addSyntaxHelp(fcnName,description,inputs,outputs);
        end
    end
    
    % Methods used to position and customize view of toolstrip app
    methods (Access = private)
        
        
        function disableInteractiveTiling(self)
           
            % Needs to be called before tool group is opened.
            g = self.hToolGroup.Peer.getWrappedComponent;
            g.putGroupProperty(com.mathworks.widgets.desk.DTGroupProperty.PERMIT_USER_TILE, false);
            
        end
               
        %------------------------------------------------------------------
        function removeViewTab(self)
            
            group = self.hToolGroup.Peer.getWrappedComponent;
            % Group without a View tab (needs to be called before t.open)
            group.putGroupProperty(com.mathworks.widgets.desk.DTGroupProperty.ACCEPT_DEFAULT_VIEW_TAB, false);
        end
        
        %------------------------------------------------------------------
        function removeQuickAccessBar(self)
            
            % Set the QAB filter property BEFORE opening the UI
            group = self.hToolGroup.Peer.getWrappedComponent;
            filter = com.mathworks.toolbox.images.QuickAccessFilter.getFilter();
            group.putGroupProperty(com.mathworks.widgets.desk.DTGroupProperty.QUICK_ACCESS_TOOL_BAR_FILTER, filter)
        end
        
        %------------------------------------------------------------------
        function disableDragDropOnToolGroup(self)
            
            % Disable drag-drop gestures on ToolGroup.
            group = self.hToolGroup.Peer.getWrappedComponent;
            dropListener = com.mathworks.widgets.desk.DTGroupProperty.IGNORE_ALL_DROPS;
            group.putGroupProperty(com.mathworks.widgets.desk.DTGroupProperty.DROP_LISTENER, dropListener);
        end
        
    end
    
    methods (Static)
        
        function deleteAllTools
            imageslib.internal.apputil.manageToolInstances('deleteAll', 'colorThresholder');
        end
        
        function TF = isValidRGBImage(im)
            
           supportedDataType = isa(im,'uint8') || isa(im,'uint16') || isa(im,'double');
           supportedAttributes = isreal(im) && all(isfinite(im(:))) && ~issparse(im);
           supportedDimensionality = (ndims(im) == 3) && size(im,3) == 3;
           
           TF = supportedDataType && supportedAttributes && supportedDimensionality;
            
        end
                
    end
       
end

%--------------------------------------------------------------------------
% Sets tool tip text for labels, buttons, and other components
%--------------------------------------------------------------------------
function setToolTipText(component, tooltipStr)
component.Peer.setToolTipText(tooltipStr)
end

%--------------------------------------------------------------------------
% Approximates the behavior of uiflowcontainer
%--------------------------------------------------------------------------
function [hPanelTop, hPanelMiddle, hPanelBottom] = createThreePanels(hParent, ratios, margin)

% In order to honor the margin argument, do the computations in Pixel units.
origUnits = get(hParent, 'Units');
set(hParent, 'Units', 'Pixels');
drawnow  % Draw before querying position.

% Compute heights of each panel.
parentPosition = get(hParent, 'Position');
parentHeight = parentPosition(4);

panelHeights = (parentHeight - 4*margin) .* ratios;
panelWidth = parentPosition(3) - 2*margin;

panelPositionBottom = [margin, ...
                       margin, ...
                       panelWidth, ...
                       panelHeights(3)];

panelPositionMiddle = [margin, ...
                       panelPositionBottom(2) + panelPositionBottom(4) + margin, ...
                       panelWidth, ...
                       panelHeights(2)];

panelPositionTop = [margin, ...
                    panelPositionMiddle(2) + panelPositionMiddle(4) + margin, ...
                    panelWidth, ...
                    panelHeights(1)];

hPanelTop = uipanel('parent', hParent, 'Units', 'Pixels', 'Position', panelPositionTop);
hPanelMiddle = uipanel('parent', hParent, 'Units', 'Pixels', 'Position', panelPositionMiddle);
hPanelBottom = uipanel('parent', hParent, 'Units', 'Pixels', 'Position', panelPositionBottom);

set(hParent, 'Units', origUnits);
set([hPanelTop, hPanelMiddle, hPanelBottom], 'Units', 'normalized', 'BorderType', 'line')

end

%--------------------------------------------------------------------------
function triples = samplesUnderMask(img, mask)

triples = zeros([nnz(mask) 3], 'like', img);

for channel=1:3
    theChannel = img(:,:,channel);
    triples(:,channel) = theChannel(mask);
end
end

%--------------------------------------------------------------------------
function hLim = computeHLim(hValues)

% Divide the problem space in half and use some heuristics to decide
% whether there is one region or if it's split around the discontinuity at
% zero.

switch (class(hValues))
    case {'single', 'double'}
        lowerRegion = hValues(hValues < 0.5);
        upperRegion = hValues(hValues >= 0.5);
        
        if isempty(lowerRegion) || isempty(upperRegion)
            bimodal = false;
        elseif (min(lowerRegion) > 0.04) || (max(upperRegion) < 0.96)
            bimodal = false;
        elseif (min(upperRegion) - max(lowerRegion)) > 1/3
            bimodal = true;
        else
            bimodal = false;
        end
        
    case {'uint8'}
        lowerRegion = hValues(hValues < 128);
        upperRegion = hValues(hValues >= 128);
        
        if isempty(lowerRegion) || isempty(upperRegion)
            bimodal = false;
        elseif (min(lowerRegion) > 10) || (max(upperRegion) < 245)
            bimodal = false;
        elseif (min(upperRegion) - max(lowerRegion)) > 255/3
            bimodal = true;
        else
            bimodal = false;
        end
        
    otherwise
end

if (bimodal)
    hLim = [min(upperRegion), max(lowerRegion)];
else
    hLim = [min(hValues), max(hValues)];
end
end
