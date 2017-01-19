classdef RefineTabManager < handle
   %RefineTabManager - Refine modal tab and associated management.
   
   % Copyright 2014, The MathWorks Inc.
   
   properties
       Tab
   end
   
   properties (Access=private)
       SegmentationCore
       
       % Widgets
       ClearBorderCheckBox
       FillHolesCheckBox
       MinRegionSlider
       MaxRegionSlider
       AcceptButton
       CancelButton
       
       % Listeners
       RemoveArtifactsListener
       MinRegionListener
       MaxRegionListener
       
       % Slider Values
       MinRegionSize
       MaxRegionSize
   end
   
   events
       CloseRefineTab
   end
   
   methods
       function self = RefineTabManager(tool)
           
           tabName = tool.TabNames.Refine;
           self.Tab = toolpack.desktop.ToolTab(tabName,getMessageString('refineSegmentationTab'));
           
           getImageData(self,tool);
           addTabWidgets(self);
           addTabListeners(self);
           
           tool.RefineTab = self;
       end
   end
   
   methods (Access=private)
       function getImageData(self,tool)
            %getImageData - Store any image data needed.
            
            self.SegmentationCore = tool.SegmentationCore;
        end
        
        function addTabWidgets(self)
            %addTabWidgets - add widgets to temporary tab.
            
            addRemoveArtifactsWidgets(self);
            addRemoveRegionsWidgets(self);
            addCloseWidgets(self);
        end
        
        function addRemoveArtifactsWidgets(self)
            
            self.ClearBorderCheckBox = toolpack.component.TSCheckBox(...
                getMessageString('clearBorder'),false);
            self.ClearBorderCheckBox.Name = 'chkClearBorder';
            
            iptui.internal.utilities.setToolTipText(self.ClearBorderCheckBox,...
                getMessageString('clearBorderTooltip'));

            self.FillHolesCheckBox = toolpack.component.TSCheckBox(...
                getMessageString('fillHoles'),false);
            self.FillHolesCheckBox.Name = 'chkFillHoles';
            
            iptui.internal.utilities.setToolTipText(self.FillHolesCheckBox,...
                getMessageString('fillHolesTooltip'));

            removeArtifactsPanel = toolpack.component.TSPanel('f:p','10px,f:p,6px,f:p');
            add(removeArtifactsPanel,self.ClearBorderCheckBox,'xy(1,2)');
            add(removeArtifactsPanel,self.FillHolesCheckBox,'xy(1,4)');
            
            miscSection = self.Tab.addSection('RemoveArtifacts',...
                getMessageString('removeArtifacts'));

            add(miscSection,removeArtifactsPanel);
        end
        
        function addRemoveRegionsWidgets(self)
            
            smallerThanLabel = toolpack.component.TSLabel(getMessageString('minSize'));
            largerThanLabel  = toolpack.component.TSLabel(getMessageString('maxSize'));
            
            iptui.internal.utilities.setToolTipText(smallerThanLabel,...
                getMessageString('minSizeTooltip'));
            iptui.internal.utilities.setToolTipText(largerThanLabel,...
                getMessageString('maxSizeTooltip'));
            
            [minArea,maxArea] = getSliderLimits(self);
            
            % Update cached slider values
            self.MinRegionSize = minArea;
            self.MaxRegionSize = maxArea;
            
            self.MinRegionSlider  = toolpack.component.TSSlider(minArea,maxArea,minArea);
            self.MinRegionSlider.Name = 'sliderSmallerThan';
            iptui.internal.utilities.setToolTipText(self.MinRegionSlider,getMessageString('minSizeSliderTooltip'));
            
            self.MaxRegionSlider  = toolpack.component.TSSlider(minArea,maxArea,maxArea);
            self.MaxRegionSlider.Name = 'sliderLargerThan';
            iptui.internal.utilities.setToolTipText(self.MaxRegionSlider,getMessageString('maxSizeSliderTooltip'));
            
            removeRegionsPanel = toolpack.component.TSPanel('f:p,6px,120px','f:p,f:p');
            
            add(removeRegionsPanel,smallerThanLabel,'xy(1,1)');
            add(removeRegionsPanel,largerThanLabel,'xy(1,2)');
            add(removeRegionsPanel,self.MinRegionSlider,'xy(3,1)');
            add(removeRegionsPanel,self.MaxRegionSlider,'xy(3,2)');
            
            removeRegionsSection = self.Tab.addSection('RemoveRegions',getMessageString('removeRegions'));
            add(removeRegionsSection,removeRegionsPanel);
            
        end
        
        function addCloseWidgets(self)
             
            self.CancelButton = toolpack.component.TSButton(getMessageString('cancel'),toolpack.component.Icon.CLOSE_24);
            self.CancelButton.Name = 'btnCancelRefine';
            self.CancelButton.Orientation = toolpack.component.ButtonOrientation.VERTICAL;
            iptui.internal.utilities.setToolTipText(self.CancelButton,getMessageString('cancelRefineTooltip'));
            
            self.AcceptButton = toolpack.component.TSButton(getMessageString('accept'),toolpack.component.Icon.CONFIRM_24);
            self.AcceptButton.Name = 'btnAcceptRefine';
            self.AcceptButton.Orientation = toolpack.component.ButtonOrientation.VERTICAL;
            iptui.internal.utilities.setToolTipText(self.AcceptButton,getMessageString('acceptRefineTooltip'));
            
            closePanel = toolpack.component.TSPanel('f:p,f:p','f:p');
            add(closePanel,self.AcceptButton,'xy(1,1)');
            add(closePanel,self.CancelButton,'xy(2,1)');
            
            closeSection = self.Tab.addSection('Close',getMessageString('close'));
            add(closeSection,closePanel);
        end
        
        function addTabListeners(self)
            
            % Remove artifacts
            self.RemoveArtifactsListener = ...
                addlistener([self.ClearBorderCheckBox self.FillHolesCheckBox],'ItemStateChanged',@(~,~)removeArtifactsCallback(self));
            
            % Remove regions
            self.MinRegionListener = ...
                addlistener(self.MinRegionSlider,'StateChanged',@(~,~)minRegionCallback(self));
            self.MaxRegionListener = ...
                addlistener(self.MaxRegionSlider,'StateChanged',@(~,~)maxRegionCallback(self));
            
            % Close
            addlistener(self.AcceptButton,'ActionPerformed',@(~,~)acceptCallback(self));
            addlistener(self.CancelButton,'ActionPerformed',@(~,~)cancelCallback(self));
        end
       
   end
   
   methods (Access=private)
       %-------------------------------------------------------------------
       % Callbacks
       %-------------------------------------------------------------------
       function removeArtifactsCallback(self)

           removeArtifacts(self.SegmentationCore,...
               self.ClearBorderCheckBox.Selected,...
               self.FillHolesCheckBox.Selected);
           updateSliderLimits(self);
       end
       
       function minRegionCallback(self)

           if self.MinRegionSlider.Value ~= self.MinRegionSize
               % update minregionsize
               self.MinRegionSize = self.MinRegionSlider.Value;
               
               % update mask
               removeComponents(self.SegmentationCore,self.MinRegionSize,self.MaxRegionSize);
           end 
       end
       
       function maxRegionCallback(self)

           if self.MaxRegionSlider.Value ~= self.MaxRegionSize
               % update maxregionsize
               self.MaxRegionSize = self.MaxRegionSlider.Value;
               
               % update mask
               removeComponents(self.SegmentationCore,self.MinRegionSize,self.MaxRegionSize);
           end
       end
       
       function acceptCallback(self)
           
           minSliderMoved = (self.MinRegionSlider.Minimum~=self.MinRegionSize);
           maxSliderMoved = (self.MaxRegionSlider.Maximum~=self.MaxRegionSize);
           evtdata = iptui.internal.RefineTabClosed(true,self.ClearBorderCheckBox.Selected,self.FillHolesCheckBox.Selected,self.MinRegionSize,self.MaxRegionSize,minSliderMoved,maxSliderMoved);
           notify(self,'CloseRefineTab',evtdata);
       end
       
       function cancelCallback(self)
           loadCachedRefineMask(self.SegmentationCore);
           
           evtdata = iptui.internal.RefineTabClosed(false);
           notify(self,'CloseRefineTab',evtdata);
       end
       
       %-------------------------------------------------------------------
       % Utility
       %-------------------------------------------------------------------
       function updateSliderLimits(self)
           
           [minArea,maxArea] =getSliderLimits(self);
           
           self.MinRegionSlider.Minimum = minArea;
           self.MinRegionSlider.Maximum = maxArea;
           self.MinRegionSlider.Value   = minArea;
           
           self.MaxRegionSlider.Minimum = minArea;
           self.MaxRegionSlider.Maximum = maxArea;
           self.MaxRegionSlider.Value   = maxArea;
       end
       
       function [minArea,maxArea] = getSliderLimits(self)
           
           areas = self.SegmentationCore.Areas;
           
           % When there are no regions in the image, areas is empty. We
           % want this to mean minArea, maxArea become 0 not empty.
           if isempty(areas)
               areas = 0;
           end
           
           % Slider minimum position should be at 1 less than number of
           % pixels in the smallest component. Ensure that this value is
           % non-negative.
           minArea = max(0,min(areas)-1);
           
           % Slider maximum position should be at 1 more than number of
           % pixels in the biggest component.
           maxArea = max(areas)+1;
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