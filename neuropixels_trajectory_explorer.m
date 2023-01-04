function neuropixels_trajectory_explorer(tv,av,st)

%% Neuropixels Trajectory Explorer
% 
% function neuropixels_trajectory_explorer(tv,av,st)
%
% Example calls:
% [tv,av,st] = nte.loadAtlas;
%  neuropixels_trajectory_explorer(tv,av,st)
%
% Or
%  neuropixels_trajectory_explorer
%
%
% Andy Peters (peters.andrew.j@gmail.com)
%
% GUI for planning Neuropixels trajectories with the Allen CCF atlas
%
% Instructions for use: 
% https://github.com/petersaj/neuropixels_trajectory_explorer


% Check for dependencies
% (npy-matlab to load in atlas)
if ~exist('readNPY','file')
   error('"npy-matlab" code not found, download here and add to matlab path: https://github.com/kwikteam/npy-matlab') 
end
% (image processing toolbox)
if ~license('test','Image_Toolbox')
    error('MATLAB Image Processing toolbox required: https://uk.mathworks.com/products/image.html')
end


% Check MATLAB version
matlab_version = version('-date');
if str2num(matlab_version(end-3:end)) <= 2016
    error('Old MATLAB - allen_ccf_npx requires 2016 or later');
end


% To speed loading 
if nargin<3
    % Load atlas if it is not supplied
    [tv,av,st] = nte.loadAtlas;
end 


% Create CCF colormap
ccf_cmap = nte.ccfmap;


% Return the transform matrix to go from CCF to bregma coords
ccf_bregma_tform = nte.return_CCF2Bregma_tform;


% Initialize gui_data structure
gui_data = struct;




% ~~~~ Make GUI axes and objects

% Set up the gui
probe_atlas_gui = figure('Toolbar','none','Menubar','none','color','w', ...
    'Name','Neuropixels Trajectory Explorer','Units','normalized','Position',[0.21,0.2,0.7,0.7]);

% Set up the atlas axes
axes_atlas = axes('Position',[-0.3,0.1,1.2,0.8],'ZDir','reverse');
axis(axes_atlas,'vis3d','equal','off','manual'); hold(axes_atlas,'on');

% Draw brain outline
slice_spacing = 5;


% The 'majority' operation performs a local cleanup 
fprintf('Cleaning data\n')
brain_volume = ...
    bwmorph3(bwmorph3(av(1:slice_spacing:end, ...
    1:slice_spacing:end,1:slice_spacing:end)>1,'majority'),'majority');

% Make 3D grids to index in all three axes
fprintf('Making grids\n')
[ap_grid_ccf,dv_grid_ccf,ml_grid_ccf] = ...
    ndgrid(1:slice_spacing:size(av,1), ...
    1:slice_spacing:size(av,2), ...
    1:slice_spacing:size(av,3));

% Transform grids
fprintf('Transforming grids\n')
[ml_grid_bregma, ap_grid_bregma, dv_grid_bregma] = ...
    transformPointsForward(ccf_bregma_tform, ml_grid_ccf, ap_grid_ccf, dv_grid_ccf);

fprintf('Making patch data\n')
brain_outline_patchdata = reducepatch(isosurface(ml_grid_bregma,ap_grid_bregma, ...
    dv_grid_bregma,brain_volume,0.5),0.1);

brain_outline = patch( ...
        'Vertices',brain_outline_patchdata.vertices, ...
        'Faces',brain_outline_patchdata.faces, ...
        'FaceColor',[0.5,0.5,0.5],'EdgeColor','none','FaceAlpha',0.1);

view([30,150]);
caxis([0 300]);

xlim([-5.2,5.2]);set(gca,'XTick',-5:0.5:5);
ylim([-8.5,5]);set(gca,'YTick',-8.5:0.5:5);
zlim([-1,6.5]);set(gca,'ZTick',-1:0.5:6.5);
grid on;


% Set up the probe reference/actual
probe_ref_top = [0,0,-0.1];
probe_ref_bottom = [0,0,6];
probe_ref_vector = [probe_ref_top',probe_ref_bottom'];
probe_ref_line = line(probe_ref_vector(1,:),probe_ref_vector(2,:),probe_ref_vector(3,:), ...
    'linewidth',1.5,'color','r','linestyle','--');

