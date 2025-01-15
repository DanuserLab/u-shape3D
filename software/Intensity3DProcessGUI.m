function varargout = Intensity3DProcessGUI(varargin)
% intensity3dprocessgui M-file for intensity3dprocessgui.fig
%      intensity3dprocessgui, by itself, creates a new intensity3dprocessgui or raises the existing
%      singleton*.
%
%      H = intensity3dprocessgui returns the handle to a new intensity3dprocessgui or the handle to
%      the existing singleton*.
%
%      intensity3dprocessgui('CALLBACK',hObject,eventData,handles,...) calls the local
%      function named CALLBACK in intensity3dprocessgui.M with the given input arguments.
%
%      intensity3dprocessgui('Property','Value',...) creates a new intensity3dprocessgui or raises the
%      existing singleton*.  Starting from the left, property value pairs are
%      applied to the GUI before intensity3dprocessgui_openingfcn gets called.  An
%      unrecognized property name or invalid value makes property application
%      stop.  All inputs are passed to intensity3dprocessgui_openingfcn via varargin.
%
%      *See GUI Options on GUIDE's Tools menu.  Choose "GUI allows only one
%      instance to run (singleton)".
%
% See also: GUIDE, GUIDATA, GUIHANDLES
%
% Copyright (C) 2025, Danuser Lab - UTSouthwestern 
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

% Edit the above text to modify the response to help intensity3dprocessgui

% Last Modified by GUIDE v2.5 30-Jul-2019 10:12:23

