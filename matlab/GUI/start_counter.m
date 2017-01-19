function varargout = start_counter(varargin)
% START_COUNTER MATLAB code for start_counter.fig
%      START_COUNTER, by itself, creates a new START_COUNTER or raises the existing
%      singleton*.
%
%      H = START_COUNTER returns the handle to a new START_COUNTER or the handle to
%      the existing singleton*.
%
%      START_COUNTER('CALLBACK',hObject,eventData,handles,...) calls the local
%      function named CALLBACK in START_COUNTER.M with the given input arguments.
%
%      START_COUNTER('Property','Value',...) creates a new START_COUNTER or raises the
%      existing singleton*.  Starting from the left, property value pairs are
%      applied to the GUI before start_counter_OpeningFcn gets called.  An
%      unrecognized property name or invalid value makes property application
%      stop.  All inputs are passed to start_counter_OpeningFcn via varargin.
%
%      *See GUI Options on GUIDE's Tools menu.  Choose "GUI allows only one
%      instance to run (singleton)".
%
% See also: GUIDE, GUIDATA, GUIHANDLES

% Edit the above text to modify the response to help start_counter

% Last Modified by GUIDE v2.5 12-Jan-2017 15:36:22

% Begin initialization code - DO NOT EDIT
gui_Singleton = 1;
gui_State = struct('gui_Name',       mfilename, ...
                   'gui_Singleton',  gui_Singleton, ...
                   'gui_OpeningFcn', @start_counter_OpeningFcn, ...
                   'gui_OutputFcn',  @start_counter_OutputFcn, ...
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


% --- Executes just before start_counter is made visible.
function start_counter_OpeningFcn(hObject, eventdata, handles, varargin)
% This function has no output args, see OutputFcn.
% hObject    handle to figure
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
% varargin   command line arguments to start_counter (see VARARGIN)

% Choose default command line output for start_counter
handles.output = hObject;

% Update handles structure
guidata(hObject, handles);

% UIWAIT makes start_counter wait for user response (see UIRESUME)
% uiwait(handles.figure1);


% --- Outputs from this function are returned to the command line.
function varargout = start_counter_OutputFcn(hObject, eventdata, handles) 
% varargout  cell array for returning output args (see VARARGOUT);
% hObject    handle to figure
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Get default command line output from handles structure
varargout{1} = handles.output;


% --- Executes on button press in buttonOpenFile.
function buttonOpenFile_Callback(hObject, eventdata, handles)
% hObject    handle to buttonOpenFile (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
[fileName,pathName,filterIndex] = uigetfile()
set(handles.textImage,'string',strcat(pathName,fileName));


function textImage_Callback(hObject, eventdata, handles)
% hObject    handle to textImage (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of textImage as text
%        str2double(get(hObject,'String')) returns contents of textImage as a double


% --- Executes during object creation, after setting all properties.
function textImage_CreateFcn(hObject, eventdata, handles)
% hObject    handle to textImage (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end



function textMask_Callback(hObject, eventdata, handles)
% hObject    handle to textMask (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of textMask as text
%        str2double(get(hObject,'String')) returns contents of textMask as a double


% --- Executes during object creation, after setting all properties.
function textMask_CreateFcn(hObject, eventdata, handles)
% hObject    handle to textMask (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end


% --- Executes on button press in buttonOpenMask.
function buttonOpenMask_Callback(hObject, eventdata, handles)
% hObject    handle to buttonOpenMask (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
[fileName,pathName,filterIndex] = uigetfile()
set(handles.textMask,'string',strcat(pathName,fileName));


% --- Executes on button press in pushbutton4.
function pushbutton4_Callback(hObject, eventdata, handles)
% hObject    handle to pushbutton4 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)


% --- Executes on button press in buttonOK.
function buttonOK_Callback(hObject, eventdata, handles)
% hObject    handle to buttonOK (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
img = imread('/Volumes/SUSHI_HD/SUSHI/CellCounter/toprocess/images/807.13_80_drn_final.tif');
gui_cellcounter(img);


% --- Executes on button press in buttonOpenMask.
function buttonOpenMark_Callback(hObject, eventdata, handles)
% hObject    handle to buttonOpenMask (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)



function edit3_Callback(hObject, eventdata, handles)
% hObject    handle to edit3 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of edit3 as text
%        str2double(get(hObject,'String')) returns contents of edit3 as a double


% --- Executes during object creation, after setting all properties.
function edit3_CreateFcn(hObject, eventdata, handles)
% hObject    handle to edit3 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end


% --- Executes on button press in buttomRunSeg.
function buttomRunSeg_Callback(hObject, eventdata, handles)
% hObject    handle to buttomRunSeg (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

hFig = figure('Toolbar','none','Menubar','none','HandleVisibility','callback',...
'IntegerHandle','off','NumberTitle','off','Tag','cpselect','Name','Cell Counter',...
'Visible','off','DeleteFcn',@deleteTool);
I = checkerboard;
J = imrotate(I,30);
fixedPoints = [11 11; 41 71];
movingPoints = [14 44; 70 81];
gui_counter(hFig,J,I,movingPoints,fixedPoints);


function textMin_Callback(hObject, eventdata, handles)
% hObject    handle to textMin (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of textMin as text
%        str2double(get(hObject,'String')) returns contents of textMin as a double


% --- Executes during object creation, after setting all properties.
function textMin_CreateFcn(hObject, eventdata, handles)
% hObject    handle to textMin (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end



function textMax_Callback(hObject, eventdata, handles)
% hObject    handle to textMax (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of textMax as text
%        str2double(get(hObject,'String')) returns contents of textMax as a double


% --- Executes during object creation, after setting all properties.
function textMax_CreateFcn(hObject, eventdata, handles)
% hObject    handle to textMax (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end


% --- Executes on button press in buttonFilter.
function buttonFilter_Callback(hObject, eventdata, handles)
% hObject    handle to buttonFilter (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)


% --- Executes on button press in buttonRunClass.
function buttonRunClass_Callback(hObject, eventdata, handles)
% hObject    handle to buttonRunClass (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)



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



function textYellow_Callback(hObject, eventdata, handles)
% hObject    handle to textYellow (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of textYellow as text
%        str2double(get(hObject,'String')) returns contents of textYellow as a double


% --- Executes during object creation, after setting all properties.
function textYellow_CreateFcn(hObject, eventdata, handles)
% hObject    handle to textYellow (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end



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
