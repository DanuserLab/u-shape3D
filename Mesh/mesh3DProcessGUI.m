function varargout = mesh3DProcessGUI(varargin)
% mesh3dprocessgui M-file for mesh3dprocessgui.fig
%      mesh3dprocessgui, by itself, creates a new mesh3dprocessgui or raises the existing
%      singleton*.
%
%      H = mesh3dprocessgui returns the handle to a new mesh3dprocessgui or the handle to
%      the existing singleton*.
%
%      mesh3dprocessgui('CALLBACK',hObject,eventData,handles,...) calls the local
%      function named CALLBACK in mesh3dprocessgui.M with the given input arguments.
%
%      mesh3dprocessgui('Property','Value',...) creates a new mesh3dprocessgui or raises the
%      existing singleton*.  Starting from the left, property value pairs are
%      applied to the GUI before mesh3dprocessgui_openingfcn gets called.  An
%      unrecognized property name or invalid value makes property application
%      stop.  All inputs are passed to mesh3dprocessgui_openingfcn via varargin.
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

% Edit the above text to modify the response to help mesh3dprocessgui

% Last Modified by GUIDE v2.5 23-Jul-2018 10:44:36

% Begin initialization code - DO NOT EDIT
gui_Singleton = 1;
gui_State = struct('gui_Name',       mfilename, ...
                   'gui_Singleton',  gui_Singleton, ...
                   'gui_OpeningFcn', @mesh3DProcessGUI_OpeningFcn, ...
                   'gui_OutputFcn',  @mesh3DProcessGUI_OutputFcn, ...
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


% --- Executes just before mesh3dprocessgui is made visible.
function mesh3DProcessGUI_OpeningFcn(hObject, eventdata, handles, varargin)

processGUI_OpeningFcn(hObject, eventdata, handles, varargin{:},'initChannel',1);

% Set-up parameters
userData = get(handles.figure1,'UserData');
userData.meshModeOptions = {'otsu', 'otsuMulticell', 'otsuSteerable', 'twoLevelSurface', 'threeLevelSurface'};
userData.smoothMeshModeOptions = {'curvature', 'none'};
userData.steerableTypeOptions = {'1', '2'};
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
function varargout = mesh3DProcessGUI_OutputFcn(~, ~, handles) 
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


if edit_steerableType_Callback(hObject, eventdata, handles);
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
    if ~strcmp(paramName,'meshMode') && ~strcmp(paramName,'smoothMeshMode') && ... 
            ~strcmp(paramName,'filterScales')
        parVal = funParams.(paramName)(iChan);
        if islogical(funParams.(paramName)) || strcmp(get(handles.(['edit_' paramName]),'Style'),'checkbox')
             set(handles.(['edit_' paramName]), 'Value', parVal);
        elseif iscell(funParams.(paramName))   
            set(handles.(['edit_' paramName]), 'String', parVal{:});
        else
            set(handles.(['edit_' paramName]), 'String', parVal);
        end
    elseif strcmp(paramName,'meshMode')
        parVal = funParams.(paramName)(iChan);
        set(handles.popupmenu_meshMode, 'String', userData.meshModeOptions,...
        'Value', find(ismember(userData.meshModeOptions, parVal)))
    elseif strcmp(paramName,'smoothMeshMode')
        parVal = funParams.(paramName)(iChan);
        set(handles.popupmenu_smoothMeshMode, 'String', userData.smoothMeshModeOptions,...
        'Value', find(ismember(userData.smoothMeshModeOptions, parVal)))
    elseif strcmp(paramName,'filterScales')
        parVal = funParams.(paramName)(iChan);
        set(handles.listbox_Scales,'String',parVal);
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
    if ~strcmp(paramName,'meshMode') && ~strcmp(paramName,'smoothMeshMode') && ... 
            ~strcmp(paramName,'filterScales')
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
    elseif strcmp(paramName,'meshMode')
        strSet = handles.popupmenu_meshMode.String;
        val = handles.popupmenu_meshMode.Value;
        funParams.(paramName)(iChan) = strSet(val);
    elseif strcmp(paramName,'smoothMeshMode')
        strSet = handles.popupmenu_smoothMeshMode.String;
        val = handles.popupmenu_smoothMeshMode.Value;
        funParams.(paramName)(iChan) = strSet(val);
    elseif strcmp(paramName,'filterScales')
       funParams.(paramName)(iChan) = {[cellfun(@(x) str2num(x), get(handles.listbox_Scales,'String'))]};
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


% --- Executes on button press in edit_useUndeconvolved.
function edit_useUndeconvolved_Callback(hObject, eventdata, handles)
% hObject    handle to edit_useUndeconvolved (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hint: get(hObject,'Value') returns toggle state of edit_useUndeconvolved


% --- Executes on selection change in popupmenu_smoothMeshMode.
function popupmenu_smoothMeshMode_Callback(hObject, eventdata, handles)
% hObject    handle to popupmenu_smoothMeshMode (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: contents = cellstr(get(hObject,'String')) returns popupmenu_smoothMeshMode contents as cell array
%        contents{get(hObject,'Value')} returns selected item from popupmenu_smoothMeshMode


% --- Executes during object creation, after setting all properties.
function popupmenu_smoothMeshMode_CreateFcn(hObject, eventdata, handles)
% hObject    handle to popupmenu_smoothMeshMode (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: popupmenu controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end

function edit_imageGamma_Callback(hObject, eventdata, handles)
% hObject    handle to edit_imageGamma (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of edit_imageGamma as text
%        str2double(get(hObject,'String')) returns contents of edit_imageGamma as a double


% --- Executes during object creation, after setting all properties.
function edit_imageGamma_CreateFcn(hObject, eventdata, handles)
% hObject    handle to edit_imageGamma (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end


function edit_smoothMeshIterations_Callback(hObject, eventdata, handles)
% hObject    handle to edit_smoothMeshIterations (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of edit_smoothMeshIterations as text
%        str2double(get(hObject,'String')) returns contents of edit_smoothMeshIterations as a double


% --- Executes during object creation, after setting all properties.
function edit_smoothMeshIterations_CreateFcn(hObject, eventdata, handles)
% hObject    handle to edit_smoothMeshIterations (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end


function edit_curvatureMedianFilterRadius_Callback(hObject, eventdata, handles)
% hObject    handle to edit_curvatureMedianFilterRadius (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of edit_curvatureMedianFilterRadius as text
%        str2double(get(hObject,'String')) returns contents of edit_curvatureMedianFilterRadius as a double


% --- Executes during object creation, after setting all properties.
function edit_curvatureMedianFilterRadius_CreateFcn(hObject, eventdata, handles)
% hObject    handle to edit_curvatureMedianFilterRadius (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end

function edit_curvatureSmoothOnMeshIterations_Callback(hObject, eventdata, handles)
% hObject    handle to edit_curvatureSmoothOnMeshIterations (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of edit_curvatureSmoothOnMeshIterations as text
%        str2double(get(hObject,'String')) returns contents of edit_curvatureSmoothOnMeshIterations as a double


% --- Executes during object creation, after setting all properties.
function edit_curvatureSmoothOnMeshIterations_CreateFcn(hObject, eventdata, handles)
% hObject    handle to edit_curvatureSmoothOnMeshIterations (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end

function edit_multicellGaussSizePreThresh_Callback(hObject, eventdata, handles)
% hObject    handle to edit_multicellGaussSizePreThresh (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of edit_multicellGaussSizePreThresh as text
%        str2double(get(hObject,'String')) returns contents of edit_multicellGaussSizePreThresh as a double


% --- Executes during object creation, after setting all properties.
function edit_multicellGaussSizePreThresh_CreateFcn(hObject, eventdata, handles)
% hObject    handle to edit_multicellGaussSizePreThresh (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end

function edit_multicellMinVolume_Callback(hObject, eventdata, handles)
% hObject    handle to edit_multicellMinVolume (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of edit_multicellMinVolume as text
%        str2double(get(hObject,'String')) returns contents of edit_multicellMinVolume as a double


% --- Executes during object creation, after setting all properties.
function edit_multicellMinVolume_CreateFcn(hObject, eventdata, handles)
% hObject    handle to edit_multicellMinVolume (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end



function edit_multicellDilateRadius_Callback(hObject, eventdata, handles)
% hObject    handle to edit_multicellDilateRadius (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of edit_multicellDilateRadius as text
%        str2double(get(hObject,'String')) returns contents of edit_multicellDilateRadius as a double


% --- Executes during object creation, after setting all properties.
function edit_multicellDilateRadius_CreateFcn(hObject, eventdata, handles)
% hObject    handle to edit_multicellDilateRadius (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end



function edit_multicellCellIndex_Callback(hObject, eventdata, handles)
% hObject    handle to edit_multicellCellIndex (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of edit_multicellCellIndex as text
%        str2double(get(hObject,'String')) returns contents of edit_multicellCellIndex as a double


% --- Executes during object creation, after setting all properties.
function edit_multicellCellIndex_CreateFcn(hObject, eventdata, handles)
% hObject    handle to edit_multicellCellIndex (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end


function edit_filterNumStdSurface_Callback(hObject, eventdata, handles)
% hObject    handle to edit_filterNumStdSurface (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of edit_filterNumStdSurface as text
%        str2double(get(hObject,'String')) returns contents of edit_filterNumStdSurface as a double


% --- Executes during object creation, after setting all properties.
function edit_filterNumStdSurface_CreateFcn(hObject, eventdata, handles)
% hObject    handle to edit_filterNumStdSurface (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end



function failStatus =  edit_steerableType_Callback(hObject, eventdata, handles)
% hObject    handle to edit_steerableType (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of edit_steerableType as text
%        str2double(get(hObject,'String')) returns contents of edit_steerableType as a double
userData = get(handles.figure1,'UserData');
failStatus = false;
if ~any(ismember(userData.steerableTypeOptions, handles.edit_steerableType.String))
    msgbox('Please input valid parameter value for Steerable Fitler Type (1 or 2)');
%     edit_steerableType.String = '1';
    failStatus = true;
end



% --- Executes during object creation, after setting all properties.
function edit_steerableType_CreateFcn(hObject, eventdata, handles)
% hObject    handle to edit_steerableType (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end



function edit_insideGamma_Callback(hObject, eventdata, handles)
% hObject    handle to edit_insideGamma (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of edit_insideGamma as text
%        str2double(get(hObject,'String')) returns contents of edit_insideGamma as a double


% --- Executes during object creation, after setting all properties.
function edit_insideGamma_CreateFcn(hObject, eventdata, handles)
% hObject    handle to edit_insideGamma (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end



function edit_insideBlur_Callback(hObject, eventdata, handles)
% hObject    handle to edit_insideBlur (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of edit_insideBlur as text
%        str2double(get(hObject,'String')) returns contents of edit_insideBlur as a double


% --- Executes during object creation, after setting all properties.
function edit_insideBlur_CreateFcn(hObject, eventdata, handles)
% hObject    handle to edit_insideBlur (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end



function edit_insideDilateRadius_Callback(hObject, eventdata, handles)
% hObject    handle to edit_insideDilateRadius (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of edit_insideDilateRadius as text
%        str2double(get(hObject,'String')) returns contents of edit_insideDilateRadius as a double


% --- Executes during object creation, after setting all properties.
function edit_insideDilateRadius_CreateFcn(hObject, eventdata, handles)
% hObject    handle to edit_insideDilateRadius (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end



function edit_insideErodeRadius_Callback(hObject, eventdata, handles)
% hObject    handle to edit_insideErodeRadius (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of edit_insideErodeRadius as text
%        str2double(get(hObject,'String')) returns contents of edit_insideErodeRadius as a double


% --- Executes during object creation, after setting all properties.
function edit_insideErodeRadius_CreateFcn(hObject, eventdata, handles)
% hObject    handle to edit_insideErodeRadius (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end


% --- Executes on selection change in listbox_Scales.
function listbox_Scales_Callback(hObject, eventdata, handles)
% hObject    handle to listbox_Scales (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: contents = cellstr(get(hObject,'String')) returns listbox_Scales contents as cell array
%        contents{get(hObject,'Value')} returns selected item from listbox_Scales


% --- Executes during object creation, after setting all properties.
function listbox_Scales_CreateFcn(hObject, eventdata, handles)
% hObject    handle to listbox_Scales (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: listbox controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end



function edit_Scale_Callback(hObject, eventdata, handles)
% hObject    handle to edit_Scale (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of edit_Scale as text
%        str2double(get(hObject,'String')) returns contents of edit_Scale as a double


% --- Executes during object creation, after setting all properties.
function edit_Scale_CreateFcn(hObject, eventdata, handles)
% hObject    handle to edit_Scale (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end


% --- Executes on button press in pushbutton_addScale.
function pushbutton_addScale_Callback(hObject, eventdata, handles)
% hObject    handle to pushbutton_addScale (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
value = str2double(get(handles.edit_Scale,'String'));
if isnan(value) || value<0
    errordlg('Please enter a valid scale for filtering');
    return;
else
%     scales = str2num(get(handles.listbox_Scales,'String'));
    scales = [cellfun(@(x) str2num(x), (get(handles.listbox_Scales,'String')))]
    if ismember(value,scales), return; end
    scales = sort([scales; value]);
    set(handles.listbox_Scales,'String',arrayfun(@(x) num2str(x), scales, 'unif', 0));
end


% --- Executes on button press in pushbutton_removeScale.
function pushbutton_removeScale_Callback(hObject, eventdata, handles)
% hObject    handle to pushbutton_removeScale (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
props = get(handles.listbox_Scales,{'String','Value'});
if isempty(props{1}), return; end

props{1}(props{2})=[];
set(handles.listbox_Scales,'String',props{1},'Value',max(1,props{2}-1));



function edit_smoothImageSize_Callback(hObject, eventdata, handles)
% hObject    handle to edit_smoothImageSize (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of edit_smoothImageSize as text
%        str2double(get(hObject,'String')) returns contents of edit_smoothImageSize as a double


% --- Executes during object creation, after setting all properties.
function edit_smoothImageSize_CreateFcn(hObject, eventdata, handles)
% hObject    handle to edit_smoothImageSize (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end