% Begin initialization code - DO NOT EDIT
gui_Singleton = 1;
gui_State = struct('gui_Name',       mfilename, ...
                   'gui_Singleton',  gui_Singleton, ...
                   'gui_OpeningFcn', @Intensity3DProcessGUI_OpeningFcn, ...
                   'gui_OutputFcn',  @Intensity3DProcessGUI_OutputFcn, ...
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


% --- Executes just before intensity3dprocessgui is made visible.
function Intensity3DProcessGUI_OpeningFcn(hObject, eventdata, handles, varargin)

processGUI_OpeningFcn(hObject, eventdata, handles, varargin{:},'initChannel',1);

% Set-up parameters
userData = get(handles.figure1,'UserData');
userData.intensityModeOptions = {'intensityInsideDepthNormal', 'intensityInsideRaw', 'intensityOtherInsideDepthNormal', 'intensityOtherOutsideRaw', 'intensityOtherRaw','intensityInsideRawVertex','intensityInsideDepthNormalVertex'};
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

% non-channel specific Parameter
userData.mainChannelOptions = 1:numel(userData.MD.channels_);
handles.popupmenu_mainChannel.String = ['self' string(userData.mainChannelOptions)];
if  ischar(funParams.mainChannel) && strcmp(funParams.mainChannel, 'self')
    handles.listbox_mainChannel.Visible = 'Off';
    handles.pushbutton_addMainChannel.Visible = 'Off';
    handles.pushbutton_rmMainChannel.Visible = 'Off';
    
else
    handles.listbox_mainChannel.Visible = 'On';
    handles.popupmenu_mainChannel.Value = find(ismember(handles.popupmenu_mainChannel.String, num2str(funParams.mainChannel)));
    set(handles.listbox_mainChannel,'String',arrayfun(@(x) num2str(x), funParams.mainChannel, 'unif', 0));
end



% Update GUI user data
set(handles.figure1, 'UserData', userData);
handles.output = hObject;
guidata(hObject, handles);

% --- Outputs from this function are returned to the command line.
function varargout = Intensity3DProcessGUI_OutputFcn(~, ~, handles) 
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


val = handles.popupmenu_mainChannel.Value;
strM = handles.popupmenu_mainChannel.String;
value = strM(val);
if iscell(value) && ischar(value{1}) && strcmp('self', value{1})
    funParams.mainChannel = 'self';
elseif isempty(get(handles.listbox_mainChannel, 'String'))
    funParams.mainChannel = str2num(value{1});
else
    funParams.mainChannel = [cellfun(@(x) str2num(x), (get(handles.listbox_mainChannel, 'String')))];
end

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
    if ~strcmp(paramName,'intensityMode')
        parVal = funParams.(paramName)(iChan);
        if islogical(funParams.(paramName)) || strcmp(get(handles.(['edit_' paramName]),'Style'),'checkbox')
             set(handles.(['edit_' paramName]), 'Value', parVal);
        elseif iscell(funParams.(paramName))   
            set(handles.(['edit_' paramName]), 'String', parVal{:});
        else
            set(handles.(['edit_' paramName]), 'String', parVal);
        end
    elseif strcmp(paramName,'intensityMode')
        parVal = funParams.(paramName)(iChan);
        set(handles.popupmenu_intensityMode, 'String', userData.intensityModeOptions,...
        'Value', find(ismember(userData.intensityModeOptions, parVal)))
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
    if ~strcmp(paramName,'intensityMode')
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
    elseif strcmp(paramName,'intensityMode')
        strSet = handles.popupmenu_intensityMode.String;
        val = handles.popupmenu_intensityMode.Value;
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


% --- Executes on selection change in popupmenu_intensityMode.
function popupmenu_intensityMode_Callback(hObject, eventdata, handles)
% hObject    handle to popupmenu_intensityMode (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: contents = cellstr(get(hObject,'String')) returns popupmenu_intensityMode contents as cell array
%        contents{get(hObject,'Value')} returns selected item from popupmenu_intensityMode


% --- Executes during object creation, after setting all properties.
function popupmenu_intensityMode_CreateFcn(hObject, eventdata, handles)
% hObject    handle to popupmenu_intensityMode (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: popupmenu controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end

% --- Executes during object creation, after setting all properties.
function edit_otherChannel_CreateFcn(hObject, eventdata, handles)
% hObject    handle to edit_otherChannel (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end

function edit_sampleRadius_Callback(hObject, eventdata, handles)
% hObject    handle to edit_sampleRadius (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of edit_sampleRadius as text
%        str2double(get(hObject,'String')) returns contents of edit_sampleRadius as a double

% --- Executes during object creation, after setting all properties.
function edit_sampleRadius_CreateFcn(hObject, eventdata, handles)
% hObject    handle to edit_sampleRadius (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end


function edit_leftRightCorrection_Callback(hObject, eventdata, handles)
% hObject    handle to edit_leftRightCorrection (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of edit_leftRightCorrection as text
%        str2double(get(hObject,'String')) returns contents of edit_leftRightCorrection as a double

% --- Executes during object creation, after setting all properties.
function edit_leftRightCorrection_CreateFcn(hObject, eventdata, handles)
% hObject    handle to edit_leftRightCorrection (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end


function edit_useDeconvolved_Callback(hObject, eventdata, handles)
% hObject    handle to edit_useDeconvolved (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of edit_useDeconvolved as text
%        str2double(get(hObject,'String')) returns contents of edit_useDeconvolved as a double

% --- Executes during object creation, after setting all properties.
function edit_useDeconvolved_CreateFcn(hObject, eventdata, handles)
% hObject    handle to edit_useDeconvolved (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end



function edit_otherChannel_Callback(hObject, eventdata, handles)
% hObject    handle to edit_otherChannel (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of edit_otherChannel as text
%        str2double(get(hObject,'String')) returns contents of edit_otherChannel as a double


% --- Executes on button press in edit_usePhotobleach.
function edit_usePhotobleach_Callback(hObject, eventdata, handles)
% hObject    handle to edit_usePhotobleach (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hint: get(hObject,'Value') returns toggle state of edit_usePhotobleach


% --- Executes on selection change in listbox_mainChannel.
function listbox_mainChannel_Callback(hObject, eventdata, handles)
% hObject    handle to listbox_mainChannel (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: contents = cellstr(get(hObject,'String')) returns listbox_mainChannel contents as cell array
%        contents{get(hObject,'Value')} returns selected item from listbox_mainChannel


% --- Executes during object creation, after setting all properties.
function listbox_mainChannel_CreateFcn(hObject, eventdata, handles)
% hObject    handle to listbox_mainChannel (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: listbox controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end


% --- Executes on selection change in popupmenu_mainChannel.
function popupmenu_mainChannel_Callback(hObject, eventdata, handles)
% hObject    handle to popupmenu_mainChannel (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: contents = cellstr(get(hObject,'String')) returns popupmenu_mainChannel contents as cell array
%        contents{get(hObject,'Value')} returns selected item from popupmenu_mainChannel
% handles.popupmenu_mainChannel.String = ['self' string(userData.mainChannelOptions)];
if  ~strcmp(handles.popupmenu_mainChannel.String{handles.popupmenu_mainChannel.Value},'self') 
    handles.listbox_mainChannel.Visible = 'On';
    handles.pushbutton_addMainChannel.Visible = 'On';
    handles.pushbutton_rmMainChannel.Visible = 'On';
else
    handles.listbox_mainChannel.Visible = 'Off';
    handles.pushbutton_addMainChannel.Visible = 'Off';
    handles.pushbutton_rmMainChannel.Visible = 'Off';
end



% --- Executes during object creation, after setting all properties.
function popupmenu_mainChannel_CreateFcn(hObject, eventdata, handles)
% hObject    handle to popupmenu_mainChannel (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: popupmenu controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end


% --- Executes on button press in pushbutton_addMainChannel.
function pushbutton_addMainChannel_Callback(hObject, eventdata, handles)
% hObject    handle to pushbutton_addMainChannel (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
val = handles.popupmenu_mainChannel.Value;
strM = handles.popupmenu_mainChannel.String;
value = strM(val);
if ~ischar(value)
    value = str2double(value);
%     scales = str2num(get(handles.listbox_Scales,'String'));
    if ~isempty(handles.listbox_mainChannel.String)
        scales = [cellfun(@(x) str2num(x), (get(handles.listbox_mainChannel, 'String')))]
        if ismember(value,scales), return; end
        scales = sort([scales; value]);        
    else
        scales = value;
    end
    set(handles.listbox_mainChannel,'String',arrayfun(@(x) num2str(x), scales, 'unif', 0));
end

% --- Executes on button press in pushbutton_rmMainChannel.
function pushbutton_rmMainChannel_Callback(hObject, eventdata, handles)
% hObject    handle to pushbutton_rmMainChannel (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
props = get(handles.listbox_mainChannel,{'String','Value'});
if isempty(props{1}), return; end

props{1}(props{2})=[];
set(handles.listbox_mainChannel,'String',props{1},'Value',max(1,props{2}-1));


% --- Executes on button press in edit_useDifImage.
function edit_useDifImage_Callback(hObject, eventdata, handles)
% hObject    handle to edit_useDifImage (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hint: get(hObject,'Value') returns toggle state of edit_useDifImage
