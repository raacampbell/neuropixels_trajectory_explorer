function [tv,av,st] = loadAtlas;
    allen_atlas_path = fileparts(which('template_volume_10um.npy'));
    if isempty(allen_atlas_path)
        error('CCF atlas not in MATLAB path (click ''Set path'', add folder with CCF)');
    end

    % Load CCF components
    fprintf('Loading atlas\n')
    tv = readNPY(fullfile(allen_atlas_path,'template_volume_10um.npy')); % grey-scale "background signal intensity"
    av = readNPY(fullfile(allen_atlas_path,'annotation_volume_10um_by_index.npy')); % the number at each pixel labels the area, see note below
    st = nte.load_structure_tree(fullfile(allen_atlas_path,'structure_tree_safe_2017.csv')); % a table of what all the labels mean