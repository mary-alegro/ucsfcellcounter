function [cb,cb_api] = createMagComboBox(hToolbar)
%This internal helper function may be removed in a future release.

%   Copyright 2005-2012 The MathWorks, Inc.

%   createMagComboBox is an undocumented function and may be removed in a future
%   version.
    
if images.internal.isFigureAvailable()
    import com.mathworks.mwswing.MJPanel;
    import java.awt.BorderLayout;
    
    [cb,cb_api] = immagboxjava;
    
    panel = javaObjectEDT('com.mathworks.mwswing.MJPanel',BorderLayout);
    panel.add(cb,BorderLayout.WEST)
    javacomponent(panel,0,hToolbar);
end