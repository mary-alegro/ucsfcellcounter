function imageRegionAnalyzer(varargin)
%imageRegionAnalyzer  Explore and filter regions in binary image.
%   imageRegionAnalyzer opens a binary image exploration and region
%   filtering app. The app can be used to create other binary images and
%   get information about the regions within binary images.
%
%   imageRegionAnalyzer(BW) loads the binary image BW into a region
%   analyzer app.
%
%   imageRegionAnalyzer CLOSE closes all open region analyzer apps.
%
%   Class Support
%   -------------
%   BW must be a logical 2-D image.
%
%   See also bwareafilt, bwpropfilt, regionprops.

% Copyright 2014 The MathWorks, Inc.

narginchk(0,1)
if (nargin == 0)
    iptui.internal.RegionAnalysisTool();
else
    if ischar(varargin{1})
        validatestring(varargin{1}, {'close'}, mfilename);
        iptui.internal.RegionAnalysisTool.deleteAllTools();
    else
        img = varargin{1};
        validateattributes(img, {'logical'}, {'2d', 'nonempty', 'nonsparse'}, 1)
        iptui.internal.RegionAnalysisTool(img);
    end
end