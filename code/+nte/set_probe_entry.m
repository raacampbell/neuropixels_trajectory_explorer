function set_probe_entry(~, ~, probe_atlas_gui, new_probe_position)
    % Sets the probe entry point
    %
    % If new_probe_position is not supplied, a UI pops up.
    % If it is supplied, it should be a vector of length four in the order
    % requested by the GUI: AP mm from bregma, ML pos from bregma, Az angle, El angle (see below)
    % This input arg allows for debugging or dev of new features. 
    %
    % e.g.
    % pa_gui = neuropixels_trajectory_explorer;
    % nte.set_probe_entry([],[],pa_gui,[2,2,0,0])

    % Get guidata
    gui_data = guidata(probe_atlas_gui);

    if nargin < 4
        % Prompt for angles
        prompt_text = { ...
            'AP position (mm from bregma)', ...
            'ML position (mm from bregma)', ...
            'Azimuth angle (relative to lambda -> bregma)', ....
            'Elevation angle (relative to horizontal)'};

        new_probe_position_input = inputdlg(prompt_text,'Set probe position',1);
        if any(cellfun(@isempty,new_probe_position_input))
           error('Not all coordinates entered'); 
        end
        new_probe_position = cellfun(@str2num,new_probe_position_input);
    else
        new_probe_position = new_probe_position(:);
    end

    % Convert degrees to radians
    probe_angle_rad = (new_probe_position(3:4)/360)*2*pi;

    % Update the probe and trajectory reference
    ml_lim = xlim(gui_data.handles.axes_atlas);
    ap_lim = ylim(gui_data.handles.axes_atlas);
    dv_lim = zlim(gui_data.handles.axes_atlas);
    max_ref_length = norm([range(ap_lim);range(dv_lim);range(ml_lim)]);
    [y,x,z] = sph2cart(pi+probe_angle_rad(1),pi-probe_angle_rad(2),max_ref_length);

    % Get top of probe reference with user brain intersection point
    % (get DV location of brain surface at chosen ML/AP point)
    dv_query_bregma = interp1([0,1], ...
        [new_probe_position([2,1])',-1; ...
        new_probe_position([2,1])',6],linspace(0,1,100));

    [ml_query_ccf,ap_query_ccf,dv_query_ccf] = ...
        transformPointsInverse(gui_data.ccf_bregma_tform, ...
        dv_query_bregma(:,1),dv_query_bregma(:,2),dv_query_bregma(:,3));

    atlas_downsample = 5;
    dv_ccf_line = interpn( ...
        imresize3(gui_data.av,1/atlas_downsample,'nearest'), ...
        ap_query_ccf/atlas_downsample, ...
        dv_query_ccf/atlas_downsample, ...
        ml_query_ccf/atlas_downsample,'nearest');
    dv_brain_intersect_idx = find(dv_ccf_line > 1,1);

    probe_brain_dv = dv_query_bregma(dv_brain_intersect_idx,3);

    % (back up to 0 DV in CCF space)
    probe_ref_top_ap = interp1(probe_brain_dv+[0,z],new_probe_position(1)+[0,y],0,'linear','extrap');
    probe_ref_top_ml = interp1(probe_brain_dv+[0,z],new_probe_position(2)+[0,x],0,'linear','extrap');

    % Set new probe position
    probe_ref_top = [probe_ref_top_ml,probe_ref_top_ap,0];
    probe_ref_bottom = probe_ref_top + [x,y,z];
    probe_ref_vector = [probe_ref_top;probe_ref_bottom]';

    set(gui_data.handles.probe_ref_line,'XData',probe_ref_vector(1,:), ...
        'YData',probe_ref_vector(2,:), ...
        'ZData',probe_ref_vector(3,:));

    probe_vector = [probe_ref_vector(:,1),diff(probe_ref_vector,[],2)./ ...
        norm(diff(probe_ref_vector,[],2))*gui_data.probe_length + probe_ref_vector(:,1)];
    set(gui_data.handles.probe_line,'XData',probe_vector(1,:), ...
        'YData',probe_vector(2,:),'ZData',probe_vector(3,:));

    % Upload gui_data
    gui_data.probe_angle = (probe_angle_rad/(2*pi))*360;
    guidata(probe_atlas_gui, gui_data);

    % Update the slice and probe coordinates
    nte.update_slice(probe_atlas_gui);
    nte.update_probe_coordinates(probe_atlas_gui);

end