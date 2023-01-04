function draw_areas(probe_atlas_gui,slice_spacing,plot_structure)

    % Get guidata
    gui_data = guidata(probe_atlas_gui);

    if ~isempty(plot_structure)
        
        % Get all areas within and below the selected hierarchy level
        plot_structure_id = gui_data.st.structure_id_path{plot_structure};
        plot_ccf_idx = find(cellfun(@(x) contains(x,plot_structure_id), ...
            gui_data.st.structure_id_path));
        
        % Plot the structure
        atlas_downsample = 5; % (downsample atlas to make this faster)
        
        [ap_grid_ccf,dv_grid_ccf,ml_grid_ccf] = ...
            ndgrid(1:atlas_downsample:size(gui_data.av,1), ...
            1:atlas_downsample:size(gui_data.av,2), ...
            1:atlas_downsample:size(gui_data.av,3));

        [ml_grid_bregma,ap_grid_bregma,dv_grid_bregma] = ...
            transformPointsForward(gui_data.ccf_bregma_tform, ...
            ml_grid_ccf,ap_grid_ccf,dv_grid_ccf);

        structure_3d = isosurface(ml_grid_bregma,ap_grid_bregma,dv_grid_bregma, ...
            ismember(gui_data.av(1:atlas_downsample:end, ...
            1:atlas_downsample:end,1:atlas_downsample:end),plot_ccf_idx),0);
        
        structure_alpha = 0.2;
        plot_structure_color = hex2dec(reshape(gui_data.st.color_hex_triplet{plot_structure},2,[])')./255;

        gui_data.structure_plot_idx(end+1) = plot_structure;
        gui_data.handles.structure_patch(end+1) = patch(gui_data.handles.axes_atlas, ...
            'Vertices',structure_3d.vertices, ...
            'Faces',structure_3d.faces, ...
            'FaceColor',plot_structure_color,'EdgeColor','none','FaceAlpha',structure_alpha);
        
    end

    % Upload gui_data
    guidata(probe_atlas_gui,gui_data);

end