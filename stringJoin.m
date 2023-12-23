function [str] = stringJoin(strings, glue)
% @brief Glue strings in a cell array
%
% Merges a cell array of char into a single char array, using optionnally
% a glue, given as a char array.
% @deprecated As of MATLAB R2013a, `strsplit()` should preferably be used
% (the MATLAB function is more efficient and supports MATLAB strings).
% @param strings The strings to be merged as a cell array of char.
% @param glue Optionnal glue to be used between two strings
% (but not before the first one and after the last one)
% @return A string composed of all the parts gued together using the
% provided glue string.
% @sa stringSplit()
%
% \par Examples
% A single string is not modified
% \code
%   parts = 'a';
%   str = strjoin(parts)
%   str = 'a'
% \endcode
% even if glue is provided
% \code
%   parts = 'a';
%   str = strjoin(parts, ',')
%   str = 'a'
% \endcode
% When no glue is provided, strings are simply stuck together
% \code
%   parts = {'a', 'b', 'c', 'd', 'e', 'f'};
%   str = strjoin(parts)
%   str = 'abcdef'
% \endcode
% When glue is provided, it is inserted between each part
% \code
%   parts = {'a', 'b', 'c', 'd', 'e', 'f'};
%   str = strjoin(parts, ',')
%   str = 'a,b,c,d,e,f'
% \endcode
% Glue can even be multiple char long
% \code
%   parts = {'a', 'b', 'c', 'd', 'e', 'f'};
%   str = strjoin(parts, ', ')
%   str = 'a, b, c, d, e, f'
% \endcode
%
% % Copyright:  2015-2023 Pascal COMBES <pascom@orange.fr>
% % Author:     Pascal COMBES <pascom@orange.fr>
% % Date:       December 23rd, 2023
% % Version:    1.0
% % License:    GPLv3
% % Requires:

    %% Checking arguments
    % Stop here if there is nothing to join
    if(isempty(strings))
        str = '';
        return;
    end
    % Default value for glue
    if(nargin < 2)
        glue = '';
    end
    % Checking glue type
    if (~ischar(glue))
        error('StringJoin:InvalidArgument', 'Glue is expected to be of type char');
    end
    % Ensure strings is a cell array
    if(~iscell(strings))
        strings = {strings};
    end
    % Check that string is a column or a row cell array
    if((size(strings, 1) ~= 1) && (size(strings, 2) ~= 1))
        error('StringJoin:InvalidArgument', 'Cell should be either a row or a column cell array');
    end

    %% Compute total length
    totalLength = 0;
    for i = 1:max(size(strings))
        % Also check that the elements of strings are char arrays
        if(~ischar(strings{i}))
            error('StringJoin:InvalidArgument', 'Cell should be a cell array of strings');
        end
        totalLength = totalLength + size(strings{i}, 2);
    end
    totalLength = totalLength + (max(size(strings)) - 1)*size(glue, 2);

    %% Merge strings
    str = char(zeros(1, totalLength));
    j = 1;
    for i = 1:(max(size(strings)) - 1)
        str(j:(j + size(strings{i}, 2) - 1)) = strings{i};
        j = j + size(strings{i}, 2);
        str(j:(j + size(glue, 2) - 1)) = glue;
        j = j + size(glue, 2);
    end
    str(j:(j + size(strings{end}, 2) - 1)) = strings{end};
end

