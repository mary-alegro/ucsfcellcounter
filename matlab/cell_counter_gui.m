function varargout = cell_counter_gui(varargin)
% CELL_COUNTER_GUI MATLAB code for cell_counter_gui.fig
%      CELL_COUNTER_GUI, by itself, creates a new CELL_COUNTER_GUI or raises the existing
%      singleton*.
%
%      H = CELL_COUNTER_GUI returns the handle to a new CELL_COUNTER_GUI or the handle to
%      the existing singleton*.
%
%      CELL_COUNTER_GUI('CALLBACK',hObject,eventData,handles,...) calls the local
%      function named CALLBACK in CELL_COUNTER_GUI.M with the given input arguments.
%
%      CELL_COUNTER_GUI('Property','Value',...) creates a new CELL_COUNTER_GUI or raises the
%      existing singleton*.  Starting from the left, property value pairs are
%      applied to the GUI before cell_counter_gui_OpeningFcn gets called.  An
%      unrecognized property name or invalid value makes property application
%      stop.  All inputs are passed to cell_counter_gui_OpeningFcn via varargin.
%
%      *See GUI Options on GUIDE's Tools menu.  Choose "GUI allows only one
%      instance to run (singleton)".
%
% See also: GUIDE, GUIDATA, GUIHANDLES

% Edit the above text to modify the response to help cell_counter_gui

% Last Modified by GUIDE v2.5 24-Jul-2015 10:44:45

% Begin initialization code - DO NOT EDIT
gui_Singleton = 1;
gui_State = struct('gui_Name',       mfilename, ...
                   'gui_Singleton',  gui_Singleton, ...
                   'gui_OpeningFcn', @cell_counter_gui_OpeningFcn, ...
                   'gui_OutputFcn',  @cell_counter_gui_OutputFcn, ...
                   'gui_LayoutFcn',  [] , ...
                   'gui_Callback',   []);
if nargin && ischar(varargin{1})
    gui_State.gui_Callback = str2func(varargin{1});
end

if nargout
    [varargout{1:nargout}] = gui_mainfcn(gui_State, varargin{:});
else
    gui_mainfcn(gui_State, varargin{:});
end
% End initialization code - DO NOT EDIT


% --- Executes just before cell_counter_gui is made visible.
function cell_counter_gui_OpeningFcn(hObject, eventdata, handles, varargin)
% This function has no output args, see OutputFcn.
% hObject    handle to figure
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
% varargin   command line arguments to cell_counter_gui (see VARARGIN)

% Choose default command line output for cell_counter_gui
handles.output = hObject;

% Update handles structure
guidata(hObject, handles);

global load_seg seg_str load_path
if load_seg == 1
    try
        seg_str = load(load_path);
        seg_str = seg_str.seg_str;
        loadData(seg_str);
    catch
    end
end

% UIWAIT makes cell_counter_gui wait for user response (see UIRESUME)
% uiwait(handles.figure1);


% --- Outputs from this function are returned to the command line.
function varargout = cell_counter_gui_OutputFcn(hObject, eventdata, handles) 
% varargout  cell array for returning output args (see VARARGOUT);
% hObject    handle to figure
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Get default command line output from handles structure
varargout{1} = handles.output;


% --- Executes on button press in buttonOpenPS.
function buttonOpenPS_Callback(hObject, eventdata, handles)
% hObject    handle to buttonOpenPS (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)


