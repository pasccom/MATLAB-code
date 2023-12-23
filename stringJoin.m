function [str] = stringJoin(strings, glue)
%% STRJOIN Glue all string in cell with glue.
% This function can handle one or two arguments. The first one is the parts
% of strings and the second which is optional is the glue. It the second
% argument is not provided the parts will be glued with the empty string.
%   @param parts Parts of the string as a cell array of strings or a
% string.
%   @param glue Optionnal. The glue to use to glue the parts together.
%   @return str A string composed of all the parts gued together using the
% provided glue string.
%
% Examples:
%   parts = 'a';
%   str = strjoin(parts)
%   str = 'a'
%
%   parts = 'a';
%   str = strjoin(parts, ',')
%   str = 'a'
%
%   parts = {'a', 'b', 'c', 'd', 'e', 'f'};
%   str = strjoin(parts, ',')
%   str = 'a,b,c,d,e,f'
%   parts = {'a', 'b', 'c', 'd', 'e', 'f'};
%   str = strjoin(parts, ', ')
%   str = 'a, b, c, d, e, f'
%
% Copyright 2015 Pascal COMBES <pascom@orange.fr>
%
% Author:   Pascal COMBES <pascom@orange.fr>
% Date:     February 15th, 2015
% Version:  1.0.0
% License:  GPLv3
% Requires: 
  
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

