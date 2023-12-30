function varargout = slwho(varargin)
% @brief List and locate all variables in MATLAB and Simulink
%
% This function lists and locates all variables from
%   - The base MATLAB workspace
%   - The global variables workspace
%   - The caller workspace
%   - A MAT-file
%   - Simulink model workspaces
%   - Simulink masked block workspaces
%
% This function accepts a property-value list of arguments which are listed
% hereafter.
%
% When no output arguments are required this function displays a table 
% containing the name and the location of each found variable. On the
% contrary, when the unique output argument is required, it returns a
% column structure array with one line for each variable and fields "name"
% and "place".
%
% Source selection properties and flags:
%   - <tt>'Base'</tt> When this flag is given the base workspace variables are included
% in the list.
%   - <tt>'Global'</tt> When this flag is given the global variables are included in
% the list.
%   - <tt>'Caller'</tt> When this flag is given the caller workspace variables are
% included in the list.
%   - <tt>'File'</tt> When this property is given with a MAT-file name as argument,
% the variables contained in the MAT-file are listed.
%   - <tt>'ModelWS'</tt> When this property is given with a model name as argument,
% the values contained in the model workspace are listed. If the model is not
% currently loaded, it is silently loaded and then closed. If the model
% name is the wildcard <tt>'*'</tt>, the variables of all currently opened models
% are listed.
%   - <tt>'Model'</tt> When this property is given with a model name as argument,
% the values contained in the model workspace and all masked subsystem
% workspaces are listed. If the model is not currently loaded, it is 
% silently loaded and then closed. If the model name is the wildcard <tt>'*'</tt>,
% the variables of all currently opened models are listed.
%   - <tt>'Block'</tt> When this property is given with a Simulink block path as
% argument, the values contained in all masked subsystem workspaces are 
% listed. If the model is not currently loaded, it is silently loaded and
% then closed.
%
% When none of these properties and flags are given, this function
% behaves as if Base and Global flags were specified and the property Model
% was given with argument '*'.
%
% Output filtering and formating properties and flags:
%   - <tt>'Name'</tt> When this property is given with a comma-separated list of
% variable names as argument, filters the list with the given variable
% names.
%   - <tt>'RegExp'</tt> When this property is given with a regular expression as
% argument, filters the list with the provided regular expression.
%   - <tt>'Truncate'</tt> When no return arguments are required and this flag is
% given, truncates the displayed values so that they fit in the command
% window. Truncated values are ended by ellipsis. Otherwise you may have to
% scroll horizontally.
%
% Simulink search options properties and flags:
%   - <tt>'SearchDepth'</tt> When this property is given with a natural number as
% argument, the search depth is limited for masks (See <tt>'Model'</tt> and <tt>'Block'</tt>
% properties). 0 will limit the output to the block itself.
%   - <tt>'FollowLinks'</tt> By default, the search is stopped by library-linked
% blocks. Specifying this flag allows to remove this constraint.
%   - <tt>'LookUnderMasks'</tt> By default, the search is stopped by non-graphical
% masks. Specifying this flag allows to remove this constraint.
%
% @param varargin Property-value list (see above)
% @return Nothing or a column structure array with one line
% for each variable and fields "name" and "place".
%
% \par Examples
%
% Lists the variables in base workspace
% \code{.m}
%   slwho Base
%   slwho('Base');
% \endcode
% Lists the global variables
% \code{.m}
%   slwho Global
%   slwho('Global');
% \endcode
% Lists the variables in the MAT-file test.mat
% \code{.m}
%   slwho File test
%   slwho File test.mat
%   slwho('File', 'test');
%   slwho('File', 'test.mat');
% \endcode
% Lists the variables in model test.mdl workspace
% \code{.m}
%   slwho ModelWS test
%   slwho ModelWS test.mdl
%   slwho('ModelWS', 'test');
%   slwho('ModelWS', 'test.mdl');
% \endcode
% Lists the variables in model `test.mdl`. Both varibales
% from the model workspace and from masks workspace are listed
% \code{.m}
%   slwho Model test
%   slwho Model test.mdl
%   slwho('Model', 'test');
%   slwho('Model', 'test.mdl');
% \endcode
% Lists the variables in the mask workspaces under test/block
% \code{.m}
%   slwho Block test/block
%   slwho('Block', 'test/block');
% \endcode
% Filters the list of base workspace variables
% by the given regular expression (varables names begining with "a" here)
% \code{.m}
%   slwho Base RegExp '^a'
%   slwho('Base', 'RegExp', '^a');
% \endcode
% Filters the list of base workspace variables by the given variable name list
% \code{.m}
%   slwho Base Name test
%   slwho Base Name 'test, Test'
%   slwho('Base', 'Name', 'test');
%   slwho('Base', 'Name', 'test, Test');
% \endcode
%
% % Copyright:  2015-2023 Pascal COMBES <pascom@orange.fr>
% % Author:     Pascal COMBES <pascom@orange.fr>
% % Date:       December 30th, 2023
% % Version:    1.0
% % License:    GPLv3
% % Requires:   parseProperties, select, strsplit, strjoin

    %% Reading argument list:
    if (nargout > 1)
        error('MATLAB:BadArgumentNumber', ['Too many output arguments.\n', ...
                                           'This function returns at most one argument, %d were required'], nargout);
    end

    % Properties list:
    properties = struct( ...
       'name', {'Base'; 'Global'; 'Caller'; 'File'; 'Model'; 'ModelWS'; 'Block'; 'RegExp'; 'Name'; 'SearchDepth'; 'FollowLinks'; 'LookUnderMasks'; 'Truncate'}, ...
       'type', {'flag'; 'flag'; 'flag'; 'char'; 'char'; 'char'; 'char'; 'char'; 'char'; 'integer'; 'flag'; 'flag'; 'flag'}, ...
       'size', {0; 0; 0; [1 0]; [1 0]; [1 0]; [1 0]; [1 0]; [1 0]; [1 1]; 0; 0; 0}, ...
       'parse', {[]; []; []; @parseFile; @parseModel; @parseModelWS; []; []; @parseName; []; []; []; []}, ...
       'min' , {[]; []; []; []; []; []; []; []; []; 0; []; []; []}, ...
       'max' , {[]; []; []; []; []; []; []; []; []; []; []; []; []} ...
    );
    % Parsing property-value list:
    values = struct;
    values.followlinks = false;
    values.lookundermasks = false;
    values = parseProperties(values, properties, varargin{:});
    % Post-processing of property-value list:
    properties = {'base'; 'global'; 'caller'; 'file'; 'model'; 'modelWS'; 'block'};
    if (all(cellfun(@(field) ~isfield(values, field), properties)))
        values.base = true;
        values.global = true;
        values.model = '*';
    end
    if (values.followlinks)
        values.followlinks = 'on';
    else
        values.followlinks = 'off';
    end
    if (values.lookundermasks)
        values.lookundermasks = 'all';
    else
        values.lookundermasks = 'graphical';
    end
    if ((nargout ~= 0) && isfield(values, 'truncate'))
        warning('MATLAB:OverridenParameter', 'The "Truncate" property flag does not have any effect when used with return arguments.');
    end
    
    %% Listing MATLAB variables
    % Initialisation of variable list
    vars = struct('name', {}, ...
                  'place', {});
    % Looks for the variables in the base workspace:
    if (isfield(values, 'base'))
        vars = [vars; putVarsInStruct(evalin('base', 'who'), 'Base WS')];
    end
    % List global workspace variables
    if (isfield(values, 'global'))
        vars = [vars; putVarsInStruct(who('global'), 'Global')];
    end
    % List caller workspace variables:
    if (isfield(values, 'caller'))
        vars = [vars; putVarsInStruct(evalin('caller', 'who'), 'Caller WS')];
    end
    % List MAT file varibles:
    if (isfield(values, 'file'))
        vars = [vars; putVarsInStruct(who('-file', values.file), ['File: ', values.file])];
    end
    %% Listing model workspace variables:
    model = [];
    % Getting the selected model name:
    if (isfield(values, 'modelWS'))
        model = values.modelWS;
    elseif (isfield(values, 'model'))
        model = values.model;
    end
    % Listing selected models:
    if (strcmp(model, '*'))
        model = find_system('SearchDepth', 0);
    else
        model = {model};
    end
    % Listing variables in all the selected model workspace:
    for m = 1:size(model, 1)
        modelWs = get_param(model{m}, 'ModelWorkspace');
        if (~isempty(modelWs))
            vars = [vars; putVarsInStruct(evalin(modelWs, 'who'), ['ModelWS: ', strFormat(model{m})])]; %#ok Too complicated to preallocate.
        end
    end
    %% Listing mask workspace variables:
    block = [];
    % Getting the selected block name:
    if (isfield(values, 'block'))
        block = values.block;
    elseif (isfield(values, 'model'))
        block = values.model;
    end
    % Listing the masks in the selected blocks:
    opts = {'FollowLinks', values.followlinks, ...
            'LookUnderMasks', values.lookundermasks};
    if (isfield(values, 'searchdepth'))
        opts = [{'SearchDepth', values.searchdepth}, opts];
    end
    if (strcmp(block, '*'))
        masks = {};
        models = find_system('SearchDepth', 0);
        for m = 1:size(model, 1)
            % Libraries does not have ModelWorkspaces.
            % This line thus allows to select libraries among the loaded
            % blocks diagrams.
            if (~isempty(get_param(model{m}, 'ModelWorkspace')))
                masks = [masks; find_system(models{m}, opts{:}, 'Mask', 'on')]; %#ok Too complicated to preallocate.
            end
        end                         
    else
        try
            masks = find_system(block, opts{:}, 'Mask', 'on');
        catch anyErr %#ok The error should be caused by the fact that the block is not found
            values.model = block(1:(find(block == '/', 1, 'first') - 1));
            if (exist([values.model, '.mdl'], 'file') == 4)
                load_system(values.model);
                values.closeModel = true;
            else
                error('Simulink:NotFound', 'No such model "%s".', values.model);
            end
            try
                masks = find_system(block, opts{:}, 'Mask', 'on');
            catch anyErr
                error('Simulink:NotFound', 'No such block "%s".', block);
            end
        end
    end
    % List the variables in all the selected mask workspaces:
    for m = 1:size(masks, 1)
        maskVars = get_param(masks{m}, 'MaskWSVariables');
        vars = [vars; putVarsInStruct(transpose({maskVars.Name}), ['MaskWS: ', strFormat(masks{m})])]; %#ok Too complicated to preallocate.
    end
    
    %% Closes a possibly opened model
    if (isfield(values, 'closeModel') && values.closeModel)
        if (isfield(values, 'modelWS'))
            close_system(values.modelWS, 0);
        elseif (isfield(values, 'model'))
            close_system(values.model, 0);
        end
    end
    
    %% Filter the variables names according to regexp:
    if (isfield(values, 'regexp'))
        if (values.regexp(1) ~= '^')
            values.regexp = ['^.*', values.regexp];
        end
        if (values.regexp(end) ~= '$')
            values.regexp = [values.regexp, '.*$'];
        end
        vars = select(@(var) ~isempty(regexp(var.name, values.regexp, 'match', 'once')), vars);
    end
    
    %% Outputs the result:
    if (nargout == 1)
        varargout = {vars};
    else
        winSize = get(0, 'CommandWindowSize');
        if (isfield(values, 'truncate'))
            colsName = max(min(max(arrayfun(@(var) length(var.name), vars)), floor((winSize(1) - 3)/2)), 13);
            colsPlace = max(3, winSize(1) - 3 - colsName);
        else
            colsName = max(max(arrayfun(@(var) length(var.name), vars)), 13);
        end
        format = sprintf('%%-%ds | %%s\\n', colsName);
        
        separator = char(ones(1, winSize(1))*double('-'));
        fprintf('%s\n', separator);
        fprintf(format, 'Variable name', 'Location'); %#ok Parser fails ...
        fprintf('%s\n', separator);
        for v = 1:size(vars, 1)
            if (isfield(values, 'truncate'))
                name = truncate(vars(v).name, colsName);
                place = truncate(vars(v).place, colsPlace);
            else
                name = vars(v).name;
                place = vars(v).place;
            end
            fprintf(format, name, place);
        end
        fprintf('%s\n', separator);
    end
