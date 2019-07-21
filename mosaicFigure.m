function newFigHandle = mosaicFigure(varargin)
%% MOSAICFIGURE Creates an auto-tiling figure.
% This function can be used to manage figure positions. It was created to
% get around the fact that MATLAB always creates figures at the same
% position. Figures can be grouped and assigned to a monitor (monitor 0
% means any monitor).
%
% Usage:
%   mosaicFigure(...) : Creates a new figure which is out of any group and
% not assigned to any monitor. Makes it the active figure.
%   mosaicFigure(m, ...) : Creates a new figure which is out of any group 
% and assigned to monitor m. Makes it the active figure.
%   mosaicFigure(m, group, ...) : Creates a new figure in specified group
% (string or number) and assigned to monitor m . Makes it the active 
% figure.
%   In all these cases mosaicFigure returns the handle to the newly-created
% figure.
%
%   Mosaic figure also accepts properties. They are notified by ... in the
% invokations. Currentlty the following properties are accepted:
%   - Title (character string): The title of the newly-created window. 
%   - DealStrategy (integer(1x1) in the range 1-3): Selects the deal
% stategies. See the code of each deal strategy for indication on how 
% they work. 
%   -LayoutStrategy (integer(1x1) in the range 1-4): Selects the layout 
% strategy. See the code of each layout strategy for indication on how 
% they work. 
%
% Special commands:
%   mosaicFigure close
%   mosaicFigure close all
%   Closes all the figures managed by mosaicFigure.
%   mosaicFigure closes groupName
%   Closes all the figures in the group named groupName
%   
%   Can also be used under function form.
%
% Debug usages:
%   mosaicFigure debug 
%   Returns the state of the function (the list of all mosaic figures).
%   Can also be used under function form.
%   mosaicFigure('debugLayout', group, monitorSizes) allows you to simulate 
% layout with other monitor sizes than the real ones.
%
% Copyright 2015 Pascal COMBES <pascom@orange.fr>
%
% Author:   Pascal COMBES <pascom@orange.fr>
% Date:     February 15th, 2015
% Version:  1.0.0
% License:  GPLv3
% Requires: parseProperties

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
        figList = {[]};
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
        if (isnumeric(group) && (round(group) == group))
            group = int64(group);
        elseif (ischar(group) && ~isempty(regexp(group, '^[1-9][0-9]*$', 'once')))
            group = int64(sscanf(group, '%d'));
        end
        if (~ischar(group) && ~isinteger(group))
            error('MATLAB:BadArgumentType', ...
                  'Group names must be integers or chars');
        end
        % If the fig list has been reset, try recover from backup:
        if ((size(figList, 1) == 1) && isempty(figList{1}))
            backup = load([tempdir, 'figList.mat']);
            figList = backup.figList;
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
            figList = {};
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
    
    %% Handler of closing events for the figures:
    function closeMosaicFigure(src, ~, group)
        % Find the group number of the figure being deleted:
        try
            gr = findGroup(group, figList);
        catch e %#ok I don't want information on an error in findgroup
            % The listof figures has probably been cleared out:
            % Tries to recover from backup.
            backup = load([tempdir, 'figList.mat']);
            figList = backup.figList;
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
            if (size(figList{gr}.contents, 1) > 1)
                rep = questdlg(['You are closing figure of group "', groupname, '". Do you want to close the whole group or only this figure?'], ...
                               ['Closing group "', groupname, '"'], ...
                               ALL, ONE, CANCEL, ALL);
            else
                rep = ALL;
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
                save([tempdir, 'figList.mat'], 'figList');
                return;
            end
        end
        % Saves figure list:
        save([tempdir, 'figList.mat'], 'figList');
        
        % Relayout (refresh monitor positions because monitors may have
        % been added or disconnected
        if (g == 1)
            layout(figList{1}, handles.getMonitorPositions(), handles);
        else
            layout(figList{g}.contents, handles.getMonitorPositions(), handles);
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
    
    %% Relayout:
    if (g == 1)
        layout(figList{1}, monitorSizes, handles);
    else
        layout(figList{g}.contents, monitorSizes, handles, true);
    end
    
    %% Ensures the new figure is the active figure:
    figure(newFigHandle);
    
    %% Saves figure list:
    save([tempdir, 'figList.mat'], 'figList');
end

function closeGroup(group)
%% CLOSEGROUP Closes a group of figures.
% This function closes the group of figure given in group.
% If 'all' is passed, then it closes all the figures created with
% mosaicFigure without prompt.
%   @param group A column structure array with the following fields:
%       -handle: The handle to the corresponding figure.
%       -screen: The screen ion which the figure must be displayed.
    for f=1:length(group)
        %set(group(f).handle, 'CloseRequestFcn', closereq);
        delete(group(f).handle);
    end
end

function layout(group, screenSizes, varargin)
%% LAYOUT Lay a group of figures out.
% This function accepts two to four arguments:
%   @param group A column structure array with the following fields:
%       -handle: The handle to the corresponding figure.
%       -screen: The screen ion which the figure must be displayed.
%   @param screenSizes The sizes of the available monitors (as given by MATLAB).
%   @param handles Optional. Handles to virtual functions (used for
% debugging and choosing the layout strategy).
%   @param activate Optional. Whether to activate the figure after
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
%% COMPUTEOCCUPATION For each layout possibility tells how much screen is used
% and how big the figures are.
%   @param n0 The number of figures not assigned to a sceen.
%   @param ns The number of figures assigned to each screen (a line array).
%   @param screenSizes The sizes of the available monitors (as given by MATLAB).
%   @param handles Handles to virtual functions (used for debugging and 
% choosing the layout strategy).
%   @return occ How much of the screen is occuped.
%   @return area How big are the figures.

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
%% LAYOUTSCREEN Layout one screen.
%   @param figs A column cell array containing the handles to the figures
% to assign to the screen.
%   @param screenSize The size of the screen being laid out
% (correctGeometry mus have been used before).
%   @param handles Handles to virtual functions (used for debugging and 
% choosing the layout strategy).
%   @param activate Whether to activate the figure after laying out or not.

    %% Arguement checking:
    if (isempty(figs))
        return;
    end
    
    %% Computing layout:
    n = size(figs, 1);
    [~, nc, wf, ~] =  handles.computeLayout(n, screenSize(3), screenSize(4));
    
    %% Doing layout:
    for c=1:nc
        nl = ceil((n - c + 1)/nc);
        hf = floor((screenSize(4) + 1)/nl);
        for l = 1:nl
            if (~strcmp(get(figs((l - 1)*nc + c), 'WindowStyle'), 'docked'))
                set(figs((l - 1)*nc + c), 'OuterPosition', [screenSize(1) + (c - 1)*wf, screenSize(2) + (nl - l)*hf, wf, hf]);
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
% PARSEDEALSTRATEGY Parses the deal strategy
% Assign the good deal strategy in the handles array.
%   @param handles Handles to virtual functions. Field dealFigures will be
% modified.
%   @param value The number of the deal strategy to use.
%   @return handles Handles to virtual functions. Field dealFigures has
% been modified.
    handles.dealFigures = str2func(sprintf('dealFigures%d', value));
end

function handles = parseLayoutStrategy(handles, value)
% PARSELAYOUTSTRATEGY Parses the layout strategy
% Assign the good layout strategy in the handles array.
%   @param handles Handles to virtual functions. Field computeLayout will be
% modified.
%   @param value The number of the deal strategy to use.
%   @return handles Handles to virtual functions. Field computeLayout has
% been modified.
    handles.computeLayout = str2func(sprintf('computeLayout%d', value));
end

function handles = parseUseJava(handles, value)
% PARSEUSEJAVA Parses the layout strategy
% Assign the good layout strategy to obtain monitor positions.
%   @param handles Handles to virtual functions. Field getMonitorPositions 
% will be modified.
%   @param value The number of the deal strategy to use.
%   @return handles Handles to virtual functions. Field 
% compgetMonitorPositions  has been modified.
    if (~value)
        handles.getMonitorPositions = @getMonitorPositions;
    end 
end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%% SCREEN DEALING FUNCTIONS :
function [deal] = dealFigures1(occs, areas) %#ok This is a virtual function which may be called when selecting DealStrategy 1
%% DEALFIGURES1 Find the best deal between monitors for the figures
% This function tries to find the best tradeoff between areas and screen
% occupation. It does it by a dichotomy selecting occupations greather than
% a level and relative difference in areas smaller than (1 - level)^2.
%   @param occs Screen occupations.
%   @param areas Figures areas.
%   @return deal A line vector containing the best deal of the figures
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
%% DEALFIGURES2 Find the best deal between monitors for the figures
% This function tries to find the best tradeoff between areas and screen
% occupation. It does it by a dichotomy selecting occupations greather than
% a level and relative difference in total areas covered by figures smaller
% than (1 - level)^2 and then selecting the deal with the biggest possible
% areas.
%   @param occs Screen occupations.
%   @param areas Figures areas.
%   @return deal A line vector containing the best deal of the figures
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
%% DEALFIGURES3 Find the best deal between monitors for the figures
% This function tries to find the best tradeoff between areas and screen
% occupation. It does it by a dichotomy selecting occupations greather than
% a level and relative difference in total areas covered by figures smaller
% than (1 - level)^2 and then selecting the deal with the smallest possible 
% area difference.
%   @param occs Screen occupations.
%   @param areas Figures areas.
%   @return deal A line vector containing the best deal of the figures
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
%% COMPUTELAYOUT1 Tries to find the best line and columns number
% It tries to have the quotient hf/wf close to 1 (square figure).
%   @param n The number or figures which will be eventually displayed on
% this screen.
%   @param w The width of the screen.
%   @param w The height of the screen.
%   @return l The number of lines of figures.
%   @return c The number of colums of figures.
%   @return wf The width of the figures.
%   @return hf The height of the figures.

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
%% COMPUTELAYOUT2 Tries to find the best line and columns number
% It tries to have c and l integers close to c0 = w/h*l0 by rounding.
%   @param n The number or figures which will be eventually displayed on
% this screen.
%   @param w The width of the screen.
%   @param w The height of the screen.
%   @return l The number of lines of figures.
%   @return c The number of colums of figures.
%   @return wf The width of the figures.
%   @return hf The height of the figures.

   l = round(sqrt(h*n/w));
   if (l == 0)
       l = 1;
   end
   c = ceil(n/l);
   wf = floor(w/c);
   hf = floor(h/l);
end

function [l, c, wf, hf] = computeLayout3(n, w, h) %#ok This is a virtual function which may be called when selecting LayouStrategy 3
%% COMPUTELAYOUT3 Tries to find the best line and columns number
% It tries to have c and l integers close to c0 = w/h*l0 and then selects
% the solution which give the closest solution. 
%   @param n The number or figures which will be eventually displayed on
% this screen.
%   @param w The width of the screen.
%   @param w The height of the screen.
%   @return l The number of lines of figures.
%   @return c The number of colums of figures.
%   @return wf The width of the figures.
%   @return hf The height of the figures.

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
%% COMPUTELAYOUT4 Tries to find the best line and columns number
% It tries to have c and l integers close to c0 = w/h*l0 and then selects
% the solution which give the most square figs. 
%   @param n The number or figures which will be eventually displayed on
% this screen.
%   @param w The width of the screen.
%   @param w The height of the screen.
%   @return l The number of lines of figures.
%   @return c The number of colums of figures.
%   @return wf The width of the figures.
%   @return hf The height of the figures.
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
%% NOOP Does nothing with any number of arguments.
end

function v = versionNumber()
%% VERSIONNUMBER Returns the version as a number
% It is better to have the version as a number in code (for comparisons).
% The returned number is equal to the year part, plus 1/2 if this ia a b
% release.
% Ex:
%   On 2011a: 2011.0
%   On 2014b: 2014.5
%   @returns An number conveying MATLAB version.
    ver = version('-release');
    v = sscanf(ver(1:4), '%d');
    if (ver(5) == 'b')
        v = v + 0.5;
    end
end

function path = getFilePath()
%% GETFILEPATH Get the file path.
%   @return path The path to the *.m file.

    path = mfilename('fullpath');
    i = find(path == filesep, 1, 'last');
    if(~isempty(i))
        path = path(1:(i - 1));
    end
end

function g = findGroup(group, list)
%% FINDGROUP Find the number of the group in list
%   @param group A integer or a string to represent the searched group.
%   @param list A line struct array with at least a field group.
%   @return The number of the given group in the list or an empty array if
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
%% GROUP2STR Converts a group identifier to a string
%   @param group A group identifier (might be a string or an integer).
%   @return str The given group identifier as a string.

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
%% FIGNUMBERHANDLE Creates a figure using the given arguments.
% This function creates a figure using thee given arguments and returns the
% number handle to it. This is strictly equivalent to the ficure command in
% version 2001a.
%   @params fig The figure created by figure.
%   @return fig The number handle to the figure.
    if (versionNumber() < 2014.5)
        figNum = fig;
    else
        figNum = fig.Number;
    end
end

function setFigureName(fig, varargin)
%% SETFIGURENAME Appropriately sets the name of the figure.
% This function can have two or three arguments:
%   @param fig The handle to the figure whose name is being set.
%   @param figNum The number of the figure in its group.
%   @param figGroup The identifier for the group of the figure.
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
%% GETMONITORPOSITIONS Gives the positions of the monitors using Java methods.
% This function corrects the positions returned by Java AWT methods
% and returns them.
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
%% GETMONITORPOSITIONS Gives the positions of the monitors.
% This function corrects the positions returned by get(0, 'MonitorPositions'))
% and returns them.
    screenPositions = correctGeometry(get(0, 'MonitorPositions'));
