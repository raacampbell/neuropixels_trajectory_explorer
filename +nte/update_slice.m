function update_slice(probe_atlas_gui,varargin)

    % Get guidata
    gui_data = guidata(probe_atlas_gui);

    % Only update the slice if it's visible
    if strcmp(gui_data.handles.slice_plot(1).Visible,'on')
        
        % Get current position of camera
        curr_campos = campos(gui_data.handles.axes_atlas);
        
        % Get probe vector
        probe_ref_top = [gui_data.handles.probe_ref_line.XData(1), ...
            gui_data.handles.probe_ref_line.YData(1),gui_data.handles.probe_ref_line.ZData(1)];
        probe_ref_bottom = [gui_data.handles.probe_ref_line.XData(2), ...
            gui_data.handles.probe_ref_line.YData(2),gui_data.handles.probe_ref_line.ZData(2)];
        probe_vector = probe_ref_top - probe_ref_bottom;
        
        % Get probe-camera vector
        probe_camera_vector = probe_ref_top - curr_campos;
        
        % Get the vector to plot the plane in (along with probe vector)
        plot_vector = cross(probe_camera_vector,probe_vector);
        
        % Get the normal vector of the plane
        normal_vector = cross(plot_vector,probe_vector);
        
        % Get the plane offset through the probe
        plane_offset = -(normal_vector*probe_ref_top');
        
        % Define a plane of points to index
        % (the plane grid is defined based on the which cardinal plan is most
        % orthogonal to the plotted plane. this is janky but it works)
        ml_lim = xlim(gui_data.handles.axes_atlas);
        ap_lim = ylim(gui_data.handles.axes_atlas);
        dv_lim = zlim(gui_data.handles.axes_atlas);

        slice_px_space = 0.01; % resolution of slice to grab
        [~,cam_plane] = max(abs(normal_vector./norm(normal_vector)));
        switch cam_plane
            case 1
                [plane_ap_bregma,plane_dv_bregma] = ndgrid(...
                    ap_lim(1):slice_px_space:ap_lim(2),...
                    dv_lim(1):slice_px_space:dv_lim(2));
                plane_ml_bregma = ...
                    (normal_vector(2)*plane_ap_bregma+normal_vector(3)*plane_dv_bregma + plane_offset)/ ...
                    -normal_vector(1);

            case 2
                [plane_ml_bregma,plane_dv_bregma] = ndgrid(...
                    ml_lim(1):slice_px_space:ml_lim(2),...
                    dv_lim(1):slice_px_space:dv_lim(2));
                plane_ap_bregma = ...
                    (normal_vector(3)*plane_dv_bregma+normal_vector(1)*plane_ml_bregma + plane_offset)/ ...
                    -normal_vector(2);    
                
            case 3
                [plane_ml_bregma,plane_ap_bregma] = ndgrid(...
                    ml_lim(1):slice_px_space:ml_lim(2),...
                    ap_lim(1):slice_px_space:ap_lim(2));
                plane_dv_bregma = ...
                    (normal_vector(2)*plane_ap_bregma+normal_vector(1)*plane_ml_bregma + plane_offset)/ ...
                    -normal_vector(3);       
        end

        % Transform bregma coordinates to CCF coordinates
        [plane_ml_ccf,plane_ap_ccf,plane_dv_ccf] = ...
            transformPointsInverse(gui_data.ccf_bregma_tform,plane_ml_bregma,plane_ap_bregma,plane_dv_bregma);

        % Grab pixels from (selected) volume
        plane_coords = ...
            round([plane_ap_ccf(:),plane_dv_ccf(:),plane_ml_ccf(:)]);
        plane_coords_inbounds = all(plane_coords > 0 & ...
            plane_coords <= size(gui_data.tv),2);

        plane_idx = sub2ind(size(gui_data.tv), ...
            plane_coords(plane_coords_inbounds,1), ...
            plane_coords(plane_coords_inbounds,2), ...
            plane_coords(plane_coords_inbounds,3));

        switch gui_data.handles.slice_volume
            case 'tv'
                curr_slice = nan(size(plane_ap_ccf));
                curr_slice(plane_coords_inbounds) = gui_data.tv(plane_idx);
                curr_slice(curr_slice < 20) = NaN; % threshold values

                colormap(gui_data.handles.axes_atlas,'gray');
                caxis(gui_data.handles.axes_atlas,[0,255]);
                
            case 'av'
                curr_slice = nan(size(plane_ap_ccf));
                curr_slice(plane_coords_inbounds) = gui_data.av(plane_idx);
                curr_slice(curr_slice <= 1) = NaN; % threshold values
            
                colormap(gui_data.handles.axes_atlas,gui_data.cmap);
                caxis(gui_data.handles.axes_atlas,[1,size(gui_data.cmap,1)]);
        end
       
        % Update the slice display
        set(gui_data.handles.slice_plot, ...
            'XData',plane_ml_bregma,'YData',plane_ap_bregma,'ZData',plane_dv_bregma,'CData',curr_slice);
        drawnow;

        % Upload gui_data
        guidata(probe_atlas_gui, gui_data);
        
    end

