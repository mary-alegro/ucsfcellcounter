classdef InitMaskTabManager < handle
    %InitMaskTabManager - Initialize Mask Temporary Tab and associated
    %management.
    
    % Copyright 2014, The MathWorks Inc.
    
    properties
        Tab
        CurrentSelection
    end
    
    properties (Access=private)
        GroupName
        SegmentationCore
        ImageData
        GridLayout
        
        %Widgets
        LoadMaskButton
        OtsuCheckBox
        ThresholdSlider
        ThresholdText
        AddFreehandButton
        AddPolygonButton
        GridSizeSlider
        Grid1Text
        Grid2Text
        CancelButton
        AcceptButton
        
        % Listeners
        OtsuCheckBoxListener
        ThresholdSliderListener
        ThresholdTextListener
    end
    
    events
        CloseInitTab
    end
    
    methods
        function self = InitMaskTabManager(tool)
            
            tabName = tool.TabNames.Initialize;
            self.Tab = toolpack.desktop.ToolTab(tabName,...
                getMessageString('initializationTab'));
            
            getImageData(self,tool);
            addTabWidgets(self);
            addTabListeners(self);
            
            tool.InitSegTab = self;
        end
        
        function setDefaultView(self)
            %setDefaultView - set up defaults when tab is opened.
            
            self.CurrentSelection = 'None';
            deleteROITools(self.SegmentationCore);
            clearStatusText(self);
            
            setDefaultOptions(self);
        end
        
        function metadata = getCodeGenMetadata(self)
            switch self.CurrentSelection
                case 'Threshold'
                    metadata.Threshold = self.ThresholdText.Text;
                case 'Grid'
                    metadata.Radius = self.GridSizeSlider.Value;
                    metadata.GridLayout = self.GridLayout;
                otherwise
                    metadata = [];
            end
        end

    end
    
    methods (Access = private)
        function getImageData(self,tool)
            %getImageData - update tab manager with image data from tool.
            
            self.SegmentationCore = tool.SegmentationCore;
            
            % Get size and intensity limits of image.
            imagedata.imSize  = size(tool.SegmentationCore.Im);
            imagedata.minInt  = double(min(tool.SegmentationCore.Im(:)));
            imagedata.maxInt  = double(max(tool.SegmentationCore.Im(:)));
            
            if isinteger(tool.SegmentationCore.Im)
                range = getrangefromclass(tool.SegmentationCore.Im);
            else
                range = [imagedata.minInt imagedata.maxInt];
            end
            
            imagedata.otsuInt = graythresh(tool.SegmentationCore.Im)*(range(2)-range(1))+range(1);
            
            imagedata.otsuInt = max(min(imagedata.otsuInt,imagedata.maxInt),imagedata.minInt);
            
            imagedata.imType  = class(tool.SegmentationCore.Im);
            
            self.ImageData = imagedata;
            
            self.GroupName = tool.GroupName;
        end
        
        function addTabWidgets(self)
            %addTabWidgets - add widgets to temporary tab.
            
            addLoadMaskWidgets(self);
            addThresholdWidgets(self);
            addManualWidgets(self);
            addGridWidgets(self);
            addCloseWidgets(self);
        end
        
        function addLoadMaskWidgets(self)
            
            self.LoadMaskButton = toolpack.component.TSSplitButton(...
                getMessageString('loadMask'),...
                toolpack.component.Icon.IMPORT_24);
            
            self.LoadMaskButton.Orientation = toolpack.component.ButtonOrientation.VERTICAL;
            self.LoadMaskButton.Name        = 'btnLoadMask';
            self.LoadMaskButton.Popup       = toolpack.component.TSDropDownPopup(getLoadOptions(),'icon_text');
            self.LoadMaskButton.Popup.Name  = 'Load Mask Popup';
            
            iptui.internal.utilities.setToolTipText(self.LoadMaskButton,getMessageString('loadMaskTooltip'));
            
            loadPanel = toolpack.component.TSPanel('f:p','f:p');
            add(loadPanel,self.LoadMaskButton,'xy(1,1)');
            
            loadSection = self.Tab.addSection('LoadMask',getMessageString('loadMask'));
            add(loadSection,loadPanel);
            
            function items = getLoadOptions()
                % defining the option entries appearing on the popup of the
                % Load Split Button.
                
                items(1) = struct(...
                    'Title', getMessageString('loadMaskFromFile'), ...
                    'Description', '', ...
                    'Icon', toolpack.component.Icon.IMPORT_16, ...
                    'Help', [], ...
                    'Header', false);
                items(2) = struct(...
                    'Title', getMessageString('loadMaskFromWorkspace'), ...
                    'Description', '', ...
                    'Icon', toolpack.component.Icon.IMPORT_16, ...
                    'Help', [], ...
                    'Header', false);
            end
        end
        
        function addThresholdWidgets(self)
            
            self.OtsuCheckBox = toolpack.component.TSCheckBox(getMessageString('setAutomaticThreshold'),false);
            self.OtsuCheckBox.Name = 'chkboxOtsu';
            
            iptui.internal.utilities.setToolTipText(self.OtsuCheckBox,getMessageString('setAutomaticThresholdTooltip'));
            
            % Create slider component for threshold control.
            minIntensity  = self.ImageData.minInt;
            maxIntensity  = self.ImageData.maxInt;
            
            % Set slider tick spacing and create label table.
            if any(strcmp(self.ImageData.imType,{'uint8','uint16','int16'}))
                self.ThresholdSlider = toolpack.component.TSSlider(minIntensity,maxIntensity,maxIntensity);
                self.ThresholdSlider.MinorTickSpacing = 1;
            else
                % For double data provide 256 ticks for the slider values.
                self.ThresholdSlider = toolpack.component.TSSlider(0,256,256);
                self.ThresholdSlider.MinorTickSpacing = 1;
            end
            self.ThresholdSlider.Name = 'ThresholdSlider';
            iptui.internal.utilities.setToolTipText(self.ThresholdSlider,getMessageString('thresholdSliderTooltip'));
            
            % Create text field to enter slider.
            text = num2str(sliderValueToImageIntensity(self,self.ThresholdSlider.Value));
            self.ThresholdText = toolpack.component.TSTextField(text,5);
            self.ThresholdText.Name = 'ThresholdText';
            iptui.internal.utilities.setToolTipText(self.ThresholdText,getMessageString('thresholdTxtTooltip'));
            
            thresholdPanel = toolpack.component.TSPanel('f:p,50px,10px,f:p','10px,f:p,10px,f:p');
            add(thresholdPanel,self.OtsuCheckBox,'xy(1,2)');
            add(thresholdPanel,self.ThresholdSlider,'xyw(1,4,2)');
            add(thresholdPanel,self.ThresholdText,'xy(4,4)');
            
            thresholdSection = self.Tab.addSection('Threshold',getMessageString('threshold'));
            add(thresholdSection,thresholdPanel);
        end
        
        function addManualWidgets(self)
            
            self.AddFreehandButton = toolpack.component.TSButton(getMessageString('addFreehand'),...
                toolpack.component.Icon(fullfile(matlabroot,'/toolbox/images/icons/Freehand_24px.png')));
            self.AddFreehandButton.Name = 'btnAddFreehand';
            iptui.internal.utilities.setToolTipText(self.AddFreehandButton,getMessageString('addFreehandTooltip'));
            
            self.AddPolygonButton = toolpack.component.TSButton(getMessageString('addPolygon'),toolpack.component.Icon(fullfile(matlabroot,'/toolbox/images/icons/Polygon_24px.png')));
            self.AddPolygonButton.Name = 'btnAddPolygon';
            iptui.internal.utilities.setToolTipText(self.AddPolygonButton,getMessageString('addPolygonTooltip'));
            
            manualPanel = toolpack.component.TSPanel('f:p','f:p,f:p');
            add(manualPanel,self.AddFreehandButton,'xy(1,1)');
            add(manualPanel,self.AddPolygonButton,'xy(1,2)');
            
            manualSection = self.Tab.addSection('Manual',getMessageString('manual'));
            add(manualSection,manualPanel);
            
        end
        
        function addGridWidgets(self)

            sizeLabel  = toolpack.component.TSLabel(getMessageString('radius'));
            gridLabel  = toolpack.component.TSLabel(getMessageString('layout'));
            
            iptui.internal.utilities.setToolTipText(sizeLabel,getMessageString('radiusTooltip'));
            iptui.internal.utilities.setToolTipText(gridLabel,getMessageString('layoutTooltip'));

            % Initialize GridStruct to defaults.
            gridLayout = [4 4];
            
            % Set initial size to half maximum allowable size.
            maxSize = getMaxAllowableSize(self,gridLayout);
            radius = 0;
            
            self.GridLayout = gridLayout;
            
            self.GridSizeSlider = toolpack.component.TSSlider(0,maxSize,radius);
            self.GridSizeSlider.Name = 'sliderRadius';
            self.GridSizeSlider.MajorTickSpacing = 1;
            iptui.internal.utilities.setToolTipText(self.GridSizeSlider,getMessageString('radiusSliderTooltip'));
            
            self.Grid1Text  = toolpack.component.TSTextField(num2str(self.GridLayout(1)),3);
            self.Grid1Text.Name = 'Grid1Text';
            iptui.internal.utilities.setToolTipText(self.Grid1Text,getMessageString('grid1TextTooltip'));
            
            gridXLabel      = toolpack.component.TSLabel(' X ');
            
            self.Grid2Text  = toolpack.component.TSTextField(num2str(self.GridLayout(2)),3);
            self.Grid2Text.Name = 'Grid2Text';
            iptui.internal.utilities.setToolTipText(self.Grid2Text,getMessageString('grid2TextTooltip'));
            
            gridPanel = toolpack.component.TSPanel('f:p,8px,f:p,f:p,f:p,30px,','10px,f:p,10px,f:p');
            
            add(gridPanel,sizeLabel,'xy(1,2)');
            add(gridPanel,self.GridSizeSlider,'xyw(3,2,4)');
            add(gridPanel,gridLabel,'xy(1,4)');
            add(gridPanel,self.Grid1Text,'xy(3,4)');
            add(gridPanel,gridXLabel,'xy(4,4)');
            add(gridPanel,self.Grid2Text,'xy(5,4)');
            
            gridSection = self.Tab.addSection('Grid',getMessageString('grid'));
            add(gridSection,gridPanel);
        end
        
        function addCloseWidgets(self)
            
            self.CancelButton = toolpack.component.TSButton(getMessageString('cancel'),toolpack.component.Icon.CLOSE_24);
            self.CancelButton.Name = 'btnCancelInit';
            self.CancelButton.Orientation = toolpack.component.ButtonOrientation.VERTICAL;
            iptui.internal.utilities.setToolTipText(self.CancelButton,getMessageString('cancelInitTooltip'));
            
            self.AcceptButton = toolpack.component.TSButton(getMessageString('accept'),toolpack.component.Icon.CONFIRM_24);
            self.AcceptButton.Name = 'btnCloseInit';
            self.AcceptButton.Orientation = toolpack.component.ButtonOrientation.VERTICAL;
            iptui.internal.utilities.setToolTipText(self.AcceptButton,getMessageString('acceptInitTooltip'));
            
            closePanel = toolpack.component.TSPanel('f:p,f:p','f:p');
            add(closePanel,self.AcceptButton,'xy(1,1)');
            add(closePanel,self.CancelButton,'xy(2,1)');
            
            closeSection = self.Tab.addSection('Close',getMessageString('close'));
            add(closeSection,closePanel);
        end
        
        function addTabListeners(self)
            %addTabListeners - install listeners to temporary tab.
            
            % Load Mask
            addlistener(self.LoadMaskButton,'ActionPerformed',@(~,~)loadMaskFromFile(self));
            addlistener(self.LoadMaskButton.Popup,'ListItemSelected',@(hobj,~)loadMask(self,hobj.SelectedIndex));
            
            % Threshold
            self.OtsuCheckBoxListener = addlistener(self.OtsuCheckBox,'ItemStateChanged',@(hobj,evt)updateThresholdControlsCheckBox(self,hobj));
            self. ThresholdSliderListener = addlistener(self.ThresholdSlider,'StateChanged',@(hobj,evt)updateThresholdControlsSlider(self,hobj));
            self.ThresholdTextListener = addlistener(self.ThresholdText,'TextEdited',@(hobj,evt)updateThresholdControlsText(self,hobj));
            
            % Manual
            addlistener(self.AddFreehandButton,'ActionPerformed',@(~,~)launchFreehandTool(self));
            addlistener(self.AddPolygonButton,'ActionPerformed',@(~,~)launchPolygonTool(self));
            
            % Grid
            addlistener(self.GridSizeSlider,'StateChanged',@(~,~)updateGridRadius(self));
            addlistener(self.Grid1Text,'TextEdited',@(hobj,~)updateGridLayout(self,hobj));
            addlistener(self.Grid2Text,'TextEdited',@(hobj,~)updateGridLayout(self,hobj));
            
            % Close
            addlistener(self.CancelButton,'ActionPerformed',@(~,~)cancelButtonCallback(self));
            addlistener(self.AcceptButton,'ActionPerformed',@(~,~)acceptButtonCallback(self));
        end
    end
    
    % Callback methods
    methods (Access=private)
        %------------------------------------------------------------------
        % Load
        %------------------------------------------------------------------
        function loadMask(self,index)
            
            if index==1
                loadMaskFromFile(self);
            elseif index==2
                loadMaskFromWorkspace(self);
            end
        end
        
        function loadMaskFromFile(self)
            
            filename = imgetfile();
            
            if ~isempty(filename)
                mask = imread(filename);
                
                isValidMask = islogical(mask) && ismatrix(mask) && all(size(mask)==self.ImageData.imSize);
                if ~isValidMask
                    
                    errDlg = invalidInitialMaskDlg(self);
                    
                    uiwait(errDlg);
                    % Drawnow is necessary so that imgetfile dialog will
                    % enforce modality in next call to imgetfile that
                    % arrises from recursion.
                    drawnow
                    
                    self.loadMaskFromFile();
                    return;
                end
                
                % Delete pending ROI tools and disable add buttons.
                deleteROITools(self.SegmentationCore);
                clearStatusText(self);
                
                %Update tool with new mask.
                initializeMask(self.SegmentationCore,mask);
                
                self.CurrentSelection = 'LoadMaskFromFile';
            end
        end
        
        function loadMaskFromWorkspace(self)
            
            [mask,~,~,~,user_cancelled_dlg] = iptui.internal.imgetvar([],3);
            
            if ~user_cancelled_dlg
                isValidMask = islogical(mask) && ismatrix(mask) && all(size(mask)==self.ImageData.imSize);
                if ~isValidMask
                    errDlg = invalidInitialMaskDlg(self);
                    
                    uiwait(errDlg);
                    
                    self.loadMaskFromWorkspace();
                    return;
                end
                
                % Delete pending ROI tools and disable add buttons.
                deleteROITools(self.SegmentationCore);
                clearStatusText(self);
                
                %Update tool with new mask.
                initializeMask(self.SegmentationCore,mask);
                
                self.CurrentSelection = 'LoadMaskFromWorkspace';
            end
        end
        
        %------------------------------------------------------------------
        % Threshold
        %------------------------------------------------------------------
        function updateThresholdControlsCheckBox(self,hobj)
            
            if hobj.Selected
                % disable listeners for threshold slider and text.
                self.ThresholdSliderListener.Enabled = false;
                self.ThresholdTextListener.Enabled   = false;
                
                % move slider position to otsu level and update text.
                threshold = self.ImageData.otsuInt;
                self.ThresholdSlider.Value = imageIntensityToSliderValue(self,threshold);
                self.ThresholdText.Text = num2str(threshold);
                
                % Delete pending ROI tools and disable add buttons.
                deleteROITools(self.SegmentationCore);
                clearStatusText(self);
                
                % update mask with threshold.
                initializeMaskWithThreshold(self.SegmentationCore,threshold);
                self.CurrentSelection = 'Otsu';
                
                drawnow;
                
                % re-enable listeners for threshold slider and text.
                self.ThresholdSliderListener.Enabled = true;
                self.ThresholdTextListener.Enabled   = true;
            end
           
        end
        
        function updateThresholdControlsSlider(self,~)
            
            % disable listener for threshold text and otsu button.
            self.ThresholdTextListener.Enabled = false;
            self.OtsuCheckBoxListener.Enabled  = false;
            
            % update text.
            sliderval = self.ThresholdSlider.Value;
            threshold = sliderValueToImageIntensity(self,sliderval);
            self.ThresholdText.Text = num2str(threshold);
            
            % un-select otsu button.
            self.OtsuCheckBox.Selected = false;
            
            % Delete pending ROI tools and disable add buttons.
            deleteROITools(self.SegmentationCore);
            clearStatusText(self);
            
            % update mask with threshold.
            initializeMaskWithThreshold(self.SegmentationCore,threshold);
            self.CurrentSelection = 'Threshold';
            
            % re-enable listener for threshold text and otsu button.
            self.ThresholdTextListener.Enabled = true;
            self.OtsuCheckBoxListener.Enabled  = true;
            
        end
        
        function updateThresholdControlsText(self,~)
            
            % disable listener for threshold slider and otsu button.
            self.ThresholdSliderListener.Enabled = false;
            self.OtsuCheckBoxListener.Enabled    = false;
            
            % validate entered string limits.
            threshold = str2double(self.ThresholdText.Text);
            
            % str2double returns a scalar double if a valid string is
            % entered, otherwise it returns a NaN. so we only need to check
            % if data is in the image range. NaN's will evaluate to false
            % in the following statement.
            isValidThreshold = threshold>self.ImageData.minInt && threshold<=self.ImageData.maxInt;
            
            if ~isValidThreshold
                % disable threshold text listener.
                self.ThresholdTextListener.Enabled = false;
                
                % fix text previous value.
                threshold = sliderValueToImageIntensity(self,self.ThresholdSlider.Value);
                self.ThresholdText.Text = num2str(threshold);
                
                % re-enable threshold text listener.
                self.ThresholdTextListener.Enabled = true;
            end
            
            % update threshold slider.
            self.ThresholdSlider.Value = imageIntensityToSliderValue(self,threshold);
            
            % un-select otsu button.
            self.OtsuCheckBox.Selected = false;
            
            % Delete pending ROI tools and disable add buttons.
            deleteROITools(self.SegmentationCore);
            clearStatusText(self);
            
            % update mask with threshold.
            initializeMaskWithThreshold(self.SegmentationCore,threshold);
            self.CurrentSelection = 'Threshold';
            
            % re-enable listener for threshold slider and otsu button.
            self.ThresholdSliderListener.Enabled = true;
            self.OtsuCheckBoxListener.Enabled    = true;
        end
        
        %------------------------------------------------------------------
        % Manual
        %------------------------------------------------------------------
        function launchFreehandTool(self,varargin)
            
            % Clear mask
            initializeMask(self.SegmentationCore);
            
            addFreehandTool(self.SegmentationCore);
            
            self.CurrentSelection = 'Freehand';
            
            iptui.internal.utilities.setStatusBarText(self.GroupName,getMessageString('freehandStatusText'));
        end
                
        function launchPolygonTool(self,varargin)
            
            % Clear mask
            initializeMask(self.SegmentationCore);
            
            addPolygonTool(self.SegmentationCore);
            
            self.CurrentSelection = 'Polygon';
            
            iptui.internal.utilities.setStatusBarText(self.GroupName,getMessageString('polygonStatusText'));
        end
        
        %------------------------------------------------------------------
        % Grid
        %------------------------------------------------------------------
        function updateGridRadius(self)
            
            % Delete pending ROI tools and disable add buttons.
            deleteROITools(self.SegmentationCore);
            clearStatusText(self);
            
            initializeMaskWithGrid(...
                self.SegmentationCore,...
                self.GridLayout(1),...
                self.GridLayout(2),...
                self.GridSizeSlider.Value);
            self.CurrentSelection = 'Grid';
        end
        
        function updateGridLayout(self,hobj)
            
            % Delete pending ROI tools and disable add buttons.
            deleteROITools(self.SegmentationCore);
            clearStatusText(self);
            
            % Find which text field it is.
            switch hobj.Name
                case 'Grid1Text'
                    idx = 1;
                case 'Grid2Text'
                    idx = 2;
            end
            
            % get text.
            val = str2double(hobj.Text);
            
            % validate text and replace if needed.
            isValid = isscalar(val) && isfinite(val) && val>=0 && val==floor(val);
            
            if ~isValid
                % replace with last valid text.
                hobj.Text = num2str(self.GridLayout(idx));
                
            else
                self.GridLayout(idx) = val;
                
                % update max size of slider.
                maxSize = getMaxAllowableSize(self,self.GridLayout);
                
                self.GridSizeSlider.Maximum = maxSize;
                self.GridSizeSlider.Value = maxSize;
                
                initializeMaskWithGrid(...
                    self.SegmentationCore,...
                    self.GridLayout(1),...
                    self.GridLayout(2),...
                    self.GridSizeSlider.Value);
                
            end
            
            self.CurrentSelection = 'Grid';
        end
        
        %------------------------------------------------------------------
        % Close
        %------------------------------------------------------------------
        function cancelButtonCallback(self)
            
            % Delete pending ROI tools
            deleteROITools(self.SegmentationCore);
            clearStatusText(self);
            
            loadCachedInitialMask(self.SegmentationCore);
            
            evtdata = iptui.internal.InitSegTabClosed(false);
            notify(self,'CloseInitTab',evtdata);
        end
        
        function acceptButtonCallback(self)
            
            clearStatusText(self);
            
            if any(strcmpi(self.CurrentSelection,{'Freehand','Polygon'}))
                initializeMaskWithROITools(self.SegmentationCore);
            end
            
            metadata = getCodeGenMetadata(self);
            evtdata = iptui.internal.InitSegTabClosed(true,self.CurrentSelection,metadata);
            notify(self,'CloseInitTab',evtdata);
        end
        
    end
    
    % Utility methods
    methods (Access=private)
        function setDefaultOptions(self)
            
            % Uncheck Otsu checkbox
            self.OtsuCheckBox.Selected = false;
            
            % Set Threshold slider to maximum. This should update text.
            self.ThresholdSlider.Value = self.ThresholdSlider.Maximum;
            
            % Layout at 4x4
            self.Grid1Text.Text = '4';
            self.Grid2Text.Text = '4';
            self.GridLayout = [4 4];
            
            % Radius slider at minimum
            self.GridSizeSlider.Value = self.GridSizeSlider.Minimum;
            self.GridSizeSlider.Maximum = getMaxAllowableSize(self,self.GridLayout);
            
            % Clear mask
            initializeMask(self.SegmentationCore);
        end
        
        function errDlg = invalidInitialMaskDlg(~)
            
            errorString = getMessageString('invalidMaskDlgText');
            dialogName  = getMessageString('invalidMaskDlgTitle');
            createMode  = 'modal';
            errDlg = errordlg(errorString,dialogName,createMode);
        end
        
        function sliderval = imageIntensityToSliderValue(self,intensity)
            if strcmp(self.ImageData.imType,'double')
                sliderval = 256*(intensity-self.ImageData.minInt)/(self.ImageData.maxInt-self.ImageData.minInt);
            else
                sliderval = intensity;
            end
        end
        
        function intensity = sliderValueToImageIntensity(self,sliderval)
            if strcmp(self.ImageData.imType,'double')
                intensity = (self.ImageData.maxInt-self.ImageData.minInt)*sliderval/256 + self.ImageData.minInt;
            else
                intensity = sliderval;
            end
        end
        
        function maxSize = getMaxAllowableSize(self,layout)
            
            maxSize = max(0,floor(.5*min((self.ImageData.imSize) ./ (layout+1))));
        end
        
        function clearStatusText(self)
            
            iptui.internal.utilities.setStatusBarText(self.GroupName,'');
        end
    end
end

function string = getMessageString(identifier,varargin)
if nargin==1
    string = getString(message(sprintf('images:imageSegmenter:%s',identifier)));
elseif nargin>1
    string = getString(message(sprintf('images:imageSegmenter:%s',identifier),varargin{:}));
end
end