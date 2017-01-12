classdef PanZoomManager < handle
    
%   Copyright 2015 The MathWorks, Inc.

    properties
        Section
    end
    
    properties (Dependent)
        Enabled
    end
    
    properties (Access = private)
        ZoomInButton
        ZoomOutButton
        PanButton
    end
    
    methods
        
        function self = PanZoomManager(hTab)
            
            import iptui.internal.*;
            
            section = hTab.addSection('PanZoom', getMessageString('zoomAndPan'));
            
            zoomPanPanel = toolpack.component.TSPanel( ...
                'f:p', ...              % columns
                'f:p:g,f:p:g,f:p:g');   % rows
            
            zoomPanPanel.Name = 'panelZoomPan';
            
            section.add(zoomPanPanel);
            self.Section = section;
            
            % Zoom in button.
            self.ZoomInButton = toolpack.component.TSToggleButton(getMessageString('zoomInTooltip'),...
                toolpack.component.Icon.ZOOM_IN_16);
            addlistener(self.ZoomInButton, 'ItemStateChanged', @(hobj,evt) self.zoomIn(hobj,evt) );
            self.ZoomInButton.Orientation = toolpack.component.ButtonOrientation.HORIZONTAL;
            
            iptui.internal.utilities.setToolTipText(self.ZoomInButton,getMessageString('zoomInTooltip'));
            self.ZoomInButton.Name = 'btnZoomIn';
            
            % Zoom out button.
            self.ZoomOutButton = toolpack.component.TSToggleButton(getMessageString('zoomOutTooltip'),...
                toolpack.component.Icon.ZOOM_OUT_16);
            addlistener(self.ZoomOutButton, 'ItemStateChanged', @(hobj,evt) self.zoomOut(hobj,evt) );
            self.ZoomOutButton.Orientation = toolpack.component.ButtonOrientation.HORIZONTAL;
            
            iptui.internal.utilities.setToolTipText(self.ZoomOutButton,getMessageString('zoomOutTooltip'));
            self.ZoomOutButton.Name = 'btnZoomOut';
            
            % Pan button.
            self.PanButton = toolpack.component.TSToggleButton(getMessageString('pan'),...
                toolpack.component.Icon.PAN_16 );
            addlistener(self.PanButton, 'ItemStateChanged', @(hobj,evt) self.panImage(hobj,evt) );
            self.PanButton.Orientation = toolpack.component.ButtonOrientation.HORIZONTAL;
            
            iptui.internal.utilities.setToolTipText(self.PanButton,getMessageString('pan'));
            self.PanButton.Name = 'btnPan';
            
            % Add buttons to panel.
            zoomPanPanel.add(self.ZoomInButton, 'xy(1,1)' );
            zoomPanPanel.add(self.ZoomOutButton,'xy(1,2)' );
            zoomPanPanel.add(self.PanButton,'xy(1,3)' );
            
        end
        
    end
    
    % Set/Get accessors
    methods
        
        function TF = get.Enabled(self)
            
            TF = self.ZoomInButton.Enabled;
            
        end
        
        function set.Enabled(self,TF)
            
            self.ZoomInButton.Enabled  = TF;
            self.ZoomOutButton.Enabled = TF;
            self.PanButton.Enabled     = TF;
            
        end
    end
    
    % Callbacks
    methods (Access = private)
        
        function zoomIn(self,hobj,evt)
        end
        
        function zoomOut(self,hobj,evt)
        end
        
        function panImage(self,hobj,evt)
        end
        
    end
end

function str = getMessageString(id)

str = getString( message( sprintf('images:commonUIString:%s',id) ) );

end