end

function geom = correctGeometry(screenSizes)
%% CORRECTGEOMETRY Gives the correct geometries for screens.
% When accessed by get(0, 'MonitorPositions'), the given rectangles are
% badly referenced for figure positionning. Indeed the frame origin is the
% top-left corner of base screen and vertcial axis is oriented towards 
% bottom. The rectangles are given as top-left and bottom right corner
% coordinates and there is an offset of one (but this is needed to draw 
% figures) 
% This function transforms these coordinates so that the returned vector
% gives the botton-left corner coordinates and the height and width of the
% screen. The new frame has axes towards the right and the top of the
% screen. The origin is the bottom left corner of the main screen. This is
% what is convenient for positioning figures.
%   @param monitor: The monitor positions (as returned by get(0, 'MonitorPositions')).
%   @returns A 1x4 vector with the coordinates of the bottom-left corner of
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

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%% DEBUGGING FUNCTIONS :
function initLayoutDebug(screenSize)
%% INITLAYOUTDEBUG Initialises a figure to debug the layout.
% This function is used to initialise layout debuggiung when rectangles are
% drawn on a figures instead of creating figures.
%   @param screenSize The size of the screen (correctGeometry must have
% been applied).
    figure('OuterPosition', screenSize);
end

function layoutScreenDebug(figs, screenSize, handles, activate)
%% LAYOUTSCREENDEBUG Debug screen layout process.
% In this mode rectangles representing figures are drawn on a screen
% instead of creating figures.
%   @param figs The figs to layout on this screen.
%   @param screenSize the size of the screen being laid out (correctGeometry must have
% been applied).
%   @param handles Handles to virtual functions (used to choose layout and
% deal strategy).
%   @param activate Wether to activate the figure or not. Activated figures
% are represented by a red rectangle where as normal figures are
% represented by a green rectangle.

    % Initialising layout:
    rectangle('Position', screenSize(1, :));
    
    % Arguement checking:
    if (isempty(figs))
        return;
    end
    
    % Computing the optimal layout:
    n = size(figs, 1);
    [~, nc, wf, ~] = handles.computeLayout(n, screenSize(3), screenSize(4));
    
    % Doing layout:
    for c=1:nc
        nl = ceil((n - c + 1)/nc);
        hf = floor((screenSize(4) + 1)/nl);
        for l = 1:nl
            if (~strcmp(get(figs((l - 1)*nc + c), 'WindowStyle'), 'docked'))
                if (activate)
                    rectangle('Position', [screenSize(1) + (c - 1)*wf, screenSize(2) + (nl - l)*hf, wf, hf], 'EdgeColor', [1 0 0]);
                else
                    rectangle('Position', [screenSize(1) + (c - 1)*wf, screenSize(2) + (nl - l)*hf, wf, hf], 'EdgeColor', [0 1 0]);
                end 
            end
        end
    end
end