probe_length = 3.840; % IMEC phase 3 (in mm)
probe_vector = [probe_ref_vector(:,1),diff(probe_ref_vector,[],2)./ ...
    norm(diff(probe_ref_vector,[],2))*probe_length + probe_ref_vector(:,1)];
probe_line = line(probe_vector(1,:),probe_vector(2,:),probe_vector(3,:), ...
    'linewidth',3,'color','b','linestyle','-');

% Set up the text to display coordinates
probe_coordinates_text = uicontrol('Style','text','String','', ...
    'Units','normalized','Position',[0,0.9,0.5,0.1], ...
    'BackgroundColor','w','HorizontalAlignment','left','FontSize',12, ...
    'FontName','Consolas');

% Set up the probe area axes
axes_probe_areas = axes('Position',[0.7,0.1,0.03,0.8]);
axes_probe_areas.ActivePositionProperty = 'position';
set(axes_probe_areas,'FontSize',11);
yyaxis(axes_probe_areas,'left');
probe_areas_plot = image(0);
set(axes_probe_areas,'XTick','','YLim',[0,probe_length],'YColor','k','YDir','reverse');
ylabel(axes_probe_areas,'Depth (mm)');
yyaxis(axes_probe_areas,'right');
set(axes_probe_areas,'XTick','','YLim',[0,probe_length],'YColor','k','YDir','reverse');
title(axes_probe_areas,'Probe areas');
colormap(axes_probe_areas,ccf_cmap);
caxis([1,size(ccf_cmap,1)]);

% Store data
gui_data.tv = tv; % Intensity atlas
gui_data.av = av; % Annotated atlas
gui_data.st = st; % Labels table
gui_data.cmap = ccf_cmap; % Atlas colormap
gui_data.ccf_bregma_tform = ccf_bregma_tform;
gui_data.probe_length = probe_length; % Length of probe
gui_data.structure_plot_idx = []; % Plotted structures
gui_data.probe_angle = [0;90]; % Probe angles in ML/DV

%Store handles
gui_data.handles.cortex_outline = brain_outline;
gui_data.handles.structure_patch = []; % Plotted structures
gui_data.handles.axes_atlas = axes_atlas; % Axes with 3D atlas
gui_data.handles.axes_probe_areas = axes_probe_areas; % Axes with probe areas
gui_data.handles.slice_plot = surface(axes_atlas,'EdgeColor','none'); % Slice on 3D atlas
gui_data.handles.slice_volume = 'tv'; % The volume shown in the slice
gui_data.handles.probe_ref_line = probe_ref_line; % Probe reference line on 3D atlas
gui_data.handles.probe_line = probe_line; % Probe reference line on 3D atlas
gui_data.handles.probe_areas_plot = probe_areas_plot; % Color-coded probe regions
gui_data.probe_coordinates_text = probe_coordinates_text; % Probe coordinates text

% Make 3D rotation the default state (toggle on/off with 'r')
h = rotate3d(axes_atlas);
h.Enable = 'on';
% Update the slice whenever a rotation is completed
h.ActionPostCallback = @nte.update_slice;

% Set functions for key presses
hManager = uigetmodemanager(probe_atlas_gui);
[hManager.WindowListenerHandles.Enabled] = deal(false);
set(probe_atlas_gui,'KeyPressFcn',@key_press);
set(probe_atlas_gui,'KeyReleaseFcn',@key_release);

% Upload gui_data
guidata(probe_atlas_gui, gui_data);

% Display the first slice and update the probe position
nte.update_slice(probe_atlas_gui);
nte.update_probe_coordinates(probe_atlas_gui);


%% Buttons

button_fontsize = 12;

%%% View angle buttons
view_button_position = [0,0,0.05,0.05];
clear view_button_h
view_button_h(1) = uicontrol('Parent',probe_atlas_gui,'Style','pushbutton','FontSize',button_fontsize, ...
    'Units','normalized','Position',view_button_position,'String','Coronal','Callback',{@view_coronal,probe_atlas_gui});
view_button_h(end+1) = uicontrol('Parent',probe_atlas_gui,'Style','pushbutton','FontSize',button_fontsize, ...
    'Units','normalized','Position',view_button_position,'String','Sagittal','Callback',{@view_sagittal,probe_atlas_gui});
view_button_h(end+1) = uicontrol('Parent',probe_atlas_gui,'Style','pushbutton','FontSize',button_fontsize, ...
    'Units','normalized','Position',view_button_position,'String','Horizontal','Callback',{@view_horizontal,probe_atlas_gui});
