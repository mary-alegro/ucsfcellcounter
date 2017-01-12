classdef ColorSpaceMontageView < handle

    %   Copyright 2013-2014 The MathWorks, Inc.

    properties (Access = private)
                        
        hFig             
        hColorSegmentationToolDeletedListener
        hPanels
                
    end
    
    properties( SetObservable)
       
        % String specifying color space that was chosen by user
        SelectedColorSpace
        
    end
    
    methods
        
        
        function RGB = computeThumbnailRGB(self,RGB)
            
            % Get the size of each axes in the thumbnail layout in pixels;
            hAx = findobj(self.hFig,'type','axes');
            
            % All of the axes are the same size, use the size of the first
            % axes when forming thumbnails.
            RGB = iptui.internal.resizeImageToFitWithinAxes(hAx(1),RGB);
            
        end
        
        function deleteView(self)
            close(self.hFig);
        end
        
        function self = ColorSpaceMontageView(hColorSegTool,RGB,dlgPos)
            
            % Add multiple colorspace view panel to figure parented to
            % toolgroup.
            self.hFig  = figure('Name',getString(message('images:colorSegmentor:chooseColorspace')),...
                'NumberTitle','off',...
                'IntegerHandle','off',...
                'Tag','chooseColorSpaceFigure', ...
                'WindowStyle', get(0,'FactoryFigureWindowStyle'), ... % Must appear before setting position.
                'Position',dlgPos,...
                'DeleteFcn',@(varargin) delete(self),...
                'Toolbar','none',...
                'Menubar','none');
            
            % Set the WindowKeyPressFcn to a non-empty function. This is
            % effectively a no-op that executes everytime a key is pressed
            % when the App is in focus. This is done to prevent focus from
            % shifting to the MATLAB command window when a key is typed.
            self.hFig.WindowKeyPressFcn = @(~,~)[];
         
            % Wire up listener that will delete color space montage view
            % instance if the associated app is deleted.
            self.hColorSegmentationToolDeletedListener = event.listener(hColorSegTool,'ObjectBeingDestroyed',@(varargin) self.deleteView() );
         
            % The only purpose of this panel is to work around a rendering bug with
            % uipanel layout in MATLAB Graphics 1 in which the seams of the
            % individual color space panels are showing when they should
            % not.
            hPanel = uipanel('Parent',self.hFig,'Position',[0 0 1 1],'HitTest','off');
            
            % Install pointer manager on figure.
            iptPointerManager(self.hFig);
                              
            hRGB   = layoutMontageView(hPanel,[0 0 0.25 1],'R','G','B','RGB');
            hHSV   = layoutMontageView(hPanel,[0.25 0 0.25 1],'H','S','V','HSV');
            hYCbCr = layoutMontageView(hPanel,[0.5 0 0.25 1],'Y','Cb','Cr','YCbCr');
            hLAB   = layoutMontageView(hPanel,[0.75 0 0.25 1],'L*','a*','b*','L*a*b*');
            self.hPanels = [hRGB,hHSV,hYCbCr,hLAB];

            % Obtain thumbnail sized representation of RGB input image so
            % that we can avoid needing to compute full scale color
            % transformation.
            RGB = self.computeThumbnailRGB(RGB);
            
            displayColorSpaceInPanel(hRGB, RGB);
            displayColorSpaceInPanel(hHSV, rgb2hsv(RGB));
            displayColorSpaceInPanel(hYCbCr, rgb2ycbcr(RGB));
            displayColorSpaceInPanel(hLAB, prepLab(images.internal.sRGB2Lab(RGB)));

            % No colorspace is selected in the initial state.
            self.SelectedColorSpace = '';
            
            addlistener(self.hFig,'WindowMouseMotion',@(hObj,evt) self.reactToMouseMotion(hObj,evt));
            addlistener(self.hFig,'WindowMousePress',@(hObj,evt) self.reactToMousePress(hObj,evt));
                                                                
            set(self.hFig,'HandleVisibility','callback');
                          
            
        end
        
        function reactToMousePress(self,~,evt)
            
            currentObject = evt.HitObject;
            
            if strcmp(get(currentObject,'type'),'uipanel')
                self.SelectedColorSpace = get(currentObject,'tag');
                close(self.hFig);
            end
               
        end
        
        
        function reactToMouseMotion(self,~,evt)
                        
           currentObject = evt.HitObject;
 
           if strcmp(get(currentObject,'type'),'uipanel')
                set(self.hPanels,'BorderType','none');
                set(currentObject,'BorderType','etchedin','BorderWidth',2);
           end
                
        end
        
        function delete(self)
           % Cleanup associated figure when delete is called
           delete(self.hFig);
        end
        
        function bringToFocusInSpecifiedPosition(self,dlgPos)
           
            figure(self.hFig);
            set(self.hFig,'Position',dlgPos);
            
        end
        
    end
    
    
