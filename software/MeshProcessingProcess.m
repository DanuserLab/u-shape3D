classdef MeshProcessingProcess < DataProcessingProcess & NonSingularProcess
% MESHPROCESSINGPROCESS - (abstract) "helper" class containing commonly used methods for the
% Morphology3DPackage processess, including draw method for generating GUI-graphjh
% Example concrete class: SurfaceSegmentation3DProcess.m
% Andrew R. Jamieson, July - 2018 
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
%
% Copyright (C) 2024, Danuser Lab - UTSouthwestern 
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

    methods (Access = public)
		
		function obj = MeshProcessingProcess(owner, varargin)
			obj = obj@DataProcessingProcess(owner, varargin{:});	
		end

		function output = loadChannelOutput(obj, iChan, varargin)
           output = [];         
        end
        
        function setParameters(obj, params, varargin)
            % overloaded method to conform Meghan's channel parameter to standard naming convention for GUI and API
            if isfield(params, 'channels')
                if ischar(params.channels) && strcmp('all', params.channels)
                    params.ChannelIndex = 1:numel(obj.owner_.channels_);
                elseif isnumeric(params.channels)
                    params.ChannelIndex = params.channels;
                else
%                     params.ChannelIndex = []; %%% NEED TO CHECK
                end
            end
            try
                obj.checkParameters(obj.owner_,params);
            catch
                % disp('parameter check failed!');
            end

            obj.setParameters@Process(params, varargin{:})
        end
        
        function setPara(obj, params, varargin)
            obj.setParameters(params, varargin{:});
        end
        
        function h = draw(obj,iChan,varargin)
            % Input check
            if ~ismember('getDrawableOutput',methods(obj)), h=[]; return; end
            outputList = obj.getDrawableOutput();
            ip = inputParser;
            ip.addRequired('obj',@(x) isa(x,'Process'));
            ip.addRequired('iChan',@isnumeric);
            ip.addOptional('iFrame',[],@isnumeric);
            ip.addParameter('output',outputList(1).var,@(x) any(cellfun(@(y) isequal(x,y),{outputList.var})));
            ip.addParameter('useCache', false, @islogical);
            ip.addParameter('movieOverlay', false, @islogical);
            ip.KeepUnmatched = true;
            ip.parse(obj,iChan,varargin{:});
            p = ip.Results;
            
            % data = obj.owner_;
%             data.obj = obj;
            data = p;
            iOutput = find(cellfun(@(y) isequal(ip.Results.output,y),{outputList.var}));
            
            % Initialize display method
            % Note use obj.resetDisplayMethod(); to reset if problems
            if isempty(obj.getDisplayMethod(iOutput,iChan))
                obj.setDisplayMethod(iOutput, iChan,...
                    outputList(iOutput).defaultDisplayMethod(iChan));
            end
            
            % Create graphic tag and delegate drawing to the display class
            tag = ['process' num2str(obj.getIndex()) '_channel' num2str(iChan) '_output' num2str(iOutput)];
            if ip.Results.movieOverlay % if not channel specific (to match what movieViewer expects)
                tag = ['process' num2str(obj.getIndex()) '_output' num2str(iOutput)];
            end
            h = obj.getDisplayMethod(iOutput, iChan).draw(data,tag,'iFrame', p.iFrame, ip.Unmatched);
        end        
    end
    
    methods (Static)
        function validChannels = checkValidMeshChannels(process, previousProcessName)
            % helper function for process dependencies, help prevent having to re-run
            % checks previous process has run and has valid channel output, 
            % returns list of valid channels output for previous process
            % will update the parameter settings to valid channels only
            prevProc = process.owner_.findProcessTag(previousProcessName,false, false,'tag',false,'last');
            validChannels = find(prevProc.checkChannelOutput);
            try
                if any(process.funParams_.ChannelIndex ~= validChannels)
                    warning(['Reconfiguring Channel selection to valid channel outputs (based on completed ' previousProcessName ': ' ...
                    num2str(validChannels)]);                    
                    funParams = process.funParams_;
                    funParams.ChannelIndex = validChannels;
                    % p.chanList = validChannels;
                    process.setPara(funParams)
                end
            catch
                warning(['Reconfiguring Channel selection to valid channel outputs (based on completed ' previousProcessName ': ' ...
                         num2str(validChannels)]);                    
                funParams = process.funParams_;
                funParams.ChannelIndex = validChannels;
                % p.chanList = validChannels;
                process.setPara(funParams)
            end
        end           
    end
end