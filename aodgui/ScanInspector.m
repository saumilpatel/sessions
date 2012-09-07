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

% Last Modified by GUIDE v2.5 06-Aug-2012 17:39:01

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
updateSessions(handles)

% UIWAIT makes ScanInspector wait for user response (see UIRESUME)
% uiwait(handles.ScanInspector);


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

contents = get(hObject,'UserData');
session_key = contents(get(hObject,'Value'));
sess = fetch(acq.Sessions(session_key));
[files keys] = fetchn(acq.AodScan & aod.TracePreprocessSet & sess, 'aod_scan_filename');
str = cell(length(keys),1);
for i = 1:length(keys)
    expTypes = fetchn(acq.Stimulation & (acq.AodStimulationLink & acq.AodScan(keys(i))), 'exp_type');
    if length(expTypes) >= 1
        expTypes = sprintf('%s,',expTypes{:});
        expTypes(end) = [];
        str{i} = [files{i} ' (' expTypes ')'];
    else
        str{i} = files{i};
    end
end
set(handles.AodScans, 'String', str);
set(handles.AodScans, 'UserData', keys);
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

keys = get(hObject,'UserData');
scan = keys(get(hObject,'Value'));
set(handles.currentScan, 'String', fetch1(acq.AodScan & scan, 'aod_scan_filename'));
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
    [traces_data fs trace_key] = fetchn(aod.TracePreprocess & key,'trace', 'fs');
    traces_data = cat(2,traces_data{:});
    traces_data = bsxfun(@rdivide, traces_data, std(traces_data,[],1)) / 4;
    traces_t = (1:size(traces_data,1)) / fs(1);
    
    for i = 1:length(trace_key)
        [coord.x(i) coord.y(i) coord.z(i)] = fetch1(aod.Traces & trace_key(i), 'x', 'y', 'z');
    end
    
    assignin('base', 'gui_traces_key', key);
    assignin('base', 'gui_traces_data', traces_data);
    assignin('base', 'gui_traces_t', traces_t);
    assignin('base', 'gui_traces_coord', coord);
    
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


% --- Executes on button press in cbExcludeEmpty.
function cbExcludeEmpty_Callback(hObject, eventdata, handles)
% hObject    handle to cbExcludeEmpty (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hint: get(hObject,'Value') returns toggle state of cbExcludeEmpty
updateSessions(handles)

function updateSessions(handles)


if get(handles.cbExcludeEmpty,'Value')
    sess = acq.Sessions(acq.Subjects('subject_name="Mouse"')) & aod.TracePreprocessSetParam;
else
    sess = acq.Sessions(acq.Subjects('subject_name="Mouse"'));
end
[sdt count key] = fetchn(pro(sess, acq.AodScan & aod.TracePreprocessSet, 'COUNT(aod_scan_start_time)->scan_count','session_datetime'),'session_datetime','scan_count');

% Add the number of scans to each session string
str = cell(length(key),1);
for i = 1:length(sdt)
    str{i} = [sdt{i} ' (' num2str(count(i)) ')'];
end

set(handles.SessionsList, 'String', str);
set(handles.SessionsList, 'UserData', key);



function currentScan_Callback(hObject, eventdata, handles)
% hObject    handle to ScanInspector (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of ScanInspector as text
%        str2double(get(hObject,'String')) returns contents of ScanInspector as a double


% --- Executes during object creation, after setting all properties.
function ScanInspector_CreateFcn(hObject, eventdata, handles)
% hObject    handle to ScanInspector (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end


% --- Executes during object creation, after setting all properties.
function currentScan_CreateFcn(hObject, eventdata, handles)
% hObject    handle to currentScan (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end
