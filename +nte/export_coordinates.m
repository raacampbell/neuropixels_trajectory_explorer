function export_coordinates(h,eventdata,probe_atlas_gui)

% Get guidata
gui_data = guidata(probe_atlas_gui);

% Export the probe coordinates in Allen CCF to the workspace
probe_vector = cell2mat(get(gui_data.handles.probe_line,{'XData','YData','ZData'})');
probe_vector_ccf = round(probe_vector([1,3,2],:))';
assignin('base','probe_vector_ccf',probe_vector_ccf)
disp('Copied probe vector coordinates to workspace');
end

function probe_histology(h,eventdata,probe_atlas_gui)
% Load histology points
% UNDER CONSTRUCTION
% (used to use SHARP-Track, now using mine)

% Get guidata
gui_data = guidata(probe_atlas_gui);

[probe_file,probe_path] = uigetfile('*.mat','Choose probe coordinate file');
load([probe_path,probe_file]);

if exist('pointList','var')
    histology_points = pointList.pointList{1};
elseif exist('probe_ccf','var')
    histology_points = probe_ccf(1).points; % only use first probe
end

r0 = mean(histology_points,1);
xyz = bsxfun(@minus,histology_points,r0);
[~,~,V] = svd(xyz,0);
histology_probe_direction = V(:,1);

probe_eval_points = [-1000,1000];
probe_line_endpoints = bsxfun(@plus,bsxfun(@times,probe_eval_points',histology_probe_direction'),r0);

% Philip's GUI: not saved in native CCF order?
% plot3(histology_points(:,3),histology_points(:,1),histology_points(:,2),'.b','MarkerSize',20);
% line(P(:,3),P(:,1),P(:,2),'color','k','linewidth',2)

% % Mine: saved in native CCF order [AP,DV,ML]
plot3(gui_data.handles.axes_atlas, ...
    histology_points(:,1),histology_points(:,3),histology_points(:,2),'.b','MarkerSize',20);
line(gui_data.handles.axes_atlas, ...
    probe_line_endpoints(:,1),probe_line_endpoints(:,3),probe_line_endpoints(:,2),'color','k','linewidth',2)

% Place the probe on the histology best-fit axis
[ap_max,dv_max,ml_max] = size(gui_data.tv);

probe_ref_top = probe_line_endpoints(1,[1,3,2]);
probe_ref_bottom = probe_line_endpoints(2,[1,3,2]);
probe_ref_vector = [probe_ref_top;probe_ref_bottom]';

set(gui_data.handles.probe_ref_line,'XData',probe_ref_vector(1,:), ...
    'YData',probe_ref_vector(2,:), ...
    'ZData',probe_ref_vector(3,:));

probe_vector = [probe_ref_vector(:,1),diff(probe_ref_vector,[],2)./ ...
    norm(diff(probe_ref_vector,[],2))*gui_data.probe_length + probe_ref_vector(:,1)];
set(gui_data.handles.probe_line,'XData',probe_vector(1,:), ...
    'YData',probe_vector(2,:),'ZData',probe_vector(3,:));

% Upload gui_data
[theta,phi] = cart2sph(diff(probe_ref_vector(1,:)),diff(probe_ref_vector(2,:)),diff(probe_ref_vector(3,:)));
gui_data.probe_angle = ([theta,phi]/(2*pi))*360;
guidata(probe_atlas_gui, gui_data);

% Update the slice and probe coordinates
nte.update_slice(probe_atlas_gui);
nte.update_probe_coordinates(probe_atlas_gui);

end

