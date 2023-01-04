function set_vertical_probe(probe_atlas_gui, ap_mm, ml_mm, dv_mm)
    % Set a vertical probe position
    %
    % function set_vertical_probe(probe_atlas_gui,ap_mm,ml_mm,dv_mm)
    %
    % Inputs
    % ap_mm - AP position (mm from bregma)
    % ml_mm - ML position (mm from bregma)
    % dv_mm - DV_position (mm from bregma)


    nte.set_probe_entry([], [], probe_atlas_gui, [ap_mm, ml_mm, 0, 0])
    nte.set_probe_endpoint([], [], probe_atlas_gui, [ap_mm, ml_mm, dv_mm, 0, 90])
