function varargout = SurfaceSegmentation3DProcessGUI(varargin)
% surfacesegmentation3dprocessgui M-file for surfacesegmentation3dprocessgui.fig
%      surfacesegmentation3dprocessgui, by itself, creates a new surfacesegmentation3dprocessgui or raises the existing
%      singleton*.
%
%      H = surfacesegmentation3dprocessgui returns the handle to a new surfacesegmentation3dprocessgui or the handle to
%      the existing singleton*.
%
%      surfacesegmentation3dprocessgui('CALLBACK',hObject,eventData,handles,...) calls the local
%      function named CALLBACK in surfacesegmentation3dprocessgui.M with the given input arguments.
%
%      surfacesegmentation3dprocessgui('Property','Value',...) creates a new surfacesegmentation3dprocessgui or raises the
%      existing singleton*.  Starting from the left, property value pairs are
%      applied to the GUI before surfacesegmentation3dprocessgui_openingfcn gets called.  An
%      unrecognized property name or invalid value makes property application
%      stop.  All inputs are passed to surfacesegmentation3dprocessgui_openingfcn via varargin.
%
%      *See GUI Options on GUIDE's Tools menu.  Choose "GUI allows only one
%      instance to run (singleton)".
%
% See also: GUIDE, GUIDATA, GUIHANDLES
%
% Copyright (C) 2019, Danuser Lab - UTSouthwestern 
%
% This file is part of Morphology3DPackage.
% 
% Morphology3DPackage is free software: you can redistribute it and/or modify
% it under the terms of the GNU General Public License as published by
% the Free Software Foundation, either version 3 of the License, or
% (at your option) any later version.
% 
% Morphology3DPackage is distributed in the hope that it will be useful,
% but WITHOUT ANY WARRANTY; without even the implied warranty of
% MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
% GNU General Public License for more details.
% 
% You should have received a copy of the GNU General Public License
% along with Morphology3DPackage.  If not, see <http://www.gnu.org/licenses/>.
% 
% 

% Edit the above text to modify the response to help surfacesegmentation3dprocessgui

% Last Modified by GUIDE v2.5 23-Jul-2018 12:49:02

