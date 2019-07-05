function varargout = RenderMeshProcessGUI(varargin)
% rendermeshprocessgui M-file for rendermeshprocessgui.fig
%      rendermeshprocessgui, by itself, creates a new rendermeshprocessgui or raises the existing
%      singleton*.
%
%      H = rendermeshprocessgui returns the handle to a new rendermeshprocessgui or the handle to
%      the existing singleton*.
%
%      rendermeshprocessgui('CALLBACK',hObject,eventData,handles,...) calls the local
%      function named CALLBACK in rendermeshprocessgui.M with the given input arguments.
%
%      rendermeshprocessgui('Property','Value',...) creates a new rendermeshprocessgui or raises the
%      existing singleton*.  Starting from the left, property value pairs are
%      applied to the GUI before rendermeshprocessgui_openingfcn gets called.  An
%      unrecognized property name or invalid value makes property application
%      stop.  All inputs are passed to rendermeshprocessgui_openingfcn via varargin.
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

% Edit the above text to modify the response to help rendermeshprocessgui

% Last Modified by GUIDE v2.5 05-Oct-2018 12:11:58

% Begin initialization code - DO NOT EDIT
gui_Singleton = 1;
gui_State = struct('gui_Name',       mfilename, ...
                   'gui_Singleton',  gui_Singleton, ...
                   'gui_OpeningFcn', @RenderMeshProcessGUI_OpeningFcn, ...
                   'gui_OutputFcn',  @RenderMeshProcessGUI_OutputFcn, ...
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

% --- Executes just before rendermeshprocessgui is made visible.
function RenderMeshProcessGUI_OpeningFcn(hObject, eventdata, handles, varargin)

processGUI_OpeningFcn(hObject, eventdata, handles, varargin{:},'initChannel',1);

% Set-up parameters
userData = get(handles.figure1,'UserData');
funParams = userData.crtProc.funParams_;

% % Original Selections
% userData.surfaceModeOptions = {'blank', 'curvature', 'curvatureWatersheds', 'curvatureSpillDepth', ...
%     'surfaceSegment', 'surfaceSegmentPreLocal', 'surfaceSegmentPatchMerge', ...
%     'surfaceSegmentInterTriangle', 'surfaceSegmentInterLOS', 'protrusions', ...
%     'protrusionsType',  'SVMscore', 'SVMscoreThree', 'clickedOn', ...
%     'blebsShrunk', 'blebsTracked', 'blebsTrackedOverlap', 'motion', ...
%     'motionForwards', 'intensity'};

%%% Included with distribution - but needs fixing...
% userData.surfaceModeOptions = {'blank', 'curvature', 'curvatureWatersheds', 'curvatureSpillDepth', ...
%     'surfaceSegment', 'surfaceSegmentPreLocal', 'surfaceSegmentPatchMerge', ...
%     'surfaceSegmentInterTriangle', 'surfaceSegmentInterLOS', 'protrusions', ...
%     'protrusionsType',  'SVMscore', 'SVMscoreThree', 'clickedOn', ...
%     'blebsShrunk', 'motion', ...
%     'motionForwards', 'intensity'};

%% Currently working with GUI release
userData.surfaceModeOptions = {'blank', 'curvature', ...
    'surfaceSegment', 'surfaceSegmentPatchMerge', ...
    'protrusions', ...
    'protrusionsType',  'SVMscore', 'SVMscoreThree', ...
    'motion', ...
    'motionForwards', 'intensity'};
userData.meshModeOptions = {'surfaceImage', 'actualMesh'};

%Remove the output directory as we don't want to replicate it to other
%movies if the "apply to all movies" box is checked. Ideally we would
%explicitly only replicate the parameters we set in this GUI but this is a
%quick fix. - HLE
if isfield(funParams,'OutputDirectory')
    funParams = rmfield(funParams,'OutputDirectory');
end


paramNames = fieldnames(funParams);
for i = 1:numel(paramNames)
    paramName = paramNames{i};
    parVal = funParams.(paramName);
    if any(ismember(fieldnames(handles), ['edit_' paramName])) && ~strcmp('setView', paramName) ...
            && ~strcmp('surfaceMode', paramName) && ~strcmp('meshMode', paramName)
        if islogical(funParams.(paramName)) || strcmp(get(handles.(['edit_' paramName]),'Style'),'checkbox')
            set(handles.(['edit_' paramName]), 'Value', parVal);
%             parVal = get(handles.(['edit_' paramName]), 'Value');
%             funParams.(paramName)(iChan) = parVal;
        elseif iscell(funParams.(paramName))   
            set(handles.(['edit_' paramName]), 'String', parVal{:});
%             parVal = get(handles.(['edit_' paramName]), 'String');
%             funParams.(paramName)(iChan) = parVal;
        else
            set(handles.(['edit_' paramName]), 'String', parVal);
%             parVal = get(handles.(['edit_' paramName]), 'String');
%             funParams.(paramName)(iChan) = str2double(parVal);
        end
    elseif strcmp('surfaceMode', paramName)
        set(handles.popupmenu_surfaceMode, 'String', userData.surfaceModeOptions,...
        'Value', find(ismember(userData.surfaceModeOptions, parVal))) 
    elseif strcmp('meshMode', paramName)        
        set(handles.popupmenu_meshMode, 'String', userData.meshModeOptions,...
        'Value', find(ismember(userData.meshModeOptions, parVal)))        
    elseif strcmp('setView', paramName)
        parVal2 = parVal(2);
        parVal1 = parVal(1);
        set(handles.(['edit_' paramName '2']), 'String', parVal2);
        set(handles.(['edit_' paramName '1']), 'String', parVal1);
    end
end

edit_makeMovie_Callback(hObject, eventdata, handles);
edit_makeRotation_Callback(hObject, eventdata, handles);
edit_makeColladaDae_Callback(hObject, eventdata, handles);
%Update channel parameter selection dropdown
% popupmenu_CurrentChannel_Callback(hObject, eventdata, handles);
% Update GUI user data
set(handles.figure1, 'UserData', userData);
handles.output = hObject;
guidata(hObject, handles);

% --- Outputs from this function are returned to the command line.
function varargout = RenderMeshProcessGUI_OutputFcn(~, ~, handles) 
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
% pushbutton_saveChannelParams_Callback(hObject, eventdata, handles)

userData = get(handles.figure1,'UserData');
funParams = userData.crtProc.funParams_;

% Retrieve detection parameters
% funParams = get(handles.popupmenu_CurrentChannel,'UserData');
% Retrieve GUI-defined non-channel specific parameters

paramNames = fieldnames(funParams);
    for i = 1:numel(paramNames)
    paramName = paramNames{i};
%     parVal = funParams.(paramName);
    if any(ismember(fieldnames(handles), ['edit_' paramName])) && ~strcmp('setView', paramName) ...
            && ~strcmp('surfaceMode', paramName) && ~strcmp('meshMode', paramName)
        if islogical(funParams.(paramName)) || strcmp(get(handles.(['edit_' paramName]),'Style'),'checkbox')
%             set(handles.(['edit_' paramName]), 'Value', parVal);
            parVal = get(handles.(['edit_' paramName]), 'Value');
            funParams.(paramName) = parVal;
        elseif iscell(funParams.(paramName))   
%             set(handles.(['edit_' paramName]), 'String', parVal{:});
            parVal = get(handles.(['edit_' paramName]), 'String');
            funParams.(paramName) = parVal;
        else
%             set(handles.(['edit_' paramName]), 'String', parVal);
            parVal = get(handles.(['edit_' paramName]), 'String');
            if strcmp('rotSavePath',paramName) || strcmp('movieSavePath',paramName) ...
                    || strcmp('daeSavePathMain',paramName)
                funParams.(paramName) = parVal; 
            else
                funParams.(paramName) = str2double(parVal);
            end
        end
    elseif strcmp('meshMode', paramName)
       strSet = handles.popupmenu_meshMode.String;
        val = handles.popupmenu_meshMode.Value;
        funParams.(paramName) = strSet{val};      
    elseif strcmp('surfaceMode', paramName)
        strSet = handles.popupmenu_surfaceMode.String;
        val = handles.popupmenu_surfaceMode.Value;
        funParams.(paramName) = strSet{val};
    elseif strcmp('setView', paramName)
        parVal1 = str2num(get(handles.(['edit_' paramName '1']), 'String'));
        parVal2 = str2num(get(handles.(['edit_' paramName '2']), 'String'));
        parVal =  [parVal1 parVal2];
        funParams.(paramName) = parVal;
    end
end

%Get selected image channels
channelIndex = get(handles.listbox_selectedChannels, 'Userdata');
if isempty(channelIndex)
    errordlg('Please select at least one input channel from ''Available Channels''.','Setting Error','modal')
    return;
end
funParams.ChannelIndex = channelIndex;
funParams.channels = funParams.ChannelIndex;
processGUI_ApplyFcn(hObject, eventdata, handles,funParams);

% --- Executes on button press in popupmenu_motionMode.
% --- Executes on button press in edit_frame.
function edit_frame_Callback(hObject, eventdata, handles)
% hObject    handle to edit_frame (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hint: get(hObject,'Value') returns toggle state of edit_frame
userData = get(handles.figure1,'UserData');
if str2num(hObject.String) > userData.MD.nFrames_ || str2num(hObject.String) <= 0
    errordlg('Please enter valid frame number');
    hObject.String = '1';
    return
end


% --- Executes on button press in edit_makeRotation.
function edit_makeRotation_Callback(hObject, eventdata, handles)
% hObject    handle to edit_makeRotation (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hint: get(hObject,'Value') returns toggle state of edit_makeRotation
if logical(handles.edit_makeRotation.Value) == true
    set(handles.uipanel_rotation,'Visible','on');
    handles.edit_makeMovieAVI.Visible = 'on';
    handles.text_makeMovieAVI.Visible = 'on';
    handles.edit_makeMovieAVI.Value = 1;
else
    set(handles.uipanel_rotation,'Visible','off');
    if logical(handles.edit_makeMovie.Value) ~= true
        handles.edit_makeMovieAVI.Visible = 'off';
        handles.text_makeMovieAVI.Visible = 'off';
        handles.edit_makeMovieAVI.Value = 0;
    end
end


% --- Executes on button press in edit_calculateVonMises.

% --- Executes on button press in edit_makeMovie.
function edit_makeMovie_Callback(hObject, eventdata, handles)
% hObject    handle to edit_makeMovie (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hint: get(hObject,'Value') returns toggle state of edit_makeMovie
if logical(handles.edit_makeMovie.Value) == true
    set(handles.uipanel_savePath,'Visible','on');
    handles.edit_makeMovieAVI.Visible = 'on';
    handles.text_makeMovieAVI.Visible = 'on';
    handles.edit_makeMovieAVI.Value = 1;
else
    set(handles.uipanel_savePath,'Visible','off');
    if logical(handles.edit_makeRotation.Value) ~= true
        handles.edit_makeMovieAVI.Visible = 'off';
        handles.text_makeMovieAVI.Visible = 'off';
        handles.edit_makeMovieAVI.Value = 0;
    end
end




% --- Executes on button press in edit_makeMovieAVI.
function edit_makeMovieAVI_Callback(hObject, eventdata, handles)
% hObject    handle to edit_makeMovieAVI (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hint: get(hObject,'Value') returns toggle state of edit_makeMovieAVI
% Hint: get(hObject,'Value') returns toggle state of edit_makeMovie

% --- Executes on button press in edit_makeColladaDae.
function edit_makeColladaDae_Callback(hObject, eventdata, handles)
% hObject    handle to edit_makeColladaDae (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hint: get(hObject,'Value') returns toggle state of edit_makeColladaDae
if logical(handles.edit_makeColladaDae.Value) == true
    set(handles.uipanel_dae,'Visible','on');
else
    set(handles.uipanel_dae,'Visible','off');
end

% --- Executes on button press in edit_calculateDistanceTransformProtrusions.
function edit_calculateDistanceTransformProtrusions_Callback(hObject, eventdata, handles)
% hObject    handle to edit_calculateDistanceTransformProtrusions (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hint: get(hObject,'Value') returns toggle state of edit_calculateDistanceTransformProtrusions


% --- Executes on button press in pushbutton_dae.
function pushbutton_dae_Callback(hObject, eventdata, handles)
% hObject    handle to pushbutton_dae (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
if exist(handles.edit_daeSavePathMain.String,'dir') == 7
    pathPSF = uigetdir(handles.edit_daeSavePathMain.String, 'Select dir for rotation output fig');
else
    pathPSF = uigetdir('Select dir for rotation output fig');    
end
handles.edit_daeSavePathMain.String = pathPSF;


function edit_surfaceSegmentInterIter_Callback(hObject, eventdata, handles)
% hObject    handle to edit_surfaceSegmentInterIter (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of edit_surfaceSegmentInterIter as text
%        str2double(get(hObject,'String')) returns contents of edit_surfaceSegmentInterIter as a double


% --- Executes during object creation, after setting all properties.
function edit_surfaceSegmentInterIter_CreateFcn(hObject, eventdata, handles)
% hObject    handle to edit_surfaceSegmentInterIter (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end



function edit_meshAlpha_Callback(hObject, eventdata, handles)
% hObject    handle to edit_meshAlpha (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of edit_meshAlpha as text
%        str2double(get(hObject,'String')) returns contents of edit_meshAlpha as a double


% --- Executes during object creation, after setting all properties.
function edit_meshAlpha_CreateFcn(hObject, eventdata, handles)
% hObject    handle to edit_meshAlpha (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end


% --- Executes on selection change in popupmenu_meshMode.
function popupmenu_meshMode_Callback(hObject, eventdata, handles)
% hObject    handle to popupmenu_meshMode (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: contents = cellstr(get(hObject,'String')) returns popupmenu_meshMode contents as cell array
%        contents{get(hObject,'Value')} returns selected item from popupmenu_meshMode


% --- Executes during object creation, after setting all properties.
function popupmenu_meshMode_CreateFcn(hObject, eventdata, handles)
% hObject    handle to popupmenu_meshMode (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: popupmenu controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end


% --- Executes on selection change in popupmenu_surfaceMode.
function popupmenu_surfaceMode_Callback(hObject, eventdata, handles)
% hObject    handle to popupmenu_surfaceMode (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: contents = cellstr(get(hObject,'String')) returns popupmenu_surfaceMode contents as cell array
%        contents{get(hObject,'Value')} returns selected item from popupmenu_surfaceMode


% --- Executes during object creation, after setting all properties.
function popupmenu_surfaceMode_CreateFcn(hObject, eventdata, handles)
% hObject    handle to popupmenu_surfaceMode (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: popupmenu controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end



function edit_setView1_Callback(hObject, eventdata, handles)
% hObject    handle to edit_setView1 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of edit_setView1 as text
%        str2double(get(hObject,'String')) returns contents of edit_setView1 as a double


% --- Executes during object creation, after setting all properties.
function edit_setView1_CreateFcn(hObject, eventdata, handles)
% hObject    handle to edit_setView1 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end



function edit_setView2_Callback(hObject, eventdata, handles)
% hObject    handle to edit_setView2 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of edit_setView2 as text
%        str2double(get(hObject,'String')) returns contents of edit_setView2 as a double


% --- Executes during object creation, after setting all properties.
function edit_setView2_CreateFcn(hObject, eventdata, handles)
% hObject    handle to edit_setView2 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end


% --- Executes on button press in pushbutton_rotSavePath.
function pushbutton_rotSavePath_Callback(hObject, eventdata, handles)
% hObject    handle to pushbutton_rotSavePath (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
if exist(handles.edit_rotSavePath.String,'dir') == 7
    pathPSF = uigetdir(handles.edit_rotSavePath.String, 'Select dir for rotation output fig');
else
    pathPSF = uigetdir('Select dir for rotation output fig');    
end

handles.edit_rotSavePath.String = pathPSF;
% --- Executes on button press in pushbutton_movieSavePath.
function pushbutton_movieSavePath_Callback(hObject, eventdata, handles)
% hObject    handle to pushbutton_movieSavePath (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
if exist(handles.edit_movieSavePath.String,'dir') == 7
    pathPSF = uigetdir(handles.edit_movieSavePath.String, 'Select dir for rotation output fig');
else
    pathPSF = uigetdir('Select dir for rotation output fig');    
end
handles.edit_movieSavePath.String = pathPSF;