end

function hpanel = layoutMontageView(hParent,position,aString,bString,cString,colorSpaceString)

hpanel = uipanel('Parent',hParent,...
    'Units','Normalized',...
    'Position',position,...
    'BorderType','none',...
    'tag',colorSpaceString);

iptSetPointerBehavior(hpanel,@(hFig,evt) set(hFig,'Pointer','hand'));

hImagePanel = uipanel('Parent',hpanel,...
    'Units','Normalized',...
    'Position',[0 0 1 0.95],...
    'BorderType','none',...
    'hittest','off');

hTitlePanel = uipanel('Parent',hpanel,...
    'Units','Normalized',...
    'Position',[0 0.95 1 0.05],...
    'BorderType','none',...
    'hittest','off');

hFlowContainer = uiflowcontainer('v0',...
    'parent',hTitlePanel,...
    'hittest','off');

% Add text description of color space
uicontrol('style', 'text',...
    'String',colorSpaceString,...
    'Parent',hFlowContainer,...
    'FontWeight','bold',...
    'FontSize',14);

% Add three axes containing each color channel. 0,0 is at bottom left of
% parent panel.
hAx1 = axes('Parent',hImagePanel,'hittest','off','OuterPosition',[0 2/3 1 1/3],'tag','channel1Axes');
hAx2 = axes('Parent',hImagePanel,'hittest','off','OuterPosition',[0 1/3 1 1/3],'tag','channel2Axes');
hAx3 = axes('Parent',hImagePanel,'hittest','off','OuterPosition',[0 0 1 1/3],'tag','channel3Axes');

% Add a title labeling each axes.
title(hAx1,aString,'hittest','off');
title(hAx2,bString,'hittest','off');
title(hAx3,cString,'hittest','off');

end

function displayColorSpaceInPanel(hpanel,im)

S = warning('off','images:imshow:magnificationMustBeFitForDockedFigure');

% Add three axes containing each color channel. 0,0 is at bottom left of
% parent panel.
hAx1 = findobj(hpanel,'tag','channel1Axes');
hAx2 = findobj(hpanel,'tag','channel2Axes');
hAx3 = findobj(hpanel,'tag','channel3Axes');

% Display each color channel in a separate axes.
hIm1 = imshow(im(:,:,1),'Parent',hAx1);
hIm2 = imshow(im(:,:,2),'Parent',hAx2);
hIm3 = imshow(im(:,:,3),'Parent',hAx3);

% We want view to be insulated from IPT preference 'ImshowAxesVisible','on'
set([hAx1,hAx2,hAx3],'Visible','off');

set(hIm1,'Tag','Channel1');
set(hIm2,'Tag','Channel2');
set(hIm3,'Tag','Channel3');

set([hIm1 hIm2 hIm3],'hittest','off');

warning(S);

end

function out = prepLab(in)
%prepLab - Convert L*a*b* image to range [0,1] for thumbnail display

out = in;
out(:,:,1)   = in(:,:,1) / 100;  % L range is [0 100].
out(:,:,2:3) = (in(:,:,2:3) + 100) / 200;  % a* and b* range is [-100,100].

end
