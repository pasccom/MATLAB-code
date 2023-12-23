function [parts] = stringSplit(string, delimiter)
% @brief Split a string
%
% Split the given string into multiple parts according to the given
% delimiter.
% @param string The string to split
% @param delimiter The delimiter for substrings in the given string
% @return A column cell array containing the substrings
%
% \par Examples
% Split a string according to the given delimiter
% \code
%   str = '1,2,3';
%   parts = stringSplit(str, ',')
%   parts =
%       '1'
%       '2'
%       '3'
% \endcode
% The presence of other possible delimiter does not impact splitting
% \code
%   str = '(a;1),(b;2),(c;3)';
%   parts = stringSplit(str, ',')
%   parts =
%       '(a;1)'
%       '(b;2)'
%       '(c;3)'
% \endcode
%
% % Copyright 2015-2023 Pascal COMBES <pascom@orange.fr>
% % Author:   Pascal COMBES <pascom@orange.fr>
% % Date:     December 23rd, 2023
% % Version:  1.0
% % License:  GPLv3
% % Requires:

    %% Check arguments
    % Check the type of the string
    if ~ischar(string)
        error('StringSplit:InvalidArgument', 'String must be a char array');
    end
    % Check the type of the delimiter
    if ~ischar(delimiter)
        error('StringSplit:InvalidArgument', 'Delimiter must be a char array');
    end
    % Check the size of the delimiter
    if(any(size(delimiter) ~= [1, 1]))
        error('StringSplit:InvalidArgument', 'Delimiter must be 1x1');
    end
    
    %% Find delimiters
    splits = find(string==delimiter);
    splits = [0, splits, size(string, 2) + 1];
    
    %% Split the string
    parts = cell(size(splits, 2) - 1, 1);
    for s=2:size(splits, 2)
        if (splits(s - 1) + 1 <= splits(s) - 1)
            parts{s - 1} = string((splits(s - 1) + 1):(splits(s) - 1));
        else
            parts{s - 1} = '';
        end
    end
end