% Begin initialization code - DO NOT EDIT
gui_Singleton = 1;
gui_State = struct('gui_Name',       mfilename, ...
                   'gui_Singleton',  gui_Singleton, ...
                   'gui_OpeningFcn', @SurfaceSegmentation3DProcessGUI_OpeningFcn, ...
                   'gui_OutputFcn',  @SurfaceSegmentation3DProcessGUI_OutputFcn, ...
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


% --- Executes just before surfacesegmentation3dprocessgui is made visible.
function SurfaceSegmentation3DProcessGUI_OpeningFcn(hObject, eventdata, handles, varargin)

processGUI_OpeningFcn(hObject, eventdata, handles, varargin{:},'initChannel',1);

% Set-up parameters
userData = get(handles.figure1,'UserData');
userData.blebModeOptions = {'triangleMerge', 'losMerge', 'triangleLosMerge', 'triangleLosMergeThenLocal'};
% userData.smoothMeshModeOptions = {'curvature', 'none'};
% userData.steerableTypeOptions = {'1', '2'};
set(handles.figure1, 'UserData', userData);
funParams = userData.crtProc.funParams_;
%Remove the output directory as we don't want to replicate it to other
%movies if the "apply to all movies" box is checked. Ideally we would
%explicitly only replicate the parameters we set in this GUI but this is a
%quick fix. - HLE
if isfield(funParams,'OutputDirectory')
    funParams = rmfield(funParams,'OutputDirectory');
end

set(handles.popupmenu_CurrentChannel,'UserData',funParams);

iChan = get(handles.popupmenu_CurrentChannel,'Value');
if isempty(iChan)
    iChan = 1;
    set(handles.popupmenu_CurrentChannel,'Value',1);
end

%Update channel parameter selection dropdown
popupmenu_CurrentChannel_Callback(hObject, eventdata, handles);

% Update GUI user data
set(handles.figure1, 'UserData', userData);
handles.output = hObject;
guidata(hObject, handles);

% --- Outputs from this function are returned to the command line.
function varargout = SurfaceSegmentation3DProcessGUI_OutputFcn(~, ~, handles) 
% varargout  cell array for returning output args (see VARARGOUT);
% hObject    handle to figure
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Get default command line output from handles structure
varargout{1} = handles.output;

% --- Executes on button press in pushbutton_cancel.
function pushbutton_cancel_Callback(~, ~, handles)
% Delete figure
delete(handles.figure1);

% --- Executes during object deletion, before destroying properties.
function figure1_DeleteFcn(hObject, ~, handles)
% Notify the package GUI that the setting panel is closed
userData = get(handles.figure1, 'UserData');
if(isempty(userData)), userData = struct(); end;

if isfield(userData, 'helpFig') && ishandle(userData.helpFig)
   delete(userData.helpFig) 
end

set(handles.figure1, 'UserData', userData);
guidata(hObject,handles);

% --- Executes on key press with focus on pushbutton_done and none of its controls.
function pushbutton_done_KeyPressFcn(~, eventdata, handles)

if strcmp(eventdata.Key, 'return')
    pushbutton_done_Callback(handles.pushbutton_done, [], handles);
end

% --- Executes on key press with focus on figure1 and none of its controls.
function figure1_KeyPressFcn(~, eventdata, handles)

if strcmp(eventdata.Key, 'return')
    pushbutton_done_Callback(handles.pushbutton_done, [], handles);
end

% --- Executes on button press in pushbutton_done.
function pushbutton_done_Callback(hObject, eventdata, handles)

% -------- Check user input --------

if isempty(get(handles.listbox_selectedChannels, 'String'))
    errordlg('Please select at least one input channel from ''Available Channels''.','Setting Error','modal')
    return;
end


%Save the currently set per-channel parameters
pushbutton_saveChannelParams_Callback(hObject, eventdata, handles)


% Retrieve detection parameters
funParams = get(handles.popupmenu_CurrentChannel,'UserData');
% Retrieve GUI-defined non-channel specific parameters

% funParams.Scales=str2num(get(handles.listbox_Scales,'String'));

%Get selected image channels
channelIndex = get(handles.listbox_selectedChannels, 'Userdata');
if isempty(channelIndex)
    errordlg('Please select at least one input channel from ''Available Channels''.','Setting Error','modal')
    return;
end
funParams.ChannelIndex = channelIndex;
funParams.channels = funParams.ChannelIndex;
processGUI_ApplyFcn(hObject, eventdata, handles,funParams);

function edit_scaleOtsu_Callback(hObject, eventdata, handles)
% hObject    handle to edit_scaleOtsu (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of edit_scaleOtsu as text
%        str2double(get(hObject,'String')) returns contents of edit_scaleOtsu as a double

% --- Executes during object creation, after setting all properties.
function edit_scaleOtsu_CreateFcn(hObject, eventdata, handles)
% hObject    handle to edit_scaleOtsu (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end

% --- Executes on selection change in popupmenu_CurrentChannel.
function popupmenu_CurrentChannel_Callback(hObject, eventdata, handles)
% hObject    handle to popupmenu_CurrentChannel (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: contents = cellstr(get(hObject,'String')) returns popupmenu_CurrentChannel contents as cell array
%        contents{get(hObject,'Value')} returns selected item from popupmenu_CurrentChannel
userData = get(handles.figure1,'UserData');
funParams = get(handles.popupmenu_CurrentChannel,'UserData');

selChan = 1:numel(userData.MD.channels_);%For now just let them set parameters for all channels.
%selChan = get(handles.listbox_selectedChannels,'UserData');
chanStr = arrayfun(@(x)(['Channel ' num2str(x)]),selChan,'Unif',0);
set(handles.popupmenu_CurrentChannel,'String',chanStr);
iChan = get(handles.popupmenu_CurrentChannel,'Value');

% Set-up parameters
for i =1 : numel(funParams.PerChannelParams)
    paramName = funParams.PerChannelParams{i};
    if ~strcmp(paramName,'blebMode')
        parVal = funParams.(paramName)(iChan);
        if islogical(funParams.(paramName)) || strcmp(get(handles.(['edit_' paramName]),'Style'),'checkbox')
             set(handles.(['edit_' paramName]), 'Value', parVal);
        elseif iscell(funParams.(paramName))   
            set(handles.(['edit_' paramName]), 'String', parVal{:});
        else
            set(handles.(['edit_' paramName]), 'String', parVal);
        end
    elseif strcmp(paramName,'blebMode')
        parVal = funParams.(paramName)(iChan);
        set(handles.popupmenu_blebMode, 'String', userData.blebModeOptions,...
        'Value', find(ismember(userData.blebModeOptions, parVal)))
    end
end

% --- Executes during object creation, after setting all properties.
function popupmenu_CurrentChannel_CreateFcn(hObject, eventdata, handles)
% hObject    handle to popupmenu_CurrentChannel (see GCBO) 
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: popupmenu controls usually have a white background on Windows.
%       See ISPC and COMPUTER.

if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end

% --- Executes on button press in pushbutton_saveChannelParams.
function pushbutton_saveChannelParams_Callback(hObject, eventdata, handles)
% hObject    handle to pushbutton_saveChannelParams (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

%Get settings for the current channel before switching to another
iChan = get(handles.popupmenu_CurrentChannel,'Value');

%userData=get(handles.figure1,'UserData');
funParams = get(handles.popupmenu_CurrentChannel,'UserData');

for i =1 : numel(funParams.PerChannelParams)
    paramName = funParams.PerChannelParams{i};
    if ~strcmp(paramName,'blebMode')
        if islogical(funParams.(paramName)) || strcmp(get(handles.(['edit_' paramName]),'Style'),'checkbox')
            parVal = get(handles.(['edit_' paramName]), 'Value');
            funParams.(paramName)(iChan) = parVal;
        elseif iscell(funParams.(paramName))   
            parVal = get(handles.(['edit_' paramName]), 'String');
            funParams.(paramName)(iChan) = parVal;
        else
            parVal = get(handles.(['edit_' paramName]), 'String');
            funParams.(paramName)(iChan) = str2double(parVal);
        end
    elseif strcmp(paramName,'blebMode')
        strSet = handles.popupmenu_blebMode.String;
        val = handles.popupmenu_blebMode.Value;
        funParams.(paramName)(iChan) = strSet(val);
    end
end

set(handles.popupmenu_CurrentChannel,'UserData',funParams);


% --- Executes on selection change in popupmenu_meshMode.
function popupmenu_meshMode_Callback(hObject, eventdata, handles)
% hObject    handle to popupmenu_meshMode (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: contents = cellstr(get(hObject,'String')) returns popupmenu_meshMode contents as cell array
%        contents{get(hObject,'Value')} returns selected item from popupmenu_meshMode


% --- Executes on selection change in popupmenu_blebMode.
function popupmenu_blebMode_Callback(hObject, eventdata, handles)
% hObject    handle to popupmenu_blebMode (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: contents = cellstr(get(hObject,'String')) returns popupmenu_blebMode contents as cell array
%        contents{get(hObject,'Value')} returns selected item from popupmenu_blebMode


% --- Executes during object creation, after setting all properties.
function popupmenu_blebMode_CreateFcn(hObject, eventdata, handles)
% hObject    handle to popupmenu_blebMode (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: popupmenu controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end

% --- Executes during object creation, after setting all properties.
function edit_raysPerCompare_CreateFcn(hObject, eventdata, handles)
% hObject    handle to edit_raysPerCompare (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end

function edit_losRatio_Callback(hObject, eventdata, handles)
% hObject    handle to edit_losRatio (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of edit_losRatio as text
%        str2double(get(hObject,'String')) returns contents of edit_losRatio as a double

% --- Executes during object creation, after setting all properties.
function edit_losRatio_CreateFcn(hObject, eventdata, handles)
% hObject    handle to edit_losRatio (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end


function edit_triangleRatio_Callback(hObject, eventdata, handles)
% hObject    handle to edit_triangleRatio (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of edit_triangleRatio as text
%        str2double(get(hObject,'String')) returns contents of edit_triangleRatio as a double

% --- Executes during object creation, after setting all properties.
function edit_triangleRatio_CreateFcn(hObject, eventdata, handles)
% hObject    handle to edit_triangleRatio (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end


function edit_otsuRatio_Callback(hObject, eventdata, handles)
% hObject    handle to edit_otsuRatio (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of edit_otsuRatio as text
%        str2double(get(hObject,'String')) returns contents of edit_otsuRatio as a double

% --- Executes during object creation, after setting all properties.
function edit_otsuRatio_CreateFcn(hObject, eventdata, handles)
% hObject    handle to edit_otsuRatio (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end
