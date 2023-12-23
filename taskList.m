function tasks = taskList(detailed, varargin)
% @brief List processes
%
% List the processes running on a Windows host
%
% @note Some fields may not be present, if they are not applicable to all
% the listed processes.
%
% @param detailed Whether to return detailed information, defaults to false
% @param varargin Either
%   - No parameter: Disable filtering
%   - One parameter: The image name that must be matched
%   - Two parameters: The filter property (among \c 'ImageName',
% \c 'PID', \c 'SessionName', \c 'SessionNumber', \c 'State', \c 'UserName',
% and \c 'WindowTitle') and the filter value
% @return A column structure array whose elements describe the tasks
% running on a host. The names of its fields are:
%   - \c 'ImageName', the process image name
%   - \c 'PID', the PID number as a double
%   - \c 'SessionName', the session name
%   - \c 'SessionNumber', the session number
%   - \c 'Memory', the memory used by the process in Ko as a double
%   - \c 'State', the process state
%   - \c 'UserName', the process user name
%   - \c 'CpuTime', the time the process consumed
%   - \c 'WindowTitle', the windows title
%
% % Copyright:  2023 Pascal COMBES <pascom@orange.fr>
% % Author:     Pascal COMBES <pascom@orange.fr>
% % Date:       December 22nd, 2023
% % Version:    1.0
% % License:    GPLv3
% % Requires:

    % Argument processing
    if (nargin < 1)
        detailed = false;
    end
    if (nargin < 2)
        filter = '';
    elseif (nargin < 3)
        filter = sprintf('/FI "IMAGENAME eq %s"', strrep(varargin{1}, '"', '\"'));
    else
        switch (varargin{1})
            case 'ImageName'
                filter = sprintf('/FI "IMAGENAME eq %s"', strrep(varargin{2}, '"', '\"'));
            case 'PID'
                filter = sprintf('/FI "PID eq %d"', varargin{2});
            case 'SessionName'
                filter = sprintf('/FI "SESSIONNAME eq %s"', strrep(varargin{2}, '"', '\"'));
            case 'SessionNumber'
                filter = sprintf('/FI "SESSION eq %d"', varargin{2});
            case 'State'
                filter = sprintf('/FI "STATUS eq %s"', strrep(varargin{2}, '"', '\"'));
            case 'UserName'
                filter = sprintf('/FI "USERNAME eq %s"', strrep(varargin{2}, '"', '\"'));
            case 'WindowTitle'
                filter = sprintf('/FI "WINDOWTITLE eq %s"', strrep(varargin{2}, '"', '\"'));
            otherwise
                error('taskList:FilterError', 'No such filter: %s', varargin{1});
        end
    end
    % Run command
    if detailed
        cmd = ['tasklist /V ', filter, ' /FO CSV /NH'];
    else
        cmd = ['tasklist ', filter, ' /FO CSV /NH'];
    end
    fprintf('Execting ''%s'' ...', cmd)
    [status, stdOut] = system(cmd);
    if (status ~= 0)
        fprintf(' ERROR\n');
        error('taskList:SystemError', 'Could not get status from system:\n%s', stdOut);
    else
        fprintf(' DONE\n');
    end
    % Parse command output
    lines = transpose(strsplit(stdOut, char(10)));
    lines(cellfun(@isempty, lines)) = [];
    tasks = processLines(lines);
end

function tasks = processLines(lines)
% @brief Parse \c tasklist output
%
% Parse each line of \c tasklist output into a structure.
%
% @param lines Output from \c tasklist split by lines
% @return A column structure array with one line for each task
% Its lines have the following fields:
%   - \c 'ImageName', the process image name
%   - \c 'PID', the PID number as a double
%   - \c 'SessionName', the session name
%   - \c 'SessionNumber', the session number
%   - \c 'Memory', the memory used by the process in Ko as a double
%   - \c 'State', the process state
%   - \c 'UserName', the process user name
%   - \c 'CpuTime', the time the process consumed
%   - \c 'WindowTitle', the windows title

    % No process matches the filter
    if ((size(lines, 1) == 1) && (sum(lines{1} == ',') < 4))
        lines = cell(0, 1);
    end
    % Initialisation
    fieldNames = {'ImageName', 'PID', 'SessionName', 'SessionNumber', 'Memory', 'State', 'UserName', 'CpuTime', 'WindowTitle'};
    structArgs = cell(1, 2*size(fieldNames, 2));
    for f = 1:size(fieldNames, 2)
        structArgs{2*f - 1} = fieldNames{f};
        structArgs{2*f} = cell(size(lines));
    end
    tasks = struct(structArgs{:});
    % Parse every line
    for l = 1:size(lines, 1)
        b = 1;
        f = 1;
        line = lines{l};
        while (b < size(line, 2))
            % Find end of token
            if (lines{l}(b) == '"')
                b = b + 1;
                e = find(line((b + 1):end) == '"', 1, 'first');
                if isempty(e)
                    error('taskList:ParserError', 'Missing quote in line: \n%s', line);
                end
                e = b + e - 1;
            else
                e = find(line((b + 1):end) == ',', 1, 'first');
                if isempty(e)
                    error('taskList:ParserError', 'Missing comma in line: \n%s', line);
                end
                e = b + e - 1;
            end
            % Update task information
            switch (fieldNames{f})
                case {'ImageName', 'SessionName', 'State', 'CpuTime'}
                    tasks(l).(fieldNames{f}) = line(b:e);
                case {'PID', 'SessionNumber'}
                    tasks(l).(fieldNames{f}) = str2double(line(b:e));
                case 'Memory'
                    tasks(l).(fieldNames{f}) = str2double(strrep(line(b:(e - 3)), char(160), ''));
                case {'UserName', 'WindowTitle'}
                    if ~strcmp(line(b:e), 'N/A')
                        tasks(l).(fieldNames{f}) = line(b:e);
                    end
                otherwise
                    error('taskList:LogicError', 'Unknown field name: %s', fieldNames{f})
            end
            % Find beginning of next token
            b = e + 1;
            if (line(b) == '"')
                b = b + 1;
            end
            if ((b < size(line, 2)) && (line(b) == ','))
                b = b + 1;
            end
            f = f + 1;
        end
    end
    % Remove missing fields
    for field = fieldNames
        if isempty([tasks.(field{:})])
            tasks = rmfield(tasks, field{:});
        end
    end
end
