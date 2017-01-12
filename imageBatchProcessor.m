function imageBatchProcessor(varargin)
%imageBatchProcessor Process a folder of images.
%   imageBatchProcessor opens an image batch processing app. This app can
%   be used to process an input folder of images using a function. This
%   function should have the following signature:
%          OUT = FCN(IN)
%   An output folder is created and the processed images are stored with
%   the same name and subfolder structure as present in the input folder.
%
%   imageBatchProcessor CLOSE closes all open image batch processing apps.
%
%   See also imread, imwrite.

% Copyright 2014-2015 The MathWorks, Inc.

narginchk(0,1)
if (nargin == 0)
    iptui.internal.ImageBatchProcessingTool();
    
elseif(nargin == 1)
    validatestring(varargin{1}, {'close'}, mfilename);
    imageslib.internal.apputil.manageToolInstances('deleteAll',...
        'imageBatchProcessor');
end
