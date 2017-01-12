 classdef ImageSegmentationTool < handle
    
    % Copyright 2014-2015, The MathWorks, Inc.
    
    properties
        GroupName
        ToolGroup
        
        % Tabs
        SegmentTab
        InitSegTab
        RefineTab
        
        % Struct with strings containing names for each tab.
        TabNames
        
        % Sections
        LoadImageSection
        InitializeSection
        SegmentImageSection
        RefineSection
        PanZoomSection
        ViewSection
        ExportSection
        
        % Widgets
        LoadImageButton
        
        InitializeButton
        ResetButton
        
        MethodButton
        IterationsText
        SegmentButton
        
        RefineButton
        
        ZoomInButton
        ZoomOutButton
        PanButton
        
        OverlayColorButton
        OpacitySlider
        ShowBinaryButton
        
        ExportButton
        
        % Handles to buttons in toolstrip that are enabled/disabled based
        % on App state.
        ChangeHandles
        
        % Backend handling all computations.
        SegmentationCore
        
        % Cache colormap to use original colormap after exiting ShowBinary
        % mode.
        cmap
        
        % We cache listeners to state changed on buttons so that we can
        % disable/enable button listeners when a new image is loaded and we
        % restore the button states to an initialized state.
        ShowBinaryButtonListener
        OpacitySliderListener
        
        % Cache knowledge of whether we normalized double input data so
        % that we can have thresholds in "generate function" context match
        % image data. Do the same for massaging of image data to handle
        % Nans and Infs appropriately.
        IsDataNormalized
        IsInfNanRemoved
        
        % Flag to notify segment button about intention to stop
        % segmentation.
        ContinueSegmentationFlag
        
        % Flag to cache whether RGB image was loaded into App.
        wasRGB
    end
    
    
    properties(Access = private)
       % Used to react to changes in SegmentationCore object to update
       % graphics appropriately.
        
        UpdateMaskListener
        UpdateIterationListener
        
    end
    
    properties (Access=private)
        % Used to record segment/refine actions performed. This is needed
        % for generating code.
        EventLog
        
        InitSelection
        InitMetadata
    end
    
    %----------------------------------------------------------------------
    % Public Methods
    %----------------------------------------------------------------------
    methods
        function self = ImageSegmentationTool(varargin)
            
            % Each tool instance needs a unique name, use tempname
            [~, name] = fileparts(tempname);
            self.GroupName = name;
            self.ToolGroup = toolpack.desktop.ToolGroup(self.GroupName, getMessageString('appName'));
            
            tabNames.Segment = 'SegmentTab';
            tabNames.Initialize = 'InitializeTab';
            tabNames.Refine = 'RefineTab';
            
            self.TabNames = tabNames;
            
            % Create Segment Tab
            self.SegmentTab = self.ToolGroup.addTab(self.TabNames.Segment,getMessageString('segmentationTab'));
            
            % Remove view tab, quick access bar and document bar
            self.setToolPreferences();
            
            % Initialize Change Handles structure
            self.ChangeHandles = struct('InitializeSegmentationHandles',[],...
                                        'SetupHandles'              ,[],...
                                        'SegmentImageHandles'       ,[],...
                                        'RefineHandles'            ,[],...
                                        'PanAndZoomHandles'         ,[],...
                                        'ViewSegmentationHandles'   ,[],...
                                        'ExportHandles'             ,[]);
                                    
            % Add Sections to Segment Tab
            self.LoadImageSection    = self.SegmentTab.addSection('LoadImage',getMessageString('loadImage'));
            self.InitializeSection   = self.SegmentTab.addSection('Initialize',getMessageString('initialize'));
            self.SegmentImageSection = self.SegmentTab.addSection('SegmentImage',getMessageString('evolve'));
            self.PanZoomSection      = self.SegmentTab.addSection('PanZoom',getMessageString('zoomAndPan'));
            self.ViewSection         = self.SegmentTab.addSection('ViewControls',getMessageString('viewControls'));
            self.RefineSection       = self.SegmentTab.addSection('Refine',getMessageString('refine'));
            self.ExportSection       = self.SegmentTab.addSection('Export',getMessageString('Export'));
            
            % Layout each Section
            self.layoutLoadImageSection();
            self.layoutInitializeSection();
            self.layoutSegmentImageSection();
            self.layoutRefineSection();
            self.layoutPanZoomSection();
            self.layoutViewSection();
            self.layoutExportSection();
            
            setControlsOnConstruction(self);
            
            self.ToolGroup.open            
            
            imageslib.internal.apputil.ScreenUtilities.setInitialToolPosition(self.GroupName);
            imageslib.internal.apputil.manageToolInstances('add', 'imageSegmenter', self);
            
            % Hide Data Browser in Tab
            self.hideDataBrowser();
            
            % Initialize event logger to record segment and refine actions
            % performed
            self.EventLog = iptui.internal.SegmentRefineEventLogger;
            
            % If image data was specified, load it into the app
            if nargin > 0
                im = varargin{1};
                if nargin==2
                    self.wasRGB = varargin{2};
                else
                    self.wasRGB = false;
                end
                self.importImageData(im);
            end
            
            % Listen for changes in Active/Closing figures in the Tool
            % Group.
            addlistener(self.ToolGroup,'ClientAction',@(hobj,evt)clientActionCB(self,hobj,evt));
            
            % We want to destroy the current
            % iptui.internal.ImageSegmentationTool instance if a user
            % interactively closes the toolgroup associated with this
            % instance.
            addlistener(self.ToolGroup, 'GroupAction', ...
                @(~,ed) doClosingSession(self,ed));
        end
        
        function initializeAppWithImage(self,im)
            
            % Initialize segmentation backend with image.
            self.SegmentationCore = iptui.internal.SegmentationBackend(im,self.ChangeHandles);
            
            % Close open modal tabs.
            closeModalTabs(self);
            
            % Build InitSeg tab.
            iptui.internal.InitMaskTabManager(self);
            
            % Create image display
            self.SegmentationCore.hFig = createSegmentationView(self);
            
            % Enable initialize button
            setControlsOnImageLoad(self);
            
            addListenersToBackend(self);
            addListenersToInitSegTab(self);
            
            % Reset segmentation history for code generation
            self.InitSelection = [];
            self.InitMetadata  = [];
            clearEventLog(self.EventLog);
        end
    end
    
    %----------------------------------------------------------------------
    % Layout Methods
    %----------------------------------------------------------------------
    methods (Access = private)
        function layoutLoadImageSection(self)
            
            % Create Panel to hold button in Load Image section.
            loadImagePanel = toolpack.component.TSPanel('f:p','f:p');
            loadImagePanel.Name = 'panelLoadImage';
            self.LoadImageSection.add(loadImagePanel);
            
            % Create and populate Load Image button.
            self.LoadImageButton = toolpack.component.TSSplitButton(getMessageString('loadImageSplitButtonTitle'),toolpack.component.Icon.IMPORT_24);
            
            self.LoadImageButton.Orientation = toolpack.component.ButtonOrientation.VERTICAL;
            self.LoadImageButton.Name        = 'btnLoadImage';
            self.LoadImageButton.Popup       = toolpack.component.TSDropDownPopup(getLoadOptions(),'icon_text');
            self.LoadImageButton.Popup.Name  = 'Load Image Popup';
            
            iptui.internal.utilities.setToolTipText(self.LoadImageButton,getMessageString('loadImageTooltip'));
            
            % Add listener to respond to button press
            addlistener(self.LoadImageButton, 'ActionPerformed', @(hobj,evt) self.loadImageFromFile(hobj,evt));
            
            % Add listener to process load image options
            addlistener(self.LoadImageButton.Popup, 'ListItemSelected', @self.openImageSplitButtonCallback);
            
            % Add Load Image button to Panel.
            loadImagePanel.add(self.LoadImageButton,'xy(1,1)');
            
            
            
            %--------------------------------------------------------------
            function items = getLoadOptions()
                % defining the option entries appearing on the popup of the
                % Load Split Button.
                
                items(1) = struct(...
                    'Title', getMessageString('loadImageFromFile'), ...
                    'Description', '', ...
                    'Icon', toolpack.component.Icon.IMPORT_16, ...
                    'Help', [], ...
                    'Header', false);
                items(2) = struct(...
                    'Title', getMessageString('loadImageFromWorkspace'), ...
                    'Description', '', ...
                    'Icon', toolpack.component.Icon.IMPORT_16, ...
                    'Help', [], ...
                    'Header', false);
            end
            
        end
        
        function layoutInitializeSection(self)
 
            % Create Panel to hold button in Initialize Segmentation section.
            InitializeSegmentationPanel = toolpack.component.TSPanel('f:p,8px,f:p','f:p');
            InitializeSegmentationPanel.Name = 'panelInitializeSegmentation';
            self.InitializeSection.add(InitializeSegmentationPanel);
            
            % Create and populate Initialize Segmentation button.
            self.InitializeButton = toolpack.component.TSButton(...
                getMessageString('initialize'),...
                toolpack.component.Icon(fullfile(matlabroot,'/toolbox/images/icons/Initialize_24px.png')));
            self.InitializeButton.Name = 'btnInitSeg';
            self.InitializeButton.Orientation = toolpack.component.ButtonOrientation.VERTICAL;
            
            addlistener(self.InitializeButton,'ActionPerformed',@(~,~)showInitSegTab(self));
            
            % Create Reset Initialization Button.
            self.ResetButton = toolpack.component.TSButton(...
                getMessageString('resetInitialSegmentation'),toolpack.component.Icon.UNDO_24);
            self.ResetButton.Name = 'btnReset';
            self.ResetButton.Orientation = toolpack.component.ButtonOrientation.VERTICAL;
            
            addlistener(self.ResetButton,'ActionPerformed',@(~,~)self.resetInitialSegmentationCallback());
            
            iptui.internal.utilities.setToolTipText(self.InitializeButton,...
                getMessageString('initializeButtonTooltip'));
            iptui.internal.utilities.setToolTipText(self.ResetButton,...
                getMessageString('resetInitSegButtonTooltip'));
            
            self.ChangeHandles.InitializeSegmentationHandles = {self.InitializeButton,self.ResetButton};
            
            InitializeSegmentationPanel.add(self.InitializeButton,'xy(1,1)');
            InitializeSegmentationPanel.add(self.ResetButton,'xy(3,1)');
        end
        
        function layoutSegmentImageSection(self)
            
            % Create Panel for Segment Button.
            segmentImagePanel = toolpack.component.TSPanel(...
                '7px,f:p,8px,f:p,8px,f:p,7px',...
                '10px,f:p:g,10px,f:p:g,10px');
            segmentImagePanel.Name = 'panelSegmentImage';
            self.SegmentImageSection.add(segmentImagePanel);
            
            % Create labels for number of iterations and segmentation
            % method.
            iterationsLabel  = toolpack.component.TSLabel(getMessageString('iterations'));
            algLabel         = toolpack.component.TSLabel(getMessageString('method'));
            
            iptui.internal.utilities.setToolTipText(iterationsLabel,getMessageString('iterationsTooltip'));
            iptui.internal.utilities.setToolTipText(algLabel,getMessageString('algTooltip'));
            
            setupHandles{1} = iterationsLabel;
            setupHandles{end+1} = algLabel;
            
            % Create dropdown for algorithm choices.
            self.MethodButton = toolpack.component.TSDropDownButton(...
                getMessageString('chanVese'));
            self.MethodButton.Name = 'btnMethod';
            
            algList(1) = struct(...
                'Title',getMessageString('chanVeseTitle'),...
                'Icon',[],...
                'Description',getMessageString('chanVeseDescription'),...
                'Header',false);
            algList(2) = struct(...
                'Title',getMessageString('edgeTitle'),...
                'Icon',[],...
                'Description',getMessageString('edgeDescription'),...
                'Header',false);
            
            popup = toolpack.component.TSDropDownPopup(algList,'icon_text_description');
            self.MethodButton.Popup = popup;
            self.MethodButton.Popup.Name = 'popupMethodList';
            iptui.internal.utilities.setToolTipText(popup,getMessageString('methodTooltip'));
            
            % Add listener to process algorithm options
            addlistener(self.MethodButton.Popup, 'ListItemSelected', @(src,~)updateAlgorithmSelection(self,src));
            
            setupHandles{end+1} = self.MethodButton;
            
            iptui.internal.utilities.setToolTipText(self.MethodButton,getMessageString('methodTooltip'));
            
            % Create text fields.
            self.IterationsText = toolpack.component.TSTextField('100',4);
            self.IterationsText.Name = 'txtIterations';
            addlistener(self.IterationsText,'TextEdited',@(~,evt)self.updateIterationsCallback(evt));
            
            iptui.internal.utilities.setToolTipText(self.IterationsText,getMessageString('iterationsTooltip'));
            
            setupHandles{end+1} = self.IterationsText;
            self.ChangeHandles.SetupHandles = setupHandles;
            
            % Create Segment Button.
            self.SegmentButton = toolpack.component.TSButton(getMessageString('evolve'),toolpack.component.Icon.RUN_24);
            self.SegmentButton.Name = 'btnSegment';
            self.SegmentButton.Orientation   = toolpack.component.ButtonOrientation.VERTICAL;
            
            iptui.internal.utilities.setToolTipText(self.SegmentButton,getMessageString('evolveSegmentationTooltip'));
            
            addlistener(self.SegmentButton,'ActionPerformed',@(~,~)self.segmentButtonCallback());
            addlistener(self.SegmentButton,'ActionPerformed',@(~,~)self.updateSegmentState());
            
            self.ChangeHandles.SegmentImageHandles = {self.SegmentButton};
            
            % Layout all widgets in Panel.
            segmentImagePanel.add(iterationsLabel,'xy(2,2)');
            segmentImagePanel.add(self.IterationsText,'xy(4,2)');
            segmentImagePanel.add(algLabel,'xy(2,4)');
            segmentImagePanel.add(self.MethodButton,'xy(4,4)');
            segmentImagePanel.add(self.SegmentButton,'xywh(6,1,1,5)');
        end

        function layoutRefineSection(self)
            
            % Create Panel to hold button in Refine section.
            RefinePanel = toolpack.component.TSPanel('f:p','f:p');
            RefinePanel.Name = 'panelRefine';
            self.RefineSection.add(RefinePanel);
            
            % Create and populate Refine button.
            RefineIcon = toolpack.component.Icon(fullfile(matlabroot,'/toolbox/images/icons/Refine_24px.png'));
            self.RefineButton = toolpack.component.TSButton(...
                getMessageString('refine'),RefineIcon);
            
            self.RefineButton.Orientation    = toolpack.component.ButtonOrientation.VERTICAL;
            self.RefineButton.Name           = 'btnRefine';
            
            addlistener(self.RefineButton,'ActionPerformed',@(~,~)showRefineTab(self));

            self.ChangeHandles.RefineHandles = {self.RefineButton};
            
            iptui.internal.utilities.setToolTipText(self.RefineButton,...
                getMessageString('refineSegmentationTooltip'));
            
             % Add Refine button to Panel.
            RefinePanel.add(self.RefineButton,'xy(1,1)');
        end
        
        function layoutPanZoomSection(self)    
            
            zoomPanPanel = toolpack.component.TSPanel( ...
                'f:p', ...              % columns
                'f:p:g,f:p:g,f:p:g');   % rows
            
            zoomPanPanel.Name = 'panelZoomPan';
            
            self.PanZoomSection.add(zoomPanPanel);
            
            self.ZoomInButton = toolpack.component.TSToggleButton(getString(message('images:commonUIString:zoomInTooltip')),...
                toolpack.component.Icon.ZOOM_IN_16);
            addlistener(self.ZoomInButton, 'ItemStateChanged', @(hobj,evt) self.zoomIn(hobj,evt) );
            self.ZoomInButton.Orientation = toolpack.component.ButtonOrientation.HORIZONTAL;
            panZoomHandles{1} = self.ZoomInButton;
            iptui.internal.utilities.setToolTipText(self.ZoomInButton,getString(message('images:commonUIString:zoomInTooltip')));
            self.ZoomInButton.Name = 'btnZoomIn';
            
            self.ZoomOutButton = toolpack.component.TSToggleButton(getString(message('images:commonUIString:zoomOutTooltip')),...
                toolpack.component.Icon.ZOOM_OUT_16);
            addlistener(self.ZoomOutButton, 'ItemStateChanged', @(hobj,evt) self.zoomOut(hobj,evt) );
            self.ZoomOutButton.Orientation = toolpack.component.ButtonOrientation.HORIZONTAL;
            panZoomHandles{end+1} = self.ZoomOutButton;
            iptui.internal.utilities.setToolTipText(self.ZoomOutButton,getString(message('images:commonUIString:zoomOutTooltip')));
            self.ZoomOutButton.Name = 'btnZoomOut';
            
            self.PanButton = toolpack.component.TSToggleButton(getMessageString('pan'),...
                toolpack.component.Icon.PAN_16 );
            addlistener(self.PanButton, 'ItemStateChanged', @(hobj,evt) self.panImage(hobj,evt) );
            self.PanButton.Orientation = toolpack.component.ButtonOrientation.HORIZONTAL;
            panZoomHandles{end+1} = self.PanButton;
            iptui.internal.utilities.setToolTipText(self.PanButton,getMessageString('pan'));
            self.PanButton.Name = 'btnPan';
            
            self.ChangeHandles.PanAndZoomHandles = panZoomHandles;
            
            zoomPanPanel.add(self.ZoomInButton, 'xy(1,1)' );
            zoomPanPanel.add(self.ZoomOutButton,'xy(1,2)' );
            zoomPanPanel.add(self.PanButton,'xy(1,3)' );
            
        end
        
        function layoutViewSection(self)

            viewSegmentationPanel = toolpack.component.TSPanel( ...
                'f:p,15px,f:p', ...    % columns
                'f:p:g');              % rows

            self.ViewSection.add(viewSegmentationPanel);
            viewSegmentationPanel.Name = 'panelViewSegmentation';

            % Show Binary Button
            ShowBinaryIcon = toolpack.component.Icon(...
                fullfile(matlabroot,'/toolbox/images/icons/ShowBinary_24px.png'));
            self.ShowBinaryButton = toolpack.component.TSToggleButton(...
                getMessageString('showBinary'),...
                ShowBinaryIcon);
            self.ShowBinaryButton.Name = 'btnShowBinary';
            self.ShowBinaryButton.Orientation = toolpack.component.ButtonOrientation.VERTICAL;
            
            self.ShowBinaryButtonListener = addlistener(self.ShowBinaryButton, 'ItemStateChanged', @(hobj,evt) showBinaryPress(self,hobj,evt) );
            
            viewSegmentationHandles = {self.ShowBinaryButton};

            iptui.internal.utilities.setToolTipText(self.ShowBinaryButton,getMessageString('viewBinaryTooltip'));

            % Foreground Opacity Slider
            self.OpacitySlider = toolpack.component.TSSlider(0,100,60);
            self.OpacitySlider.MinorTickSpacing = 0.1;
            self.OpacitySlider.Name = 'sliderMaskOpacity';
            
            self.OpacitySliderListener = addlistener(self.OpacitySlider,'StateChanged',@(hobj,evt) opacitySliderMoved(self,hobj,evt) );
            
            viewSegmentationHandles{end+1} = self.OpacitySlider;
            
            iptui.internal.utilities.setToolTipText(self.OpacitySlider,getMessageString('sliderTooltip'));

            % Foreground Color and Opacity Labels
            overlayColorLabel   = toolpack.component.TSLabel(getMessageString('foregroundColor'));
            overlayColorLabel.Name = 'labelOverlayColor';
            iptui.internal.utilities.setToolTipText(overlayColorLabel,getMessageString('foregroundColor'));
            
            overlayOpacityLabel = toolpack.component.TSLabel(getMessageString('foregroundOpacity'));
            overlayOpacityLabel.Name = 'labelOverlayOpacity';
            iptui.internal.utilities.setToolTipText(overlayOpacityLabel,getMessageString('foregroundOpacity'));

            viewSegmentationHandles{end+1} = overlayColorLabel;
            viewSegmentationHandles{end+1} = overlayOpacityLabel;

            % Foreground Color Button
            % There is no MCOS interface to set the icon of a TSButton
            % directly from a uint8 buffer.
            self.OverlayColorButton = toolpack.component.TSButton();
            self.OverlayColorButton.Name = 'btnOverlayColor';

            % Set default color to green.
            iconImage = cat(3,zeros(16,16,'uint8'),255*ones(16,16,'uint8'),zeros(16,16,'uint8'));
            self.setTSButtonIconFromImage(self.OverlayColorButton,iconImage);
            
            addlistener(self.OverlayColorButton,'ActionPerformed',@(hobj,evt) self.chooseOverlayColor(hobj,evt) );
            
            viewSegmentationHandles{end+1} = self.OverlayColorButton;
            
            iptui.internal.utilities.setToolTipText(self.OverlayColorButton,getMessageString('foregroundColorTooltip'));
            
            % Panel to hold foreground color and opacity controls.
            foregroundPanel = toolpack.component.TSPanel('10px,left:pref,40dlu,f:p,f:p','f:p,f:p');
            foregroundPanel.add(overlayColorLabel,'xy(2,1)');
            foregroundPanel.add(self.OverlayColorButton,'xy(3,1,''l,c'')');
            foregroundPanel.add(overlayOpacityLabel,'xy(2,2)');
            foregroundPanel.add(self.OpacitySlider,'xywh(3,2,2,1)');

            addTitledBorderToPanel(self,foregroundPanel,getMessageString('foregroundPanelTitle'));
            
            viewSegmentationHandles{end+1} = foregroundPanel;

            self.ChangeHandles.ViewSegmentationHandles = viewSegmentationHandles;

            viewSegmentationPanel.add(foregroundPanel,'xy(1,1)');
            viewSegmentationPanel.add(self.ShowBinaryButton,'xy(3,1)');

        end
        
        function layoutExportSection(self)
            
            exportPanel = toolpack.component.TSPanel('f:p','f:p');
            self.ExportSection.add(exportPanel);
            exportPanel.Name = 'panelExport';
            
            createMaskIcon = toolpack.component.Icon(...
                fullfile(matlabroot,'/toolbox/images/icons/CreateMask_24px.png'));
            
            self.ExportButton = toolpack.component.TSSplitButton(getMessageString('Export'), ...
                createMaskIcon);
            self.ExportButton.Orientation = toolpack.component.ButtonOrientation.VERTICAL;
            self.ExportButton.Name = 'btnExport';
            iptui.internal.utilities.setToolTipText(self.ExportButton,getMessageString('exportButtonTooltip'));
            
            addlistener(self.ExportButton, 'ActionPerformed', @(~,~)exportDataToWorkspace(self));

            % This style tells TSDropDownPopup to show just text and the
            % icon. We could also use 'text_only'.
            style = 'icon_text';
            
            self.ExportButton.Popup = toolpack.component.TSDropDownPopup(...
                getExportOptions(), style);
            self.ExportButton.Popup.Name = 'Export Popup';            
            
            % Add listener for processing load image options
            addlistener(self.ExportButton.Popup, 'ListItemSelected',...
                @self.exportSplitButtonCallback);
            
            self.ChangeHandles.ExportHandles = {self.ExportButton};
            
            exportPanel.add(self.ExportButton, 'xy(1,1)' );
            
            
            %--------------------------------------------------------------
            function items = getExportOptions(~)
                % defining the option entries appearing on the popup of the
                % Export Split Button.
                
                exportDataIcon = toolpack.component.Icon(...
                    fullfile(matlabroot,'/toolbox/images/icons/CreateMask_16px.png'));
                
                exportFunctionIcon = toolpack.component.Icon(...
                    fullfile(matlabroot,'/toolbox/images/icons/GenerateMATLABScript_Icon_16px.png'));
                
                items(1) = struct(...
                    'Title', getMessageString('exportImages'), ...
                    'Description', '', ...
                    'Icon', exportDataIcon, ...
                    'Help', [], ...
                    'Header', false);
                                
                items(2) = struct(...
                    'Title', getMessageString('exportFunction'), ...
                    'Description', '', ...
                    'Icon', exportFunctionIcon, ...
                    'Help', [], ...
                    'Header', false);
            end
            
        end
    end
    
    %----------------------------------------------------------------------
    % Callback Methods
    %----------------------------------------------------------------------
    methods (Access = private)
        %------------------------------------------------------------------
        % Load image section
        %------------------------------------------------------------------
        function openImageSplitButtonCallback(self,src,~)
            
            % from save options popup
            if src.SelectedIndex == 1         % Open Image From File
                self.loadImageFromFile();
            elseif src.SelectedIndex == 2     % Load Image From Workspace
                self.loadImageFromWorkspace();
            end
        end
        
        function loadImageFromFile(self,varargin)
            
            % Reset status bar text.
            iptui.internal.utilities.setStatusBarText(self.GroupName,'');
            
            user_cancelled_import = self.showImportingDataWillCauseDataLossDlg();
            if ~user_cancelled_import
                
                filename = imgetfile();
                if ~isempty(filename)
                    im = imread(filename);
                    
                    isValidType = iptui.internal.ImageSegmentationTool.isValidImageType(im);
                    self.wasRGB  = ndims(im)==3 && size(im,3)==3;
                    isValidDim  = ismatrix(im);
                    
                    if ~isValidType || (~self.wasRGB && ~isValidDim)
                        %error
                        errdlg = errordlg(getMessageString('nonGrayErrorDlgMessage'),getMessageString('nonGrayErrorDlgTitle'),'modal');
                        % We need the error dialog to be blocking, otherwise
                        % loadImageFromFile() is invoked before the dialog finishes
                        % setting itself up and becomes modal.
                        uiwait(errdlg);
                        % Drawnow is necessary so that imgetfile dialog will
                        % enforce modality in next call to imgetfile that
                        % arrises from recursion.
                        drawnow
                        self.loadImageFromFile();
                        return;
                        
                    elseif isValidType && self.wasRGB
                        %warning
                        wrndlg = warndlg(getMessageString('convertToGray'),getMessageString('convertToGrayDlgTitle'),'modal');
                        uiwait(wrndlg);
                        im = rgb2gray(im);
                        self.importImageData(im);
                    elseif isValidType && isValidDim
                        self.importImageData(im);
                    else
                        assert(false,'Internal error: Invalid image');
                    end
                else %No file was selected and imgetfile returned an empty string. User hit Cancel.
                    setControlsOnConstruction(self);
                end
            end
        end
        
        function loadImageFromWorkspace(self,varargin)
            
            % Reset status bar text.
            iptui.internal.utilities.setStatusBarText(self.GroupName,'');
            
            user_canceled_import = self.showImportingDataWillCauseDataLossDlg();
            if ~user_canceled_import
                 
                [im,~,~,~,user_canceled_dlg] = iptui.internal.imgetvar([],2);
                if ~user_canceled_dlg
                    % While loading from workspace, image has to be
                    % grayscale.
                    self.wasRGB = false;
                    self.importImageData(im);
                else%No variable was selected and imgetvar returned an empty string. User hit Cancel.
                    setControlsOnConstruction(self);
                end
                
            end
            
        end
        
        function user_canceled = showImportingDataWillCauseDataLossDlg(self)
            
            user_canceled = false;
            
            if self.ToolGroup.isClientShowing('Segmentation')
                buttonName = questdlg(getMessageString('loadingNewImageMessage'),...
                    getMessageString('loadingNewImageTitle'),...
                    getString(message('images:commonUIString:yes')),...
                    getString(message('images:commonUIString:cancel')),...
                    getString(message('images:commonUIString:cancel')));
                
                if strcmp(buttonName,getString(message('images:commonUIString:yes')))
                    
                    validFigHandles = ishandle(self.SegmentationCore.hFig);
                    close(self.SegmentationCore.hFig(validFigHandles));
                    self.SegmentationCore.hFig = [];
                else
                    user_canceled = true;
                end
            end
        end
        
        %------------------------------------------------------------------
        % Initialize mask section
        %------------------------------------------------------------------
        function showInitSegTab(self)
            
            % Reset status bar text.
            iptui.internal.utilities.setStatusBarText(self.GroupName,'');
            
            existingTabs = self.ToolGroup.TabNames;
            
            if ~any(strcmp(existingTabs,self.TabNames.Initialize))
                
                % If InitSeg tab is not in the toolgroup, add it.
                add(self.ToolGroup,self.InitSegTab.Tab,2);
                
                % Remove Refine tab.
                if any(strcmp(existingTabs,self.TabNames.Refine))
                    remove(self.ToolGroup,self.RefineTab.Tab);
                end
                
                % Disable segment,Refine controls till mask initialization
                % is complete.
                setControlsDuringMaskInit(self);
                
                % Move focus to InitSeg Tab.
                self.ToolGroup.SelectedTab = self.TabNames.Initialize;
                
                % Update previous mask.
                cacheInitialMask(self.SegmentationCore);
                
                setDefaultView(self.InitSegTab);
            else
                % If InitSeg tab is in the toolgroup, move focus to it and
                % leave this function.
                self.ToolGroup.SelectedTab = self.TabNames.Initialize;
                return;
            end
            
        end
        
        function closeInitSegTab(self,evt)
            
            % Remove Tab
            removeTab(self.ToolGroup,self.TabNames.Initialize);
            
            cacheInitialMask(self.SegmentationCore);
            
            % Log initialization selection and metadata
            if evt.AcceptPressed
                self.InitSelection = evt.Selection;
                self.InitMetadata  = evt.Metadata;
            end
            
            % Clear history of segmentation states for code generation.
            clearEventLog(self.EventLog);
            
            % Update controls
            if isMaskEmpty(self.SegmentationCore)
                
                setControlsOnImageLoad(self);
                
                iptui.internal.utilities.setStatusBarText(self.GroupName, getMessageString('emptyMaskStatusText'));
            else
                
                setControlsOnMaskInit(self);
                
            end
        end
        
        function resetInitialSegmentationCallback(self)
            
            % Reset status bar text.
            iptui.internal.utilities.setStatusBarText(self.GroupName,'');
            
            % Reset Mask.
            loadCachedInitialMask(self.SegmentationCore);
            
            % Clear history of segmentation states for code generation.
            clearEventLog(self.EventLog);
            
            setControlsOnMaskInit(self);
        end
        
        %------------------------------------------------------------------
        % Setup section
        %------------------------------------------------------------------
        function updateAlgorithmSelection(self,src)
            
            % Reset status bar text.
            iptui.internal.utilities.setStatusBarText(self.GroupName,'');
            
            switch src.SelectedIndex
                case 1
                    self.SegmentationCore.Algorithm = 'Chan-Vese';
                    self.MethodButton.Text = getMessageString('chanVese');
                case 2
                    self.SegmentationCore.Algorithm = 'edge';
                    self.MethodButton.Text = getMessageString('edge');
            end
        end
        
        function updateIterationsCallback(self,textfield)
            
            % Reset status bar text.
            iptui.internal.utilities.setStatusBarText(self.GroupName,'');
            
            nIter = str2double(textfield.Source.Text);
            
            % validate entered string
            isValid = isscalar(nIter) && isfinite(nIter) && nIter>0 && nIter==floor(nIter);
            
            if ~isValid
                % Reset to previous value.
                nIter = self.SegmentationCore.Iterations;
                self.IterationsText.Text = num2str(nIter);
            else
                self.SegmentationCore.Iterations = nIter;
            end
            
            
        end
                
        %------------------------------------------------------------------
        % Segment section
        %------------------------------------------------------------------
        function segmentButtonCallback(self)
            
            % Set flag to notify segmentation state.
            self.ContinueSegmentationFlag = true;
                        
            % Update controls during evolution.
            setControlsDuringSegment(self);
            
            try
                runSegmentationAlgorithm(self.SegmentationCore);
                updateSegmentButtonIcon(self,'segment');
                addSegmentEvent(self.EventLog,self.SegmentationCore.Algorithm,self.SegmentationCore.Iterations);
                setControlsOnSegment(self);
            catch ME
                if strcmp(ME.identifier,'images:SegmentationBackend:emptyMask')
                    updateSegmentButtonIcon(self,'segment');
                    iptui.internal.invalidSegmentationDialog();
                    setControlsToEmptyMask(self);
                elseif strcmp(ME.identifier,'MATLAB:class:InvalidHandle')
                    % Deleting the app while it is running will cause self
                    % to become an invalid handle. Do nothing, the app is
                    % already being destroyed.
                else
                    rethrow(ME)
                end
            end
                                
        end
        
        function updateSegmentState(self)
            self.ContinueSegmentationFlag = ~self.ContinueSegmentationFlag;
            if ~self.ContinueSegmentationFlag
                stopSegmentationAlgorithm(self.SegmentationCore);
            end
            
        end
        
        %------------------------------------------------------------------
        % Refine section
        %------------------------------------------------------------------
        function showRefineTab(self)
            
            % Reset status bar text.
            iptui.internal.utilities.setStatusBarText(self.GroupName,'');
            
            existingTabs = self.ToolGroup.TabNames;
            
            if ~any(strcmp(existingTabs,self.TabNames.Refine))
                
                % If Refine tab is not in the toolgroup, initialize
                % cleanup, update tab manager and add it.
                % Initialize cleanup option and update tab manager.
                initCleanup(self.SegmentationCore);
                iptui.internal.RefineTabManager(self);
                addListenersToRefineTab(self);
                
                add(self.ToolGroup,self.RefineTab.Tab,2);
                
                % Remove InitSeg tab.
                if any(strcmp(existingTabs,self.TabNames.Initialize))
                    remove(self.ToolGroup,self.InitSegTab.Tab);
                end
                
                setControlsDuringRefine(self);
                
                % Move focus to Refine tab.
                self.ToolGroup.SelectedTab = self.TabNames.Refine;
                
            else
                % If Refine tab is in the toolgroup, move focus to it and
                % leave this function.
                self.ToolGroup.SelectedTab = self.TabNames.Refine;
            end
        end
        
        function closeRefineTab(self,evt)
            
            % Remove Tab
            removeTab(self.ToolGroup,self.TabNames.Refine);
            
            % Update controls
            if isMaskEmpty(self.SegmentationCore)
                
                setControlsToEmptyMask(self);
                
                iptui.internal.utilities.setStatusBarText(self.GroupName, getMessageString('emptyRefineStatusText'));
            else
                setControlsOnRefine(self);
            end
            
            % Update event logger
            if evt.AcceptPressed
                addRefineEvent(self.EventLog,evt.ClearBorder,evt.FillHoles,evt.MinSize,evt.MaxSize,evt.MinFilter,evt.MaxFilter);
            end
        end
        
        %------------------------------------------------------------------
        % View section
        %------------------------------------------------------------------
        function showBinaryPress(self,hobj,~)
            
            hIm = findobj(self.SegmentationCore.hScrollpanel,'type','image');
            if hobj.Selected
                % Set colormap of figure to gray(2).
                set(self.SegmentationCore.hFig,'Colormap',gray(2));
                
                set(hIm,'AlphaData',1);
                self.updateMaskOverlayGraphics();
                self.OpacitySlider.Enabled = false;
                self.OverlayColorButton.Enabled = false;
            else
                % Set colormap back to original map.
                set(self.SegmentationCore.hFig,'Colormap',self.cmap);
                
                set(hIm,'CData',self.SegmentationCore.Im);
                self.updateMaskOverlayGraphics();
                self.OpacitySlider.Enabled = true;
                self.OverlayColorButton.Enabled = true;
            end
            
        end
        
        function chooseOverlayColor(self,TSButtonObj,~)
            
            if isempty(self.SegmentationCore.ForegroundColor)
                prevColor = [0 1 0]; %Default color (green)
            else
                prevColor = self.SegmentationCore.ForegroundColor;
            end
                            
            rgbColor = uisetcolor(prevColor,getMessageString('selectForegroundColor'));
            
            self.SegmentationCore.ForegroundColor = rgbColor;
            
            colorSelectionCanceled = isequal(rgbColor, 0);
            if ~colorSelectionCanceled
                iconImage = zeros(16,16,3);
                iconImage(:,:,1) = rgbColor(1);
                iconImage(:,:,2) = rgbColor(2);
                iconImage(:,:,3) = rgbColor(3);
                iconImage = im2uint8(iconImage);
                
                self.setTSButtonIconFromImage(TSButtonObj,iconImage);
                
                % Set imscrollpanel axes color to apply chosen overlay color.
                set(findobj(self.SegmentationCore.hScrollpanel,'type','axes'),'Color',rgbColor);
                
            end
            
        end
        
        function opacitySliderMoved(self,varargin)
            
            self.SegmentationCore.ForegroundOpacity = self.OpacitySlider.Value;
            self.updateMaskOverlayGraphics();
        end
        
        %------------------------------------------------------------------
        % Pan-zoom section
        %------------------------------------------------------------------
        function zoomIn(self,hToggle,~)
            
            hIm = findobj(self.SegmentationCore.hScrollpanel,'type','image');
            if hToggle.Selected
                self.ZoomOutButton.Selected = false;
                self.PanButton.Selected = false;
                warnstate = warning('off','images:imuitoolsgate:undocumentedFunction');
                zoomInFcn = imuitoolsgate('FunctionHandle', 'imzoomin');
                warning(warnstate);
                set(hIm,'ButtonDownFcn',zoomInFcn);
                glassPlus = setptr('glassplus');
                iptSetPointerBehavior(hIm,@(hFig,~) set(hFig,glassPlus{:}));
            else
                if ~(self.ZoomOutButton.Selected || self.PanButton.Selected)
                    set(hIm,'ButtonDownFcn','');
                    iptSetPointerBehavior(hIm,[]);
                end
            end
            
        end
        
        function zoomOut(self,hToggle,~)
            
            hIm = findobj(self.SegmentationCore.hScrollpanel,'type','image');
            if hToggle.Selected
                self.ZoomInButton.Selected = false;
                self.PanButton.Selected    = false;
                warnstate = warning('off','images:imuitoolsgate:undocumentedFunction');
                zoomOutFcn = imuitoolsgate('FunctionHandle', 'imzoomout');
                warning(warnstate);
                set(hIm,'ButtonDownFcn',zoomOutFcn);
                glassMinus = setptr('glassminus');
                iptSetPointerBehavior(hIm,@(hFig,~) set(hFig,glassMinus{:}));
            else
                if ~(self.ZoomInButton.Selected || self.PanButton.Selected)
                    set(hIm,'ButtonDownFcn','');
                    iptSetPointerBehavior(hIm,[]);
                end
            end
            
        end
        
        function panImage(self,hToggle,~)
            
            hIm = findobj(self.SegmentationCore.hScrollpanel,'type','image');
            if hToggle.Selected
                self.ZoomOutButton.Selected = false;
                self.ZoomInButton.Selected = false;
                warnstate = warning('off','images:imuitoolsgate:undocumentedFunction');
                panFcn = imuitoolsgate('FunctionHandle', 'impan');
                warning(warnstate);
                set(hIm,'ButtonDownFcn',panFcn);
                handCursor = setptr('hand');
                iptSetPointerBehavior(hIm,@(hFig,~) set(hFig,handCursor{:}));
            else
                if ~(self.ZoomInButton.Selected || self.ZoomOutButton.Selected)
                    set(hIm,'ButtonDownFcn','');
                    iptSetPointerBehavior(hIm,[]);
                    
                end
            end
            
        end
        
        %------------------------------------------------------------------
        % Export section
        %------------------------------------------------------------------
        function exportSplitButtonCallback(self, src, ~)
            
            if src.SelectedIndex == 1 
                self.exportDataToWorkspace();
            elseif src.SelectedIndex == 2
                self.generateCode();
            end

        end
                
        function exportDataToWorkspace(self)
            
            % Reset status bar text.
            iptui.internal.utilities.setStatusBarText(self.GroupName,'');
            
            maskedImage = self.SegmentationCore.Im;
            
            % Set background pixels where BW is false to zero.
            maskedImage(~self.SegmentationCore.Mask)=0;
            
            export2wsdlg({getMessageString('initialSegmentation'),...
                getMessageString('finalSegmentation'),...
                getMessageString('maskedImage')},...
                {'mask','BW','maskedImage'},...
                {self.SegmentationCore.InitialMask,self.SegmentationCore.Mask,maskedImage});
            
        end
        
        function generateCode(self)
            
            % Reset status bar text.
            iptui.internal.utilities.setStatusBarText(self.GroupName,'');
            
            codeGenerator = iptui.internal.CodeGenerator();
            
            addFunctionDeclaration(self,codeGenerator);
            codeGenerator.addReturn();
            
            codeGenerator.addHeader('imageSegmenter');
            
            addImageLoadingCode(self,codeGenerator);
            
            addInitializationCode(self,codeGenerator);
            
            addSegmentRefineCode(self,codeGenerator);
            
            addMaskedImageCode(self,codeGenerator);
            
            % End function
            codeGenerator.addLine('end');
            
            % Terminate the file with carriage return
            codeGenerator.addReturn();
            
            % Output the generated code to the MATLAB editor
            %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
            codeGenerator.putCodeInEditor();
        end
        
        %------------------------------------------------------------------
        % Client Handling
        %------------------------------------------------------------------
        function clientActionCB(self,~,event)
            
            % If the figure is closed, restore app to initial state.
            if strcmpi(event.EventData.EventType,'CLOSED')
                appDeleted = ~isvalid(self) || ~isvalid(self.ToolGroup);
                if ~appDeleted
                    if ~self.ToolGroup.isClientShowing('Segmentation')
                        setControlsOnConstruction(self);
                    end
                end
                
            end
        end
        
        function doClosingSession(self, event)
            if strcmp(event.EventData.EventType, 'CLOSING')                
                imageslib.internal.apputil.manageToolInstances('remove', 'imageSegmenter', self);
                delete(self);                     
            end
        end
        
    end
    
    %----------------------------------------------------------------------
    % Figure Display Methods
    %----------------------------------------------------------------------
    methods (Access = private)
        
        function hFig = createSegmentationView(self)
            
            hFig = figure(...
                'NumberTitle', 'off',...
                'Name', 'Segmentation',...
                'Colormap', gray(2),...
                'IntegerHandle', 'off');
            
            % Set the WindowKeyPressFcn to a non-empty function. This is
            % effectively a no-op that executes everytime a key is pressed
            % when the App is in focus. This is done to prevent focus from
            % shifting to the MATLAB command window when a key is typed.
            hFig.WindowKeyPressFcn = @(~,~)[];
            
            self.ToolGroup.addFigure(hFig);
            
            % Unregister image in drag and drop gestures when figures are
            % docked in toolgroup.
            self.ToolGroup.getFiguresDropTargetHandler.unregisterInterest(hFig);
            
            iptPointerManager(hFig);
            
            imPanel = uipanel(...
                'Parent',hFig,...
                'Position',[0 0 1 1],...
                'BorderType','none',...
                'tag','ImagePanel');
            
            layoutScrollpanel(self,imPanel);
            
            % Cache colormap for update after 'ShowBinary'
            self.cmap = get(hFig,'Colormap');
            
            % Prevent MATLAB graphics from being drawn in figures docked
            % within App.
            set(hFig,'HandleVisibility','callback');
            
        end
        
        function layoutScrollpanel(self,imPanel)
            
            if isempty(self.SegmentationCore.hScrollpanel) || ~ishandle(self.SegmentationCore.hScrollpanel)
                
                hAx   = axes('Parent',imPanel);
                
                % Figure will be docked before imshow is invoked. We want
                % to avoid warning about fit mag in context of a docked
                % figure.
                warnState = warning('off','images:imshow:magnificationMustBeFitForDockedFigure');
                
                % We don't want to auto-scale uint8's, but want to
                % auto-scale uint16 and double.
                if isa(self.SegmentationCore.Im,'uint8')
                    hIm = imshow(self.SegmentationCore.Im,'Parent',hAx);
                else
                    hIm = imshow(self.SegmentationCore.Im,'Parent',hAx,'DisplayRange',[]);
                end
                warning(warnState);
                
                
                self.SegmentationCore.hScrollpanel = imscrollpanel(imPanel,hIm);
                set(self.SegmentationCore.hScrollpanel,'Units','normalized',...
                    'Position',[0 0 1 1]);
                
                % We need to ensure that graphics objects related to the
                % scrollpanel are constructed before we set the
                % magnification of the tool.
                drawnow;drawnow;
                
                api = iptgetapi(self.SegmentationCore.hScrollpanel);
                fitmag = api.findFitMag();
                api.setMagnification(fitmag);
                
                % Turn on axes visibility
                hAx = findobj(self.SegmentationCore.hScrollpanel,'type','axes');
                set(hAx,'Visible','on');
                
                % Initialize Overlay color by setting axes color.
                set(hAx,'Color','green');
                
                % Turn off axes gridding
                set(hAx,'XTick',[],'YTick',[]);
                
            else
                % If scrollpanel has already been created, we simply want
                % to reparent it to the current figure that is being
                % created/in view.
                set(self.SegmentationCore.hScrollpanel,'Parent',imPanel);
            end
            
        end
    end
    
    methods (Access = private)
        function setToolPreferences(self)
            
            % Get group
            group = self.ToolGroup.Peer.getWrappedComponent;
            
            % Remove View tab
            group.putGroupProperty(...
                com.mathworks.widgets.desk.DTGroupProperty.ACCEPT_DEFAULT_VIEW_TAB, false);
            
            % Remove Quick Access bar
            filter = com.mathworks.toolbox.images.QuickAccessFilter.getFilter();
            group.putGroupProperty(...
                com.mathworks.widgets.desk.DTGroupProperty.QUICK_ACCESS_TOOL_BAR_FILTER, filter)
            
            % Remove Document bar
            group.putGroupProperty(...
                com.mathworks.widgets.desk.DTGroupProperty.SHOW_SINGLE_ENTRY_DOCUMENT_BAR, false);
            
            % Clean up title
            group.putGroupProperty(...
                com.mathworks.widgets.desk.DTGroupProperty.APPEND_DOCUMENT_TITLE, false);
            
            % Disable "Hide" option in tabs
            group.putGroupProperty(...
                com.mathworks.widgets.desk.DTGroupProperty.PERMIT_DOCUMENT_BAR_HIDE, false);
            
            % Disable Drag-Drop gestures on toolgroup
            dropListener = com.mathworks.widgets.desk.DTGroupProperty.IGNORE_ALL_DROPS;
            group.putGroupProperty(com.mathworks.widgets.desk.DTGroupProperty.DROP_LISTENER, dropListener);
            
        end
        
        function hideDataBrowser(self)
            
            % Can only be done after t.open
            md = com.mathworks.mlservices.MatlabDesktopServices.getDesktop;
            md.hideClient('DataBrowserContainer',self.GroupName);
        end
        
        %------------------------------------------------------------------
        % Figure View
        %------------------------------------------------------------------
        function updateMaskOverlayGraphics(self)
                        
            if ~isvalid(self)
                return
            end
            
            hIm = findobj(self.SegmentationCore.hScrollpanel,'type','image');
            if self.ShowBinaryButton.Selected
                set(hIm,'CData',self.SegmentationCore.Mask);
                set(hIm,'CDataMapping','direct');
            else
                alphaData = ones(size(self.SegmentationCore.Mask,1),size(self.SegmentationCore.Mask,2));
                alphaData(self.SegmentationCore.Mask) = 1-self.OpacitySlider.Value/100;
                set(hIm,'CDataMapping','scaled');
                set(hIm,'AlphaData',alphaData);
            end
            
        end
        
        function updateIterationGraphics(self)
                       
           if ~isvalid(self)
               return
           end
            
           iptui.internal.utilities.setStatusBarText(self.GroupName,...
               getMessageString('iterationStatusText',...
                num2str(self.SegmentationCore.CurrentIteration),...
                num2str(self.SegmentationCore.Iterations)...
                )...
               );
            
        end
        
        %------------------------------------------------------------------
        % Image Load
        %------------------------------------------------------------------
        function [self,im] = normalizeDoubleDataDlg(self,im)
            
            self.IsDataNormalized = false;
            self.IsInfNanRemoved      = false;
            
            % Check if image has NaN,Inf or -Inf valued pixels.
            finiteIdx       = isfinite(im(:));
            hasNansInfs     = ~all(finiteIdx);
            
            % Check if image pixels are outside [0,1].
            isOutsideRange  = any(im(finiteIdx)>1) || any(im(finiteIdx)<0);
            
            % Offer the user the option to normalize and clean-up data if
            % either of these conditions is true.
            if isOutsideRange || hasNansInfs
                
                buttonname = questdlg(getMessageString('normalizeDataDlgMessage'),...
                    getMessageString('normalizeDataDlgTitle'),...
                    getMessageString('normalizeData'),...
                    getString(message('images:commonUIString:cancel')),...
                    getMessageString('normalizeData'));
                
                if strcmp(buttonname,getMessageString('normalizeData'))
                    
                    % First clean-up data by removing NaN's and Inf's.
                    if hasNansInfs
                        % Replace nan pixels with 0.
                        im(isnan(im)) = 0;
                        
                        % Replace inf pixels with 1.
                        im(im== Inf)   = 1;
                        
                        % Replace -inf pixels with 0.
                        im(im==-Inf)   = 0;
                        
                        self.IsInfNanRemoved = true;
                    end
                    
                    % Normalize data in [0,1] if outside range.
                    if isOutsideRange
                        im = im ./ max(im(:));
                        
                        self.IsDataNormalized = true;
                    end
                    
                    
                else
                    im = [];
                end
                
            end
        end
        
        function importImageData(self,im)
            
            if isa(im,'double')
                [self,im] = normalizeDoubleDataDlg(self,im);
                if isempty(im)
                    return;
                end
            end
            
            self.initializeAppWithImage(im);
            
        end
        
        %------------------------------------------------------------------
        % Initialize
        %------------------------------------------------------------------
        function addListenersToInitSegTab(self)
            
            addlistener(self.InitSegTab,'CloseInitTab',@(~,evt)closeInitSegTab(self,evt));
        end
        
        %------------------------------------------------------------------
        % Segmentation
        %------------------------------------------------------------------
        function updateSegmentButtonIcon(self,name)
            switch name
                case 'segment'
                    self.SegmentButton.Icon = toolpack.component.Icon.RUN_24;
                    self.SegmentButton.Text = getMessageString('evolve');
                case 'stop'
                    self.SegmentButton.Icon = toolpack.component.Icon.END_24;
                    self.SegmentButton.Text = getMessageString('stopSegmentation');
            end
        end
        
        %------------------------------------------------------------------
        % Cleanup
        %------------------------------------------------------------------
        
        function addListenersToRefineTab(self)
            
            addlistener(self.RefineTab,'CloseRefineTab',@(~,evt)closeRefineTab(self,evt));
        end
        
        %------------------------------------------------------------------
        % Code Generation
        %------------------------------------------------------------------
        function addFunctionDeclaration(self,generator)
            
            % Mask needs to be specified as part of the function call
            % if it was loaded or manually supplied, else function call
            % only requires input.
            fcnName = 'segmentImage';
            
            switch self.InitSelection
                case {'LoadMaskFromFile','LoadMaskFromWorkspace','Freehand','Polygon'}
                    inputs = {'im','mask'};
                    description = ['segments image IM using auto-generated code '...
                        'from the imageSegmenter App starting from the'...
                        ' initial segmentation specified by binary mask MASK. The'...
                        ' final segmentation is returned in BW and a masked image' ...
                        ' is returned in MASKEDIMAGE.'];
                case {'Otsu','Threshold','Grid'}
                    description = ['segments image IM using auto-generated code '...
                        'from the imageSegmenter App. The final '...
                        'segmentation is returned in BW and a masked image is '...
                        'returned in MASKEDIMAGE.'];
                    inputs = {'im'};
            end
            
            outputs = {'BW','maskedImage'};
            
            h1Line  = 'segments image using auto-generated code from imageSegmenter App';
            
            generator.addFunctionDeclaration(fcnName,inputs,outputs,h1Line);
            generator.addSyntaxHelp(fcnName,description,inputs,outputs);
        end
        
        function addImageLoadingCode(self,generator)
            
            % If image loaded was RGB, add code to convert to grayscale.
            if self.wasRGB
                generator.addComment('Convert to grayscale');
                generator.addLine('im = rgb2gray(im);');
            end
            
            % If we clean image data of Nans or Infs, insert this  into
            % generated code.
            if isa(self.SegmentationCore.Im,'double') && (self.IsInfNanRemoved)
                generator.addComment('Replace nan values with 0');
                generator.addLine('im(isnan(im)) = 0;');
                
                generator.addComment('Replace inf values with 1');
                generator.addLine('im(im==Inf) = 1;');
                
                generator.addComment('Replace -inf values with 0');
                generator.addLine('im(im==-Inf) = 0;');
            end
            
            % If we normalized double data, insert normalization into
            % generated code.
            if isa(self.SegmentationCore.Im,'double') && (self.IsDataNormalized)
                generator.addComment('Normalize double input data to range [0 1]');
                generator.addLine('im = im ./ max(im(:));');
            end
        end
        
        function addInitializationCode(self,generator)
            
            metadata = self.InitMetadata;
            switch self.InitSelection
                case 'Otsu'
                    generator.addComment('Initialize segmentation with Otsu''s threshold');
                    generator.addLine('level = graythresh(im);');
                    generator.addLine('mask = im2bw(im,level);');
                    
                case 'Threshold'
                    thresholdStr = metadata.Threshold;
                    generator.addComment('Initialize segmentation with threshold');
                    generator.addLine(sprintf('mask = im>%s;',thresholdStr));
                    
                case 'Grid'
                    radius = metadata.Radius;
                    ny     = metadata.GridLayout(1);
                    nx     = metadata.GridLayout(2);
                    
                    radiusStr = num2str(radius);
                    nyStr     = num2str(ny);
                    nxStr     = num2str(nx);
                    nyComment = ' % number of circles in y direction';
                    nxComment = ' % number of circles in x direction';
                    
                    generator.addComment('Initialize segmentation with a grid of circles');
                    generator.addLine(sprintf('radius = %s;',radiusStr));
                    generator.addLine(sprintf('ny = %s; %s',nyStr,nyComment));
                    generator.addLine(sprintf('nx = %s; %s',nxStr,nxComment));
                    generator.addLine('mask = circleGrid(radius,ny,nx,size(im));');
                    
                    circleGridgenerator = iptui.internal.CodeGenerator();
                    
                    % Add definition
                    circleGridgenerator.addFunctionDeclaration('circleGrid',...
                        {'radius','ny','nx','sz'},{'mask'},...
                        'creates a mask containing a grid of circles');
                    
                    % Add syntax description
                    description = ['creates a mask containing a grid of' ...
                        ' circles of radius RADIUS. The grid is laid out' ...
                        ' with NY circles vertically and NX circles' ...
                        ' horizontally on a mask MASK of size SZ.'];
                    
                    circleGridgenerator.addSyntaxHelp('circleGrid',...
                        description,{'radius','ny','nx','sz'},{'mask'});
                    
                    % Add function code
                    circleGridgenerator.addLine('mask = false(sz);');
                    circleGridgenerator.addReturn();
                    circleGridgenerator.addLine('if radius>0');
                    circleGridgenerator.addReturn();
                    circleGridgenerator.addLine('% Find centers of circles to be drawn');
                    circleGridgenerator.addLine('centersy = round(linspace(1,sz(1),ny+2));');
                    circleGridgenerator.addLine('centersy = centersy(2:end-1);');
                    circleGridgenerator.addReturn();
                    circleGridgenerator.addLine('centersx = round(linspace(1,sz(2),nx+2));');
                    circleGridgenerator.addLine('centersx = centersx(2:end-1);');
                    circleGridgenerator.addReturn();
                    circleGridgenerator.addLine('% Create a circle mask');
                    circleGridgenerator.addLine('circle = strel(''disk'',radius,0).getnhood();');
                    circleGridgenerator.addLine('');
                    circleGridgenerator.addLine('% Place circle at each center');
                    circleGridgenerator.addLine('for y = 1 : ny');
                    circleGridgenerator.addLine('for x = 1 : nx');
                    circleGridgenerator.addLine('mask(centersy(y)-radius:centersy(y)+radius,centersx(x)-radius:centersx(x)+radius) = circle;');
                    circleGridgenerator.addLine('end');
                    circleGridgenerator.addLine('end');
                    circleGridgenerator.addLine('end');
                    
                    % Add function end
                    circleGridgenerator.addLine('end');
                    
                    % Get code as a string
                    circleGridCode = circleGridgenerator.getCodeString();
                    
                    % Add sub-function at the end of main function
                    generator.addSubFunction(circleGridCode);
            end
                
        end
        
        function addSegmentRefineCode(self,generator)
            
            addCodeToGenerator(self.EventLog,generator);
        end
        
        function addMaskedImageCode(~,generator)
            
            generator.addComment('Form masked image from input image and segmented image.');
            generator.addLine('maskedImage = im;');
            generator.addLine('maskedImage(~BW) = 0;');
        end
        
        %------------------------------------------------------------------
        % State Management
        %------------------------------------------------------------------
        function setControlsOnConstruction(self)
            %setControlsOnConstruction - Set initial App state
            
            % Enable load image button.
            setControlsEnabled(self,{self.LoadImageButton},true);
            
            % Disable all controls except load image button.
            cellHandles = [self.ChangeHandles.InitializeSegmentationHandles ...
                self.ChangeHandles.SetupHandles ...
                self.ChangeHandles.SegmentImageHandles ...
                self.ChangeHandles.RefineHandles ...
                self.ChangeHandles.PanAndZoomHandles ...
                self.ChangeHandles.ViewSegmentationHandles ...
                self.ChangeHandles.ExportHandles];
            
            
            setControlsEnabled(self,cellHandles,false);
        end
        
        function setControlsOnImageLoad(self)
            %setControlsOnImageLoad - Set App state once image is loaded
            
            if self.ShowBinaryButton.Selected
                self.ShowBinaryButton.Selected = false;
                % This drawnow ensures that the callback triggered when
                % show binary is unselected fires immediately.
                drawnow;
            end
            
            % Enable Load,InitSeg, PanZoom sections.
            cellHandles = [{self.LoadImageButton} ...
                self.ChangeHandles.InitializeSegmentationHandles(1) ...
                self.ChangeHandles.PanAndZoomHandles];
            
            setControlsEnabled(self,cellHandles,true);
            
            % Disable remaining sections.
            cellHandles = [self.ChangeHandles.InitializeSegmentationHandles(2) ...
                self.ChangeHandles.SetupHandles ...
                self.ChangeHandles.SegmentImageHandles ...
                self.ChangeHandles.ViewSegmentationHandles ...
                self.ChangeHandles.RefineHandles ...
                self.ChangeHandles.ExportHandles];
            
            setControlsEnabled(self,cellHandles,false);
            
            restoreViewSectionDefaults(self);
            
        end
        
        function setControlsDuringMaskInit(self)
            %setControlsDuringMaskInit - Set App state when init mask tab
            %is open
            
            % Enable InitSeg, PanZoom and View sections.
            cellHandles = [self.ChangeHandles.InitializeSegmentationHandles(1) ...
                self.ChangeHandles.ViewSegmentationHandles ...
                self.ChangeHandles.PanAndZoomHandles];
            
            setControlsEnabled(self,cellHandles,true);
            
            % Disable remaining sections.
            cellHandles = [{self.LoadImageButton} ...
                self.ChangeHandles.InitializeSegmentationHandles(2) ...
                self.ChangeHandles.SetupHandles ...
                self.ChangeHandles.SegmentImageHandles ...
                self.ChangeHandles.RefineHandles ...
                self.ChangeHandles.ExportHandles];
            
            setControlsEnabled(self,cellHandles,false);
        end
        
        function setControlsOnMaskInit(self)
            %setControlsOnMaskInit - Set App state once mask is initialized
            
            showBinaryMode = self.ShowBinaryButton.Selected;
                
            cellHandles = [{self.LoadImageButton} ...
                self.ChangeHandles.InitializeSegmentationHandles(1) ...
                self.ChangeHandles.SetupHandles ...
                self.ChangeHandles.SegmentImageHandles ...
                self.ChangeHandles.PanAndZoomHandles ...
                self.ChangeHandles.ViewSegmentationHandles ...
                self.ChangeHandles.RefineHandles ...
                self.ChangeHandles.ExportHandles];
            
            setControlsEnabled(self,cellHandles,true);
            
            cellHandles = self.ChangeHandles.InitializeSegmentationHandles(2);
            setControlsEnabled(self,cellHandles,false);
            
            % If the show binary button was selected, disable the opacity
            % slider and foreground color button.
            if showBinaryMode
                self.OpacitySlider.Enabled = false;
                self.OverlayColorButton.Enabled = false;
            end
            
            self.ContinueSegmentationFlag = false;
        end
        
        function setControlsDuringSegment(self)
            %setControldDuringSegment - Set App state while segmentation
            %state is running
            
            % Change Icon to Stop.
            updateSegmentButtonIcon(self,'stop');
            
            % Enable segment button, pan and zoom section and view controls
            % section.
            cellHandles = [self.ChangeHandles.SegmentImageHandles ...
                self.ChangeHandles.PanAndZoomHandles ...
                self.ChangeHandles.ViewSegmentationHandles];
            
            setControlsEnabled(self,cellHandles,true);
            
            % Disable all remaining handles.
            cellHandles = [{self.LoadImageButton} ...
                self.ChangeHandles.InitializeSegmentationHandles ...
                self.ChangeHandles.SetupHandles ...
                self.ChangeHandles.RefineHandles ...
                self.ChangeHandles.ExportHandles];
            
            setControlsEnabled(self,cellHandles,false);
        end
        
        function setControlsOnSegment(self)
            %setControlsOnSegment - Set App state after segmentation
            
            % Change icon to segment.
            updateSegmentButtonIcon(self,'segment');
            
            % Enable all handles.
            cellHandles = [{self.LoadImageButton} ...
                self.ChangeHandles.InitializeSegmentationHandles ...
                self.ChangeHandles.SetupHandles ...
                self.ChangeHandles.SegmentImageHandles ...
                self.ChangeHandles.RefineHandles ...
                self.ChangeHandles.PanAndZoomHandles ...
                self.ChangeHandles.ViewSegmentationHandles ...
                self.ChangeHandles.ExportHandles];
            
            setControlsEnabled(self,cellHandles,true);
        end
        
        function setControlsToEmptyMask(self)
            
            if self.ShowBinaryButton.Selected
                self.ShowBinaryButton.Selected = false;
                % This drawnow ensures that the callback triggered when
                % show binary is unselected fires immediately.
                drawnow;
            end
            
            % Enable Load,InitSeg, PanZoom sections.
            cellHandles = [{self.LoadImageButton} ...
                self.ChangeHandles.InitializeSegmentationHandles ...
                self.ChangeHandles.PanAndZoomHandles];
            
            setControlsEnabled(self,cellHandles,true);
            
            % Disable remaining sections.
            cellHandles = [self.ChangeHandles.SetupHandles ...
                self.ChangeHandles.SegmentImageHandles ...
                self.ChangeHandles.ViewSegmentationHandles ...
                self.ChangeHandles.RefineHandles ...
                self.ChangeHandles.ExportHandles];
            
            setControlsEnabled(self,cellHandles,false);
        end
        
        function setControlsDuringRefine(self)
            %setControlsDuringRefine - Set App state when refine tab is
            %open
            
            % Enable Refine, PanZoom and View sections.
            cellHandles = [self.ChangeHandles.RefineHandles ...
                self.ChangeHandles.ViewSegmentationHandles ...
                self.ChangeHandles.PanAndZoomHandles];
            
            setControlsEnabled(self,cellHandles,true);
            
            % Disable remaining sections.
            cellHandles = [{self.LoadImageButton} ...
                self.ChangeHandles.InitializeSegmentationHandles ...
                self.ChangeHandles.SetupHandles ...
                self.ChangeHandles.SegmentImageHandles ...
                self.ChangeHandles.ExportHandles];
            
            setControlsEnabled(self,cellHandles,false);
            
        end
        
        function setControlsOnRefine(self)
            %setControlsOnRefine - Set App state after refine is completed
            
            showBinaryMode = self.ShowBinaryButton.Selected;
            
            cellHandles = [{self.LoadImageButton} ...
                self.ChangeHandles.InitializeSegmentationHandles ...
                self.ChangeHandles.SetupHandles ...
                self.ChangeHandles.SegmentImageHandles ...
                self.ChangeHandles.RefineHandles ...
                self.ChangeHandles.PanAndZoomHandles ...
                self.ChangeHandles.ViewSegmentationHandles ...
                self.ChangeHandles.ExportHandles];
            
            setControlsEnabled(self,cellHandles,true);
            
            % If the show binary button was selected, disable the opacity
            % slider and foreground color button.
            if showBinaryMode
                self.OpacitySlider.Enabled = false;
                self.OverlayColorButton.Enabled = false;
            end
        end
        
        function setControlsEnabled(~,cellHandles,TF)
            
            for n = 1 : numel(cellHandles)
                cellHandles{n}.Enabled = TF;
            end
        end
        
        function restoreViewSectionDefaults(self)
            
            % Disable listeners
            self.ShowBinaryButtonListener.Enabled = false;
            self.OpacitySliderListener.Enabled = false;
            
            % Set Show Binary and Opacity Slider back to their
            % default state whenever a new image is loaded.
            self.ShowBinaryButton.Selected = false;
            self.OpacitySlider.Value  = 60;
            
            % Reset zoom and foreground color/opacity
            self.ZoomInButton.Selected = false;
            self.ZoomOutButton.Selected = false;
            self.PanButton.Selected = false;
            self.setTSButtonIconFromImage(self.OverlayColorButton,...
                cat(3,zeros(16,16,'uint8'),255*ones(16,16,'uint8'),zeros(16,16,'uint8')));
            
            % This drawnow is necessary to allow state of buttons to settle
            % before re-enabling listeners.
            drawnow;
            
            % Enable listeners
            self.ShowBinaryButtonListener.Enabled = true;
            self.OpacitySliderListener.Enabled = true;
        end
        
        %------------------------------------------------------------------
        % Tab Management
        %------------------------------------------------------------------
        function closeModalTabs(self)
            %closeModalTabs - close initialize and refine tabs.
            
            removeTab(self.ToolGroup,self.TabNames.Initialize);
            removeTab(self.ToolGroup,self.TabNames.Refine);
            
        end
        
        %------------------------------------------------------------------
        % Utility
        %------------------------------------------------------------------
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
        
        function addListenersToBackend(self)
            
            self.UpdateMaskListener = event.proplistener(self.SegmentationCore,...
                self.SegmentationCore.findprop('Mask'),'PostSet',@(~,~)updateMaskOverlayGraphics(self));
            
            self.UpdateIterationListener = event.proplistener(self.SegmentationCore,...
                self.SegmentationCore.findprop('CurrentIteration'),'PostSet',@(~,~) updateIterationGraphics(self));
        end
        
        function addTitledBorderToPanel(~,panel,title)
            
            emptyBorder = javaMethodEDT('createEmptyBorder','javax.swing.BorderFactory');
            titledBorder = javaMethodEDT('createTitledBorder','javax.swing.BorderFactory',emptyBorder,title);
            javaObjectEDT(titledBorder);
            panel.Peer.setBorder(titledBorder);
        end
        
    end
    
    methods (Static)
        function deleteAllTools
            imageslib.internal.apputil.manageToolInstances('deleteAll', 'imageSegmenter');
        end
        
        function TF = isValidImageType(im)
            
            supportedDataType       = isa(im,'uint8') || isa(im,'uint16') || isa(im,'double');
            supportedAttributes     = isreal(im) && all(isfinite(im(:))) && ~issparse(im);
            
            TF = supportedDataType && supportedAttributes;
            
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