align(view_button_h,'fixed',0.1,'middle');


%%% Control panel

control_panel = figure('Toolbar','none','Menubar','none','color','w', ...
    'Name','Controls','Units','normalized','Position',[0.09,0.2,0.11,0.7]);
button_position = [0.05,0.05,0.9,0.05];
header_text_position = [0.05,0.05,0.9,0.03];
clear controls_h

% (probe controls)
controls_h(1) = uicontrol('Parent',control_panel,'Style','text','FontSize',button_fontsize, ...
    'Units','normalized','Position',header_text_position,'String','Probe controls:', ...
    'BackgroundColor','w','FontWeight','bold');
controls_h(end+1) = uicontrol('Parent',control_panel,'Style','text','FontSize',button_fontsize, ...
    'Units','normalized','Position',header_text_position,'String','Whole probe: arrow keys', ...
    'BackgroundColor','w');
controls_h(end+1) = uicontrol('Parent',control_panel,'Style','text','FontSize',button_fontsize, ...
    'Units','normalized','Position',header_text_position,'String','Depth: alt+arrow keys', ...
    'BackgroundColor','w');
controls_h(end+1) = uicontrol('Parent',control_panel,'Style','text','FontSize',button_fontsize, ...
    'Units','normalized','Position',header_text_position,'String','Probe tip: shift+arrow keys', ...
    'BackgroundColor','w');
controls_h(end+1) = uicontrol('Parent',control_panel,'Style','text','FontSize',button_fontsize, ...
    'Units','normalized','Position',header_text_position,'String','(changes probe angle)', ...
    'BackgroundColor','w');
controls_h(end+1) = uicontrol('Parent',control_panel,'Style','pushbutton','FontSize',button_fontsize, ...
    'Units','normalized','Position',button_position,'String','Set entry','Callback',{@nte.set_probe_entry,probe_atlas_gui});
controls_h(end+1) = uicontrol('Parent',control_panel,'Style','pushbutton','FontSize',button_fontsize, ...
    'Units','normalized','Position',button_position,'String','Set endpoint','Callback',{@nte.set_probe_endpoint,probe_atlas_gui});

% (area selector)
controls_h(end+1) = uicontrol('Parent',control_panel,'Style','text','FontSize',button_fontsize, ...
    'Units','normalized','Position',header_text_position,'String','3D areas:', ...
    'BackgroundColor','w','FontWeight','bold');
controls_h(end+1) = uicontrol('Parent',control_panel,'Style','pushbutton','FontSize',button_fontsize, ...
    'Units','normalized','Position',button_position,'String','List areas','Callback',{@add_area_list,probe_atlas_gui});
controls_h(end+1) = uicontrol('Parent',control_panel,'Style','pushbutton','FontSize',button_fontsize, ...
    'Units','normalized','Position',button_position,'String','Search areas','Callback',{@add_area_search,probe_atlas_gui});
controls_h(end+1) = uicontrol('Parent',control_panel,'Style','pushbutton','FontSize',button_fontsize, ...
    'Units','normalized','Position',button_position,'String','Hierarchy areas','Callback',{@add_area_hierarchy,probe_atlas_gui});
controls_h(end+1) = uicontrol('Parent',control_panel,'Style','pushbutton','FontSize',button_fontsize, ...
    'Units','normalized','Position',button_position,'String','Remove areas','Callback',{@remove_area,probe_atlas_gui});

% (visibility toggle)
controls_h(end+1) = uicontrol('Parent',control_panel,'Style','text','FontSize',button_fontsize, ...
    'Units','normalized','Position',header_text_position,'String','Toggle visibility:', ...
    'BackgroundColor','w','FontWeight','bold');
controls_h(end+1) = uicontrol('Parent',control_panel,'Style','pushbutton','FontSize',button_fontsize, ...
    'Units','normalized','Position',button_position,'String','Slice','Callback',{@visibility_slice,probe_atlas_gui});
controls_h(end+1) = uicontrol('Parent',control_panel,'Style','pushbutton','FontSize',button_fontsize, ...
    'Units','normalized','Position',button_position,'String','Brain outline','Callback',{@visibility_brain_outline,probe_atlas_gui});
controls_h(end+1) = uicontrol('Parent',control_panel,'Style','pushbutton','FontSize',button_fontsize, ...
    'Units','normalized','Position',button_position,'String','Grid','Callback',{@visibility_grid,probe_atlas_gui});
