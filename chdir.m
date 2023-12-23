function varargout = chdir(path, varargin)
%% CHDIR Equivent to cd with a history.
% This command is equivalent to cd in all cases except when the path is
% '-'. In this case it goes back to the previously visited directory.
% This function is very useful in initialisation functions of models (see
% example below).
%   @param path The path to change to.
%
% This function keeps a stack of visited directories which can be
% obtained by sending 'Debug' as second argument.
%
% Examples:
%   chdir('Folder'); % Now in ./Folder directory
%   chdir('-'); % Returns in initial directory.
%
%   [modelPath, ~, ~] = fileparts(which(gcs));
%   chdir(modelPath);
%   % Model initialisation code.
%   chdir('-');
%
% Copyright 2015 Pascal COMBES <pascom@orange.fr>
%
% Author:   Pascal COMBES <pascom@orange.fr>
% Date:     February 15th, 2015
% Version:  1.0.0
% License:  GPLv3
% Requires: 

    persistent oldPwd
    if isempty(oldPwd)
        oldPwd = {};
    end
    
    % Special second argument for debugging
    if ((nargin == 2) && strcmp(varargin{1}, 'Debug'))
        varargout = {oldPwd};
        return;
    end
    
    % Argument number checking
    if (nargin ~= 1)
        error('chdir:BadArgumentNumber', 'This function accepts only one argument. %d were passed.', nargin);
    end
    if (nargout ~= 0)
        error('chdir:BadArgumentNumber', 'This function doesn''t return any argument. %d were asked.', nargout);
    end
    
    if (strcmp(path, '-'))
        % Go to previously visited directory
        if (isempty(oldPwd))
            warning('chdir:NoHistory', 'No saved directory.')
        else
            cd(oldPwd{end});
            oldPwd(end) = [];
        end
    elseif (~strcmp(path, '.')  && ~strcmp(path, pwd))
        % Try to go to directory
        try
            oldPwd = [oldPwd, {pwd}];
            cd(path);
        catch anyErr
            % Fail if directory does not exist
            oldPwd(end) = [];
            if strcmp(anyErr.identifier, 'MATLAB:cd:NonExistentFolder')
                error('chdir:NonExistentFolder', 'Unable to change current folder to "%s"', path);
            end
            rethrow(anyErr);
        end
    end
end

