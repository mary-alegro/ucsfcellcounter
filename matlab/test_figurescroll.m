function varargout = test_figurescroll(varargin)
% TEST_FIGURESCROLL MATLAB code for test_figurescroll.fig
%      TEST_FIGURESCROLL, by itself, creates a new TEST_FIGURESCROLL or raises the existing
%      singleton*.
%
%      H = TEST_FIGURESCROLL returns the handle to a new TEST_FIGURESCROLL or the handle to
%      the existing singleton*.
%
%      TEST_FIGURESCROLL('CALLBACK',hObject,eventData,handles,...) calls the local
%      function named CALLBACK in TEST_FIGURESCROLL.M with the given input arguments.
%
%      TEST_FIGURESCROLL('Property','Value',...) creates a new TEST_FIGURESCROLL or raises the
%      existing singleton*.  Starting from the left, property value pairs are
%      applied to the GUI before test_figurescroll_OpeningFcn gets called.  An
%      unrecognized property name or invalid value makes property application
%      stop.  All inputs are passed to test_figurescroll_OpeningFcn via varargin.
%
%      *See GUI Options on GUIDE's Tools menu.  Choose "GUI allows only one
%      instance to run (singleton)".
%
% See also: GUIDE, GUIDATA, GUIHANDLES

% Edit the above text to modify the response to help test_figurescroll

% Last Modified by GUIDE v2.5 11-Jan-2017 14:11:42

% Begin initialization code - DO NOT EDIT
gui_Singleton = 1;
gui_State = struct('gui_Name',       mfilename, ...
                   'gui_Singleton',  gui_Singleton, ...
                   'gui_OpeningFcn', @test_figurescroll_OpeningFcn, ...
                   'gui_OutputFcn',  @test_figurescroll_OutputFcn, ...
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


% --- Executes just before test_figurescroll is made visible.
function test_figurescroll_OpeningFcn(hObject, eventdata, handles, varargin)
% This function has no output args, see OutputFcn.
% hObject    handle to figure
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
% varargin   command line arguments to test_figurescroll (see VARARGIN)

% Choose default command line output for test_figurescroll
handles.output = hObject;

% Update handles structure
guidata(hObject, handles);

% UIWAIT makes test_figurescroll wait for user response (see UIRESUME)
% uiwait(handles.figure1);


% --- Outputs from this function are returned to the command line.
function varargout = test_figurescroll_OutputFcn(hObject, eventdata, handles) 
% varargout  cell array for returning output args (see VARARGOUT);
% hObject    handle to figure
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Get default command line output from handles structure
varargout{1} = handles.output;


% --- Executes on button press in buttonRun.
function buttonRun_Callback(hObject, eventdata, handles)
% hObject    handle to buttonRun (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
hIm = imshow('/Volumes/SUSHI_HD/SUSHI/CellCounter/toprocess/images/807.13_80_drn_final.tif');
hMainWindow = findall(0,'type','figure');
hSP = imscrollpanel(hIm);
set(hSP,'parent',handles.panelImage);
