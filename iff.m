function ret = iff(condition, varargin)
% @brief Inline if constuct
%
% Allows to use inline if constructs with MATLAB. This is equilavlent to
% the ternary operator (?:) of C-based languages.
%
% \note This function is very usefull when writing anonymous functions,
% as the default if constuct cannot be used in this context.
% @param condition A MATLAB expression evaluating to a boolean
% @param varargin The following arguments are accepted:
%   - **trueResult** The value returned by the function if the condition
% evaluates to \c true
%   - **falseResult** (optional) The value returned by the function if the
% condition evaluates to \c false
% @return Depending on the condition
%   - **trueResult** if the condition evaluates to \c true
%   - **falseResult** if the condition evaluates to \c false and it is provided
%   - A default value for true result type if the condition evaluates to
% \c false and there are only 2 arguments.
%
% \par Examples
% Returns \c 'True'
% \code{.m}
%   iff(true, 'True', 'False')
% \endcode
% Returns \c 'False'
% \code{.m}
%   iff(false, 'True', 'False')
% \endcode
% Returns \c 'True'
% \code{.m}
%   iff(true, 'True')
% \endcode
% Returns \c '' which is the default value for strings
% \code{.m}
%   iff(false, 'True')
% \endcode
% Usage example (returns <tt>[0, 1 -1, 1, -1]</tt>)
% \code{.m}
%   % Declaration of an anonymous function
%   sign = @(X) iff(X < 0, -1, iff(X > 0, 1));
%   % NB: The defaut for an array of number A is zeros(size(A))
%   % Using the function:
%   arrayfun(sign, [0, 1, -2, 3, -4])
% \endcode
%
% % Copyright:  2015-2023 Pascal COMBES <pascom@orange.fr>
% % Author:     Pascal COMBES <pascom@orange.fr>
% % Date:       December 28th, 2023
% % Version:    1.0
% % License:    GPLv3
% % Requires:

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

