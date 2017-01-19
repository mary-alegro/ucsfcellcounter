classdef ApplyCloseManager < handle
    
    % Copyright 2015 The MathWorks, Inc.
    
    properties
        Section
        
        ApplyButton
        CloseButton
    end
    
    methods
        function self = ApplyCloseManager(hTab)
            
            section = hTab.addSection('ApplyClose', getMessageString('close'));
            
            closePanel = toolpack.component.TSPanel('f:p,f:p','f:p');
            closePanel.Name = 'panelClose';
            section.add(closePanel);
            self.Section = section;
            
            self.ApplyButton = toolpack.component.TSButton(getMessageString('apply'),toolpack.component.Icon.CONFIRM_24);
            self.ApplyButton.Name = 'btnApply';
            self.ApplyButton.Orientation = toolpack.component.ButtonOrientation.VERTICAL;
            
            self.CloseButton = toolpack.component.TSButton(getMessageString('close'),toolpack.component.Icon.CLOSE_24);
            self.CloseButton.Name = 'btnClose';
            self.CloseButton.Orientation = toolpack.component.ButtonOrientation.VERTICAL;
            
            closePanel.add(self.ApplyButton,'xy(1,1)');
            closePanel.add(self.CloseButton,'xy(2,1)');
            
        end
    end
end

function str = getMessageString(id)

str = getString( message( sprintf('images:commonUIString:%s',id) ) );

end