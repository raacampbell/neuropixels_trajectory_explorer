function set_probe_endpoint(h,eventdata,probe_atlas_gui)

% Get guidata
gui_data = guidata(probe_atlas_gui);

% Prompt for angles
prompt_text = { ...
    'AP position (mm from bregma)', ...
    'ML position (mm from bregma)', ...
    'DV position (mm from bregma)', ...
    'Azimuth angle (relative to lambda -> bregma)', ....
    'Elevation angle (relative to horizontal)'};

new_probe_position_input = inputdlg(prompt_text,'Set probe position',1);
if any(cellfun(@isempty,new_probe_position_input))
   error('Not all coordinates entered'); 
end
new_probe_position = cellfun(@str2num,new_probe_position_input);

% Convert degrees to radians
probe_angle_rad = (new_probe_position(4:5)/360)*2*pi;

% Update the probe and trajectory reference
ml_lim = xlim(gui_data.handles.axes_atlas);
ap_lim = ylim(gui_data.handles.axes_atlas);
dv_lim = zlim(gui_data.handles.axes_atlas);
max_ref_length = norm([range(ap_lim);range(dv_lim);range(ml_lim)]);
[y,x,z] = sph2cart(pi+probe_angle_rad(1),pi-probe_angle_rad(2),max_ref_length);

% Move probe reference (draw line through point and DV 0 with max length)
probe_ref_top_ap = interp1(new_probe_position(3)+[0,z],new_probe_position(1)+[0,y],0,'linear','extrap');
probe_ref_top_ml = interp1(new_probe_position(3)+[0,z],new_probe_position(2)+[0,x],0,'linear','extrap');

probe_ref_top = [probe_ref_top_ml,probe_ref_top_ap,0];
probe_ref_bottom = probe_ref_top + [x,y,z];
probe_ref_vector = [probe_ref_top;probe_ref_bottom]';

set(gui_data.handles.probe_ref_line,'XData',probe_ref_vector(1,:), ...
    'YData',probe_ref_vector(2,:), ...
    'ZData',probe_ref_vector(3,:));

% Move probe (lock endpoint, back up length of probe)
probe_vector = [diff(probe_ref_vector,[],2)./norm(diff(probe_ref_vector,[],2))* ...
    -gui_data.probe_length + new_probe_position([2,1,3]), ...
    new_probe_position([2,1,3])];
set(gui_data.handles.probe_line,'XData',probe_vector(1,:), ...
    'YData',probe_vector(2,:),'ZData',probe_vector(3,:));

% Upload gui_data
gui_data.probe_angle = (probe_angle_rad/(2*pi))*360;
guidata(probe_atlas_gui, gui_data);

% Update the slice and probe coordinates
nte.update_slice(probe_atlas_gui);
nte.update_probe_coordinates(probe_atlas_gui);

end
