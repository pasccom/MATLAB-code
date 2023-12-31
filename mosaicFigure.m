function newFigHandle = mosaicFigure(varargin)
% @brief Auto-tiling figure
%
% Manage figure positions. Indeed, by default, MATLAB always creates
% figures at the same position. Figures can be grouped and assigned
% to a monitor (monitor <tt>0</tt> means any monitor).
%
% \par Creating figures
% To create a new figure, the function can be invoked as follows:
%   - Without arguments, this function creates a new figure
% which is out of any group and not assigned to any monitor,
% and makes it the active figure.
%   - If the first argument is numeric, it is considered as
% the monitor number, that the figure is assigned to.
% The new figure is out of any group, it is assigned to the given monitor
% and it is activated.
%   - If the next argument (the first argument, or the second argument,
% if a monitor number was given), is a character array,
% it is considered as the group name.
% The function creates a new figure in specified group,
% assigns it to a monitor (if given), and makes it the active figure.
%   - If the second argument is a number, it is considered as
% the group number. The function creates a new figure in specified group,
% assigns it to the given monitor, and makes it the active figure.
%
% In all these cases mosaicFigure() returns the handle to the newly-created
% figure.
%
% The following properties are currently accepted by mosaicFigure():
%   - <tt>'Title'</tt> (character array) The title of the
% newly-created window (defaults to <tt>"Figure f (mosaicFigure)"</tt>,
% or <tt>"Figure f (group g)"</tt>, if a group number was given,
% or <tt>"Figure f (groupName)"</tt>, if a group name was given.
%   - <tt>'DealStrategy'</tt> (integer 1x1 in the range 1-3)
% Selects the deal stategies. See the code of each deal strategy
% for indication on how they work. The default one should be the best.
%   - <tt>'LayoutStrategy'</tt> (integer 1x1 in the range 1-4)
% Selects the layout strategy. See the code of each layout strategy
% for indication on how they work. The default one should be the best.
%   - <tt>'UseJava'</tt> (logical 1x1): Whether to use Java
% to obtain monitor positions
%
% \par Special commands
% Relayout the figures with no assigned group
% \code{.m}
%   mosaicFigure layout
% \endcode
%   Relayout the group with number *groupNumber*
% \code{.m}
%   mosaicFigure layout groupNumber
% \endcode
% Relayout the group named *groupName*
% \code{.m}
%   mosaicFigure layout groupName
% \endcode
% Closes all the figures managed by mosaicFigure()
% \code{.m}
%   mosaicFigure close
%   mosaicFigure close all
% \endcode
% Closes all the figures in the group number groupNumber
% \code{.m}
%   mosaicFigure close groupNumber
% \endcode
% Closes all the figures in the group named groupName
% \code{.m}
%   mosaicFigure close groupName
% \endcode
% \note These commands can also be used under function form.
%
% \par Debug usages
% Returns the state of the function (the list of all mosaic figures)
% \code{.m}
%   mosaicFigure debug 
% \endcode
% Simulate layout with other monitor sizes than the real ones.
% \code{.m}
%   mosaicFigure('debugLayout', group, monitorSizes)
% \endcode
%
% @param varargin Function arguments described above
% @return Nothing or the handle to the new figure
%
% % Copyright:  2015-2023 Pascal COMBES <pascom@orange.fr>
% % Author:     Pascal COMBES <pascom@orange.fr>
% % Date:       December 31st, 2023
% % Version:    1.0
% % License:    GPLv3
% % Requires:   parseProperties

    %% Properties:
    % Available properties:
    properties = struct( ...
        'name', {'DealStrategy'; 'LayoutStrategy'; 'Title'; 'UseJava'}, ...
        'type', {'integer'; 'integer'; 'char'; 'logical'}, ...
        'size', {[1, 1]; [1, 1]; [1, 0]; [1, 1]}, ...
        'parse', {@parseDealStrategy; @parseLayoutStrategy; []; @parseUseJava}, ...
        'min' , {1; 1; []; []}, ...
        'max' , {3; 4; []; []} ...
    );
    % Default settings:
    handles.title = [];
    handles.getMonitorPositions = @getMonitorPositionsJava;
    handles.dealFigures = @dealFigures3;
    handles.computeLayout = @computeLayout4;
    handles.initLayout = @noop;
    handles.layoutScreen = @layoutScreen;

    %% Initialisation:
    persistent figList
    if(isempty(figList))
        figList = loadBackup();
    end
    persistent silentClose
    if(isempty(silentClose))
        silentClose = false;
    end
    % Gets the positions of the monitors:
    % In versions before 2014b, they are refereced by the coordinates of the
    % top-left and bottom-right points in the frame (O, u, v), where:
    %   -O is the top-left point of the first monitor.
    %   -u is a vector oriented towards the left of the screen.
    %   -v is a vectcor oriented towards the bottom of the screen.
    % For version 2014b and after, they are referenced by the coordinates 
    % of their lower-left points in the same frame (O, u, v') and their 
    % width and height, where:
    %   -v' is a vector oriented towards the top of the screen.
    monitorSizes = handles.getMonitorPositions();
    
    %% DEBUG CODE:
    % Allows debuging by returning the state of the function:
    if ((nargin == 1) && strcmp(varargin{1}, 'debug'))
        newFigHandle = figList;
        return;
    end
    % Allows to debug the layout fuction:
    if ((nargin >= 3) && strcmp(varargin{1}, 'debugLayout'))
        % Argument parsing and checking:
        if (isnumeric(varargin{2}))
            group = uint64(varargin{2});
        else
            error('The second argument must be the number of the group to layout');
        end
        if (~isnumeric(varargin{3}) || (size(varargin{3}, 2) ~= 4))
            error('The third argument must be the monitor sizes to simulate');
        end
        if (nargin > 3)
            handles = parseProperties(handles, properties, varargin{4:end});
        end
        % Initializes debug handles:
        handles.initLayout = @initLayoutDebug;
        handles.layoutScreen = @layoutScreenDebug;
        % Debugs the layout:
        monitorSizes = varargin{3};
        if (group == 1)
            layout(figList{1}, monitorSizes, handles);
        else
            layout(figList{group}.contents, monitorSizes, handles, true);
        end
        return;
    end
    
    %% Command parsing:
    % The layout command:
    if ((nargin >= 1) && strcmp(varargin{1}, 'layout'))
        % Argument parsing:
        if(nargin < 2)
            group = [];
        else
            group = varargin{2};
        end
        if (~isempty(group) && isnumeric(group) && (round(group) == group))
            group = int64(group);
        elseif (ischar(group) && ~isempty(regexp(group, '^[1-9][0-9]*$', 'once')))
            group = int64(sscanf(group, '%d'));
        end
        if (~isempty(group) && ~ischar(group) && ~isinteger(group))
            error('MATLAB:BadArgumentType', ...
                  'Group names must be integers or chars');
        end
        if (ischar(group) && strcmp(group, 'all'))
            error('MATLAB:BadArgumentValue', ...
                  'The group name "all" is a reserved group name and should not be used');
        end
        % If the fig list has been reset, try recover from backup:
        if ((size(figList, 1) == 1) && isempty(figList{1}))
            figList = loadBackup();
        end
        % Relayout:
        g = findGroup(group, figList);
        if (isempty(g) || (g == 1))
            layout(figList{1}, monitorSizes, handles);
        else
            layout(figList{g}.contents, monitorSizes, handles, true);
        end
        return
    end
    % The close command:
    if ((nargin >= 1) && strcmp(varargin{1}, 'close'))
        % Argument parsing:
        if(nargin < 2)
            group = 'all';
        else
            group = varargin{2};
        end
        if (nargin > 2)
            warning('MATLAB:TooManyArguments', ...
                    ['MosaicFigure close command only needs 1 argument.', ...
                    'Others will be ignored']);
        end
        if (ischar(group) && ~isempty(regexp(group, '^[1-9][0-9]*$', 'once')))
            group = int64(sscanf(group, '%d'));
        elseif (isnumeric(group) && (round(group) == group))
            group = int64(group);
        elseif (isa(group, 'matlab.ui.Figure') || isempty(group))
            silentClose = true;
            for fig = 1:length(group)
                close(fig);
            end
            silentClose = false;
            return;
        end
        if (~ischar(group) && ~isinteger(group))
            error('MATLAB:BadArgumentType', ...
                  'Group names must be integers or chars');
        end
        % If the fig list has been reset, try recover from backup:
        if ((size(figList, 1) == 1) && isempty(figList{1}))
            figList = loadBackup();
        end
        % Closes the figures:
        if (strcmp(group, 'all'))
            for g = 1:size(figList, 2)
                if (g == 1)
                    closeGroup(figList{g});
                else
                    closeGroup(figList{g}.contents);
                end
            end
            figList = {[]};
        else
            g = findGroup(group, figList);
            if (isempty(g))
                warning('MosaicFigure:GroupNotFound', ...
                        'Could not find the specified group "%s".', ...
                        num2str(group));
            else
                closeGroup(figList{g}.contents);
                figList(g) = [];
            end
        end
        saveBackup(figList);
        return
    end
    
    %% Argument parsing:
    group = [];
    monitor = uint8(0);
    % First argument is the monitor number (or 0 if not assigned) if it is
    % not a string. Otherwise its the group name and the second argument is
    % in the property list.
    if (nargin > 0)
        if (ischar(varargin{1}))
            group = varargin{1};
        else
            monitor = uint8(varargin{1});
        end
    end
    % Second argument is the group name if it has not already been read 
    % or number (defaults to empty).
    if ((nargin > 1) && isempty(group))
        group = varargin{2};
        if (isnumeric(group))
            group = int64(group);
        end
        beginPropertyList = 3;
    else
        beginPropertyList = 2;
    end
    % Other arguments are properties
    if (nargin >= beginPropertyList)
        handles = parseProperties(handles, properties, varargin{beginPropertyList:end});
    end
    
    %% Argument cheching:
    if (~ischar(group) && ~isinteger(group) && ~isempty(group))
        error('MATLAB:BadArgumentType', ...
              'Group must be either a string, an integer or an empty array');
    end
    if (ischar(group) && strcmp(group, 'all'))
        error('MATLAB:BadArgumentValue', ...
              'The group name "all" is a reserved group name and should not be used');
    end
    if (ischar(group) && ~isempty(regexp(group, '^[1-9][0-9]*$', 'once')))
        error('MATLAB:BadArgumentValue', ...
             ['The group name must not be an integer number as a string.', ...
              'However you can used the integer number as is.']);
    end
    if (monitor > size(monitorSizes, 1))
        warning('MATLAB:ArgumentOutOfRange', ...
                'There is only %d monitors.', size(monitorSizes, 1));
        monitor = 0;
    end
    
    %% Handler of close events for the figures:
    function closeMosaicFigure(src, ~, group)
    % @brief Close event handler
    %
    % Handle close events for mosaicFigure(): Close the figure
    % and relayout the remaining figures.
    % If the figure is part of a group, asks the user whether
    % all other figures in the group should be closed as well.
    % @param src The figure which raised the close event
    % @param group The group the figure belongs to
        % Find the group number of the figure being deleted:
        try
            gr = findGroup(group, figList);
        catch e %#ok I don't want information on an error in findgroup
            % The listof figures has probably been cleared out:
            % Tries to recover from backup.
            figList = loadBackup();
            try
                gr = findGroup(group, figList);
            catch e %#ok I don't want information on an error in findgroup
                delete(src);
                return;
            end
        end
        if(isempty(gr))
            % The figure list may have been cleared out and overwritten...
            warning('MosaicFigure:GroupNotFound', 'Group "%s" not found', group2str(group));
            delete(src);
            return;
        elseif (gr == 1)
            % Clears the figure being deleted from the list:
            for f=1:(length(figList{1}) + 1)
                if (f == length(figList{1}) + 1)
                    % The figure was not in the list.
                    warning('MosaicFigure:FigureNotFound', 'Figure not found');
                    delete(src);
                    break;
                end
                if (figList{1}(f).handle == src)
                    % Found the figure in the list.
                    delete(figList{1}(f).handle);
                    figList{1}(f) = [];
                    break;
                end
            end
        else
            % Possible answers:
            ALL = 'all';
            ONE = 'one';
            CANCEL = 'cancel';
            % The name of the group as a string:
            groupname = [];
            if (ischar(group))
                groupname = group;
            elseif (isinteger(group))
                groupname = sprintf('%d', group);
            end
            % Ask only if there is more than one window in group:
            if (~silentClose && (size(figList{gr}.contents, 1) > 1))
                rep = questdlg(['You are closing figure of group "', groupname, '". Do you want to close the whole group or only this figure?'], ...
                               ['Closing group "', groupname, '"'], ...
                               ALL, ONE, CANCEL, ALL);
            else
                rep = ONE;
            end
            % If cancel was chosen, returns:
            if (strcmp(rep, CANCEL))
                return;
            end
            % Clears wanted figures:
            for f=size(figList{gr}.contents, 1):-1:0
                if (f == 0)
                    % Ensure the figure has been deleted.
                    if (ishandle(src))
                        warning('MosaicFigure:FigureNotFound', 'Figure not found');
                        delete(src);
                    end
                    break;
                end
                if (strcmp(rep, ALL) || (figList{gr}.contents(f).handle == src))
                    delete(figList{gr}.contents(f).handle);
                    figList{gr}.contents(f) = [];
                    if (~strcmp(rep, ALL))
                        break;
                    end
                end
            end
            % If group is empty, then remove it:
            if (isempty(figList{gr}.contents))
                figList(gr) = [];
                saveBackup(figList);
                return;
            end
        end
        % Saves figure list:
        saveBackup(figList);
        
        % Relayout (refresh monitor positions because monitors may have
        % been added or disconnected
        if (gr == 1)
            layout(figList{1}, handles.getMonitorPositions(), handles);
        else
            layout(figList{gr}.contents, handles.getMonitorPositions(), handles);
        end
    end
    
    %% Initializes the new figure:
    newFigHandle = figure;
    set(newFigHandle, 'CloseRequestFcn', {@closeMosaicFigure, group});
    set(newFigHandle, 'NumberTitle', 'off');
    set(newFigHandle, 'DockControls', 'off');
    fig = struct('handle', getNumberHandle(newFigHandle), ...
                 'screen', monitor);
    
    %% Adds the new figure to figure list:
    g = findGroup(group, figList);
    if (isempty(g))
        newGroup.group = group;
        newGroup.contents = fig;
        figList = [figList, newGroup];
        g = size(figList, 2);
        if (~isempty(handles.title))
            setFigureName(newFigHandle, handles.title);
        else
            setFigureName(newFigHandle, 1, group);
        end
    elseif (g == 1)
        figList{1} = [figList{1}; fig];
        if (~isempty(handles.title))
            setFigureName(newFigHandle, handles.title);
        else
            setFigureName(newFigHandle, size(figList{1}, 1));
        end
    else
        oldGroup = figList{g};
        oldGroup.contents = [oldGroup.contents; fig];
        figList{g} = oldGroup;
        if (~isempty(handles.title))
            setFigureName(newFigHandle, handles.title);
        else
            setFigureName(newFigHandle, size(oldGroup.contents, 1), group);
        end
    end
    saveBackup(figList);
    
    %% Relayout:
    if (g == 1)
        layout(figList{1}, monitorSizes, handles);
    else
        layout(figList{g}.contents, monitorSizes, handles, true);
    end
    
    %% Ensures the new figure is the active figure:
    figure(newFigHandle);
end

function closeGroup(group)
% @brief Close a group of figures
%
% Close all the figures in the given group.
% @param group A column structure array with the following fields:
%   - <tt>handle</tt> The handle to the corresponding figure.
%   - <tt>screen</tt> The screen ion which the figure must be displayed.
    for f=1:length(group)
        %set(group(f).handle, 'CloseRequestFcn', closereq);
        if (ishandle(group(f).handle) && isvalid(group(f).handle))
            delete(group(f).handle);
        end
    end
end

function layout(group, screenSizes, varargin)
% @brief Lay a group of figures out
%
% @param group A column structure array with the following fields:
%   - <tt>handle</tt> The handle to the corresponding figure.
%   - <tt>screen</tt> The screen on which the figure must be displayed.
% @param screenSizes The sizes of the available monitors (as given by MATLAB).
% @param varargin The following optionnal arguments are accepted:
%   - **handles** Handles to virtual functions (used for
% debugging and choosing the layout strategy).
%   - **activate** Whether to activate the figure after
% laying out or not.

    %% Argument parsing and checking:
    if (nargin >= 3)
        handles = varargin{1};
    else
        handles.initLayout = @noop;
        handles.layoutScreen = @layoutScreen;
    end
    if (nargin >= 4)
        activate = varargin{2};
    else
        activate = false;
    end

    %% Filter out invisible figures (especially the ones created by live scripts)
    group = group(arrayfun(@(fig) get(fig.handle, 'Visible'), group));
    if (isempty(group))
        return;
    end
    
    %% Sort figures by monitor:
    figs0 = zeros(size(group, 1), 1);
    figs = cell(1, size(screenSizes, 1));
    
    f0 = 1;
    for f=1:size(group, 1)
        if (group(f).screen == 0)
            figs0(f0) = group(f).handle;
            f0 = f0 + 1;
        else
            if (group(f).screen <= size(figs, 2))
                figs{group(f).screen} = [figs{group(f).screen}; group(f).handle];
            else
                figs0(f0) = group(f).handle;
                f0 = f0 + 1;
            end
        end
    end
    figs0 = figs0(1:(f0-1), 1);
    
    %% Deals the figures of screen 0 between all the screens:
    [occs, areas] = computeOccupation(size(figs0, 1), cellfun('size', figs, 1), screenSizes, handles);
    deal = handles.dealFigures(occs, areas);
    
    %% Layout each screen
    f = 1;
    handles.initLayout(screenSizes(1, :));
    for m = 1:size(screenSizes, 1)
        handles.layoutScreen([figs{m}; figs0(f:(f + deal(m) - 1))], screenSizes(m, :), handles, activate);
        f = f + deal(m);
    end
end

function [occ, area] = computeOccupation(n0, ns, screenSizes, handles)
% @brief Compute screen space used by a figure
%
% Tell how much screen is used and how big the figures are,
% for each layout possibility.
% @param n0 The number of figures not assigned to a sceen.
% @param ns The number of figures assigned to each screen (a line array).
% @param screenSizes The sizes of the available monitors
% (correctGeometry() must have been used before).
% @param handles Handles to virtual functions (used for debugging and
% choosing the layout strategy).
% @return The following information is returned:
%   - **occ** How much of the screen is occuped.
%   - **area** How big are the figures.

    %% Stop recursion:
    if (size(screenSizes, 1) == 0)
        area = ones(1, 0);
        if (all(size(ns) == [1 1]) && (ns == 0) && (n0 == 0))
            occ = 1;
        else
            occ = 0;
        end
        return;
    end
    
    %% Recursion body:
    occ = [];
    area = [];
    for n = 0:n0
        if (n + ns(1) == 0)
            % There won't be any figure on this screen.
            % This is probably not the good choice when there is a lot of
            % figs to allocate, but it should still be considered when
            % there are less figures.
            % Area of the figures will be taken to be 0.
            if (size(ns, 2) > 1)
                [occp, areap] = computeOccupation(n0 - n, ns(2:end), screenSizes(2:end, :), handles);
            else
                [occp, areap] = computeOccupation(n0 - n, 0, screenSizes(2:end, :), handles);
            end
            if (~isempty(occp) && (any(size(occp) ~= [1 1]) || (occp ~= 0)))
                % All the figures can be allocated to a screen.
                % Case is valid. Otherwise case is ignored.
                occ = [occ; n*ones(size(occp, 1), 1), occp]; %#ok There won't be so much figures assigned to screen 0.
                area = [area; zeros(size(areap, 1), 1), areap]; %#ok There won't be so much figures assigned to screen 0.
            end
            continue;
        end
        % Computes for the next screens:
        if (size(ns, 2) > 1)
            [occp, areap] = computeOccupation(n0 - n, ns(2:end), screenSizes(2:end, :), handles);
        else
            [occp, areap] = computeOccupation(n0 - n, 0, screenSizes(2:end, :), handles);
        end
        if (isempty(occp) || (all(size(occp) == [1 1]) && (occp == 0)))
            % There is one figure which cannot be allocated. Skip case.
            continue;
        end
        % Compute best layout and occupation for this setting on this
        % screen.
        w = screenSizes(1, 3);
        h = screenSizes(1, 4);
        [~, ~, wf, hf] = handles.computeLayout(ns(1) + n, w, h);
        o = (wf*hf*(ns(1) + n))/w/h;
        if (o > 1)
            warning('mosaicFigure:assertionFailed', 'Found occupation greather than 1. This should not be possible.');
        else
            occp(:, end) = o*occp(:, end);
            occ = [occ; n*ones(size(occp, 1), 1), occp]; %#ok There won't be so much figures assigned to screen 0.
            area = [area; ones(size(areap, 1), 1)*wf*hf, areap]; %#ok There won't be so much figures assigned to screen 0.
        end
    end
end

function layoutScreen(figs, screenSize, handles, activate)
% @brief Lay one screen out
%
% Lay the given figures out on on screen
% @param figs A column cell array containing the handles to the figures
% to assign to the screen.
% @param screenSize The size of the screen being laid out
% (correctGeometry() must have been used before).
% @param handles Handles to virtual functions (used for debugging and
% choosing the layout strategy).
% @param activate Whether to activate the figure after laying out or not.

    %% Arguement checking:
    if (isempty(figs))
        return;
    end
    
    %% Computing layout:
    n = size(figs, 1);
    [~, nc, ~, ~] =  handles.computeLayout(n, screenSize(3), screenSize(4));
    
    %% Doing layout:
    for c=1:nc
        w0 = floor((c - 1)*screenSize(3)/nc);
        w1 = floor(c*screenSize(3)/nc);
        nl = ceil((n - c + 1)/nc);
        for l = 1:nl
            h0 = floor((nl - l)*screenSize(4)/nl);
            h1 = floor((nl - l + 1)*screenSize(4)/nl);
            if (~strcmp(get(figs((l - 1)*nc + c), 'WindowStyle'), 'docked'))
                set(figs((l - 1)*nc + c), 'OuterPosition', correctOuterPosition([screenSize(1) + w0, screenSize(2) + h0, w1 - w0, h1 - h0]));
                if (activate)
                    figure(figs((l - 1)*nc + c));
                end
            end
        end
    end
end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%% PROPERTIES PARSING FUNCTIONS :
function handles = parseDealStrategy(handles, value)
% @brief Parse the deal strategy
%
% Assign the good deal strategy in the handles array.
% @param handles Handles to virtual functions. Field <tt>dealFigures</tt> will be
% modified.
% @param value The number of the deal strategy to use.
% @return handles Handles to virtual functions. Field <tt>dealFigures</tt> has
% been modified.
    handles.dealFigures = str2func(sprintf('dealFigures%d', value));
end

function handles = parseLayoutStrategy(handles, value)
% @brief Parse the layout strategy
%
% Assign the good layout strategy in the handles array.
% @param handles Handles to virtual functions. Field <tt>computeLayout</tt> will be
% modified.
% @param value The number of the deal strategy to use.
% @return handles Handles to virtual functions. Field <tt>computeLayout</tt> has
% been modified.
    handles.computeLayout = str2func(sprintf('computeLayout%d', value));
end

function handles = parseUseJava(handles, value)
% @brief Parse Java usage property
%
% Modify the handles structure so that Java is not used.
% Otherwise the monitor positions are obtained using Java.
% @param handles Handles to virtual functions. Field <tt>getMonitorPositions</tt>
% will be modified.
% @param value The number of the deal strategy to use.
% @return handles Handles to virtual functions. Field
% <tt>getMonitorPositions</tt> has been modified.
    if (~value)
        handles.getMonitorPositions = @getMonitorPositions;
    end 
end

function handles = parseMonitorPositions(handles, value)
% @brief Parse monitor positions
%
% Ensure that the given monitor positions are used when laying out
% the figures.
% @param handles Handles to virtual functions. Field <tt>getMonitorPositions</tt>
% will be modified.
% @param value The number of the deal strategy to use.
% @return handles Handles to virtual functions. Field
% <tt>getMonitorPositions</tt> has been modified.
    handles.getMonitorPositions = @() value;
end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%% SCREEN DEALING FUNCTIONS :
function [deal] = dealFigures1(occs, areas) %#ok This is a virtual function which may be called when selecting DealStrategy 1
% @brief Deal figures between monitors
%
% Find the best deal between monitors for the figures.
% This function tries to find the best tradeoff between areas and screen
% occupation. It does it by a dichotomy selecting occupations greather than
% a level and relative difference in areas smaller than (1 - level)^2.
% @param occs Screen occupations.
% @param areas Figures areas.
% @return deal A line vector containing the best deal of the figures
% between all the available screens.
    minAreas = min(areas + 1./areas.*(areas == 0), [], 2);
    
    %% Find the best possible deal:
    levelMin = 0;
    levelMax = 1;
    while(true)
        level = (levelMin + levelMax) / 2;
        acceptableAreas = (max(minAreas) - minAreas) < (1 - level)^2*max(minAreas);
        acceptableOccs = occs(:, end) >= level;
        % Precision of dichotomy reached:
        if (levelMax - levelMin < 5e-3)
            break;
        end
        % There is only on layout acceptable, perfect:
        if (sum(acceptableAreas & acceptableOccs) == 1)
            break;
        end
        if (sum(acceptableAreas & acceptableOccs) == 0)
            % No layout is accetable, decrease level.
            levelMax = level;
        else
            % To many layouts are acceptable, increase level.
            levelMin = level;
        end 
    end
    i = find(acceptableAreas & acceptableOccs, 1);
    deal = occs(i, :);
end

function [deal] = dealFigures2(occs, areas) %#ok This is a virtual function which may be called when selecting DealStrategy 2
% @brief Deal figures between monitors
%
% Find the best deal between monitors for the figures
% This function tries to find the best tradeoff between areas and screen
% occupation. It does it by a dichotomy selecting occupations greather than
% a level and relative difference in total areas covered by figures smaller
% than (1 - level)^2 and then selecting the deal with the biggest possible
% areas.
% @param occs Screen occupations.
% @param areas Figures areas.
% @return deal A line vector containing the best deal of the figures
% between all the available screens.
    sumAreas = sum(areas.*occs(:, 1:size(areas, 2)), 2);
    
    %% Find the best possible deal:
    levelMin = 0;
    levelMax = 1;
    while(true)
        level = (levelMin + levelMax) / 2;
        acceptableAreas = (max(sumAreas) - sumAreas) < (1 - level)^2*max(sumAreas);
        acceptableOccs = occs(:, end) >= level;
        % Precision of dichotomy reached:
        if (levelMax - levelMin < 5e-3)
            break;
        end
        % There is only one layout acceptable, perfect:
        if (sum(acceptableAreas & acceptableOccs) == 1)
            break;
        end
        if (sum(acceptableAreas & acceptableOccs) == 0)
            % No layout is accetable, decrease level.
            levelMax = level;
        else
            % To many layouts are acceptable, increase level.
            levelMin = level;
        end
    end
    [~, i] = max(min(areas + 1./areas.*(areas == 0), [], 2).*(acceptableAreas & acceptableOccs));
    %i = find(acceptableAreas & acceptableOccs, 1);
    deal = occs(i, :);
end

function [deal] = dealFigures3(occs, areas)
% @brief Deal figures between monitors
%
% Find the best deal between monitors for the figures
% This function tries to find the best tradeoff between areas and screen
% occupation. It does it by a dichotomy selecting occupations greather than
% a level and relative difference in total areas covered by figures smaller
% than (1 - level)^2 and then selecting the deal with the smallest possible 
% area difference.
% @param occs Screen occupations.
% @param areas Figures areas.
% @return deal A line vector containing the best deal of the figures
% between all the available screens.
    sumAreas = sum(areas.*occs(:, 1:size(areas, 2)), 2);
    
    %% Find the best possible deal:
    levelMin = 0;
    levelMax = 1;
    while(true)
        level = (levelMin + levelMax) / 2;
        acceptableAreas = (max(sumAreas) - sumAreas) < (1 - level)^2*max(sumAreas);
        acceptableOccs = occs(:, end) >= level;
        % Precision of dichotomy reached:
        if (levelMax - levelMin < 5e-3)
            break;
        end
        % There is only one layout acceptable, perfect:
        if (sum(acceptableAreas & acceptableOccs) == 1)
            break;
        end
        if (sum(acceptableAreas & acceptableOccs) == 0)
            % No layout is accetable, decrease level.
            levelMax = level;
        else
            % To many layouts are acceptable, increase level.
            levelMin = level;
        end
    end
    [~, i] = min((max(areas, [], 2) - min(areas, [], 2))./(acceptableAreas & acceptableOccs));
    %i = find(acceptableAreas & acceptableOccs, 1);
    deal = occs(i, :);
end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%% LAYOUT COMPUTING FUNCTIONS :
function [l, c, wf, hf] = computeLayout1(n, w, h) %#ok This is a virtual function which may be called when selecting LayoutStrategy 1
% @brief Lay a screen out
%
% Tries to find the best line and columns number to lay out
% the given number of figures on a screen.
% This function tries to have the quotient hf/wf close to 1 (square figure).
% @param n The number or figures which will be eventually displayed on
% this screen.
% @param w The width of the screen.
% @param h The height of the screen.
% @return The following informarion:
%   - **l** The number of lines of figures.
%   - **c** The number of colums of figures.
%   - **wf** The width of the figures.
%   - **hf** The height of the figures.

    %% Determines the best values for l and c:
    % Tries to get the best square figure.
    l = 1;
    while (l <= n)
        c = ceil(n/l);
        wf = floor(w/c);
        hf = floor(h/l);
        sqrf = hf/wf;
        if (sqrf < 1)
            if (l == 1)
                % If with one line width is greather than height, then
                % stop.
                return
            else
                % Are figures with previous setting more square?
                % If yes, then return to it. Otherwise keep current.
                if ((sqrfp - 1) - eps < (1 - sqrf))
                    l = l-1;
                    c = ceil(n/l);
                    wf = floor(w/c);
                    hf = floor(h/l);
                end
                return;
            end
        end
        sqrfp = sqrf;
        l = l + 1;
    end
end

function [l, c, wf, hf] = computeLayout2(n, w, h) %#ok This is a virtual function which may be called when selecting LayoutStrategy 2
% @brief Lay a screen out
%
% Tries to find the best line and columns number to lay out
% the given number of figures on a screen.
% It tries to have c and l integers close to c0 = w/h*l0 by rounding.
% @param n The number or figures which will be eventually displayed on
% this screen.
% @param w The width of the screen.
% @param h The height of the screen.
% @return The following informarion:
%   - **l** The number of lines of figures.
%   - **c** The number of colums of figures.
%   - **wf** The width of the figures.
%   - **hf** The height of the figures.

   l = round(sqrt(h*n/w));
   if (l == 0)
       l = 1;
   end
   c = ceil(n/l);
   wf = floor(w/c);
   hf = floor(h/l);
end

function [l, c, wf, hf] = computeLayout3(n, w, h) %#ok This is a virtual function which may be called when selecting LayouStrategy 3
% @brief Lay a screen out
%
% Tries to find the best line and columns number to lay out
% the given number of figures on a screen.
% It tries to have c and l integers close to c0 = w/h*l0 and then selects
% the solution which give the closest solution. 
% @param n The number or figures which will be eventually displayed on
% this screen.
% @param w The width of the screen.
% @param h The height of the screen.
% @return The following informarion:
%   - **l** The number of lines of figures.
%   - **c** The number of colums of figures.
%   - **wf** The width of the figures.
%   - **hf** The height of the figures.

   l0 = floor(sqrt(h*n/w));
   l1 = ceil(sqrt(h*n/w));
   if ((l0 == 0) || (l1^2 - h*n/w < h*n/w - l0^2))
       l = l1;
   else
       l = l0;
   end
   c = ceil(n/l);
   wf = floor(w/c);
   hf = floor(h/l);
end

function [l, c, wf, hf] = computeLayout4(n, w, h)
% @brief Lay a screen out
%
% Tries to find the best line and columns number to lay out
% the given number of figures on a screen.
% It tries to have c and l integers close to c0 = w/h*l0 and then selects
% the solution which give the most square figs. 
% @param n The number or figures which will be eventually displayed on
% this screen.
% @param w The width of the screen.
% @param h The height of the screen.
% @return The following informarion:
%   - **l** The number of lines of figures.
%   - **c** The number of colums of figures.
%   - **wf** The width of the figures.
%   - **hf** The height of the figures.
    l0 = floor(sqrt(h*n/w));
    l1 = ceil(sqrt(h*n/w));
    if ((l0 == 0) || (abs(1 - sqrt(floor(w/ceil(n/l1))/floor(h/l1))) < abs(1 - sqrt(floor(w/ceil(n/l0))/floor(h/l0)))))
        l = l1;
    else
        l = l0;
    end
    c = ceil(n/l);
    wf = floor(w/c);
    hf = floor(h/l);
end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%% HELPER FUNCTIONS :
function noop(varargin)
% @brief No-op
%
% Do nothing with any number of arguments
% @param varargin Any arguments
end

function v = versionNumber()
% @brief MATLAB version Number
%
% Return MATLAB version as a number.
%
% Indeed, it is better to have the version as a number in code (for comparisons).
% The returned number is equal to the year part, plus 1/2 if the version is a b
% release.
%
% @returns An number conveying MATLAB version.
%
% \par Examples
%  - When invoked on MATLAB 2011a, this function returns <tt>2011.0</tt>
%  - When invoked on MATLAB 2014b, this function returns <tt>2014.5</tt>
    ver = version('-release');
    v = sscanf(ver(1:4), '%d');
    if (ver(5) == 'b')
        v = v + 0.5;
    end
end

function v = windowsVersionNumber()
% @brief Windows version Number
%
% Returns the version of Windows as a number.
%
% Indeed, it is better to have the version as a number in code (for comparisons).
% The returned number is equal to the major number of Windows release.
%
% @returns An number conveying MATLAB version.
%
% \par Esamples
%   - When invoked on Windows 7, this function returns <tt>7</tt>
%   - When invoked on Windows 10, this function returns <tt>10</tt>
    v = nan;
    [status, verStr] = system('ver');
    if (status == 0)
        verStr = strtrim(verStr);
        match = regexp(verStr, '^Microsoft Windows \[version (\d+)(?:\.\d+)*\]$', 'tokens');
        if ~isempty(match)
            v = sscanf(match{1}{1}, '%d');
        end
    end
end

function path = getFilePath()
% @brief Path to this file
%
% Get the path to the folder containing this file.
% @return The path to the folder containing this file.

    path = mfilename('fullpath');
    i = find(path == filesep, 1, 'last');
    if(~isempty(i))
        path = path(1:(i - 1));
    end
end

function g = findGroup(group, list)
% @brief Find a group
%
% Find the index of the group (given as a number of a name) in the list.
% @param group An integer or a string to represent the searched group.
% @param list A line struct array with at least a field group.
% @return The index of the group in the list or an empty array if
% the group was not found.

    % Initialisation:
    g = 1;
    if (isempty(group))
        return;
    end
    g = g + 1;
    
    % Loops over list:
    while(g <= size(list, 2))
        localGroup = list{g};
        if (ischar(localGroup.group) && ischar(group) && strcmp(group, localGroup.group))
            return;
        end
        if (isinteger(localGroup.group) && isinteger(group) && (group == localGroup.group))
            return;
        end
        g = g + 1;
    end
    
    g = [];
end

function str = group2str(group)
% @brief Convert group to string
%
% Converts a group identifier (number or name) to a character array.
% @param group A group identifier (might be a string or an integer).
% @return The given group identifier as a character array.
    if (isempty(group))
        str = '';
    elseif (ischar(group))
        str = group;
    elseif (isinteger(group))
        str = sprintf('%d', group);
    else
        str = 'Bad group name';
    end
end

function figNum = getNumberHandle(fig)
% @brief Number handle to a figure
%
% Return a numeric handle to the given figure.
% \note This function needs to be used as the figure handles
% are not numeric anymore ofter MATLAB R2014b.
% @param fig The figure handle (returned by `figure`).
% @return The number handle to the given figure.
    if (versionNumber() < 2014.5)
        figNum = fig;
    else
        figNum = fig.Number;
    end
end

function setFigureName(fig, varargin)
% @brief Set figure title
%
% Set the title of the figure appropriately (using the <tt>'Name'</tt> property).
% @param fig The handle to the figure whose name is being set.
% @param varargin Arguments to set the name:
%   - **figNum** (Mandatory) The number of the figure in its group.
%   - **figGroup** (Optionnal) figGroup The identifier for the group of the figure.
    if(nargin > 2)
        if (~isnumeric(varargin{1}) || (varargin{1} ~= round(varargin{1})))
            error('mosaicFigure:BadArgument', 'When this function has 3 arguments, the second must be a number.');
        end
        if (ischar(varargin{2}))
            set(fig, 'Name', sprintf('%s: Figure %d', varargin{2}, varargin{1}));
        elseif (isinteger(varargin{2}))
            set(fig, 'Name', sprintf('Group %d: Figure %d', varargin{2}, varargin{1}));
        else
            set(fig, 'Name', sprintf('Figure %d in group', varargin{1}));
        end
    elseif (nargin > 1)
        if (ischar(varargin{1}))
            set(fig, 'Name', varargin{1});
        elseif (isnumeric(varargin{1}) && (varargin{1} == round(varargin{1})))
            set(fig, 'Name', sprintf('Figure %d (mosaic)', varargin{1}));
        else
            set(fig, 'Name', sprintf('Figure (mosaic)'));
        end
    else
        error('mosaicFigure:BadArgumentNumber', 'This function can handle between 1 and 3 arguments.');
    end
end

function screenPositions = getMonitorPositionsJava()
% @brief Get monitor positions using Java
%
% Give the positions of the monitors using Java AWT methods.
% This function corrects the positions returned by Java AWT methods
% and returns them.
% \note This function is more reliable than the positions obtained from MATLAB,
% see getMonitorPositions().
% @return The monitor positions obtained from Java AWT methods
    graphicsEnv = javaMethod('getLocalGraphicsEnvironment', 'java.awt.GraphicsEnvironment');
    screenDevices = javaMethod('getScreenDevices', graphicsEnv);
    screenPositions = zeros(length(screenDevices), 4);
    base = [];
    for d = 1:length(screenDevices)
        graphicsConfs = javaMethod('getConfigurations', screenDevices(d));
        % ASSERT length(graphicsConfs) == 1 ...
        bounds = javaMethod('getBounds', graphicsConfs(1));
        if (isempty(base))
            base = [bounds.x, bounds.y, bounds.width, bounds.height];
            screenPositions(d, :) = [1, 1, bounds.width, bounds.height];
        else
            x = bounds.x + 1;
            y = -bounds.y - bounds.height + base(4) + 1;

            screenPositions(d, :) = [x, y, bounds.width, bounds.height];
        end
    end
end

function screenPositions = getMonitorPositions()
% @brief Get monitor positions from MATLAB
%
% Give the positions of the monitors.
% This function corrects the positions returned by
% \code{.m}
%    get(0, 'MonitorPositions'))
% \endcode
% and returns them.
% \note This function is less reliable than getMonitorPositionsJava().
% @return The monitor positions obtained from MATLAB
    screenPositions = correctGeometry(get(0, 'MonitorPositions'));
end

function geom = correctGeometry(screenSizes)
% @brief Correct monitor geometry
%
% Give the correct geometries for screens.
% When accessed by
% \code{.m}
%   get(0, 'MonitorPositions')
% \endcode
% the given rectangles are badly referenced for figure positionning.
% Indeed the frame origin is the top-left corner of base screen
% and vertcial axis is oriented towards bottom. The rectangles are given
% as top-left and bottom right corner coordinates and there is an offset
% of one (but this is needed to draw figures).
% This function transforms these coordinates so that the returned vector
% gives the botton-left corner coordinates and the height and width of the
% screen. The new frame has axes towards the right and the top of the
% screen. The origin is the bottom left corner of the main screen. This is
% what is convenient for positioning figures.
% @param screenSizes The monitor positions (as returned by get(0, 'MonitorPositions')).
% @return A 1x4 vector with the coordinates of the bottom-left corner of
% the monitor, its width and its height.
    if (versionNumber() >= 2014.5)
        % Geometries are OK from this version
        geom = screenSizes;
    else
        base = screenSizes(1, :);
        geom = zeros(size(screenSizes));
        for i = 1:size(screenSizes, 1)
            w = screenSizes(i, 3) - screenSizes(i, 1) + 1;
            h = screenSizes(i, 4) - screenSizes(i, 2) + 1;
            hb = base(4) - base(2) + 1;
            x = screenSizes(i, 1);
            y = -(screenSizes(i, 2) - 1) - h + hb + 1;

            geom(i, :) = [x, y, w, h];
        end
    end
end

function pos = correctOuterPosition(pos)
% @brief Correct figure outer position
%
% Correct the outer position for a figure depending on Windows version.
% \note On Windows 8, the window borders were removed,
% but this has never been taken into account by MATLAB:
% When setting a figure with the screen size as the <tt>OuterPosition</tt>,
% there are a few pixels lost.
% @param pos The desired outer position.
% @returns The position corrected so that when using <tt>OuterPosition</tt>
% the effective position is as desired.
    if (windowsVersionNumber() > 7)
        pos(1) = pos(1) - 8;
        pos(2) = pos(2) - 8;
        pos(3) = pos(3) + 15;
        pos(4) = pos(4) + 8;
    end
end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%% BACKUP FUNCTIONS :
function saveBackup(figList)
% @brief Backup figure list
%
% Save the figure list
% \note In case the figure list gets cleared (for instance by issuing <tt>clear all</tt>).
% This functions makes an on-disk backup of the figure list so that it can
% be retrieved later.
% @param figList Current figure list
% @sa loadBackup()
    backupPath = [tempdir, 'figList.mat'];
    try
        save(backupPath, 'figList');
    catch anyErr %#ok<NASGU>
        warning('Could not save figure list in backup file "%s"', backupPath);
    end
end

function figList = loadBackup()
% @brief Restore figure list
%
% Load the figure list from on-disk backup
% \note Sometimes the figure list is cleared (for instance by issuing <tt>clear all</tt>).
% When this happens, it can be restored from an on-disk backup using this function.
% @return The figure list from the on-disk backup
% @sa saveBackup()
    backupPath = [tempdir, 'figList.mat'];
    try
        backup = load(backupPath);
        figList = backup.figList;
    catch anyErr %#ok<NASGU>
        figList = {[]};
    end
end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%% DEBUGGING FUNCTIONS :
function initLayoutDebug(screenSize)
% @brief Initialise a figure to debug the layout
%
% Initialise layout debuggiung (when rectangles are
% drawn on a figure instead of creating figures)
% @param screenSize The size of the screen (correctGeometry() must have
% been applied).
    figure('OuterPosition', correctOuterPosition(screenSize));
end

function layoutScreenDebug(figs, screenSize, handles, activate)
% @brief Debug screen layout process
%
% Lay the given figures out on on screen
%
% In this mode rectangles representing figures are drawn on a figure
% instead of creating figures.
% @param figs A column cell array containing the handles to the figures
% to assign to the screen.
% @param screenSize the size of the screen being laid out (correctGeometry()
% must have been applied).
% @param handles Handles to virtual functions (used to choose layout and
% deal strategy).
% @param activate Wether to activate the figure or not. Activated figures
% are represented by a red rectangle whereas normal figures are
% represented by a green rectangle.

    % Initialising layout:
    rectangle('Position', screenSize(1, :));
    
    % Arguement checking:
    if (isempty(figs))
        return;
    end
    
    % Computing the optimal layout:
    n = size(figs, 1);
    [~, nc, ~, ~] = handles.computeLayout(n, screenSize(3), screenSize(4));
    
    % Doing layout:
    for c=1:nc
        w0 = floor((c - 1)*screenSize(3)/nc);
        w1 = floor(c*screenSize(3)/nc);
        nl = ceil((n - c + 1)/nc);
        for l = 1:nl
            h0 = floor((nl - l)*screenSize(4)/nl);
            h1 = floor((nl - l + 1)*screenSize(4)/nl);
            if (~strcmp(get(figs((l - 1)*nc + c), 'WindowStyle'), 'docked'))
                if (activate)
                    rectangle('Position', [screenSize(1) + w0, screenSize(2) + h0, w1 - w0, h1 - h0], 'EdgeColor', [1 0 0]);
                else
                    rectangle('Position', [screenSize(1) + w0, screenSize(2) + h0, w1 - w0, h1 - h0], 'EdgeColor', [0 1 0]);
                end 
            end
        end
    end
end