end

function values = parseFile(values, value)
% @brief Check file name
%
% This function is used by the argument parser to check the given file name.
% @param values The value list before parsing the current property value
% @param value The value for the current property
% @return The value list after parsing the current property value
    if (~strcmp(value((end-3):end), '.mat'))
        value = [value, '.mat'];
    end
    if (exist(value, 'file') ~=2)
        error('MATLAB:FileNotExist', 'The given file name "%s" does not exist.', value);
    end
    values.file = value;
end

function values = parseModel(values, value)
% @brief Check model name
%
% This function is used by the argument parser to check the given model name.
% @param values The value list before parsing the current property value
% @param value The value for the current property
% @return The value list after parsing the current property value
    if (~strcmp(value, '*') && (length(value) > 4) && strcmp(value((end-3):end), '.mdl'))
        value = value(1:(end-4));
    end
    if (isfield(values, 'modelWS'))
        warning('MATLAB:OverridenParameter', ...
                ['The "ModelWS" property is stronger than the "Model" property.\n', ...
                 'Only the first one should be given, the second will be ignored.']);
    else
        values.closeModel = ~checkModel(value);
        values.model = value;
    end
end

function values = parseModelWS(values, value)
% @brief Check model name
%
% This function is used by the argument parser to check the given model name.
% @param values The value list before parsing the current property value
% @param value The value for the current property
% @return The value list after parsing the current property value
    if (~strcmp(value, '*') && (length(value) > 4) && strcmp(value((end-3):end), '.mdl'))
        value = value(1:(end-4));
    end
    values.closeModel = ~checkModel(value);
    if (isfield(values, 'model'))
        warning('MATLAB:OverridenParameter', ...
                ['The "ModelWS" property is stronger than the "Model" property.\n', ...
                 'Only the first one should be given, the second will be ignored.']);
        values = rmfield(values, 'model');
    end
    values.modelWS = value;
