function ret = iff(condition, varargin)
%% IFF Inline if constuct
% Allows to use inline if constructs with MATLAB. This is equilavlent to
% the ternary operator (?:) of C-based languages.
% This function is very usefull when writing anonymous functions: You
% cannot use the default if constuct in this context.
%   @param condition A MATLAB expression evaluating to a boolean
%   @param trueResult The value returned by the function if the condition
% evaluates to true
%   @param falseResult [optional] The value returned by the function if the
% condition evaluates to false
%   @return 
%       -trueResult if the condition evaluates to true
%       -falseResult if the condition evaluates to false and it is provided
%       -A default value for true result type if the condition evaluates to
% false and there are only 2 arguments.
%
% Examples:
%   iff(true, 'True', 'False') % Returns 'True'
%   iff(false, 'True', 'False') % Returns 'False'
%   iff(true, 'True') % Returns 'True'
%   iff(false, 'True') % Returns '' which is the default value for strings
%
%   % Declaration of an anonymous function
%   sign = @(X) iff(X < 0, -1, iff(X > 0, 1));
%   % NB: The defaut for an array of number A is zeros(size(A))
%   % Using the function:
%   arrayfun(sign, [0, 1, -2, 3, -4]) % returns [0, 1 -1, 1, -1]
%
% Copyright 2015 Pascal COMBES <pascom@orange.fr>
%
% Author:   Pascal COMBES <pascom@orange.fr>
% Date:     May 1st, 2015
% Version:  1.0.0
% License:  GPLv3
% Requires: 

    %% Argument number checking
    if (nargin < 2)
        error('iff:BadArgumentNumber', ...
              'This function needs at least 2 arguments (%d given)', ...
              nargin);
    elseif (nargin > 3)
        error('iff:BadArgumentNumber', ...
              'This function accepts at most 3 arguments (%d given)', ...
              nargin);
    end
    
    %% Core of the function
    if (condition)
        ret = varargin{1};
    elseif (nargin == 3)
        ret = varargin{2};
    else
        % When the third argument is not given and the condition is false,
        % tries to find an appropriate default value for the type.
        switch (class(varargin{1}))
            case {'double', 'single', ...
                  'int8', 'uint8', 'int16', 'uint16', ...
                  'int32', 'uint32', 'int64', 'uint64', ...
                  'logical'}
                ret = eval(sprintf('%s(zeros(%s))', class(varargin{1}), strrep(int2str(size(varargin{1})), '  ', ', ')));
            case 'char'
                ret = '';
            case 'function_handle'
                ret = @(varargin) 0;
            case 'cell'
                ret = cell(size(varargin{1}));
            case 'struct'
                ret = struct;
            otherwise
                warning('iff:TypeUnsupported', ...
                        'Could not determine a default value for the type "%s"', ...
                        class(varargin{1}));
                ret = [];
        end
    end

end

