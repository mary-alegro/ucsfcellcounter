
function gui_cellcounter(img)

hFig = figure('Toolbar','none','Menubar','none');

% Main flow panel
hFlow = uiflowcontainer('v0','Parent',hFig,'FlowDirection','LeftToRight','Margin',1);

%%%%%%
% Create Left Panel
%%%%%%
hFlowLeft = uiflowcontainer('v0','Parent',hFlow,'FlowDirection','topdown','Margin',1);

hGridSeg = uigridcontainer('Parent',hFlowLeft,'Units','norm','GridSize',[2,1]);
uicontrol('string','Run Segmentation','parent',hGridSeg);

hGridFilter = uigridcontainer('Parent',hGridSeg,'Units','norm','GridSize',[4,2]);
uicontrol('style','text','string','Filter False Positives:','parent',hGridFilter);
uicontrol('style','text','string','    ','parent',hGridFilter);
uicontrol('style','text','string','Min:','parent',hGridFilter);
uicontrol('Style','edit','parent',hGridFilter);
uicontrol('style','text','string','Max:','parent',hGridFilter);
uicontrol('Style','edit','parent',hGridFilter);
uicontrol('string','Filter','parent',hGridFilter);
%set(hGridFilter,'HeightLimits',[50 50]); % pin height
set(hGridSeg,'HeightLimits',[200 200]); % pin height

hGridClass = uigridcontainer('Parent',hFlowLeft,'Units','norm','GridSize',[1,1]);
uicontrol('string','Run Classification','parent',hGridClass);
set(hGridClass,'HeightLimits',[50 50]); % pin height
%set(hFlowLeft,'HeightLimits',[300 300]); % pin height

%%%%%%
% Create Middle Panel'
%%%%%%%

%create image view
hFlowMid = uiflowcontainer('v0','Parent',hFlow,'FlowDirection','topdown','Margin',1);

%channel buttons
hFlowTabs = uiflowcontainer('v0','Parent',hFlowMid,'FlowDirection','lefttoright','Margin',1);
uicontrol('string','RGB','parent',hFlowTabs);
uicontrol('string','Red','parent',hFlowTabs);
uicontrol('string','Green','parent',hFlowTabs);
uicontrol('string','Blue','parent',hFlowTabs);
set(hFlowTabs,'HeightLimits',[30 30]); % pin height

%image
hPanelMiddle = uipanel(hFlowMid,'Position',[0 0 1 1],'BorderType','none');
hPanelImage  = uipanel('Parent', hPanelMiddle,'Position',[0 0 1 1],'BorderType','none');
%hIm = imshow(img);
hIm = imshow('/Volumes/SUSHI_HD/SUSHI/CellCounter/toprocess/images/807.13_80_drn_final.tif');

hSP = imscrollpanel(hFig,hIm);
set(hSP,'parent',hPanelImage);
set(hFlowMid,'WidthLimits',[1000 1000]); % pin height
%apiSP = iptgetapi(hSP);
%apiSP.setMagnification(0.75);
hSPAxes = findall(0,'type','axes');
plot(hSPAxes,10,10,'MarkerSize',20)

%%%%%%
% Create Right Panel
%%%%%%
hFlowRight = uiflowcontainer('v0','Parent',hFlow,'FlowDirection','topdown','Margin',1);
hFlowCount = uiflowcontainer('v0','Parent',hFlowRight,'FlowDirection','topdown','Margin',1);
hFlowR = uiflowcontainer('v0','Parent',hFlowCount,'FlowDirection','lefttoright','Margin',1);
uicontrol('Style','text','string','Red:','parent',hFlowR);
uicontrol('Style','edit','parent',hFlowR);
hFlowG = uiflowcontainer('v0','Parent',hFlowCount,'FlowDirection','lefttoright','Margin',1);
uicontrol('Style','text','string','Green:','parent',hFlowG);
uicontrol('Style','edit','parent',hFlowG);
hFlowB = uiflowcontainer('v0','Parent',hFlowCount,'FlowDirection','lefttoright','Margin',1);
uicontrol('Style','text','string','Blue:','parent',hFlowB);
uicontrol('Style','edit','parent',hFlowB);
hFlowT = uiflowcontainer('v0','Parent',hFlowCount,'FlowDirection','lefttoright','Margin',1);
uicontrol('Style','text','string','Total:','parent',hFlowT);
uicontrol('Style','edit','parent',hFlowT);
set(hFlowCount,'HeightLimits',[100 100]); % pin height

%%%%%
% Create toolbar
%%%%%



menu = uimenu(hFig,'Label','File');
m1 = uimenu(menu,'Label','Save...');
m2 = uimenu(menu,'Label','Open...');






end