% --- Executes on button press in buttonRun.
function buttonRun_Callback(hObject, eventdata, handles)
% hObject    handle to buttonRun (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
global img R G B rows cols seg_str

h = get(handles.groupMethod,'SelectedObject');
s = get(h,'Tag');
switch s
    case 'radioEM'
        
    case 'radioSVM'
        
    case 'radioDL'
        doResize = 1;
        si = get(handles.menuWinSize,'Value');
        opt = get(handles.menuWinSize,'String'); 
       
        wsize = str2num(opt{si});
        
        [mask,R2,G2,B2,centersX,centersY,classes] = test_DL1(R,G,B,rows,cols,doResize,wsize);
        
        seg_str.img = img;
        seg_str.mask = mask;
        seg_str.centersX = centersX;
        seg_str.centersY = centersY;
        seg_str.classes = classes;   
        
        msgbox('Segmentation finished.');
        
    otherwise
        warning('Nothing to do. No segmentation method selected.');
end

total = length(seg_str.centersX);
nRed = length(find(classes == 0));
nGreen = length(find(classes == 1));
nOver = length(find(classes == 2));

set(handles.textTotal,'String',num2str(total));
set(handles.textRed,'String',num2str(nRed));
set(handles.textGreen,'String',num2str(nGreen));
set(handles.textOverlap,'String',num2str(nOver));



function textTotal_Callback(hObject, eventdata, handles)
% hObject    handle to textTotal (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of textTotal as text
%        str2double(get(hObject,'String')) returns contents of textTotal as a double


% --- Executes during object creation, after setting all properties.
function textTotal_CreateFcn(hObject, eventdata, handles)
% hObject    handle to textTotal (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end



function textRed_Callback(hObject, eventdata, handles)
% hObject    handle to textRed (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of textRed as text
%        str2double(get(hObject,'String')) returns contents of textRed as a double


% --- Executes during object creation, after setting all properties.
function textRed_CreateFcn(hObject, eventdata, handles)
% hObject    handle to textRed (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end



function textGreen_Callback(hObject, eventdata, handles)
% hObject    handle to textGreen (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of textGreen as text
%        str2double(get(hObject,'String')) returns contents of textGreen as a double


% --- Executes during object creation, after setting all properties.
function textGreen_CreateFcn(hObject, eventdata, handles)
% hObject    handle to textGreen (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end



function textOverlap_Callback(hObject, eventdata, handles)
% hObject    handle to textOverlap (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of textOverlap as text
%        str2double(get(hObject,'String')) returns contents of textOverlap as a double


% --- Executes during object creation, after setting all properties.
function textOverlap_CreateFcn(hObject, eventdata, handles)
% hObject    handle to textOverlap (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end



function textNuclei_Callback(hObject, eventdata, handles)
% hObject    handle to textNuclei (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of textNuclei as text
%        str2double(get(hObject,'String')) returns contents of textNuclei as a double


% --- Executes during object creation, after setting all properties.
function textNuclei_CreateFcn(hObject, eventdata, handles)
% hObject    handle to textNuclei (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end


% --- Executes on selection change in menuWinSize.
function menuWinSize_Callback(hObject, eventdata, handles)
% hObject    handle to menuWinSize (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: contents = cellstr(get(hObject,'String')) returns menuWinSize contents as cell array
%        contents{get(hObject,'Value')} returns selected item from menuWinSize


% --- Executes during object creation, after setting all properties.
function menuWinSize_CreateFcn(hObject, eventdata, handles)
% hObject    handle to menuWinSize (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: popupmenu controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end



function textFilePath_Callback(hObject, eventdata, handles)
% hObject    handle to textFilePath (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of textFilePath as text
%        str2double(get(hObject,'String')) returns contents of textFilePath as a double


% --- Executes during object creation, after setting all properties.
function textFilePath_CreateFcn(hObject, eventdata, handles)
% hObject    handle to textFilePath (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end


% --- Executes on button press in buttonLoad.
function buttonLoad_Callback(hObject, eventdata, handles)
% hObject    handle to buttonLoad (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

global root_dir file_path img R G B rows cols N
curr_dir = pwd;

[name,path,i] = uigetfile(strcat(curr_dir, '/*.*'));
file_path = strcat(path,name);
idx = strfind(file_path,'/');
idx = idx(end);
root_dir = file_path(1:idx);

img = imread(file_path);
[rows cols N] = size(img);
R = img(:,:,1);
G = img(:,:,2);
B = img(:,:,3);

set(handles.textFilePath,'String',file_path);

% --- Executes on button press in buttonSave.
function buttonSave_Callback(hObject, eventdata, handles)
% hObject    handle to buttonSave (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
global seg_str root_dir

if ~isempty(seg_str)
    [name,path,idx] = uiputfile(strcat(root_dir,'*.mat'),'Save segmentation result');
    if name == 0
        return;
    end
    
    filename = strcat(path,name);
    try
        save(filename,'seg_str');
        msgbox('Segmentation results saved.');
    catch
        warndlg('Could not save segmentation results.');
    end
    
end


function loadData(str)

global img
        img = str.img;
 
total = length(str.centersX);
nRed = length(find(str.classes == 0));
nGreen = length(find(str.classes == 1));
nOver = length(find(str.classes == 2));

set(handles.textTotal,'String',num2str(total));
set(handles.textRed,'String',num2str(nRed));
set(handles.textGreen,'String',num2str(nGreen));
set(handles.textOverlap,'String',num2str(nOver));   
