function [fullPathStr] = fullpath(pathStr)
%% FULLPATH Returns the absolute path to the path given.
% This function finds the absolute path to the given path. The given path
% may point to a file, a folder, or a non existant thing.
%   @param pathStr A path to somewhere.
%   @returns fullpathStr The absolute path to the path.
%
% Copyright 2015 Pascal COMBES <pascom@orange.fr>
%
% Author:   Pascal COMBES <pascom@orange.fr>
% Date:     February 15th, 2015
% Version:  1.0.0
% License:  GPLv3
% Requires: chdir

    % Finds file path, file name and file extension:
    if (((size(pathStr, 2) >= 1) && strcmp(pathStr(end), '.')) || ...
        ((size(pathStr, 2) >= 2) && strcmp(pathStr((end-1):end), '..')))
        filename = '';
        fileext = '';
        filepath = pathStr;
    else
        [filepath, filename, fileext] = fileparts(pathStr);
    end
    % Change to file path:
    oldPwd = pwd;
    chdir(filepath);
    % Full path is now: [pwd, filesep, filename, fileext]:
    fullPathStr = fullfile(pwd, [filename, fileext]);
    % Return to initial directory:
    if ~strcmp(oldPwd, pwd)
        chdir('-');
    end
end