controls_h(end+1) = uicontrol('Parent',control_panel,'Style','pushbutton','FontSize',button_fontsize, ...
    'Units','normalized','Position',button_position,'String','Probe','Callback',{@visibility_probe,probe_atlas_gui});
controls_h(end+1) = uicontrol('Parent',control_panel,'Style','pushbutton','FontSize',button_fontsize, ...
    'Units','normalized','Position',button_position,'String','3D areas','Callback',{@visibility_3d_areas,probe_atlas_gui});
controls_h(end+1) = uicontrol('Parent',control_panel,'Style','pushbutton','FontSize',button_fontsize, ...
    'Units','normalized','Position',button_position,'String','Dark mode','Callback',{@visibility_darkmode,probe_atlas_gui});

% (other)
controls_h(end+1) = uicontrol('Parent',control_panel,'Style','text','FontSize',button_fontsize, ...
    'Units','normalized','Position',header_text_position,'String','Other:', ...
    'BackgroundColor','w','FontWeight','bold');
controls_h(end+1) = uicontrol('Parent',control_panel,'Style','pushbutton','FontSize',button_fontsize, ...
    'Units','normalized','Position',button_position,'String','Export coordinates','Callback',{@nte.export_coordinates,probe_atlas_gui});
controls_h(end+1) = uicontrol('Parent',control_panel,'Style','pushbutton','FontSize',button_fontsize, ...
    'Units','normalized','Position',button_position,'String','Load/plot histology','Callback',{@probe_histology,probe_atlas_gui});

set(controls_h(1),'Position',header_text_position+[0,0.9,0,0]);
align(fliplr(controls_h),'center','distribute');

% Set close functions for windows
set(probe_atlas_gui,'CloseRequestFcn',{@gui_close,probe_atlas_gui,control_panel});
set(control_panel,'CloseRequestFcn',{@gui_close,probe_atlas_gui,control_panel});
end


function gui_close(h,eventdata,probe_atlas_gui,control_panel)
    % When closing either GUI or control panel, close both windows
    delete(control_panel);
    delete(probe_atlas_gui);
end

%% Probe controls and slice updating

