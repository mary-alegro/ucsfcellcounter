% Copyright 2014-2015 The MathWorks, Inc.


classdef ImageBatchProcessingTool < handle
    
    % Toolstrip
    properties
        
        GroupName
        ToolGroup
        MainTab
        
        % Load
        LoadSection
        LoadButton
        
        % Batch Function
        BatchFunctionSection
        BatchFunctionNameComboBox
        BatchFunctionCreateButton
        BatchFunctionOpenInEditorButton
        BatchFunctionBrowseButton
        
        % Output
        OutputSection
        OutputNameText
        OutputButton
        OutputOverwriteLabel
        OutputOverwriteCheckbox
        
        % Parallel
        ParallelSection
        ProcessInParallelLabel
        ProcessInParallelToggle
        
        % Process
        ProcessPanel
        ProcessSection
        ProcessStopButton
        
        % Zoom Pan
        ZoomPanSection
        ZoomInButton
        ZoomOutButton
        PanButton
        
        % Export
        ExportSection
        ExportButton
    end
    
    % HG Handles
    properties
        imageList    = [];
        imageListInFreshState = false;
        
        hExceptionDisplay = [];
        
        hImageView   = [];
        hSideBySide  = [];
        hScrollpanel = [];
    end
    
    % Computation
    properties
        imageBatchDataStore
        batchFunctionName
        batchFunctionFullFile 
        batchFunctionHandle
        batchProcessor
    end
    
    % Java
    properties
        jProgressLabel = [];
        dataBrowserPanel = [];
    end
    
    % State
    properties
        
        fullOuputDirectoryName = '';
        
        selectedImgInds     = [];
        currentlyProcessing = false;
        currentlyClosing    = false;
        stopRequested       = false;
        
        numberOfTodoImages    = 0;
        numberOfQueuedImages  = 0;
        numberOfDoneImages    = 0;
        numberOfSkippedImages = 0;
        numberOfErroredImages = 0;
        
        createdFunctionDocument = [];
        
        settingsObj;
        maxMemory = 5; % as specified in images.settings
        
        UserSetOutDir = false;
    end
    
    % Construction and App events
    methods
        function tool = ImageBatchProcessingTool()
            narginchk(0,2);
            
            imageslib.internal.apputil.manageToolInstances('add', 'imageBatchProcessor', tool);
            tool.settingsObj = Settings;
            
            % Toolstrip
            tool.GroupName  = matlab.lang.makeValidName(tempname);
            tool.ToolGroup = toolpack.desktop.ToolGroup(tool.GroupName,...
                getString(message('images:imageBatchProcessor:appName')));
            tool.MainTab = tool.ToolGroup.addTab('MainTab', ...
                getString(message('images:imageBatchProcessor:mainTabName')));
            
            addlistener(tool.ToolGroup, 'GroupAction',@tool.userClosed);
            addlistener(tool.ToolGroup, 'GroupAction',@tool.gainedFocus);
            
            % Load
            tool.LoadSection = tool.MainTab.addSection('Load',...
                getString(message('images:imageBatchProcessor:loadSectionLabel')));
            tool.layoutLoadSection();
            % Batch Function
            tool.BatchFunctionSection = tool.MainTab.addSection('BatchFunction',...
                getString(message('images:imageBatchProcessor:batchFunctionSectionLabel')));
            tool.layoutBatchFunctionSection();
            % Output
            tool.OutputSection = tool.MainTab.addSection('Output',...
                getString(message('images:imageBatchProcessor:outputSectionLabel')));
            tool.layoutOutputSection();
            % Parallel
            if(images.internal.isPCTInstalled())
                tool.ParallelSection = tool.MainTab.addSection('Parallel',...
                    getString(message('images:imageBatchProcessor:processInParallelLabel')));
                tool.layoutParallelSection();
            else
                tool.ProcessInParallelToggle.Selected = false;
            end
            % Process
            tool.ProcessSection = tool.MainTab.addSection('Process',...
                getString(message('images:imageBatchProcessor:processSectionLabel')));
            tool.layoutProcessSection();
            % Export
            tool.ExportSection = tool.MainTab.addSection('Export',...
                getString(message('images:imageBatchProcessor:exportSectionLabel')));
            tool.layoutExportSection();
            % Zoom/Pan
            tool.ZoomPanSection = tool.MainTab.addSection('Zoom',...
                getString(message('images:commonUIString:zoomAndPan')));
            tool.layoutZoomPanSection();
            
            group = tool.ToolGroup.Peer.getWrappedComponent;
            % Remove View tab
            group.putGroupProperty(...
                com.mathworks.widgets.desk.DTGroupProperty.ACCEPT_DEFAULT_VIEW_TAB,...
                false);
            % Remove Quick Access Bar
            filter = com.mathworks.toolbox.images.QuickAccessFilter.getFilter();
            group.putGroupProperty(...
                com.mathworks.widgets.desk.DTGroupProperty.QUICK_ACCESS_TOOL_BAR_FILTER,...
                filter);
            
            % Disable drag-drop
            dropListener = com.mathworks.widgets.desk.DTGroupProperty.IGNORE_ALL_DROPS;
            group.putGroupProperty(com.mathworks.widgets.desk.DTGroupProperty.DROP_LISTENER, dropListener);
                        
            tool.ToolGroup.open
            imageslib.internal.apputil.ScreenUtilities.setInitialToolPosition(tool.GroupName);
            
            % Show the data browser with initial help text (use HTML to get
            % multiline)
            helpTextString = ['<html>',...
                getString(message('images:imageBatchProcessor:initialHelpText1')),...
                '<br>',...
                '<br>',...
                getString(message('images:imageBatchProcessor:initialHelpText2')),...
                '<br>','&nbsp;&nbsp;&nbsp;&nbsp;',...
                getString(message('images:imageBatchProcessor:initialHelpText3')),...
                '<br>',...
                '</html>'];
            helpTextLabel = javaObjectEDT('javax.swing.JLabel', helpTextString);
            helpTextLabel.setName('helpTextLabel');
            tool.dataBrowserPanel = javaObjectEDT('javax.swing.JPanel',...
                java.awt.BorderLayout);
            tool.dataBrowserPanel.setBackground(java.awt.Color.white);
            tool.dataBrowserPanel.add(helpTextLabel, java.awt.BorderLayout.NORTH);
            tool.ToolGroup.setDataBrowser(tool.dataBrowserPanel);
           
            md = com.mathworks.mlservices.MatlabDesktopServices.getDesktop;
            % Hide tabs
            md.setDocumentBarPosition(tool.GroupName, ...
                com.mathworks.widgets.desk.Desktop.HIDE_DOCUMENT_BAR);
            
            % Setup space to report progress
            frame = md.getFrameContainingGroup(tool.GroupName);
            sb = javaObjectEDT('com.mathworks.mwswing.MJStatusBar');
            javaMethodEDT('setSharedStatusBar', frame, sb)
            tool.jProgressLabel = javaObjectEDT('javax.swing.JLabel','');
            tool.jProgressLabel.setName('progressLabel');
            sb.add(tool.jProgressLabel);
            
            tool.setState('notReady');                                    
        end
        
        function gainedFocus(tool, varargin)
            if strcmp(varargin{2}.EventData.EventType, 'ACTIVATED')
                % App came into focus.
                tool.checkIfUserBatchFunctionWasSaved();
            end
        end
        
        function userClosed(tool, varargin)
            if strcmp(varargin{2}.EventData.EventType, 'CLOSING')
                tool.checkAndClose();
            end
        end
        
        function checkAndClose(tool, varargin)
            if(~isvalid(tool) || tool.currentlyClosing)
                % Already in the process of closing
                return;
            end
            if(tool.currentlyProcessing)
                noStr  = getString(message('images:commonUIString:no'));
                yesStr = getString(message('images:commonUIString:yes'));
                
                selectedStr = questdlg(...
                    getString(message('images:imageBatchProcessor:closeWhenRunning')),...
                    getString(message('images:imageBatchProcessor:closeWhenRunningTitle')),...
                    yesStr, noStr, noStr);
                if(strcmp(selectedStr, noStr))
                    tool.ToolGroup.vetoClose();
                    return;
                end
            end
            
            tool.delete();                        
        end
        
        function delete(tool)            
            imageslib.internal.apputil.manageToolInstances('remove', 'imageBatchProcessor', tool);
            tool.ToolGroup.approveClose();            
            tool.currentlyClosing = true;
            delete(tool.hExceptionDisplay);
            delete(tool.hImageView);                        
            tool.ToolGroup.close();           
        end
        
    end
    
    %% Layout and Toolstrip Callbacks
    
    % Load
    methods
        function layoutLoadSection(tool)
            loadPanel = toolpack.component.TSPanel('f:p','f:p');
            loadPanel.Name = 'panelLoad';
            tool.LoadSection.add(loadPanel);
            
            tool.LoadButton = toolpack.component.TSButton(...
                getString(message('images:imageBatchProcessor:loadButtonText')),...
                toolpack.component.Icon.IMPORT_24);
            tool.LoadButton.Name = 'LoadButton';
            iptui.internal.utilities.setToolTipText(...
                tool.LoadButton,...
                getString(message('images:imageBatchProcessor:loadButtonTextToolTip')));
            tool.LoadButton.Orientation = toolpack.component.ButtonOrientation.VERTICAL;
            
            addlistener(tool.LoadButton, 'ActionPerformed',...
                @tool.loadDirectory);
            loadPanel.add(tool.LoadButton,'xy(1,1)');
        end
        
        function loadDirectory(tool, varargin)
            [cancelled, newBatchDataStore] = ...
                iptui.internal.loadInputBatchFolderDialog();
            if(~cancelled)
                tool.imageListInFreshState = false;
                tool.imageBatchDataStore = newBatchDataStore;
                tool.setReadyIfPossible();
            end
        end
        
    end
    
    % Batch Function
    methods
        
        function layoutBatchFunctionSection(tool)
            batchPanel = toolpack.component.TSPanel(...
                '70px,80px,f:p',... %columns
                '1dlu, f:p, 1dlu, f:p, 2dlu, f:p:g, 1dlu');
            batchPanel.Name = 'panelBatch';
            tool.BatchFunctionSection.add(batchPanel);
            
            % Top row
            batchLabel = toolpack.component.TSLabel(...
                getString(message('images:imageBatchProcessor:batchFunctionLabel')));
            batchPanel.add(batchLabel,'xyw(1,2,2)');
            
            
            % Middle row - text box
            tool.BatchFunctionNameComboBox = toolpack.component.TSComboBox();
            tool.BatchFunctionNameComboBox.Name = 'BatchFunctionName';
            tool.BatchFunctionNameComboBox.Editable = true;
            
            addlistener(tool.BatchFunctionNameComboBox,'ActionPerformed',...
                @tool.batchNameInTextBoxChanged);
            batchPanel.add(tool.BatchFunctionNameComboBox,'xyw(1,4,2)');
            
            % Middle row - open
            tool.BatchFunctionBrowseButton = toolpack.component.TSButton(...
                '',...
                toolpack.component.Icon.OPEN);
            tool.BatchFunctionBrowseButton.Name = 'FunctionBrowseButton';
            iptui.internal.utilities.setToolTipText(...
                tool.BatchFunctionBrowseButton,...
                getString(message('images:imageBatchProcessor:batchFunctionAddToolTip')));
            
            addlistener(tool.BatchFunctionBrowseButton, 'ActionPerformed',...
                @tool.batchFileBrowse);
            batchPanel.add(tool.BatchFunctionBrowseButton,'xy(3,4)');
            
            
            % Bottom row - create
            tool.BatchFunctionCreateButton = toolpack.component.TSButton(...
                getString(message('images:imageBatchProcessor:createLabel')),...
                toolpack.component.Icon.NEW);
            tool.BatchFunctionCreateButton.Name = 'CreateBatchFunctionButton';
            iptui.internal.utilities.setToolTipText(...
                tool.BatchFunctionCreateButton ,...
                getString(message('images:imageBatchProcessor:createToolTip')));
            
            addlistener(tool.BatchFunctionCreateButton, 'ActionPerformed',...
                @tool.createBatchFunctionInEditor);
            batchPanel.add(tool.BatchFunctionCreateButton,'xy(1,6)');
            
            % Bottom row - edit
            ei = com.mathworks.common.icons.ApplicationIcon.EDITOR.getIcon();
            icon = toolpack.component.Icon(ei);            

            tool.BatchFunctionOpenInEditorButton = toolpack.component.TSButton(...
                getString(message('images:imageBatchProcessor:openInEditorLabel')),...
                icon);
            tool.BatchFunctionOpenInEditorButton.Name = 'OpenInEditorButton';
            iptui.internal.utilities.setToolTipText(...
                tool.BatchFunctionOpenInEditorButton ,...
                getString(message('images:imageBatchProcessor:openInEditorToolTip')));
            
            addlistener(tool.BatchFunctionOpenInEditorButton, 'ActionPerformed',...
                @tool.openBatchFunctionInEditor);
            batchPanel.add(tool.BatchFunctionOpenInEditorButton,'xy(2,6)');
            

            % Initialize
            tool.updateBatchFunctionComboBoxFromHistory();
        end
        
        function batchNameInTextBoxChanged(tool, varargin)            
            selectedText = tool.BatchFunctionNameComboBox.SelectedItem;
            
            if(strcmp(selectedText,getString(message('images:imageBatchProcessor:batchFunctionInitialText'))))
                % No action is helper text is selected
                return;
            end
                       
            if(any(filesep == selectedText))
                % / or \ found, treat as absolute path
                fullFcnFile = selectedText;
                [~, fileName] = fileparts(fullFcnFile);
            else
                fileName = selectedText;
                fullFcnFile = tool.findPath(fileName);
            end
                        
            tool.updateBatchFunction(fullFcnFile, fileName);
        end
        
        function fullFcnFile = findPath(tool, fileName)            
            fullFcnFile = '';
            
            % Check if we have full path in history
            fullFcnPaths = tool.settingsObj.images.imagebatchprocessingtool.BatchFunctions;
            for ind = numel(fullFcnPaths):-1:1
                [~, rFileName] = fileparts(fullFcnPaths{ind}); % remembered file name
                if(strcmp(fileName,rFileName))
                    fullFcnFile = fullFcnPaths{ind};
                    break;
                end
            end
                        
            if(isempty(fullFcnFile))            
                % See if its on path
                try
                    fullFcnFile = which(fileName);
                catch ALL %#ok<NASGU>
                    % will fail for bad strings (or function handles)
                    fullFcnFile ='';
                end
                if(isempty(fullFcnFile))
                    % Not on path
                    fullFcnFile = fileName;
                end
            end
        end

        function updateBatchFunction(tool, fullFcnFile, fileName)                                
            
            [fcnPath, ~, fcnExt] = fileparts(fullFcnFile);
            
            if(~strcmpi(fcnExt, '.m') || ~exist(fullFcnFile,'file'))
                errordlg(getString(message('images:imageBatchProcessor:invalidFunctionFile', fullFcnFile)),...
                    getString(message('images:imageBatchProcessor:invalidFunctionFileTitle')),...
                    'modal');
                tool.batchFunctionInvalid(fullFcnFile);
                return;                
            end
            
            % Get a clean file name (cleans up ../folder//file.m to
            % .../folder/file.m
            fid = fopen(fullFcnFile,'r');
            closeFile =onCleanup(@()fclose(fid));
            fullFcnFile = fopen(fid);
            clear closeFile;
            
            if(isempty(fcnPath))
                errordlg(getString(message('images:imageBatchProcessor:pathNotFoundError', fullFcnFile)),...
                    getString(message('images:imageBatchProcessor:pathNotFoundTitle')),...
                    'modal');
                tool.batchFunctionInvalid(fullFcnFile);
                return;
            end

            % Cross check with WHICH 
            whichPath = which(fileName);
            if(isempty(whichPath))
                % Not on path - cd or add path?
                cancelButton = getString(message('images:commonUIString:cancel'));
                addToPathButton = getString(message('images:imageBatchProcessor:addToPath'));
                cdButton = getString(message('images:imageBatchProcessor:cdFolder'));
                buttonName = questdlg(getString(message('images:imageBatchProcessor:notOnPathQuestion', fcnPath)),...
                    getString(message('images:imageBatchProcessor:notOnPathTitle')),...
                    cdButton, addToPathButton, cancelButton, cdButton);
                switch buttonName
                    case cdButton
                        cd(fcnPath);
                    case addToPathButton
                        addpath(fcnPath);
                    otherwise
                        % cancel 
                        tool.batchFunctionInvalid(fullFcnFile);
                        return
                end                
            elseif(~strcmpi(whichPath, fullFcnFile))
                % Clash. No clean way to handle this, so error out.
                errordlg(getString(message('images:imageBatchProcessor:nameClash', fileName, whichPath)),...
                    getString(message('images:imageBatchProcessor:nameClashTitle')),'modal');
                tool.batchFunctionInvalid(fullFcnFile);
                return;
            end            

            tool.validBatchFunctionPathDefined(fullFcnFile);
        end
        
        function validBatchFunctionPathDefined(tool, fullFcnFile)
            [~, fcnName] = fileparts(fullFcnFile);
            
            if(strcmpi(fullFcnFile, tool.batchFunctionFullFile)...
                    && strcmpi(fcnName, tool.BatchFunctionNameComboBox.SelectedItem))
                % Change already registered.
                return;
            end
            
            tool.batchFunctionFullFile = fullFcnFile;
            tool.batchFunctionName = fcnName;
                        
            tool.batchFunctionHandle = str2func(tool.batchFunctionName);

            tool.rememberBatchFunction();
            tool.updateBatchFunctionComboBoxFromHistory();
            
            oldOutputDir = tool.fullOuputDirectoryName;
            
            %Update the output directory in response to new function. Only
            %do this if images have been loaded (in which case oldOutputDir
            %is non-empty) and the user hasn't manually specified output
            %directory.
            if ~isempty(oldOutputDir) && ~tool.UserSetOutDir
                newOutputDir = [tool.imageBatchDataStore.ReadLocation, '_', fcnName];
                tool.updateOutputDir(newOutputDir);
            end
            
            % A function was specified, forget about any generated user
            % batch code.
            tool.createdFunctionDocument = [];
            
            tool.setReadyIfPossible();
        end
        
        function rememberBatchFunction(tool)
            fullFcnPaths = tool.settingsObj.images.imagebatchprocessingtool.BatchFunctions;
            if(isempty(fullFcnPaths)||isempty(fullFcnPaths{1}))
                fullFcnPaths = {};
            end
            
            inds = strcmp(tool.batchFunctionFullFile, fullFcnPaths);
            if(any(inds))
                % Already remembered, move to head of list
                fullFcnPaths = [{tool.batchFunctionFullFile}, fullFcnPaths];
                lind = find(inds);
                fullFcnPaths(lind+1) = [];
            else
                % Not previously remembered.
                numNewFunctions = min(tool.maxMemory, numel(fullFcnPaths)+1);
                newFunctions = cell(1,numNewFunctions);
                newFunctions(1:numel(fullFcnPaths)) = fullFcnPaths;
                % Shift down
                newFunctions(2:end) = newFunctions(1:end-1);
                newFunctions{1} = tool.batchFunctionFullFile;                
                fullFcnPaths = newFunctions;
            end
            curMemory = min(tool.maxMemory, numel(fullFcnPaths));
            functionNamesToSave = fullFcnPaths(1:curMemory);
            tool.settingsObj.images.imagebatchprocessingtool.set(...
                'BatchFunctions',functionNamesToSave,'user');
        end
        
        function updateBatchFunctionComboBoxFromHistory(tool)
            tool.BatchFunctionNameComboBox.removeAllItems();
            
            functionNames = tool.settingsObj.images.imagebatchprocessingtool.BatchFunctions;
            if(isempty(functionNames)||isempty(functionNames{1}))
                % Initialize
                tool.BatchFunctionNameComboBox.addItem(...
                    getString(message('images:imageBatchProcessor:batchFunctionInitialText')));
                iptui.internal.utilities.setToolTipText(...
                    tool.BatchFunctionNameComboBox,...
                    getString(message('images:imageBatchProcessor:batchFunctionNameToolTip')));
            else
                % Load from history
                for ind = 1:numel(functionNames)
                    [~, fcnName] = fileparts(functionNames{ind});
                    tool.BatchFunctionNameComboBox.addItem(fcnName);
                end
                tool.BatchFunctionNameComboBox.SelectedIndex = 1;
                iptui.internal.utilities.setToolTipText(...
                    tool.BatchFunctionNameComboBox,functionNames{1});
                tool.BatchFunctionOpenInEditorButton.Enabled = true;
            end
        end
        
        function batchFunctionInvalid(tool, fullFcnFile)
            % Forget bad file 
            previousFunctions = tool.settingsObj.images.imagebatchprocessingtool.BatchFunctions;
            badIndex = strcmp(fullFcnFile, previousFunctions);
            previousFunctions(badIndex) = [];
            tool.settingsObj.images.imagebatchprocessingtool.set(...
                'BatchFunctions',previousFunctions,'user');
            % Reinitialize
            tool.updateBatchFunctionComboBoxFromHistory();            
        end
        
        function createBatchFunctionInEditor(tool, varargin)
            templateFile = fullfile(matlabroot, 'toolbox','images','images','+images','+internal','templateBatchUserFunction.template');
            codeString = fileread(templateFile);
            tool.createdFunctionDocument = matlab.desktop.editor.newDocument(codeString);
        end
        
        function checkIfUserBatchFunctionWasSaved(tool)
            if(isvalid(tool) && ~isempty(tool.createdFunctionDocument))
                % A user batch function was generated
                if(tool.createdFunctionDocument.Opened)
                    if(tool.createdFunctionDocument.Modified)
                        tool.BatchFunctionNameComboBox.Enabled = false;
                        iptui.internal.utilities.setToolTipText(...
                            tool.BatchFunctionNameComboBox,...
                            getString(message('images:imageBatchProcessor:saveGeneratedUserBatchCode', ...
                            tool.createdFunctionDocument.Filename)))
                    else
                        % Generated code was saved, update with full file
                        % name and update the short name
                        tool.BatchFunctionNameComboBox.Enabled = true;
                        fullFcnPath = tool.createdFunctionDocument.Filename;
                        [~, fileName] = fileparts(fullFcnPath);
                        tool.updateBatchFunction(fullFcnPath, fileName);
                        % Forget about the generated code
                        tool.createdFunctionDocument = [];
                    end
                    
                else
                    % User closed before saving. Forget about generated
                    % code. Go back.
                    tool.BatchFunctionNameComboBox.Enabled = true;
                    tool.createdFunctionDocument = [];
                    tool.updateBatchFunctionComboBoxFromHistory();
                end
            end
        end
        
        function openBatchFunctionInEditor(tool, varargin)
            matlab.desktop.editor.openDocument(tool.batchFunctionFullFile);
        end
        
        function batchFileBrowse(tool, varargin)
            [fileName, filePath]  = uigetfile('*.m',...                
                getString(message('images:imageBatchProcessor:selectBatchFunction')));
            if(fileName == 0)
                return;
            end
            tool.updateBatchFunction([filePath, filesep, fileName], fileName)                    
        end
        
    end
    
    % Ouput
    methods
        function layoutOutputSection(tool)
            outputPanel = toolpack.component.TSPanel(...
                '140px,f:p',... %columns
                '1dlu, f:p, 1dlu, f:p, 2dlu, f:p:g, 1dlu');
            outputPanel.Name = 'panelOutput';
            tool.OutputSection.add(outputPanel);
            
            outputLabel = toolpack.component.TSLabel(...
                getString(message('images:imageBatchProcessor:outputLabel')));
            outputPanel.add(outputLabel,'xy(1,2)');
            
            tool.OutputNameText = toolpack.component.TSTextField('',10);
            tool.OutputNameText.Name = 'OutputFolderNameText';
            iptui.internal.utilities.setToolTipText(...
                tool.OutputNameText,...
                getString(message('images:imageBatchProcessor:outputNameToolTip')));
            
            addlistener(tool.OutputNameText,'TextEdited',...
                @tool.outputNameEdited);
            addlistener(tool.OutputNameText,'FocusLost',...
                @tool.showOnlyLeafFolder);
                            
            outputPanel.add(tool.OutputNameText,'xy(1,4)');
            
            tool.OutputButton = toolpack.component.TSButton(...
                '',...
                toolpack.component.Icon.OPEN);
            tool.OutputButton.Name = 'OutputBrowseButton';
            iptui.internal.utilities.setToolTipText(...
                tool.OutputButton,...
                getString(message('images:imageBatchProcessor:outputButtonToolTip')));
            
            addlistener(tool.OutputButton, 'ActionPerformed',...
                @tool.browseForOutput);
            outputPanel.add(tool.OutputButton,'xy(2,4)');
            
            
            tool.OutputOverwriteCheckbox = toolpack.component.TSCheckBox(...
                getString(message('images:imageBatchProcessor:overwriteOutputLabel')));
            tool.OutputOverwriteCheckbox.Name = 'OutputOverwriteCheckbox';
            iptui.internal.utilities.setToolTipText(...
                tool.OutputOverwriteCheckbox,...
                getString(message('images:imageBatchProcessor:overwriteOutputToolTip')));
            outputPanel.add(tool.OutputOverwriteCheckbox,'xy(1,6)');
        end
        
        function browseForOutput(tool, varargin)
            dirname = uigetdir(tool.fullOuputDirectoryName);
            if(dirname==0) % cancelled
                return;
            end
            tool.UserSetOutDir = true;
            tool.updateOutputDir(dirname);
        end
        
        function outputNameEdited(tool, varargin)
            if(isempty(tool.OutputNameText.Text))
                % Revert to last known
                tool.showOnlyLeafFolder();
                return;
            end
            
            if(any(tool.OutputNameText.Text == filesep))
                % Assume full path given
                fullOutputFolder = tool.OutputNameText.Text;
            else
                % Assume leaf folder name was updated
                if(isempty(tool.fullOuputDirectoryName))                    
                    rootOutputFolder = pwd;
                else
                    rootOutputFolder = fileparts(tool.fullOuputDirectoryName);
                end
                fullOutputFolder = ...
                    [rootOutputFolder, filesep, tool.OutputNameText.Text];                
            end

            if(fullOutputFolder(end)==filesep)
                % trim trailing fileseps
                fullOutputFolder = fullOutputFolder(1:end-1);
            end         
            
            tool.UserSetOutDir = true;
            tool.updateOutputDir(fullOutputFolder);           
        end
        
        function updateOutputDir(tool, newOutputDir)
            if(strcmpi(tool.fullOuputDirectoryName, newOutputDir))
                %nothing to do;
                return;
            end
            
            if(tool.checkIfInputAndOutputDirectoriesAreTheSame(newOutputDir))
                return;
            end
            
            if(isdir(newOutputDir))
                % Ensure writable
                [~,attribs] = fileattrib(newOutputDir);
                if(~attribs.UserWrite)
                    errordlg(getString(message('images:imageBatchProcessor:nowritePermissions', newOutputDir)),...
                        getString(message('images:imageBatchProcessor:nowritePermissionsTitle')),'modal');
                    return;
                end
            end
            
            tool.fullOuputDirectoryName = newOutputDir;
            
            tool.showOnlyLeafFolder();
            
            % Update state of app
            if(~isempty(tool.imageBatchDataStore))
                tool.imageBatchDataStore.WriteLocation = tool.fullOuputDirectoryName;
            end
            if(~isempty(tool.batchProcessor))
                % Forget about processing already done
                tool.batchProcessor.resetState();
            end
            if(~isempty(tool.imageList))
                tool.updateImageList();
            end
        end
        
        
        function tf = checkIfInputAndOutputDirectoriesAreTheSame(tool, outputDir)
            tf = false;
            if(isempty(tool.imageBatchDataStore))
                % Input not specified yet
                return;
            end
            if(strcmpi(outputDir, ...
                    tool.imageBatchDataStore.ReadLocation))
                % Cannot overwrite input
                eh = errordlg(getString(message('images:imageBatchProcessor:cannotOverwriteInput', outputDir)),...
                    getString(message('images:imageBatchProcessor:cannotOverwriteInputTitle')),...
                    'modal');
                uiwait(eh);
                tf = true;
            end
        end
        
        function showOnlyLeafFolder(tool, varargin)
            if(isempty(tool.fullOuputDirectoryName))
                return;
            end
            % Show only leaf folder name with /, account for directory
            % names with a '.'
            [~, leafFolder, leafExt] = fileparts(tool.fullOuputDirectoryName);
            tool.OutputNameText.Text = [leafFolder, leafExt];
            tool.OutputNameText.Text(end+1) = filesep;
            % Set tooltip to full path
            iptui.internal.utilities.setToolTipText(...
                tool.OutputNameText,tool.fullOuputDirectoryName);            
        end
                        
        function created = createOutputDir(tool)
            if(tool.checkIfInputAndOutputDirectoriesAreTheSame(tool.fullOuputDirectoryName))
                created = false;
            else                
                [created, creationMessage] = mkdir(tool.fullOuputDirectoryName);
                if(~created)
                    errordlg(getString(message('images:imageBatchProcessor:couldNotCreateOutput', tool.fullOuputDirectoryName, creationMessage)),...
                        getString(message('images:imageBatchProcessor:couldNotCreateOutputTitle')),'modal');
                end
            end
        end
        
    end
    
    % Parallel
    methods
        function layoutParallelSection(tool)
            parallelPanel = toolpack.component.TSPanel(...
                '80px',... % columns
                'f:p');
            parallelPanel.Name = 'panelParallel';
            tool.ParallelSection.add(parallelPanel);
            
            tool.ProcessInParallelToggle = toolpack.component.TSToggleButton(...
                getString(message('images:imageBatchProcessor:useParallelLabel')),...
                toolpack.component.Icon(fullfile(matlabroot, 'toolbox/images/icons/desktop_parallel_large.png')));
            tool.ProcessInParallelToggle.Name = 'ParallelModeToggleButton';
            tool.ProcessInParallelToggle.Orientation = toolpack.component.ButtonOrientation.VERTICAL;
            iptui.internal.utilities.setToolTipText(...
                tool.ProcessInParallelToggle ,...
                getString(message('images:imageBatchProcessor:processInParallelToolTip')));
            
            tool.ProcessInParallelToggle.Enabled = false;
            addlistener(tool.ProcessInParallelToggle,'ItemStateChanged',...
                @tool.toggleParallelProcessing);
            parallelPanel.add(tool.ProcessInParallelToggle,'xy(1,1)');
        end
        
        function toggleParallelProcessing(tool, varargin)
            if(tool.ProcessInParallelToggle.Selected)
                % Toggling on
                tool.setState('locked');
                tool.ProcessInParallelToggle.Text = ...
                    getString(message('images:imageBatchProcessor:connecting'));
                iptui.internal.utilities.setStatusBarText(tool.GroupName,...
                    getString(message('images:imageBatchProcessor:connectingToPoolStatus')));
                
                ppool = tool.connectToALocalCluster();
                if(isempty(ppool))
                    % Dont toggle on the switch
                    tool.ProcessInParallelToggle.Selected = false;
                end
                
                iptui.internal.utilities.setStatusBarText(tool.GroupName,'');
                tool.ProcessInParallelToggle.Text = ...
                    getString(message('images:imageBatchProcessor:useParallelLabel'));
                tool.setState('ready');
            end
            
            % else, if toggling off, nothing to do.
        end
        
        function ppool = connectToALocalCluster(tool)
            ppool = gcp('nocreate');
            if(isempty(ppool))
                ppool = tool.tryToCreateLocalPool();
            else
                % A pool was already open, verify its on a local
                % cluster
                if(~isa(ppool.Cluster,'parallel.cluster.Local'))
                    ppool = [];
                    errordlg(...
                        getString(message('images:imageBatchProcessor:poolNotLocalString')),...
                        getString(message('images:imageBatchProcessor:poolNotLocalTitle')),...
                        'modal');
                end
            end
        end
        
        function ppool = tryToCreateLocalPool(~)
            defaultProfile = ...
                parallel.internal.settings.ProfileExpander.getClusterType(parallel.defaultClusterProfile());
            
            if(defaultProfile == parallel.internal.types.SchedulerType.Local)
                % Inform the user of the wait time
                noStr  = getString(message('images:commonUIString:no'));
                yesStr = getString(message('images:commonUIString:yes'));
                selectedStr = questdlg(...
                    getString(message('images:imageBatchProcessor:createParallelPool')),...
                    getString(message('images:imageBatchProcessor:createParallelPoolTitle')),...
                    yesStr, noStr, yesStr);
                
                if(strcmp(selectedStr, noStr))
                    ppool = [];
                else
                    % Create the default pool (ensured local)
                    ppool = parpool;
                    if(isempty(ppool))
                        errordlg(...
                            getString(message('images:imageBatchProcessor:nopoolString')),...
                            getString(message('images:imageBatchProcessor:nopoolTitle')),...
                            'modal');
                    end
                end
            else
                % Default profile not local
                ppool = [];
                errordlg(...
                    getString(message('images:imageBatchProcessor:profileNotLocalString',parallel.defaultClusterProfile())),...
                    getString(message('images:imageBatchProcessor:poolNotLocalTitle')),...
                    'modal');
            end
        end
        
    end
    
    % Process
    methods
        function layoutProcessSection(tool)
            tool.ProcessPanel = toolpack.component.TSPanel(...
                'f:p',... % columns
                'f:p');
            tool.ProcessPanel.Name = 'panelProcess';
            tool.ProcessSection.add(tool.ProcessPanel);
            
            tool.changeToProcessButton();
            tool.ProcessStopButton.Enabled = false;           
        end
        
        function changeToProcessButton(tool)
            tool.ProcessPanel.removeAll;
            tool.ProcessStopButton = toolpack.component.TSSplitButton(...
                getString(message('images:imageBatchProcessor:processSelectedButton')));
            tool.ProcessStopButton.Name = 'ProcessStopButton';
            tool.ProcessStopButton.Orientation = toolpack.component.ButtonOrientation.VERTICAL;
            
            iptui.internal.utilities.setToolTipText(...
                tool.ProcessStopButton,...
                getString(message('images:imageBatchProcessor:processSelectedToolTip')));
            
            tool.ProcessStopButton.Icon = toolpack.component.Icon.RUN_24;
            tool.ProcessStopButton.Text = getString(message('images:imageBatchProcessor:processSelectedButton'));
            tool.ProcessStopButton.Popup       = toolpack.component.TSDropDownPopup(...
                tool.getProcessStopButtonOptions(),'icon_text');
            tool.ProcessStopButton.Popup.Name  = 'ProcessStopButtonDropDown';
            
            addlistener(tool.ProcessStopButton.Popup, 'ListItemSelected',...
                @tool.ProcessStopButtonCallback);
            addlistener(tool.ProcessStopButton, 'ActionPerformed',...
                @tool.processSelected);            
            
            tool.ProcessPanel.add(tool.ProcessStopButton,'xy(1,1)');
        end
        
        function changeToStopButton(tool)
            tool.ProcessPanel.removeAll;
            tool.ProcessStopButton = toolpack.component.TSButton(...
                getString(message('images:imageBatchProcessor:processSelectedButton')));
            tool.ProcessStopButton.Name = 'ProcessStopButton';
            tool.ProcessStopButton.Orientation = toolpack.component.ButtonOrientation.VERTICAL;
            
            iptui.internal.utilities.setToolTipText(...
                tool.ProcessStopButton,...
                getString(message('images:imageBatchProcessor:stopButtonToolTip')));
            
            tool.ProcessStopButton.Icon = toolpack.component.Icon.END_24;
            tool.ProcessStopButton.Text = getString(message('images:imageBatchProcessor:stopButton'));            
            addlistener(tool.ProcessStopButton, 'ActionPerformed',...
                @tool.stopProcessing);            
            
            tool.ProcessPanel.add(tool.ProcessStopButton,'xy(1,1)');
        end
        
        function items = getProcessStopButtonOptions(~)
            items(1) = struct(...
                'Title', getString(message('images:imageBatchProcessor:processSelectedButton')), ...
                'Description', '', ...
                'Icon', toolpack.component.Icon.RUN_16, ...
                'Help', [], ...
                'Header', false);
            items(2) = struct(...
                'Title', getString(message('images:imageBatchProcessor:processAllButton')), ...
                'Description', '', ...
                'Icon', toolpack.component.Icon.RUN_16, ...
                'Help', [], ...
                'Header', false);
        end
               
        function ProcessStopButtonCallback(tool, src,~)
            if src.SelectedIndex == 1
                tool.processSelected();
            elseif src.SelectedIndex == 2
                tool.processAll();
            end
        end
                
        function processSelected(tool, varargin)
            tool.processDelegate(tool.selectedImgInds);
        end
        
        function processAll(tool, varargin)
            tool.processDelegate(1:tool.imageBatchDataStore.NumberOfImages);
        end
        
        function processDelegate(tool, processInds)
            if(tool.currentlyProcessing || tool.stopRequested)
                % Running, or in the processing of stopping
                return;
            end
            
            outPutDirectoryExistsOrWasCreated = tool.createOutputDir();
            
            if(outPutDirectoryExistsOrWasCreated)
                
                if(tool.ProcessInParallelToggle.Selected)
                    % Ensure pool is still open
                    if(isempty(tool.connectToALocalCluster()))
                        tool.ProcessInParallelToggle.Selected = false;
                        return;
                    end
                end
                
                if(tool.OutputOverwriteCheckbox.Selected)
                    tool.batchProcessor.SkipExistingOutputFiles = false;
                else
                    skipCancelOverwrite = tool.outputOverwriteCheck(processInds);
                    switch skipCancelOverwrite
                        case getString(message('images:commonUIString:cancel'))
                            return;
                        case getString(message('images:imageBatchProcessor:skip'))
                            tool.batchProcessor.SkipExistingOutputFiles = true;
                        case getString(message('images:imageBatchProcessor:overwrite'))
                            tool.batchProcessor.SkipExistingOutputFiles = false;
                        otherwise
                            assert(false);
                    end
                end                
                
                tool.imageBatchDataStore.WriteLocation = ...
                    tool.fullOuputDirectoryName;
                
                tool.currentlyProcessing = true;
                tool.setState('processing');
                
                tool.numberOfTodoImages = numel(processInds);
                
                tool.numberOfQueuedImages = 0;
                tool.numberOfDoneImages = 0;                
                tool.numberOfSkippedImages = 0;
                tool.numberOfErroredImages = 0;
                
                tool.indicateProgress();
                tool.batchProcessor.UseParallel = ...
                    tool.ProcessInParallelToggle.Selected;
                
                tool.imageListInFreshState = false;
                
                try
                    % Use onCleanup to reset the App in case of CTRL+C
                    % issued when in this TRY block
                    setDoneWhenDone = onCleanup(@()tool.doneProcessing);
                    tool.ToolGroup.setClosingApprovalNeeded(true);
                    tool.batchProcessor.processSelected(processInds);
                    clear setDoneWhenDone;
                catch ALL
                    % Unexpected
                    rethrow(ALL);
                end                
            end            
        end
        
        function doneProcessing(tool)
            if(~isvalid(tool))
                % tool was closed
                return;
            end
            tool.ToolGroup.setClosingApprovalNeeded(false);
            tool.setState('ready');
            tool.currentlyProcessing = false;
            tool.stopRequested       = false;
        end
        
        function stopProcessing(tool, varargin)
            if(tool.currentlyProcessing)
                tool.stopRequested = true;
            end
        end
        
    end
    
    % Zoom/pan
    methods
        function layoutZoomPanSection(tool)
            zoomPanPanel = toolpack.component.TSPanel( ...
                'f:p', ...              % columns
                'f:p,f:p,f:p');   % rows
            zoomPanPanel.Name = 'panelZoomPan';
            tool.ZoomPanSection.add(zoomPanPanel);
            
            tool.ZoomInButton = toolpack.component.TSToggleButton(...
                getString(message('images:commonUIString:zoomInTooltip')),...
                toolpack.component.Icon.ZOOM_IN_16);
            tool.ZoomInButton.Enabled = false;
            addlistener(tool.ZoomInButton, 'ItemStateChanged', @tool.zoomIn);
            tool.ZoomInButton.Orientation = toolpack.component.ButtonOrientation.HORIZONTAL;
            iptui.internal.utilities.setToolTipText(tool.ZoomInButton,...
                getString(message('images:commonUIString:zoomInTooltip')));
            tool.ZoomInButton.Name = 'btnZoomIn';
            
            tool.ZoomOutButton = toolpack.component.TSToggleButton(...
                getString(message('images:commonUIString:zoomOutTooltip')),...
                toolpack.component.Icon.ZOOM_OUT_16);
            tool.ZoomOutButton.Enabled = false;
            addlistener(tool.ZoomOutButton, 'ItemStateChanged', @tool.zoomOut);
            tool.ZoomOutButton.Orientation = toolpack.component.ButtonOrientation.HORIZONTAL;
            iptui.internal.utilities.setToolTipText(tool.ZoomOutButton,...
                getString(message('images:commonUIString:zoomOutTooltip')));
            tool.ZoomOutButton.Name = 'btnZoomOut';
            
            tool.PanButton = toolpack.component.TSToggleButton(...
                getString(message('images:commonUIString:pan')),...
                toolpack.component.Icon.PAN_16 );
            tool.PanButton.Enabled = false;
            addlistener(tool.PanButton, 'ItemStateChanged', @tool.panImage);
            tool.PanButton.Orientation = toolpack.component.ButtonOrientation.HORIZONTAL;
            iptui.internal.utilities.setToolTipText(tool.PanButton,...
                getString(message('images:commonUIString:pan')));
            tool.PanButton.Name = 'btnPan';
            
            zoomPanPanel.add(tool.ZoomInButton, 'xy(1,1)' );
            zoomPanPanel.add(tool.ZoomOutButton,'xy(1,2)' );
            zoomPanPanel.add(tool.PanButton,'xy(1,3)' );
        end
        
        function zoomIn(tool,hToggle,~)
            if hToggle.Selected
                tool.ZoomOutButton.Selected = false;
                tool.PanButton.Selected = false;
                
                zoom(tool.hImageView,'off');
                hZoomPan = zoom(tool.hImageView);
                hZoomPan.Direction = 'in';
                hZoomPan.Enable = 'on';
            else
                if(~tool.ZoomOutButton.Selected)
                    zoom(tool.hImageView,'off');
                end
            end
        end
        
        function zoomOut(tool,hToggle,~)
            if hToggle.Selected
                tool.ZoomInButton.Selected = false;
                tool.PanButton.Selected = false;
                
                zoom(tool.hImageView,'off');
                hZoomPan = zoom(tool.hImageView);
                hZoomPan.Direction = 'out';
                hZoomPan.Enable = 'on';
            else
                if(~tool.ZoomInButton.Selected)
                    zoom(tool.hImageView,'off');
                end
            end
        end
        
        function panImage(tool,hToggle,~)
            if hToggle.Selected
                tool.ZoomOutButton.Selected = false;
                tool.ZoomInButton.Selected = false;
                
                hZoomPan = pan(tool.hImageView);
                hZoomPan.Enable = 'on';
            else
                pan(tool.hImageView,'off');
            end
        end
    end
    
    % Export
    methods
        function layoutExportSection(tool)
            exportPanel      = toolpack.component.TSPanel('f:p:g, f:p, f:p:g','f:p');
            exportPanel.Name = 'panelExport';
            tool.ExportSection.add(exportPanel);
            
            tool.ExportButton = toolpack.component.TSButton(...
                getString(message('images:imageBatchProcessor:exportButtonLabel')),...
                toolpack.component.Icon.EXPORT_24);
            tool.ExportButton.Name = 'ExportButton';
            iptui.internal.utilities.setToolTipText(...
                tool.ExportButton,...
                getString(message('images:imageBatchProcessor:exportButtonToolTip')));
            tool.ExportButton.Orientation = toolpack.component.ButtonOrientation.VERTICAL;
            tool.ExportButton.Enabled     = false;
            
            addlistener(tool.ExportButton, 'ActionPerformed',...
                @(hobj, evt) tool.exportCallback(hobj,evt));
            
            exportPanel.add(tool.ExportButton,'xy(2,1)');
        end
        
        function exportCallback(tool, varargin)
            codeGenerator = iptui.internal.CodeGenerator();
            templateFile = fullfile(matlabroot, 'toolbox','images','images','+images','+internal','templateBatchProcessingFunction.template');
            codeString = fileread(templateFile);
            
            % Update template with current state
            codeString = strrep(codeString,'<FUNCTION>',tool.batchFunctionName);
            inDir = tool.imageBatchDataStore.ReadLocation;
            inDir = strrep(inDir,'''','''''');
            codeString = strrep(codeString,'<DEFAULTINPUT>',inDir);
            % Pick write location from UI, since process need not be
            % pressed (and so not supplied to the image data store)
            outDir = tool.fullOuputDirectoryName;
            outDir = strrep(outDir,'''','''''');
            codeString = strrep(codeString,'<DEFAULTOUTPUT>',outDir);
            
            if(tool.imageBatchDataStore.IncludeSubdirectories)
                codeString = strrep(codeString, '<INCLUDESUBDIRECTORIES>','true');
            else
                codeString = strrep(codeString, '<INCLUDESUBDIRECTORIES>','false');
            end
            
            if(tool.ProcessInParallelToggle.Selected)
                codeString = strrep(codeString, '<FOR>','parfor');
            else
                codeString = strrep(codeString, '<FOR>','for');
            end
            
            codeString = strrep(codeString, '<DATE>',date);
            
            codeGenerator.addLineWithoutWhitespace(codeString);
            codeGenerator.putCodeInEditor();
        end
    end
    
    % Validation
    methods
        function skipCancelOverwrite = outputOverwriteCheck(tool, processInds)
            iptui.internal.utilities.setStatusBarText(tool.GroupName,...
                getString(message('images:imageBatchProcessor:checkingOutput')));
            skipCancelOverwrite = getString(message('images:imageBatchProcessor:overwrite'));
            
            atLestOneOutputExists = false;
            for ind = processInds
                if(tool.imageBatchDataStore.outputExists(ind))
                    atLestOneOutputExists = true;
                    break;
                end
            end
            
            if(atLestOneOutputExists)
                skipCancelOverwrite = questdlg(getString(message('images:imageBatchProcessor:outputExists')),...
                    getString(message('images:imageBatchProcessor:outputExistsTitle')),...
                    getString(message('images:imageBatchProcessor:overwrite')),...
                    getString(message('images:imageBatchProcessor:skip')),...
                    getString(message('images:commonUIString:cancel')),...
                    getString(message('images:imageBatchProcessor:overwrite')));
            end
            iptui.internal.utilities.setStatusBarText(tool.GroupName,'');
        end
    end
    
    %% HG
    methods
        
        function updateImageList(tool)
            if(isempty(tool.imageList))
                tool.createImageList();
            end
            if(tool.imageListInFreshState)
                % Dont refresh if the last updated image list is still
                % valid. Refresh is heavy.
                tool.imageList.setSelection(1);
                return;
            end
            
            loadedStatus = getString(message('images:imageBatchProcessor:MLoaded', ...
                num2str(tool.imageBatchDataStore.NumberOfImages)));
            iptui.internal.utilities.setStatusBarText(tool.GroupName, loadedStatus);
            
            tool.ToolGroup.setWaiting(true);
            tool.imageList.setContent(tool.imageBatchDataStore);
            tool.ToolGroup.setWaiting(false);
            
            tool.imageListInFreshState = true;
        end
               
        function createImageList(tool)            
            tool.dataBrowserPanel = javaObjectEDT('javax.swing.JPanel');
            tool.dataBrowserPanel.setBackground(java.awt.Color.white);
            tool.dataBrowserPanel.setLayout(javax.swing.BoxLayout(...
                tool.dataBrowserPanel, javax.swing.BoxLayout.Y_AXIS));
            tool.ToolGroup.setDataBrowser(tool.dataBrowserPanel);
            
            tool.imageList = iptui.internal.ImageList(tool.dataBrowserPanel);
            tool.imageList.setSelectionCallback(@tool.imageListClicked);            
        end
                
        function createImageViewFigure(tool)            
            figureName = tool.imageBatchDataStore.ReadLocation;
            tool.hImageView = figure('NumberTitle', 'off',...
                'Name',figureName,...
                'Color','w',...
                'Visible','on',...
                'Tag','ImageView',...
                'IntegerHandle','off',...
                'CloseRequestFcn',[]);
            set(tool.hImageView,'HandleVisibility','off');
            
            % Set the WindowKeyPressFcn to a non-empty function. This is
            % effectively a no-op that executes everytime a key is pressed
            % when the App is in focus. This is done to prevent focus from
            % shifting to the MATLAB command window when a key is typed.
            tool.hImageView.WindowKeyPressFcn = @(~,~)[];
            
            tool.ToolGroup.addFigure(tool.hImageView);
            tool.ToolGroup.getFiguresDropTargetHandler.unregisterInterest(tool.hImageView);

            tool.hSideBySide = iptui.internal.ImageSideBySideDisplay(tool.hImageView);
        end
        
        function imageListClicked(tool, imgInds)
            if(~isvalid(tool))
                return;
            end
            
            tool.selectedImgInds = imgInds;
            selectionStatus = getString(message('images:imageBatchProcessor:NofMSelected', ...
                num2str(numel(imgInds)), num2str(tool.imageBatchDataStore.NumberOfImages)));
            iptui.internal.utilities.setStatusBarText(tool.GroupName, selectionStatus);
            
            tool.updateImageView();
        end
        
        function updateImageView(tool)
            % If multiple selected, show only first
            if(isempty(tool.selectedImgInds))
                % Nothing in image list.
                tool.clearImageView();
                return;
            end
            imgInd = tool.selectedImgInds(1);
            
            if(isempty(tool.hImageView) || ~isvalid(tool.hImageView))
                tool.createImageViewFigure();
            end
            
            if(~isempty(tool.batchProcessor) ...
                    && tool.batchProcessor.visited(imgInd))
                tool.updateImageViewWithTwoImages(imgInd);
            else
                tool.updateImageViewWithOneImage(imgInd);
            end
        end
        
        function updateImageViewWithOneImage(tool,imgInd)
            tool.clearImageView();
            try            
                iptui.internal.imshowWithCaption(tool.hImageView, ...
                    tool.imageBatchDataStore.read(imgInd),...
                    [getString(message('images:commonUIString:inputImage')), ' ' num2str(imgInd)], ...
                    'im');
                tool.resetAndEnablePanZoom();                
            catch ALL
                tool.showOneException(ALL);
            end
        end
        
        function updateImageViewWithTwoImages(tool,imgInd)
            if(tool.batchProcessor.errored(imgInd))
                tool.showOneImageOneException(imgInd);
                return;
            end
            
            tool.clearImageView();
            try
                tool.hSideBySide.showImages(...
                    tool.imageBatchDataStore.read(imgInd), ...
                    [getString(message('images:commonUIString:inputImage')), ' ' num2str(imgInd)], ...
                    tool.imageBatchDataStore.readOutput(imgInd),...
                    [getString(message('images:commonUIString:outputImage')), ' ' num2str(imgInd)]);            
                tool.resetAndEnablePanZoom();                                
            catch ALL
                tool.showOneException(ALL);
            end
        end
        
        function showOneException(tool, exception)
            tool.clearImageView();
            
            tool.ZoomInButton.Enabled  = false;
            tool.ZoomOutButton.Enabled = false;
            tool.PanButton.Enabled     = false;
            tool.hExceptionDisplay = ...
                iptui.internal.ExceptionDisplay(tool.hImageView, exception);
        end
        
        function showOneImageOneException(tool, imgInd)
            tool.clearImageView();
            exception = tool.batchProcessor.getException(imgInd);
            try
                hImagePanel = tool.hSideBySide.lPanel;
                hImagePanel.Visible = 'on';
                
                iptui.internal.imshowWithCaption(hImagePanel, ...
                    tool.imageBatchDataStore.read(imgInd),...
                    [getString(message('images:commonUIString:inputImage')), ' ' num2str(imgInd)], ...
                    'im');
                
                % Reset pan zoom
                tool.ZoomInButton.Enabled = true;
                tool.ZoomOutButton.Enabled = true;
                tool.PanButton.Enabled = true;
                
                tool.ZoomInButton.Selected = false;
                tool.ZoomOutButton.Selected = false;
                tool.PanButton.Selected = false;
                
                hExceptionPanel = tool.hSideBySide.rPanel;
                hExceptionPanel.Visible = 'on';
                tool.hExceptionDisplay = ...
                    iptui.internal.ExceptionDisplay(hExceptionPanel, exception);
            catch ALL
                tool.showOneException(ALL);
            end
        end

        function resetAndEnablePanZoom(tool)
            tool.ZoomInButton.Enabled = true;
            tool.ZoomOutButton.Enabled = true;
            tool.PanButton.Enabled = true;
            tool.ZoomInButton.Selected = false;
            tool.ZoomOutButton.Selected = false;
            tool.PanButton.Selected = false;
        end
        
        function clearImageView(tool)
            delete(tool.hExceptionDisplay);        
            if(~isempty(tool.hImageView) && tool.hImageView.isvalid)
                drawnow;
                %clf(tool.hImageView);
                ch = tool.hImageView.Children;
                for cind=1:numel(ch)
                    if(isa(ch(cind),'matlab.ui.container.Panel'))
                        % Remove all images in panel
                        delete(ch(cind).Children);
                        % Hide for reuse later
                        ch(cind).Visible='off';
                    else
                        delete(ch(cind));
                    end
                end
                tool.hImageView.SizeChangedFcn = [];
            end
            % flush clearing
            drawnow;
        end
        
    end
    
    %% UI State control
    methods
        function setState(tool, state)
            switch state
                case 'notReady'
                    tool.LoadButton.Enabled                      = true;
                    tool.BatchFunctionNameComboBox.Enabled       = true;
                    tool.BatchFunctionBrowseButton.Enabled       = true;
                    tool.BatchFunctionOpenInEditorButton.Enabled = false;
                    tool.BatchFunctionCreateButton.Enabled       = true;
                    tool.OutputNameText.Enabled                  = true;
                    tool.OutputButton.Enabled                    = true;
                    tool.OutputOverwriteCheckbox.Enabled         = true;
                    tool.ProcessInParallelToggle.Enabled         = false;
                    tool.ProcessStopButton.Enabled              = false;
                    tool.ZoomInButton.Enabled                    = false;
                    tool.ZoomOutButton.Enabled                   = false;
                    tool.PanButton.Enabled                       = false;
                    tool.ExportButton.Enabled                    = false;
                case 'ready'
                    tool.LoadButton.Enabled                      = true;
                    tool.BatchFunctionNameComboBox.Enabled       = true;
                    tool.BatchFunctionBrowseButton.Enabled       = true;
                    tool.BatchFunctionOpenInEditorButton.Enabled = true;
                    tool.BatchFunctionCreateButton.Enabled       = true;
                    tool.OutputNameText.Enabled                  = true;
                    tool.OutputButton.Enabled                    = true;
                    tool.OutputOverwriteCheckbox.Enabled         = true;
                    tool.ProcessInParallelToggle.Enabled         = true;
                    tool.ProcessStopButton.Enabled              = true;
                    tool.ZoomInButton.Enabled                    = true;
                    tool.ZoomOutButton.Enabled                   = true;
                    tool.PanButton.Enabled                       = true;
                    tool.ExportButton.Enabled                    = true;
                    
                    tool.changeToProcessButton();
                    
                case 'processing'
                    tool.LoadButton.Enabled                      = false;
                    tool.BatchFunctionNameComboBox.Enabled       = false;
                    tool.BatchFunctionBrowseButton.Enabled       = false;
                    tool.BatchFunctionOpenInEditorButton.Enabled = false;
                    tool.BatchFunctionCreateButton.Enabled       = false;
                    tool.OutputNameText.Enabled                  = false;
                    tool.OutputButton.Enabled                    = false;
                    tool.OutputOverwriteCheckbox.Enabled         = false;
                    tool.ProcessInParallelToggle.Enabled         = false;
                    tool.ProcessStopButton.Enabled              = true;
                    tool.ExportButton.Enabled                    = false;
                    
                    tool.changeToStopButton();
                    
                case 'locked'
                    tool.LoadButton.Enabled                      = false;
                    tool.BatchFunctionNameComboBox.Enabled       = false;
                    tool.BatchFunctionBrowseButton.Enabled       = false;
                    tool.BatchFunctionOpenInEditorButton.Enabled = false;
                    tool.BatchFunctionCreateButton.Enabled       = false;
                    tool.OutputNameText.Enabled                  = false;
                    tool.OutputButton.Enabled                    = false;
                    tool.OutputOverwriteCheckbox.Enabled         = false;
                    tool.ProcessInParallelToggle.Enabled         = false;
                    tool.ProcessStopButton.Enabled              = false;
                    tool.ZoomInButton.Enabled                    = false;
                    tool.ZoomOutButton.Enabled                   = false;
                    tool.PanButton.Enabled                       = false;
                    tool.ExportButton.Enabled                    = false;
                    
                otherwise
                    assert(false,'unknown state requested');
            end
        end
        
        function setReadyIfPossible(tool)
            if(~isempty(tool.imageBatchDataStore))
                tool.updateImageList();
                if(~isempty(tool.batchFunctionHandle))
                    if(isempty(tool.fullOuputDirectoryName))
                        % Create a default output if needed
                        defaultOutputDir = ...
                            [tool.imageBatchDataStore.ReadLocation, '_', tool.batchFunctionName];
                        tool.updateOutputDir(defaultOutputDir);
                    end
                    
                    if(~isempty(tool.fullOuputDirectoryName))
                        % Either user specified or default output dir is
                        % specified
                        tool.batchProcessor = images.internal.BatchProcessor(...
                            tool.imageBatchDataStore,tool.batchFunctionHandle);
                        % wire up
                        tool.batchProcessor.beginning = @tool.indicateImageBeginning;
                        tool.batchProcessor.done      = @tool.indicateImageDone;
                        tool.batchProcessor.cleanup   = @tool.cleanUp;
                        tool.batchProcessor.checkIfStopRequested = @tool.checkIfStopRequested;
                        
                        tool.setState('ready');
                    end
                end
            end
        end
    end
    
    %% Handle callback functions from the batchprocessor
    methods
        function indicateImageBeginning(tool, imgInd)
            tool.numberOfQueuedImages = tool.numberOfQueuedImages+1;
            tool.imageList.setFileState(imgInd,'queued');
            tool.indicateProgress();
        end
        
        function indicateImageDone(tool, imgInd)
            
            if(~isvalid(tool))
                % Tool has closed
                return
            end
           
            if(~tool.batchProcessor.visited(imgInd))
                % 'done' was invoked before the output was visited, i.e
                % processing did not complete (potential dbquit midway),
                % clean up the status for this image.
                tool.cleanUp(imgInd);
                return;
            end
            
            if(tool.batchProcessor.skipped(imgInd))
                tool.imageList.setFileState(imgInd,'skipped');
                tool.numberOfSkippedImages = tool.numberOfSkippedImages+1;
            else
                if(tool.batchProcessor.errored(imgInd))
                    tool.imageList.setFileState(imgInd,'errored');
                    tool.numberOfErroredImages = tool.numberOfErroredImages+1;
                else
                    tool.imageList.setFileState(imgInd,'done');
                    tool.numberOfDoneImages = tool.numberOfDoneImages+1;
                end
            end
            
            if(~isempty(tool.selectedImgInds) &&...
                    imgInd == tool.selectedImgInds(1))
                % Update currently selected image immediately
                tool.updateImageView();
            end
            
            tool.indicateProgress();
        end
        
        function indicateProgress(tool)
            progressStateString = '';
            if(tool.ProcessInParallelToggle.Selected==true)
                progressStateString = [num2str(tool.numberOfQueuedImages) ' ',...
                    getString(message('images:imageBatchProcessor:queued')),...
                    '.'];                
            end
            
            progressStateString = [progressStateString ' ' ,...
                num2str(tool.numberOfDoneImages),' ',...
                getString(message('images:imageBatchProcessor:doneOf')),...
                ' ',num2str(tool.numberOfTodoImages) '.'];
            
            if(tool.numberOfSkippedImages~=0)
                progressStateString = [progressStateString ' ',...
                    num2str(tool.numberOfSkippedImages),' ',...
                    getString(message('images:imageBatchProcessor:existedSkipped')),...
                    '.'];
            end
            if(tool.numberOfErroredImages~=0)
                progressStateString = [progressStateString ' ',...
                    num2str(tool.numberOfErroredImages),' ',...
                    getString(message('images:imageBatchProcessor:errored')),...
                    '.'];
            end
            
            tool.jProgressLabel.setText(progressStateString);
        end
        
        function cleanUp(tool, inds)
            % Queued images did not complete, clean up their status
            for ind = inds
                tool.imageList.setFileState(ind,'default');
            end
        end
        
        function stopnow = checkIfStopRequested(tool)
            % Give the stop button callback a chance
            drawnow;
            
            if(~isvalid(tool))
                % Tool has closed
                stopnow = true;
                return
            end
            
            stopnow = tool.stopRequested;
            if(stopnow)
                % Request will already be relayed to backend
                tool.stopRequested = false;
                tool.ProcessStopButton.Text = getString(message('images:imageBatchProcessor:stoppingButton'));
            end
        end
        
    end
    
    
end
