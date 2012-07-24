function varargout = ScanInspector(varargin)
% SCANINSPECTOR MATLAB code for ScanInspector.fig
%      SCANINSPECTOR, by itself, creates a new SCANINSPECTOR or raises the existing
%      singleton*.
%
%      H = SCANINSPECTOR returns the handle to a new SCANINSPECTOR or the handle to
%      the existing singleton*.
%
%      SCANINSPECTOR('CALLBACK',hObject,eventData,handles,...) calls the local
%      function named CALLBACK in SCANINSPECTOR.M with the given input arguments.
%
%      SCANINSPECTOR('Property','Value',...) creates a new SCANINSPECTOR or raises the
%      existing singleton*.  Starting from the left, property value pairs are
%      applied to the GUI before ScanInspector_OpeningFcn gets called.  An
%      unrecognized property name or invalid value makes property application
%      stop.  All inputs are passed to ScanInspector_OpeningFcn via varargin.
%
%      *See GUI Options on GUIDE's Tools menu.  Choose "GUI allows only one
%      instance to run (singleton)".
%
% See also: GUIDE, GUIDATA, GUIHANDLES

% Edit the above text to modify the response to help ScanInspector

% Last Modified by GUIDE v2.5 20-Jul-2012 17:23:16

% Begin initialization code - DO NOT EDIT
gui_Singleton = 1;
gui_State = struct('gui_Name',       mfilename, ...
                   'gui_Singleton',  gui_Singleton, ...
                   'gui_OpeningFcn', @ScanInspector_OpeningFcn, ...
                   'gui_OutputFcn',  @ScanInspector_OutputFcn, ...
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


% --- Executes just before ScanInspector is made visible.
function ScanInspector_OpeningFcn(hObject, eventdata, handles, varargin)
% This function has no output args, see OutputFcn.
% hObject    handle to figure
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
% varargin   command line arguments to ScanInspector (see VARARGIN)

% Choose default command line output for ScanInspector
handles.output = hObject;

% Update handles structure
guidata(hObject, handles);

sdt = fetchn(acq.Sessions(acq.Subjects('subject_name="Mouse"')),'session_datetime');
set(handles.SessionsList, 'String', sdt);

% UIWAIT makes ScanInspector wait for user response (see UIRESUME)
% uiwait(handles.figure1);


% --- Outputs from this function are returned to the command line.
function varargout = ScanInspector_OutputFcn(hObject, eventdata, handles) 
% varargout  cell array for returning output args (see VARARGOUT);
% hObject    handle to figure
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Get default command line output from handles structure
varargout{1} = handles.output;


% --- Executes on selection change in SessionsList.
function SessionsList_Callback(hObject, eventdata, handles)
% hObject    handle to SessionsList (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: contents = cellstr(get(hObject,'String')) returns SessionsList contents as cell array
%        contents{get(hObject,'Value')} returns selected item from SessionsList

contents = cellstr(get(hObject,'String'));
sdt = contents{get(hObject,'Value')};
sess = fetch(acq.Sessions(['session_datetime="' sdt '"']));
files = fetchn(acq.AodScan & sess, 'aod_scan_filename');
set(handles.AodScans, 'String', files);
set(handles.AodScans, 'Value', 1);

% --- Executes during object creation, after setting all properties.
function SessionsList_CreateFcn(hObject, eventdata, handles)
% hObject    handle to SessionsList (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: listbox controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end


% --- Executes on selection change in AodScans.
function AodScans_Callback(hObject, eventdata, handles)
% hObject    handle to AodScans (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: contents = cellstr(get(hObject,'String')) returns AodScans contents as cell array
%        contents{get(hObject,'Value')} returns selected item from AodScans

contents = cellstr(get(hObject,'String'));
fileName = contents{get(hObject,'Value')};
scan = acq.AodScan(['aod_scan_filename="' fileName '"']);
data = fetch(aod.TracePreprocessSet & scan);
if ~isempty(data)
    methods = fetchn(aod.TracePreprocessMethod(data),'preprocess_method_name');
    set(handles.Preprocessing, 'UserData', data);
    set(handles.Preprocessing, 'String', methods);
    set(handles.Preprocessing, 'Value', 1);
else
    set(handles.Preprocessing, 'UserData', [])
    set(handles.Preprocessing, 'String', 'None');
    set(handles.Preprocessing, 'Value', 1);
end


% --- Executes during object creation, after setting all properties.
function AodScans_CreateFcn(hObject, eventdata, handles)
% hObject    handle to AodScans (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: listbox controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end


% --- Executes on selection change in Preprocessing.
function Preprocessing_Callback(hObject, eventdata, handles)
% hObject    handle to Preprocessing (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: contents = cellstr(get(hObject,'String')) returns Preprocessing contents as cell array
%        contents{get(hObject,'Value')} returns selected item from Preprocessing

keys = get(hObject,'UserData');
if isempty(keys)
    axes(handles.Traces)
    cla
    return;
end

key = keys(get(hObject,'Value'));

if count(aod.TracePreprocessSet(key)) == 1
    traces = fetch(aod.TracePreprocess & key,'*');
    traces_data = cat(2,traces.trace);
    traces_data = bsxfun(@rdivide, traces_data, std(traces_data,[],1)) / 4;
    traces_t = (1:size(traces_data,1)) / traces(1).fs;
    axes(handles.Traces);
    plot(traces_t, bsxfun(@plus,traces_data, 1:size(traces_data,2)));
end

% --- Executes during object creation, after setting all properties.
function Preprocessing_CreateFcn(hObject, eventdata, handles)
% hObject    handle to Preprocessing (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: popupmenu controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end
