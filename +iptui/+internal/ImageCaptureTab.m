classdef ImageCaptureTab < iptui.internal.AbstractTab
% ImageCaptureTab Defines key UI elements of the Image Capture Tab of Color Thresholder App
%
%    This class defines all key UI elements and sets up their callbacks.
    
% Copyright 2014 The MathWorks, Inc.

    properties (Access=private)
        %% Device Section
        DeviceComboBox
        PropertiesButton
        PropertiesPanel
        
        %% Capture Section
        CaptureButton
    end
    
    properties (GetAccess=public, SetAccess=private)
        % Current status of Image Capture Tab 
        CaptureFlag
        
        % Store device name
        SavedCamera
        
        % All images that image capture tab has acquired in a session
        % (emptied when you close Image Capture Tab).
        Images
        
        % Valid tab.
        LoadTab
    end
    
    properties (Access=private)
        CameraObject = []
        PreviewObject
        
        ToolGroupName
    end
    
    methods (Access=public)
        % Constructor
        function this = ImageCaptureTab(tool)
            this = this@iptui.internal.AbstractTab(tool, ...
                        getString(message('images:colorSegmentor:ImageCaptureTabName')), ...
                        getString(message('images:colorSegmentor:ImageCaptureTab')));
            this.CaptureFlag = false;
            this.ToolGroupName = tool.GroupName();

            % Create the toolstrip widgets.
            this.createWidgets();
            
            % Add listeners.
            this.installListeners(); 
        end
        
        % Creates and starts a preview.
        function createDevice(this)
            if strcmpi(this.SavedCamera, this.DeviceComboBox.SelectedItem)
                constructWithResolution = true;
            else
                constructWithResolution = false;
                this.PropertiesPanel = [];
            end
            this.updateDeviceSection(this.DeviceComboBox, constructWithResolution);
        end
        
        % Close preview
        function closePreview(this)
            if ~isempty(this.CameraObject) && isvalid(this.CameraObject)
                closePreview(this.CameraObject); % Stops the timer
            end
        end
        
        % Preview
        function preview(this)
            if ~isempty(this.CameraObject) && isvalid(this.CameraObject)
                [width, height] = this.getResolution;
                tool = this.getParent;
                drawImage(tool.ImagePreviewDisplay, width, height);
                replaceImage(tool.ImagePreviewDisplay, width, height);
                preview(this.CameraObject, tool.ImagePreviewDisplay.ImHandle);
                % Setup close preview window callback
                set(tool.ImagePreviewDisplay.Fig,'CloseRequestFcn', @(src,event)this.closePreviewWindowCallback);                    
            end
        end        
        
        function closePreviewWindowCallback(this, ~, ~)
            tool = this.getParent;
            if isvalid(tool) && ~isempty(tool.ImagePreviewDisplay)
                % Remove the tab.
                removeTab(tool.getToolGroup, getString(message('images:colorSegmentor:ImageCaptureTabName')));
                tool.ImagePreviewDisplay.makeFigureInvisible();
            end
            
            % Delete the Camera Object.
            if (~isempty(this.CameraObject) && isvalid(this.CameraObject) )
                this.closePreview();
                delete(this.CameraObject);
            end
        end        
        
    end

    methods (Access=private)

        function createWidgets(this)
        % Creates the widgets on the toolstrip
            
            %% Create Device Widgets
            createDeviceWidgets(this);
             
            %% Create Capture Widgets
            createCaptureWidgets(this);
            
        end
        
        function createDeviceWidgets(this)
            %% Toolstrip sections
            deviceSection = toolpack.desktop.ToolSection('DeviceSection',...
                getString(message('images:colorSegmentor:DeviceSection')));
            
            devicePanel = toolpack.component.TSPanel(...
                '10px,f:p,10px,f:p,10px',...
                '10px,f:p,10px,f:p,10px');
            devicePanel.Name = 'DevicePanel';
            
            % Device drop down
            deviceLabel = toolpack.component.TSLabel(getString(message('images:colorSegmentor:DeviceDropDown')));
            
            % Get available webcams
            cams = this.enumerateCameras;
            
            this.DeviceComboBox = toolpack.component.TSComboBox(cams);
            this.DeviceComboBox.Name = 'DeviceCombo';
            
            this.DeviceComboBox.Peer.setToolTipText(getString(message('images:colorSegmentor:EnabledCameraDropDownToolTip')));
            
            % Create buttons.
            this.PropertiesButton = toolpack.component.TSButton(getString(message('images:colorSegmentor:PropertiesButton')),toolpack.component.Icon.SETTINGS_16);
            this.PropertiesButton.Name = 'PropertiesButton';
            this.PropertiesButton.Peer.setToolTipText(getString(message('images:colorSegmentor:EnabledCameraPropertiesToolTip')));
            
            % Add labels to panel.
            devicePanel.add(deviceLabel, 'xy(2,2)');
            devicePanel.add(this.DeviceComboBox, 'xy(4,2)');
            devicePanel.add(this.PropertiesButton, 'xyw(2,4,3)');
            
            % Add the section to the Panel.
            add(deviceSection, devicePanel);
            tab = this.getToolTab();
            add(tab,deviceSection);            
        end
        
        function createCaptureWidgets(this)
            loadFromCameraIcon = toolpack.component.Icon(...
                    fullfile(matlabroot,'/toolbox/images/icons/CreateMask_24px.png'));
            this.CaptureButton = toolpack.component.TSButton(getString(message('images:colorSegmentor:StartCaptureButton')),loadFromCameraIcon);
            this.CaptureButton.Name = 'CaptureButton';
            this.CaptureButton.Orientation = toolpack.component.ButtonOrientation.VERTICAL;
            this.CaptureButton.Peer.setToolTipText(getString(message('images:colorSegmentor:TakeSnapshotButtonToolTip')));
            
            capturePanel = toolpack.component.TSPanel('f:p','f:p');
            capturePanel.Name = 'CapturePanel';
            add(capturePanel,this.CaptureButton,'xy(1,1)');
            
            captureSection = toolpack.desktop.ToolSection('CaptureSection', ...
                                    getString(message('images:colorSegmentor:CaptureSection')));
            add(captureSection,capturePanel);            
            tab = this.getToolTab();
            add(tab, captureSection);            
        end

        function installListeners(this)
            % Device Section
            addlistener(this.DeviceComboBox,'ActionPerformed',@(~,evt)this.updateDeviceSection(evt.Source));
            addlistener(this.PropertiesButton,'ActionPerformed',@(~,~) this.cameraPropertiesCallback());
            
            % Capture button.
            addlistener(this.CaptureButton,'ActionPerformed',@(es,ed)capture(this));
            
        end

    end
    
    
    %% Callback methods
    methods(Access=private)
        
        % Capture button callback
        function capture(this)
            % Check for existing images.
            tool = this.getParent;
            user_canceled_import = tool.showImportingDataWillCauseDataLossDlg(...
                            getString(message('images:colorSegmentor:takingNewSnapshotMessage')), ...
                            getString(message('images:colorSegmentor:takeNewSnapshotTitle')));
            
            if ~user_canceled_import
                % Get a snapshot
                im = snapshot(this.CameraObject);
                tool.importImageData(im);
                removeTab(tool.getToolGroup, getString(message('images:colorSegmentor:ImageCaptureTabName')));
            end
        end
        
        function cams = enumerateCameras(this)
            % Find the location of webcam.
            webcamLoc = which('webcam.m');
            expectedLoc = fullfile(matlabroot, 'toolbox', 'matlab', 'webcam');
            if strcmpi(expectedLoc, fileparts(webcamLoc))
                cams = {getString(message('images:colorSegmentor:NoSPPKGInstalled'))};
                uiwait(errordlg(getString(message('images:colorSegmentor:SupportPkgNotInstalledMsg')), ...
                    getString(message('images:colorSegmentor:GenericErrorTitle')), ...
                    'modal'));
                this.LoadTab = false;
                return;
            end
            
            % Get available webcams
            try
                cams = webcamlist;
                if isempty(cams)
                    cams = {getString(message('images:colorSegmentor:NoWebcamsDetected'))};
                    uiwait(errordlg(getString(message('images:colorSegmentor:NoWebcamsDetectedMsg')), ...
                        getString(message('images:colorSegmentor:NoWebcamsDetected')), ...
                        'modal'));                    
                    this.LoadTab = false;
                    return;
                end                
            catch excep
                cams = {getString(message('images:colorSegmentor:NoWebcamsDetected'))};
                uiwait(errordlg(excep.message, ...
                    getString(message('images:colorSegmentor:GenericErrorTitle')), ...
                    'modal'));
                this.LoadTab = false;
                return;
            end
            
        end
        
        function updateDeviceSection(this, devComboBox, varargin)
            % If no device exists, do nothing and return.
            if ismember(devComboBox.SelectedItem, {getString(message('images:colorSegmentor:NoSPPKGInstalled')), getString(message('images:colorSegmentor:NoWebcamsDetected'))})
                % Empty the properties panel.
                this.PropertiesPanel = [];
                this.LoadTab = false;
                return;
            end
            
            % Update load tab status.
            this.LoadTab = true;
            
            % Create device
            try
                if (~isempty(this.CameraObject) && isvalid(this.CameraObject) )
                    this.closePreview();
                    delete(this.CameraObject);
                    this.CameraObject = [];
                    if (nargin~=3)
                        this.PropertiesPanel = [];
                    end
                end
                if (nargin==3)
                    useResolution = varargin{1};
                    if useResolution
                        this.CameraObject = webcam(devComboBox.SelectedIndex, 'Resolution', this.PropertiesPanel.DevicePropObjects.Resolution.ComboControl.SelectedItem);
                    else
                        this.CameraObject = webcam(devComboBox.SelectedIndex);
                    end
                else
                    this.CameraObject = webcam(devComboBox.SelectedIndex);
                end
                this.preview();
                % Save the device.
                this.SavedCamera = devComboBox.SelectedItem;
                
                % Create properties panel.
                this.createPropertiesPanel();
                
                % Disable buttons
                this.updateButtonStates(true);                      
            catch excep
                % The camera is in use by another application. 
                uiwait(errordlg(excep.message, ...
                    getString(message('images:colorSegmentor:CameraInUseTitle')), ...
                    'modal'));
                
                % Disable buttons
                this.updateButtonStates(false);                
            end
        end

        function updateButtonStates(this, flag)
            this.PropertiesButton.Enabled = flag;
            this.CaptureButton.Enabled = flag;
        end
        
        function cameraPropertiesCallback(this)
            this.createPropertiesPanel();
            this.PropertiesPanel.popup.Floating = false;
            this.PropertiesPanel.popup.show(this.PropertiesButton,'SOUTH');
        end
        
        function createPropertiesPanel(this)
            tool = this.getParent;            
            if isempty(this.PropertiesPanel) % We have to create a new one.
                this.PropertiesPanel = iptui.internal.CameraPropertiesPanel(this.CameraObject, tool.ImagePreviewDisplay);
            else
                this.PropertiesPanel.updateCameraObject(this.CameraObject, tool.ImagePreviewDisplay);
            end
        end
                
        function [width, height] = getResolution(this)
            % Resolution is of the form: 'WidthxHeight'.
            res = this.CameraObject.Resolution;
            idx = strfind(res, 'x');
            width = str2double(res(1:idx-1));
            height = str2double(res(idx+1:end));
        end
    end
end