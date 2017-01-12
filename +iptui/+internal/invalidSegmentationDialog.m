function dlg = invalidSegmentationDialog()
%invalidSegmentationDialog - Launch warning dialog for invalid
%segmentation.

% Copyright 2014 The MathWorks, Inc.

warnstring = getString(message('images:imageSegmenter:invalidSegmentationDlgString'));
dlgname    = getString(message('images:imageSegmenter:invalidSegmentationDlgName'));
createmode = 'modal';

dlg = warndlg(warnstring,dlgname,createmode);
end
