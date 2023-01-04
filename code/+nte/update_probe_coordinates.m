function update_probe_coordinates(probe_atlas_gui,varargin)

% Get guidata
gui_data = guidata(probe_atlas_gui);

% Get the positions of the probe and trajectory reference
probe_ref_vector = cell2mat(get(gui_data.handles.probe_ref_line,{'XData','YData','ZData'})');
probe_vector = cell2mat(get(gui_data.handles.probe_line,{'XData','YData','ZData'})');

trajectory_n_coords = round(max(abs(diff(probe_ref_vector,[],2)))*100); % 10um resolution
[trajectory_ml_coords_bregma,trajectory_ap_coords_bregma,trajectory_dv_coords_bregma] = deal( ...
    linspace(probe_ref_vector(1,1),probe_ref_vector(1,2),trajectory_n_coords), ...
    linspace(probe_ref_vector(2,1),probe_ref_vector(2,2),trajectory_n_coords), ...
    linspace(probe_ref_vector(3,1),probe_ref_vector(3,2),trajectory_n_coords));

probe_n_coords = round(sqrt(sum(diff(probe_vector,[],2).^2))*100); % 10um resolution along active sites
probe_coords_depth = linspace(0,gui_data.probe_length,probe_n_coords);
[probe_ml_coords_bregma,probe_ap_coords_bregma,probe_dv_coords_bregma] = deal( ...
    linspace(probe_vector(1,1),probe_vector(1,2),probe_n_coords), ...
    linspace(probe_vector(2,1),probe_vector(2,2),probe_n_coords), ...
    linspace(probe_vector(3,1),probe_vector(3,2),probe_n_coords));

% Transform bregma coordinates to CCF coordinates
[trajectory_ml_coords_ccf,trajectory_ap_coords_ccf,trajectory_dv_coords_ccf] = ...
    transformPointsInverse(gui_data.ccf_bregma_tform, ...
    trajectory_ml_coords_bregma,trajectory_ap_coords_bregma,trajectory_dv_coords_bregma);

[probe_ml_coords_ccf,probe_ap_coords_ccf,probe_dv_coords_ccf] = ...
    transformPointsInverse(gui_data.ccf_bregma_tform, ...
    probe_ml_coords_bregma,probe_ap_coords_bregma,probe_dv_coords_bregma);

% Get brain labels across the probe and trajectory, and intersection with brain
trajectory_coords_ccf = ...
    round([trajectory_ap_coords_ccf;trajectory_dv_coords_ccf;trajectory_ml_coords_ccf]);
trajectory_coords_ccf_inbounds = all(trajectory_coords_ccf > 0 & ...
    trajectory_coords_ccf <= size(gui_data.av)',1);

trajectory_idx = ...
    sub2ind(size(gui_data.av), ...
    round(trajectory_ap_coords_ccf(trajectory_coords_ccf_inbounds)), ...
    round(trajectory_dv_coords_ccf(trajectory_coords_ccf_inbounds)), ...
    round(trajectory_ml_coords_ccf(trajectory_coords_ccf_inbounds)));
trajectory_areas = ones(trajectory_n_coords,1); % (out of CCF = 1: non-brain)
trajectory_areas(trajectory_coords_ccf_inbounds) = gui_data.av(trajectory_idx);

trajectory_brain_idx = find(trajectory_areas > 1,1);
trajectory_brain_intersect = ...
    [trajectory_ml_coords_bregma(trajectory_brain_idx), ...
    trajectory_ap_coords_bregma(trajectory_brain_idx), ...
    trajectory_dv_coords_bregma(trajectory_brain_idx)]';

% (if the probe doesn't intersect the brain, don't update)
if isempty(trajectory_brain_intersect)
    return
end

probe_coords_ccf = ...
    round([probe_ap_coords_ccf;probe_dv_coords_ccf;probe_ml_coords_ccf]);
probe_coords_ccf_inbounds = all(probe_coords_ccf > 0 & ...
    probe_coords_ccf <= size(gui_data.av)',1);

probe_idx = ...
    sub2ind(size(gui_data.av), ...
    round(probe_ap_coords_ccf(probe_coords_ccf_inbounds)), ...
    round(probe_dv_coords_ccf(probe_coords_ccf_inbounds)), ...
    round(probe_ml_coords_ccf(probe_coords_ccf_inbounds)));
probe_areas = ones(probe_n_coords,1); % (out of CCF = 1: non-brain)
probe_areas(probe_coords_ccf_inbounds) = gui_data.av(probe_idx);

probe_area_boundaries = intersect(unique([find(~isnan(probe_areas),1,'first'); ...
    find(diff(probe_areas) ~= 0);find(~isnan(probe_areas),1,'last')]),find(~isnan(probe_areas)));
probe_area_centers_idx = round(probe_area_boundaries(1:end-1) + diff(probe_area_boundaries)/2);
probe_area_centers = probe_coords_depth(probe_area_centers_idx);
probe_area_labels = gui_data.st.safe_name(probe_areas(probe_area_centers_idx));

% Get coordinate from bregma and probe-axis depth from surface
% (round to nearest 10 microns)
probe_bregma_coordinate = trajectory_brain_intersect;
probe_depth = norm(trajectory_brain_intersect - probe_vector(:,2));

% Update the text
% (manipulator angles)
probe_angle_text = sprintf('Probe angle:     % .0f%c azimuth, % .0f%c elevation', ...
    gui_data.probe_angle(1),char(176),gui_data.probe_angle(2),char(176));
% (probe insertion point and depth)
probe_insertion_text = sprintf('Probe insertion: % .2f AP, % .2f ML, % .2f depth', ...
    probe_bregma_coordinate(2),probe_bregma_coordinate(1),probe_depth);
% (probe start/endpoints)
recording_startpoint_text = sprintf('Recording start: % .2f AP, % .2f ML, % .2f DV', ...
    probe_vector([2,1,3],1));
recording_endpoint_text = sprintf('Recording end:   % .2f AP, % .2f ML, % .2f DV', ...
    probe_vector([2,1,3],2));

% (combine and update)
probe_text = {probe_angle_text,probe_insertion_text, ...
    recording_startpoint_text,recording_endpoint_text};
set(gui_data.probe_coordinates_text,'String',probe_text);

% Update the probe areas
yyaxis(gui_data.handles.axes_probe_areas,'right');
set(gui_data.handles.probe_areas_plot,'YData',probe_coords_depth,'CData',probe_areas); 
set(gui_data.handles.axes_probe_areas,'YTick',probe_area_centers,'YTickLabels',probe_area_labels);

% Upload gui_data
guidata(probe_atlas_gui, gui_data);

end