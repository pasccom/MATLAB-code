function [fullPathStr] = fullpath(pathStr)
% @brief Absolute path
%
% Find the absolute path to the given path. The given path
% may point to a file, a folder, or a non existing thing.
% @param pathStr A path (relalive or absolute).
% @return The absolute path to the given path.
%
% % Copyright:  2015-2023 Pascal COMBES <pascom@orange.fr>
% % Author:     Pascal COMBES <pascom@orange.fr>
% % Date:       December 24th, 2023
% % Version:    1.0
% % License:    GPLv3
% % Requires:   chdir

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
    while (true)
        try
            if isempty(filepath)
                fullPathStr = fullfile(pwd, [filename, fileext]);
                break;
            end
            if strcmp(filepath, filesep)
                fullPathStr = [filepath, filename, fileext];
                break;
            end
            chdir(filepath);
            fullPathStr = fullfile(pwd, [filename, fileext]);
            break;
        catch anyErr
            if strcmp(anyErr.identifier, 'chdir:NonExistentFolder')
                [filepath, name, ext] = fileparts(filepath);
                if ~isempty(ext)
                    filename = fullfile([name, ext], filename);
                else
                    filename = fullfile(name, filename);
                end
            else
                rethrow(anyErr);
            end
        end
    end
    % Return to initial directory:
    if ~strcmp(oldPwd, pwd)
        chdir('-');
    end
end