end

function values = parseName(values, value)
% @brief Check file name
%
% This function is used by the argument parser to check the given name.
% @param values The value list before parsing the current property value
% @param value The value for the current property
% @return The value list after parsing the current property value
    names = stringSplit(value, ',');
    names = cellfun(@(name) strtrim(name), names, 'UniformOutput', false);
    goodNames = select(@(name) ~isempty(regexp(name, '^[A-Za-z][A-Za-z0-9_]*$', 'match', 'once')), names);
    if (size(goodNames, 1) ~= size(names, 1))
        badNames = select(@(name) ~isempty(regexp(name, '^[A-Za-z][A-Za-z0-9_]*$)', 'matches', 'once')), names);
        warning('MATLAB:BadVariableName', ['The following variable names "%s" are invalid.\n', ...
                                           'They will be ignored.'], strjoin(badNames, '", "'));
    end
    values.regexp = ['^(', strjoin(goodNames, '|'), ')$'];
end

function alreadyOpen = checkModel(modelname)
% @brief Check model
%
% Ensure the given model is openned
% @param modelname The name of the model
% @return Whether the model was already opened
    if (strcmp(modelname, '*'))
        alreadyOpen = true;
    else
        try
            find_system(modelname);
            alreadyOpen = true;
        catch anyErr %#ok The error is probably due to the fact that the model is not loaded.
            if (exist([modelname, '.mdl'], 'file') == 4)
                load_system(modelname);
                alreadyOpen = false;
            else
                error('Simulink:NotFound', 'No such system "%s".', modelname);
            end
        end
    end
end

function vars = putVarsInStruct(variables, location)
% @brief Add vars to return struct
%
% Create a struct from the given variables and location
% @param variables A column cell-array of variables names
% @param location The location of the variables
% @return A struct with fields:
%   - <tt>'name'</tt> The variable name
%   - <tt>'place'</tt> The variable location
        vars = struct('name', cell(size(variables)), ...
                      'place', cell(size(variables)));
        for v = 1:size(variables, 1);
            s.name = variables{v};
            s.place = location;
            vars(v) = s;
        end
end

function str = strFormat(str)
% @brief Format a char array
%
% Currently simply replaces multiple spaces with a single one.
% @param str The string to be processed
% @return The processed string
    str = regexprep(str, '\s+', ' ');
end

function str = truncate(str, len)
% @brief Truncate a char array
%
% Truncate the char array at the given length
% @param str The string to be processed
% @param len The length of the final string
% @return The processed string
    if (size(str, 2) > len)
        str = [str(1:(len-3)), '...'];
    end
end