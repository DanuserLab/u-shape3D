function varargout = MotifDetection3DProcessGUI(varargin)
% motifdetection3dprocessgui M-file for motifdetection3dprocessgui.fig
%      motifdetection3dprocessgui, by itself, creates a new motifdetection3dprocessgui or raises the existing
%      singleton*.
%
%      H = motifdetection3dprocessgui returns the handle to a new motifdetection3dprocessgui or the handle to
%      the existing singleton*.
%
%      motifdetection3dprocessgui('CALLBACK',hObject,eventData,handles,...) calls the local
%      function named CALLBACK in motifdetection3dprocessgui.M with the given input arguments.
%
%      motifdetection3dprocessgui('Property','Value',...) creates a new motifdetection3dprocessgui or raises the
%      existing singleton*.  Starting from the left, property value pairs are
%      applied to the GUI before motifdetection3dprocessgui_openingfcn gets called.  An
%      unrecognized property name or invalid value makes property application
%      stop.  All inputs are passed to motifdetection3dprocessgui_openingfcn via varargin.
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

% Edit the above text to modify the response to help motifdetection3dprocessgui

% Last Modified by GUIDE v2.5 14-May-2019 17:08:50

% Begin initialization code - DO NOT EDIT
gui_Singleton = 1;
gui_State = struct('gui_Name',       mfilename, ...
                   'gui_Singleton',  gui_Singleton, ...
                   'gui_OpeningFcn', @MotifDetection3DProcessGUI_OpeningFcn, ...
                   'gui_OutputFcn',  @MotifDetection3DProcessGUI_OutputFcn, ...
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

% --- Executes just before motifdetection3dprocessgui is made visible.
function MotifDetection3DProcessGUI_OpeningFcn(hObject, eventdata, handles, varargin)

processGUI_OpeningFcn(hObject, eventdata, handles, varargin{:},'initChannel',1);

% Set-up parameters
userData = get(handles.figure1,'UserData');
funParams = userData.crtProc.funParams_;
%Remove the output directory as we don't want to replicate it to other
%movies if the "apply to all movies" box is checked. Ideally we would
%explicitly only replicate the parameters we set in this GUI but this is a
%quick fix. - HLE
if isfield(funParams,'OutputDirectory')
    funParams = rmfield(funParams,'OutputDirectory');
end


handles.listbox_svmPath.String = funParams.svmPath;

if iscell(handles.listbox_svmPath.String)
    defaultFile = handles.listbox_svmPath.String{1};
else
    defaultFile = handles.listbox_svmPath.String;
end

try 
    defaultDir = fileparts(defaultFile);
catch
    defaultDir = [];
end

if ~(exist(defaultDir,'dir') == 7)
    handles.defaultDir_svm = [];
else
    handles.defaultDir_svm = defaultDir;
end    
handles.edit_userClicksName.String = funParams.userClicksName;
handles.edit_removePatchesSVMpath.String = funParams.removePatchesSVMpath;
% set(handles.popupmenu_CurrentChannel,'UserData',funParams);
set(handles.popupmenu_CurrentChannel,'UserData',funParams);

% handles
% handles.edit_svmPath.String = funParams.svmPath;

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
function varargout = MotifDetection3DProcessGUI_OutputFcn(~, ~, handles) 
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

if isempty(get(handles.listbox_svmPath, 'String')) %|| exist(get(handles.edit_svmPath, 'String'),'file') ~= 2
    errordlg('Please provide valid svm .mat file path ','Setting Error','modal')
    return;
elseif iscell(get(handles.listbox_svmPath, 'String'))
    strings_ = get(handles.listbox_svmPath, 'String');
    for i = 1:length(strings_)
        if exist(strings_{i}, 'file') ~= 2
            errordlg(['Please provide valid svm .mat file path: ' strings_{1}], 'Setting Error','modal')
            return;            
        end
    end
elseif ischar(get(handles.listbox_svmPath, 'String')) && exist(get(handles.listbox_svmPath, 'String'),'file') ~= 2
    errordlg('Please provide valid svm .mat file path ','Setting Error','modal')
else
    
end

% if isempty(get(handles.edit_removePatchesSVMpath, 'String'))
%     errordlg('Please provide svm .mat file path ','Setting Error','modal')
%     return;
% end

% if isempty(get(handles.handles.edit_userClicksName, 'String'))
%     errordlg('Please provide svm .mat file path ','Setting Error','modal')
%     return;
% end

%Save the currently set per-channel parameters
pushbutton_saveChannelParams_Callback(hObject, eventdata, handles)

% Retrieve detection parameters
funParams = get(handles.popupmenu_CurrentChannel,'UserData');
% Retrieve GUI-defined non-channel specific parameters

funParams.svmPath = handles.listbox_svmPath.String;
funParams.userClicksName = handles.edit_userClicksName.String;
funParams.removePatchesSVMpath = handles.edit_removePatchesSVMpath.String;

%Get selected image channels
channelIndex = get(handles.listbox_selectedChannels, 'Userdata');
if isempty(channelIndex)
    errordlg('Please select at least one input channel from ''Available Channels''.','Setting Error','modal')
    return;
end
funParams.ChannelIndex = channelIndex;
funParams.channels = funParams.ChannelIndex;
processGUI_ApplyFcn(hObject, eventdata, handles,funParams);

% --- Executes on selection change in popupmenu_CurrentChannel.
function popupmenu_CurrentChannel_Callback(hObject, eventdata, handles)
% hObject    handle to popupmenu_CurrentChannel (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: contents = cellstr(get(hObject,'String')) returns popupmenu_CurrentChannel contents as cell array
%        contents{get(hObject,'Value')} returns selected item from popupmenu_CurrentChannel
userData=get(handles.figure1,'UserData');
funParams = get(handles.popupmenu_CurrentChannel,'UserData');

selChan = 1:numel(userData.MD.channels_);%For now just let them set parameters for all channels.
%selChan = get(handles.listbox_selectedChannels,'UserData');
chanStr = arrayfun(@(x)(['Channel ' num2str(x)]),selChan,'Unif',0);
set(handles.popupmenu_CurrentChannel,'String',chanStr);
iChan = get(handles.popupmenu_CurrentChannel,'Value');
%set(handles.popupmenu_CurrentChannel,'UserData',iChan);

% set(handles.popupmenu_deconMode, 'String', {'weiner','richLucy'},...
%      'Value', find(ismember(funParams.deconMode,{'weiner','richLucy'})))

% Set-up parameters
for i =1 : numel(funParams.PerChannelParams)
    paramName = funParams.PerChannelParams{i};
    parVal = funParams.(paramName)(iChan);
    if islogical(funParams.(paramName)) || strcmp(get(handles.(['edit_' paramName]),'Style'),'checkbox')
         set(handles.(['edit_' paramName]), 'Value', parVal);
    elseif iscell(funParams.(paramName))   
        set(handles.(['edit_' paramName]), 'String', parVal{:});
    else
        set(handles.(['edit_' paramName]), 'String', parVal);
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
    if islogical(funParams.(paramName)) || strcmp(get(handles.(['edit_' paramName]),'Style'),'checkbox')
        parVal = get(handles.(['edit_' paramName]), 'Value');
        funParams.(paramName)(iChan) = parVal;
    elseif iscell(funParams.(paramName))   
        parVal = get(handles.(['edit_' paramName]), 'String');
        funParams.(paramName)(iChan) = {parVal};
    else
        parVal = get(handles.(['edit_' paramName]), 'String');
        funParams.(paramName)(iChan) = str2double(parVal);
    end
end

set(handles.popupmenu_CurrentChannel,'UserData',funParams);


% --- Executes on button press in edit_usePatchMerge.
function edit_usePatchMerge_Callback(hObject, eventdata, handles)
% hObject    handle to edit_usePatchMerge (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hint: get(hObject,'Value') returns toggle state of edit_usePatchMerge


% --- Executes on button press in edit_calculateShrunk.
function edit_calculateShrunk_Callback(hObject, eventdata, handles)
% hObject    handle to edit_calculateShrunk (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hint: get(hObject,'Value') returns toggle state of edit_calculateShrunk


% --- Executes on button press in edit_useClicks.
function edit_useClicks_Callback(hObject, eventdata, handles)
% hObject    handle to edit_useClicks (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hint: get(hObject,'Value') returns toggle state of edit_useClicks


function edit_minMotifSize_Callback(hObject, eventdata, handles)
% hObject    handle to edit_minMotifSize (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of edit_minMotifSize as text
%        str2double(get(hObject,'String')) returns contents of edit_minMotifSize as a double


% --- Executes on button press in pushbutton_svmPath.
function pushbutton_svmPath_Callback(hObject, eventdata, handles)
% hObject    handle to pushbutton_svmPath (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

if ~isempty(handles.listbox_svmPath.String)
    if iscell(handles.listbox_svmPath.String)
        defaultDir = fileparts(handles.listbox_svmPath.String{1});
    else
        defaultDir = fileparts(handles.listbox_svmPath.String);
    end
    if ~(exist(defaultDir,'dir') == 7)
        defaultDir = handles.defaultDir_svm;
    else
        handles.defaultDir_svm = defaultDir;
    end
else
    defaultDir = handles.defaultDir_svm;
end
% grab a new svm Mat file
[fileSVM, pathSVM] = uigetfile('*.mat','Select SVM model .mat file', ... 
    defaultDir); 

% Cancelled by user
if (isnumeric(pathSVM) && pathSVM == 0) || (isnumeric(fileSVM) && fileSVM == 0)
    return
end

svmPath_String = fullfile(pathSVM,fileSVM);
if ismember(svmPath_String, handles.listbox_svmPath.String)
    return; 
else
    handles.listbox_svmPath.String = [handles.listbox_svmPath.String; {svmPath_String}];    
end



% --- Executes on button press in pushbutton_removePatchesSVMpath.
function pushbutton_removePatchesSVMpath_Callback(hObject, eventdata, handles)
% hObject    handle to pushbutton_removePatchesSVMpath (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
if exist(handles.edit_removePatchesSVMpath.String,'dir') == 7
    [fileSVM, pathSVM] = uigetfile('*.mat',...
               'Select SVM model .mat file',handles.edit_removePatchesSVMpath.String);
else
    [fileSVM, pathSVM] = uigetfile('*.mat',...
               'Select SVM model .mat file');    
end
handles.edit_removePatchesSVMpath.String = fullfile(pathSVM,fileSVM);


% --- Executes on button press in pushbutton_userClicksName.
function pushbutton_userClicksName_Callback(hObject, eventdata, handles)
% hObject    handle to pushbutton_userClicksName (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
if exist(handles.edit_userClicksName.String,'dir') == 7
    [fileSVM, pathSVM] = uigetfile('*.mat',...
               'Select SVM model .mat file',handles.edit_userClicksName.String);
else
    [fileSVM, pathSVM] = uigetfile('*.mat',...
               'Select SVM model .mat file');    
end
handles.edit_userClicksName.String = fullfile(pathSVM,fileSVM);


% --- Executes on selection change in listbox_svmPath.
function listbox_svmPath_Callback(hObject, eventdata, handles)
% hObject    handle to listbox_svmPath (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: contents = cellstr(get(hObject,'String')) returns listbox_svmPath contents as cell array
%        contents{get(hObject,'Value')} returns selected item from listbox_svmPath


% --- Executes during object creation, after setting all properties.
function listbox_svmPath_CreateFcn(hObject, eventdata, handles)
% hObject    handle to listbox_svmPath (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: listbox controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end


% --- Executes on button press in pushbutton_removeSVM.
function pushbutton_removeSVM_Callback(hObject, eventdata, handles)
% hObject    handle to pushbutton_removeSVM (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
props = get(handles.listbox_svmPath,{'String','Value'});

value_ = props{2};
strings_ = props{1};

if isempty(strings_), return; end

if iscell(strings_)
    strings_(value_) = [];
else
    strings_ = [];
end

if ~isempty(strings_)
    set(handles.listbox_svmPath,'String',strings_,'Value',1); %max(1,value_-1));
else
    set(handles.listbox_svmPath,'String',[],'Value',1); %max(1,value_-1));
end
