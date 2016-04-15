function varargout = CellCounterUI(varargin)
% CELLCOUNTERUI MATLAB code for CellCounterUI.fig
%      CELLCOUNTERUI, by itself, creates a new CELLCOUNTERUI or raises the existing
%      singleton*.
%
%      H = CELLCOUNTERUI returns the handle to a new CELLCOUNTERUI or the handle to
%      the existing singleton*.
%
%      CELLCOUNTERUI('CALLBACK',hObject,eventData,handles,...) calls the local
%      function named CALLBACK in CELLCOUNTERUI.M with the given input arguments.
%
%      CELLCOUNTERUI('Property','Value',...) creates a new CELLCOUNTERUI or raises the
%      existing singleton*.  Starting from the left, property value pairs are
%      applied to the GUI before CellCounterUI_OpeningFcn gets called.  An
%      unrecognized property name or invalid value makes property application
%      stop.  All inputs are passed to CellCounterUI_OpeningFcn via varargin.
%
%      *See GUI Options on GUIDE's Tools menu.  Choose "GUI allows only one
%      instance to run (singleton)".
%
% See also: GUIDE, GUIDATA, GUIHANDLES

% Edit the above text to modify the response to help CellCounterUI

% Last Modified by GUIDE v2.5 24-Jul-2015 10:13:19

% Begin initialization code - DO NOT EDIT
gui_Singleton = 1;
gui_State = struct('gui_Name',       mfilename, ...
                   'gui_Singleton',  gui_Singleton, ...
                   'gui_OpeningFcn', @CellCounterUI_OpeningFcn, ...
                   'gui_OutputFcn',  @CellCounterUI_OutputFcn, ...
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


% --- Executes just before CellCounterUI is made visible.
function CellCounterUI_OpeningFcn(hObject, eventdata, handles, varargin)
% This function has no output args, see OutputFcn.
% hObject    handle to figure
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
% varargin   command line arguments to CellCounterUI (see VARARGIN)

% Choose default command line output for CellCounterUI
handles.output = hObject;

% Update handles structure
guidata(hObject, handles);

global load_seg
load_seg = 0;
% UIWAIT makes CellCounterUI wait for user response (see UIRESUME)
% uiwait(handles.figure1);


% --- Outputs from this function are returned to the command line.
function varargout = CellCounterUI_OutputFcn(hObject, eventdata, handles) 
% varargout  cell array for returning output args (see VARARGOUT);
% hObject    handle to figure
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Get default command line output from handles structure
varargout{1} = handles.output;


% --- Executes on button press in buttonNew.
function buttonNew_Callback(hObject, eventdata, handles)
% hObject    handle to buttonNew (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
cell_counter_gui;


% --- Executes on button press in buttonLoadMat.
function buttonLoadMat_Callback(hObject, eventdata, handles)
% hObject    handle to buttonLoadMat (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
global load_path load_seg;

curr_dir = pwd;
load_seg = 1;
[name,path,i] = uigetfile(strcat(curr_dir,'/*.mat'));
load_path = strcat(path,name);
cell_counter_gui;



% --- Executes on button press in buttonLoadPS.
function buttonLoadPS_Callback(hObject, eventdata, handles)
% hObject    handle to buttonLoadPS (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
