function export_coordinates(h,eventdata,probe_atlas_gui)

    % Get guidata
    gui_data = guidata(probe_atlas_gui);

    % Export the probe coordinates in Allen CCF to the workspace
    probe_vector = cell2mat(get(gui_data.handles.probe_line,{'XData','YData','ZData'})');
    probe_vector_ccf = round(probe_vector([1,3,2],:))';
    assignin('base','probe_vector_ccf',probe_vector_ccf)
    disp('Copied probe vector coordinates to workspace');
end
