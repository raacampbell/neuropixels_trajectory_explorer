function ccf_cmap = ccfmap

    % (copied from cortex-lab/allenCCF/setup_utils
    % too many adjacent areas have colors that are too similar

    allen_atlas_path = fileparts(which('template_volume_10um.npy'));
    if isempty(allen_atlas_path)
        error('CCF atlas not in MATLAB path (click ''Set path'', add folder with CCF)');
    end

    st = nte.load_structure_tree(fullfile(allen_atlas_path,'structure_tree_safe_2017.csv')); % a table of what all the labels mean

    % Create CCF colormap
    % (copied from cortex-lab/allenCCF/setup_utils
    ccf_color_hex = st.color_hex_triplet;
    ccf_color_hex(cellfun(@numel,ccf_color_hex)==5) = {'019399'}; % special case where leading zero was evidently dropped
    ccf_cmap_c1 = cellfun(@(x)hex2dec(x(1:2)), ccf_color_hex, 'uni', false);
    ccf_cmap_c2 = cellfun(@(x)hex2dec(x(3:4)), ccf_color_hex, 'uni', false);
    ccf_cmap_c3 = cellfun(@(x)hex2dec(x(5:6)), ccf_color_hex, 'uni', false);
    ccf_cmap = horzcat(vertcat(ccf_cmap_c1{:}),vertcat(ccf_cmap_c2{:}),vertcat(ccf_cmap_c3{:}))./255;

