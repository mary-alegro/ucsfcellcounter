classdef ImageList < handle
    
    %     Copyright 2014 The MathWorks, Inc.
    
    properties (Hidden = true)
        HParent;
        
        JInputDirectoryLabel;
        JFilterDropDown;
        JImageStrip;
        JImageStripContainer;
        
        JClickCallback;
        JViewPortCallback;
        
        AllRows;
        InFilterInds;
        
        ImageStore;
        
        FileStates;
        STATE_DEFAULT    = 0;
        ICON_PLACEHOLDER = fullfile(matlabroot, 'toolbox/images/icons/PlaceHolderImage_72.png');
        STATE_QUEUED     = 1
        ICON_QUEUED      = fullfile(matlabroot, 'toolbox/images/icons/Queued_16.png');
        STATE_DONE       = 2;
        ICON_DONE        = fullfile(matlabroot, 'toolbox/images/icons/Completed_16.png');
        STATE_SKPPED     = 3;
        ICON_SKIPPED     = fullfile(matlabroot, 'toolbox/images/icons/Skipped_16.png');
        STATE_ERRORED    = 4;
        ICON_ERRORED     = fullfile(matlabroot, 'toolbox/images/icons/Error_16.png');
        
        ICON_CORRUPT     = fullfile(matlabroot, 'toolbox/images/icons/CorruptedImage_72.png');
        
        ThumbnailDir  = '';
        
        SelectionCallback = @(inds)[];
        
        ServicedClicks = [];
    end
    
    properties (Constant = true)        
        % Controls the height of each cell in the list
        CELLHEIGHT = 100; %px
        
        % Controls the square size of the thumbnail. Thumbnail will fit
        % into this square, resized to preserve aspect ratio.
        THUMBNAILSIZE = 72; %px
    end
    
    %% API
    methods
        function self = ImageList(parentHandle)
            self.HParent = parentHandle;
            
            % Input directory name
            self.JInputDirectoryLabel = javaObjectEDT('javax.swing.JLabel','');
            self.JInputDirectoryLabel.setName('inputFolderLabel');            
            self.JInputDirectoryLabel.setAlignmentX(java.awt.Component.LEFT_ALIGNMENT);            
            parentHandle.add(self.JInputDirectoryLabel);           
                        
            % File state filter
            self.JFilterDropDown = javaObjectEDT('javax.swing.JComboBox',...
                {getString(message('images:imageList:showAll')), ...
                getString(message('images:imageList:showErrored')),...
                getString(message('images:imageList:showSkipped')),...
                getString(message('images:imageList:showCompleted'))});
            self.JFilterDropDown.setName('filterDropDown');
            self.JFilterDropDown.setAlignmentX(java.awt.Component.LEFT_ALIGNMENT);            
            jDimension = self.JFilterDropDown.getMaximumSize();
            jDimension.height = 0; % i.e use minimum required
            self.JFilterDropDown.setMaximumSize(jDimension);
            parentHandle.add(self.JFilterDropDown);           
            
            % Thumbnail strip
            self.JImageStrip = javaObjectEDT(...
                com.mathworks.toolbox.images.ImageStrip(self.CELLHEIGHT));
            jScrollPane = self.JImageStrip.getScrollPane();
            jScrollPane.setAlignmentX(java.awt.Component.LEFT_ALIGNMENT);
            parentHandle.add(jScrollPane);           
                                               
            set(self.JFilterDropDown,'ActionPerformedCallback',...
                @(varargin)self.applyFilter());
            
            % Wire up MATLAB callbacks to left click on jlist
            hSelectionCallback  = handle(self.JImageStrip.getSelectionCallback);
            self.JClickCallback = ...
                handle.listener(hSelectionCallback,...
                'delayed', @self.leftClickCallback);
            
            % Wire up MATLAB callbacks to view port changes in jlist
            hViewPortChangedCallback  = handle(self.JImageStrip.getViewPortCallback);
            self.JViewPortCallback = ...
                handle.listener(hViewPortChangedCallback,...
                'delayed', @self.jViewPortChanged);
        end
        
        function delete(self)
            try
                if(~isempty(self.ThumbnailDir))
                    rmdir(self.ThumbnailDir,'s');
                end
            catch ALL %#ok<NASGU>
                % Not fatal, but no clean recovery possible.
            end
        end
        
        function setContent(self, ImageStore_)
            assert(isa(ImageStore_, 'images.internal.ImageBatchDataStore'));
            assert(ImageStore_.NumberOfImages>0);
            
            % Clear list
            self.JImageStrip.setDataModel([]);
            self.setSelection([]);
            
            % Forget about previous clicks, content has changed
            self.ServicedClicks = [];
                        
            self.ImageStore = ImageStore_;
            self.JInputDirectoryLabel.setText(ImageStore_.ReadLocation);
            self.JInputDirectoryLabel.setToolTipText(ImageStore_.ReadLocation);
            
            % Remove old cache if it existed
            if(exist(self.ThumbnailDir,'dir'))                
                rmdir(self.ThumbnailDir,'s');
            end
            
            % Create new
            self.ThumbnailDir = tempname;
            try
                mkdir(self.ThumbnailDir);
                mkdir([self.ThumbnailDir, filesep, 'output']);
            catch ALL
                assert(false, ['Unable to create temporary cache '...
                    self.ThumbnailDir, ' on disk. ', ALL.message]);
            end
            
            % Flush states
            self.FileStates = zeros(1, self.ImageStore.NumberOfImages);
            % All images are filtered in by default (Show All)
            self.JFilterDropDown.setSelectedIndex(0); % 'Show All'
            self.InFilterInds = 1:self.ImageStore.NumberOfImages;
            
            % Show placeholders initially
            self.AllRows = cell(1,self.ImageStore.NumberOfImages);
            for imgInd = 1:self.ImageStore.NumberOfImages
                self.AllRows{imgInd} = self.placeHolderRow(imgInd);
            end
            
            self.filterImageRows();
            self.setSelection(1);
            self.createVisibleRowThumbnails();            
        end
        
        function setSelectionCallback(self, callbackfcn)
            self.SelectionCallback = callbackfcn;
        end
        
        function setSelection(self,rowInds)
            % Convert to 0 based java index
            self.JImageStrip.setSelection(rowInds-1);
        end
        
        function setFileState(self, imgInd, state)
            state = lower(state);
            switch(state)
                case 'default'
                    self.FileStates(imgInd) = self.STATE_DEFAULT;
                case 'queued'
                    self.FileStates(imgInd) = self.STATE_QUEUED;
                case 'done'
                    if(self.FileStates(imgInd) == self.STATE_DONE)
                        % Was already done, now 're-done',
                        % refresh output thumbnail only
                        self.createOutputThumbnail(imgInd);
                    else
                        self.FileStates(imgInd) = self.STATE_DONE;
                    end
                case 'skipped'
                    self.FileStates(imgInd) = self.STATE_SKPPED;
                case 'errored'
                    self.FileStates(imgInd) = self.STATE_ERRORED;
                otherwise
                    assert(false, 'unknown state for image list box');
            end
            self.filterImageRows();           
            self.createVisibleRowThumbnails();
        end
    end
    
    %% Helpers
    methods (Hidden = true)        
                        
        function applyFilter(self, varargin)
            % Filter dropdown callback
            self.setSelection([]);
            self.filterImageRows();            
            if(numel(self.InFilterInds)>0)
                self.setSelection(1);
            end            
            self.JImageStrip.redrawList();
        end
        
        function filterImageRows(self)
            switch(self.JFilterDropDown.getSelectedIndex)
                case 0
                    % all
                    self.InFilterInds = 1:numel(self.FileStates);
                case 1
                    % errored
                    self.InFilterInds = find(self.FileStates == self.STATE_ERRORED);
                case 2
                    % skipped
                    self.InFilterInds = find(self.FileStates == self.STATE_SKPPED);
                case 3
                    % done
                    self.InFilterInds = find(self.FileStates == self.STATE_DONE);
                otherwise
                    assert(false, 'unknown filter drop down value');
            end           
            % Always keep image list model in sync with InFilterInds
            data = self.AllRows(self.InFilterInds);
            self.JImageStrip.setDataModel(data);
            if(isempty(data))
                self.setSelection([]);
            end
        end
        
        function leftClickCallback(self, varargin)
            jInds = self.JImageStrip.getSelection();            
            imgInds = self.InFilterInds(jInds+1);
            if(~isequal(imgInds,self.ServicedClicks))                                
                % Servicing is heavy, dont double post
                self.ServicedClicks = imgInds;
                self.SelectionCallback(imgInds);
            end
        end
        
        function rowInds = inViewIndices(self)
            minmax = self.JImageStrip.getInViewIndices();
            % Convert from 0 based indexing
            topRowInd = minmax(1)+1;
            bottomRowInd = minmax(2)+1;
            if(bottomRowInd==0)
                % No contents
                rowInds = [];
            else
                rowInds = topRowInd : bottomRowInd;
            end
        end
        
        function jViewPortChanged(self, varargin)            
            % On fast view port changes, MATLAB drops selection callbacks,
            % so ensure we catch up when the view port changes (coalesced).
            self.leftClickCallback();
            self.createVisibleRowThumbnails();
        end
        
        function createVisibleRowThumbnails(self)
            rowInds = self.inViewIndices();
            % Handle case when filtered list is shorter than number of
            % visible rows
            if(numel(self.InFilterInds)< numel(rowInds))
                rowInds = rowInds(1:numel(self.InFilterInds));
            end
            imgInds = self.InFilterInds(rowInds);
            
            for imgInd = imgInds
                switch (self.FileStates(imgInd))
                    case self.STATE_DEFAULT
                        self.AllRows{imgInd} = self.defaultRow(imgInd);
                    case self.STATE_QUEUED
                        self.AllRows{imgInd} = self.queuedRow(imgInd);
                    case self.STATE_DONE
                        self.AllRows{imgInd} = self.doneRow(imgInd);
                    case self.STATE_SKPPED
                        self.AllRows{imgInd} = self.skippedRow(imgInd);
                    case self.STATE_ERRORED
                        self.AllRows{imgInd} = self.erroredRow(imgInd);
                    otherwise
                        assert(false, 'unknown state');
                end
                % Update model based on current filter
                self.filterImageRows();
                % Redraw each thumbnail
                self.JImageStrip.redrawList();
            end
            % This is required when imgInds is empty to clear the list
            self.JImageStrip.redrawList();
        end
        
    end
    
    %% Row creators
    methods(Hidden = true)
        
        function rowStr = numberAndFileNameRow(~, num, name)
            rowStr = [
                '<table><tr>',...
                '<td width="20px" align="center"><font size ="2"> ' num2str(num) '</td>'...
                '<td              align="center"><font size ="2"> ', name,'</td>'...
                '</tr></table>'];
        end
        
        function str = placeHolderRow(self, imgInd)
            [~, fileName] = self.ImageStore.getInputImageName(imgInd);
            thumbnailFile = self.ICON_PLACEHOLDER;
            str = ...
                ['<html>',...
                self.numberAndFileNameRow(imgInd, fileName),...
                '<table><tr>',...
                '<td width="20px"></td>',...
                '<td width="72px" align="left" valign="top"><img src="file:',thumbnailFile,'"/></td>',...
                '</tr></table>',...
                '</html> '];
        end
        
        function str = defaultRow(self, imgInd)
            [~, fileName] = self.ImageStore.getInputImageName(imgInd);
            thumbnailFile = fullfile(self.ThumbnailDir,[num2str(imgInd), '.jpg']);
            % Create thumbnails if they dont exist
            if(~exist(thumbnailFile,'file'))
                try
                    im = self.ImageStore.read(imgInd);
                    self.createThumbnail(im, thumbnailFile);
                catch ALL %#ok<NASGU>
                    thumbnailFile = self.ICON_CORRUPT;
                end
            end
            str = ...
                ['<html>',...
                self.numberAndFileNameRow(imgInd, fileName),...
                '<table><tr>',...
                '<td width="20px"></td>',...
                '<td width="72px" align="left" valign="top"><img src="file:',thumbnailFile,'"/></td>',...
                '</tr></table>',...
                '</html> '];
        end
        
        function str = queuedRow(self, imgInd)
            [~, fileName] = self.ImageStore.getInputImageName(imgInd);
            thumbnailFile = fullfile(self.ThumbnailDir,[num2str(imgInd), '.jpg']);
            % Create thumbnails if they dont exist
            if(~exist(thumbnailFile,'file'))
                try
                    im = self.ImageStore.read(imgInd);
                    self.createThumbnail(im, thumbnailFile);
                catch ALL %#ok<NASGU>
                    thumbnailFile = self.ICON_CORRUPT;
                end
            end
            str = ...
                ['<html>',...
                self.numberAndFileNameRow(imgInd, fileName),...
                '<table><tr>',...
                '<td width="20px" align="center" valign="top"><img src="file:',self.ICON_QUEUED,'"/></td>',...
                '<td width="72px" align="left" valign="top"><img src="file:',thumbnailFile,'"/></td>',...
                '</tr></table>',...
                '</html> '];
        end
        
        function str = doneRow(self, imgInd)
            [~, fileName] = self.ImageStore.getInputImageName(imgInd);
            thumbnailFileA = fullfile(self.ThumbnailDir,[num2str(imgInd), '.jpg']);
            % Create thumbnails if they dont exist
            if(~exist(thumbnailFileA,'file'))
                try
                    im = self.ImageStore.read(imgInd);
                    self.createThumbnail(im, thumbnailFileA);
                catch ALL %#ok<NASGU>
                    thumbnailFileA = self.ICON_CORRUPT;
                end
            end
            thumbnailFileB = createOutputThumbnail(self, imgInd);
            str = ...
                ['<html>',...
                self.numberAndFileNameRow(imgInd, fileName),...
                '<table><tr>',...
                '<td width="20px" align="center" valign="top"><img src="file:',self.ICON_DONE,'"/></td>',...
                '<td width="72px" align="left" valign="top"><img src="file:',thumbnailFileA,'"/></td>',...
                '<td width="72px" align="left" valign="top"><img src="file:',thumbnailFileB,'"/></td>',...
                '</tr></table>',...
                '</html> '];
        end
        
        function str = skippedRow(self, imgInd)
            [~, fileName] = self.ImageStore.getInputImageName(imgInd);
            thumbnailFileA = fullfile(self.ThumbnailDir,[num2str(imgInd), '.jpg']);
            % Create thumbnails if they dont exist
            if(~exist(thumbnailFileA,'file'))
                try
                    im = self.ImageStore.read(imgInd);
                    self.createThumbnail(im, thumbnailFileA);
                catch ALL %#ok<NASGU>
                    thumbnailFileA = self.ICON_CORRUPT;
                end
            end
            thumbnailFileB = fullfile(self.ThumbnailDir,[num2str(imgInd), 'B.jpg']);
            % Create thumbnails if they dont exist
            if(~exist(thumbnailFileB,'file'))
                try
                    im = self.ImageStore.readOutput(imgInd);
                    self.createThumbnail(im, thumbnailFileB);
                catch ALL %#ok<NASGU>
                    thumbnailFileB = self.ICON_CORRUPT;
                end
            end
            str = ...
                ['<html>',...
                self.numberAndFileNameRow(imgInd, fileName),...
                '<table><tr>',...
                '<td width="20px" align="center" valign="top"><img src="file:',self.ICON_SKIPPED,'"/></td>',...
                '<td width="72px" align="left" valign="top"><img src="file:',thumbnailFileA,'"/></td>',...
                '<td width="72px" align="left" valign="top"><img src="file:',thumbnailFileB,'"/></td>',...
                '</tr></table>',...
                '</html> '];
        end
        
        function str = erroredRow(self, imgInd)
            [~, fileName] = self.ImageStore.getInputImageName(imgInd);
            thumbnailFileA = fullfile(self.ThumbnailDir,[num2str(imgInd), '.jpg']);
            % Create thumbnails if they dont exist
            if(~exist(thumbnailFileA,'file'))
                try
                    im = self.ImageStore.read(imgInd);
                    self.createThumbnail(im, thumbnailFileA);
                catch ALL %#ok<NASGU>
                    thumbnailFileA = self.ICON_CORRUPT;
                end
            end
            
            str = ...
                ['<html>',...
                self.numberAndFileNameRow(imgInd, fileName),...
                '<table><tr>',...
                '<td width="20px" align="center" valign="top"><img src="file:',self.ICON_ERRORED,'"/></td>',...
                '<td width="72px" align="left" valign="top"><img src="file:',thumbnailFileA,'"/></td>',...
                '</tr></table>',...
                '</html> '];
        end
        
        function createThumbnail(self, im, thumbnailFile)
            % Create thumbnails that will fit in
            % THUMBNAILSIZExTHUMBNAILSIZE while preserving the aspect ratio
            if(size(im,1)>size(im,2))
                thumbnail = imresize(im,[self.THUMBNAILSIZE, NaN],'nearest');
            else
                thumbnail = imresize(im,[NaN, self.THUMBNAILSIZE],'nearest');
            end
            
            % JPG needs uint8, scale to range of data
            if(~isa(thumbnail,'uint8'))
                minPix = min(thumbnail(:));
                thumbnail = thumbnail - minPix;
                maxPix = max(thumbnail(:));
                thumbnail = uint8(double(thumbnail)/double(maxPix) *255);
            end
            
            imwrite(thumbnail, thumbnailFile);
        end
        
        function thumbnailFile = createOutputThumbnail(self, imgInd)
            thumbnailFile = fullfile(self.ThumbnailDir,[num2str(imgInd), 'B.jpg']);
            % Create thumbnails (overwrite if it already exists)
            try
                im = self.ImageStore.readOutput(imgInd);
                self.createThumbnail(im, thumbnailFile);
            catch ALL %#ok<NASGU>
                thumbnailFile = self.ICON_CORRUPT;
            end
        end
        
        
    end
end