function key_press(probe_atlas_gui,eventdata)
    % Get guidata
    gui_data = guidata(probe_atlas_gui);

    % Set step size in millimeters
    step_size = 0.1;

    % Update probe coordinates
    ap_offset = 0;
    ml_offset = 0;
    probe_offset = 0;
    angle_change = [0;0];

    switch eventdata.Key
        case 'uparrow'
            if isempty(eventdata.Modifier)
                ap_offset = step_size;
            elseif any(strcmp(eventdata.Modifier,'shift'))
                angle_change = [0;step_size];
            elseif any(strcmp(eventdata.Modifier,'alt'))
                probe_offset = -step_size;
            end
        case 'downarrow'
            if isempty(eventdata.Modifier)
                ap_offset = -step_size;
            elseif any(strcmp(eventdata.Modifier,'shift'))
                angle_change = [0;-step_size];
            elseif any(strcmp(eventdata.Modifier,'alt'))
                probe_offset = step_size;
            end
        case 'leftarrow'
            if isempty(eventdata.Modifier)
                ml_offset = -step_size;
            elseif any(strcmp(eventdata.Modifier,'shift'))
                angle_change = [-step_size;0];
            end
        case 'rightarrow'
            if isempty(eventdata.Modifier)
                ml_offset = step_size;
            elseif any(strcmp(eventdata.Modifier,'shift'))
                angle_change = [step_size;0];
            end
    end

    % Draw updated probe
    if any([ap_offset,ml_offset,probe_offset])
        % (AP/ML)
        set(gui_data.handles.probe_ref_line,'XData',get(gui_data.handles.probe_ref_line,'XData') + ml_offset);
        set(gui_data.handles.probe_line,'XData',get(gui_data.handles.probe_line,'XData') + ml_offset);
        set(gui_data.handles.probe_ref_line,'YData',get(gui_data.handles.probe_ref_line,'YData') + ap_offset);
        set(gui_data.handles.probe_line,'YData',get(gui_data.handles.probe_line,'YData') + ap_offset);
        % (probe axis)
        old_probe_vector = cell2mat(get(gui_data.handles.probe_line,{'XData','YData','ZData'})');
        move_probe_vector = diff(old_probe_vector,[],2)./ ...
            norm(diff(old_probe_vector,[],2))*probe_offset;
        new_probe_vector = bsxfun(@plus,old_probe_vector,move_probe_vector);
        set(gui_data.handles.probe_line,'XData',new_probe_vector(1,:), ...
            'YData',new_probe_vector(2,:),'ZData',new_probe_vector(3,:));
    end
    % (angle)
    if any(angle_change)
        gui_data = nte.update_probe_angle(probe_atlas_gui,angle_change);
    end

    % Upload gui_data
    guidata(probe_atlas_gui, gui_data);
end

function key_release(probe_atlas_gui,eventdata)
    % Get guidata
    gui_data = guidata(probe_atlas_gui);

    switch eventdata.Key
        case {'rightarrow','leftarrow','uparrow','downarrow'}
            % Update the probe info/slice on arrow release 
            nte.update_probe_coordinates(probe_atlas_gui);
            nte.update_slice(probe_atlas_gui);
    end

    % Upload gui_data
    guidata(probe_atlas_gui, gui_data);
end



%% Button callback functions

function view_coronal(h,eventdata,probe_atlas_gui)
    % Set coronal view
    gui_data = guidata(probe_atlas_gui);
    view(gui_data.handles.axes_atlas,[0,0]);
    nte.update_slice(probe_atlas_gui);
end


function view_sagittal(h,eventdata,probe_atlas_gui)
    % Set sagittal view
    gui_data = guidata(probe_atlas_gui);
    view(gui_data.handles.axes_atlas,[-90,0]);
    nte.update_slice(probe_atlas_gui);
end


function view_horizontal(h,eventdata,probe_atlas_gui)
    % Set horizontal view
    gui_data = guidata(probe_atlas_gui);
    view(gui_data.handles.axes_atlas,[0,90]);
    nte.update_slice(probe_atlas_gui);
end


function add_area_list(h,eventdata,probe_atlas_gui)
    % List all CCF areas, draw selected

    % Get guidata
    gui_data = guidata(probe_atlas_gui);

    % Prompt for which structures to show (only structures which are
    % labelled in the slice-spacing downsampled annotated volume)
    slice_spacing = 10;
    parsed_structures = unique(reshape(gui_data.av(1:slice_spacing:end, ...
        1:slice_spacing:end,1:slice_spacing:end),[],1));

    % plot_structure_parsed = listdlg('PromptString','Select a structure to plot:', ...
    %     'ListString',gui_data.st.safe_name(parsed_structures),'ListSize',[520,500], ...
    %     'SelectionMode','single');
    % plot_structure = parsed_structures(plot_structure_parsed);

    % (change: show all structures even if not parsed to allow hierarchy)
    plot_structure = listdlg('PromptString','Select a structure to plot:', ...
        'ListString',gui_data.st.safe_name,'ListSize',[520,500], ...
        'SelectionMode','single');

    % Draw areas
    nte.draw_areas(probe_atlas_gui,slice_spacing,plot_structure);
end


function add_area_search(h,eventdata,probe_atlas_gui)
    % Search all CCF areas, draw selected

    % Get guidata
    gui_data = guidata(probe_atlas_gui);

    % Prompt for which structures to show (only structures which are
    % labelled in the slice-spacing downsampled annotated volume)
    slice_spacing = 10;
    parsed_structures = unique(reshape(gui_data.av(1:slice_spacing:end, ...
        1:slice_spacing:end,1:slice_spacing:end),[],1));

    structure_search = lower(inputdlg('Search structures'));
    structure_match = find(contains(lower(gui_data.st.safe_name),structure_search));
    % list_structures = intersect(parsed_structures,structure_match);
    % (change: show all structures even if not parsed to allow hierarchy)
    list_structures = structure_match;

    plot_structure_parsed = listdlg('PromptString','Select a structure to plot:', ...
        'ListString',gui_data.st.safe_name(list_structures),'ListSize',[520,500], ...
        'SelectionMode','single');
    plot_structure = list_structures(plot_structure_parsed);

    % Draw areas
    nte.draw_areas(probe_atlas_gui,slice_spacing,plot_structure);
end


function add_area_hierarchy(h,eventdata,probe_atlas_gui)
    % Explore CCF hierarchy, draw selected

    % Get guidata
    gui_data = guidata(probe_atlas_gui);

    % Bring up hierarchical selector
    plot_structure = hierarchical_select(gui_data.st);

    % Draw areas
    slice_spacing = 10;
    nte.draw_areas(probe_atlas_gui,slice_spacing,plot_structure);
end


function remove_area(h,eventdata,probe_atlas_gui)
    % Remove previously drawn areas

    % Get guidata
    gui_data = guidata(probe_atlas_gui);

    if ~isempty(gui_data.structure_plot_idx)
        remove_structures = listdlg('PromptString','Select a structure to remove:', ...
            'ListString',gui_data.st.safe_name(gui_data.structure_plot_idx));
        delete(gui_data.handles.structure_patch(remove_structures))
        gui_data.structure_plot_idx(remove_structures) = [];
        gui_data.handles.structure_patch(remove_structures) = [];
    end

    % Upload gui_data
    guidata(probe_atlas_gui,gui_data);
end


function visibility_slice(h,eventdata,probe_atlas_gui)
    % Get guidata
    gui_data = guidata(probe_atlas_gui);

    % Toggle slice volume/visibility
    slice_volumes = {'tv','av','none'};
    new_slice_volume = slice_volumes{circshift( ...
        strcmp(gui_data.handles.slice_volume,slice_volumes),[0,1])};

    if strcmp(new_slice_volume,'none')
        set(gui_data.handles.slice_plot,'Visible','off');
    else
        set(gui_data.handles.slice_plot,'Visible','on');
    end

    gui_data.handles.slice_volume = new_slice_volume;
    guidata(probe_atlas_gui, gui_data);

    nte.update_slice(probe_atlas_gui);

    % Upload gui_data
    guidata(probe_atlas_gui,gui_data);
end


function visibility_brain_outline(h,eventdata,probe_atlas_gui)
    % Get guidata
    gui_data = guidata(probe_atlas_gui);

    % Toggle brain outline visibility
    current_visibility = gui_data.handles.cortex_outline.Visible;
    switch current_visibility; case 'on'; new_visibility = 'off'; case 'off'; new_visibility = 'on'; end;
    set(gui_data.handles.cortex_outline,'Visible',new_visibility);

    % Upload gui_data
    guidata(probe_atlas_gui,gui_data);
end


function visibility_grid(h,eventdata,probe_atlas_gui)
    % Get guidata
    gui_data = guidata(probe_atlas_gui);

    % Toggle grid
    current_visibility = gui_data.handles.axes_atlas.Visible;
    switch current_visibility; case 'on'; new_visibility = 'off'; case 'off'; new_visibility = 'on'; end;
    set(gui_data.handles.axes_atlas,'Visible',new_visibility);

    % Upload gui_data
    guidata(probe_atlas_gui,gui_data);
end


function visibility_probe(h,eventdata,probe_atlas_gui)
    % Get guidata
    gui_data = guidata(probe_atlas_gui);

    % Toggle probe visibility
    current_visibility = gui_data.handles.probe_ref_line.Visible;
    switch current_visibility; case 'on'; new_visibility = 'off'; case 'off'; new_visibility = 'on'; end;
    set(gui_data.handles.probe_ref_line,'Visible',new_visibility);
    set(gui_data.handles.probe_line,'Visible',new_visibility);

    % Upload gui_data
    guidata(probe_atlas_gui,gui_data);
end


function visibility_3d_areas(h,eventdata,probe_atlas_gui)
    % Get guidata
    gui_data = guidata(probe_atlas_gui);

    % Toggle plotted structure visibility
    if ~isempty(gui_data.structure_plot_idx)
        current_visibility = get(gui_data.handles.structure_patch(1),'Visible');
        switch current_visibility; case 'on'; new_visibility = 'off'; case 'off'; new_visibility = 'on'; end;
        set(gui_data.handles.structure_patch,'Visible',new_visibility);
    end

    % Upload gui_data
    guidata(probe_atlas_gui,gui_data);
    end

    function visibility_darkmode(h,eventdata,probe_atlas_gui)
    % Get guidata
    gui_data = guidata(probe_atlas_gui);

    % Toggle dark mode
    curr_bg = max(get(probe_atlas_gui,'color'));

    switch curr_bg
        case 1
            new_bg_color = 'k';
            new_font_color = 'w';
        case 0
            new_bg_color = 'w';
            new_font_color = 'k';
    end

    % Set font colors
    set(probe_atlas_gui,'color',new_bg_color)
    yyaxis(gui_data.handles.axes_probe_areas,'left');
    set(gui_data.handles.axes_probe_areas,'ycolor',new_font_color)
    yyaxis(gui_data.handles.axes_probe_areas,'right');
    set(gui_data.handles.axes_probe_areas,'ycolor',new_font_color)
    set(gui_data.handles.axes_probe_areas.Title,'color',new_font_color)

    % Upload gui_data
    guidata(probe_atlas_gui,gui_data);
end



function selIdx = hierarchical_select(st)
    %% Hierarchy select dialog box
    % (copied wholesale from cortex-lab/allenCCF/Browsing Functions/hierarchicalSelect to remove dependence)

    selID = 567; % Cerebrum, default to start

    [boxList, idList] = makeBoxList(st, selID); 

    ud.idList = idList; ud.st = st;

    % make figure
    f = figure; set(f, 'KeyPressFcn', @hierarchical_select_ok);

    % selector box
    ud.hBox = uicontrol(f, 'Style', 'listbox', 'String', boxList, ...
        'Callback', @hierarchical_select_update, 'Value', find(idList==selID),...
        'Units', 'normalized', 'Position', [0.1 0.2 0.8 0.7],...
        'KeyPressFcn', @hierarchical_select_ok); 

    titleStr = boxList{idList==selID}; titleStr = titleStr(find(titleStr~=' ', 1):end);
    ud.hSelTitle = uicontrol(f, 'Style', 'text', ...
        'String', sprintf('Selected: %s', titleStr), ...
        'Units', 'normalized', 'Position', [0.1 0.9 0.8 0.1]); 

    ud.hCancel = uicontrol(f, 'Style', 'pushbutton', ...
        'String', 'Cancel', 'Callback', @hierarchical_select_cancel, ...
        'Units', 'normalized', 'Position', [0.1 0.1 0.2 0.1]); 

    ud.hOK = uicontrol(f, 'Style', 'pushbutton', ...
        'String', 'OK', 'Callback', @hierarchical_select_ok, ...
        'Units', 'normalized', 'Position', [0.3 0.1 0.2 0.1]); 

    set(f, 'UserData', ud);
    drawnow;

    uiwait(f);

    if ishghandle(f)
        ud = get(f, 'UserData');
        idList = ud.idList;

            if ud.hBox.Value>1
                selID = idList(get(ud.hBox, 'Value'));

                selIdx = find(st.id==selID);
            else
                selIdx = [];
            end
            delete(f)
            drawnow; 
        else
            selIdx = [];
    end
end


function [boxList, idList] = makeBoxList(st, selID)
    idList = selID;
    while idList(end)~=997 % root
        idList(end+1) = st.parent_structure_id(st.id==idList(end));
    end
    idList = idList(end:-1:1); % this is the tree of parents down to the selected one

    % make the parent string representation
    for q = 1:numel(idList)
        boxList{q} = sprintf('%s%s (%s)', repmat('  ', 1, q-1), ...
            st.acronym{st.id==idList(q)}, ...
            st.safe_name{st.id==idList(q)});
    end
    np = numel(idList);

    % now add children
    idList = [idList st.id(st.parent_structure_id==selID)'];

    % make the parent string representation
    for q = np+1:numel(idList)
        boxList{q} = sprintf('%s%s (%s)', repmat('  ', 1, np), ...
            st.acronym{st.id==idList(q)}, ...
            st.safe_name{st.id==idList(q)});
    end
end


function hierarchical_select_update(src, ~)
    f = get(src, 'Parent'); 
    ud = get(f, 'UserData');
    st = ud.st; idList = ud.idList;

    selID = idList(get(src, 'Value'));

    [boxList, idList] = makeBoxList(st, selID); 

    ud.idList = idList;
    set(f, 'UserData', ud);
    set(src, 'String', boxList, 'Value', find(idList==selID));

    titleStr = boxList{idList==selID}; titleStr = titleStr(find(titleStr~=' ', 1):end);
    set(ud.hSelTitle, 'String', sprintf('Selected: %s', titleStr));
end


% OK callback
function hierarchical_select_ok(~, ~)
    uiresume(gcbf);
end


% Cancel callback
function hierarchical_select_cancel(~, ~)
    ud = get(gcbf, 'UserData');
    ud.hBox.Value = 1;
    uiresume(gcbf);
end

