function imageSegmenter(I)
%imageSegmenter Segment grayscale image.
%   imageSegmenter opens a grayscale image segmentation app. The app can be
%   used to create a segmentation mask to a grayscale image using
%   evolutionary segmentation techniques.
%
%   imageSegmenter(I) loads the grayscale image I into an image
%   segmentation app.
%
%   imageSegmenter CLOSE closes all open image segmentation apps.
%
%   Class Support
%   -------------
%   I is a grayscale image of class uint8, uint16, or double.
%
%   See also activecontour

%   Copyright 2014 The MathWorks, Inc.

if nargin == 0
    % Create a new Image Segmentation app.
    iptui.internal.ImageSegmentationTool();
else
    if ischar(I)
        % Handle the 'close' request
        validatestring(I, {'close'}, mfilename);
        iptui.internal.ImageSegmentationTool.deleteAllTools(); 
    else
        supportedImageClasses    = {'uint8','uint16','double'};
        supportedImageAttributes = {'real','nonsparse','nonempty'};
        validateattributes(I,supportedImageClasses,supportedImageAttributes,mfilename,'I');
        
        % If image is RGB, issue warning and convert to grayscale.
        isRGB = ndims(I)==3 && size(I,3)==3;
        if isRGB
            warning(message('images:imageSegmenter:convertToGray'));
            I = rgb2gray(I);
        % If image is not 2D grayscale or RGB, error.    
        elseif ~ismatrix(I)
            error(message('images:imageSegmenter:expectedGray'));
        end
        
        iptui.internal.ImageSegmentationTool(I,isRGB);
    end
        
end
