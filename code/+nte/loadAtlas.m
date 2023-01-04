function [tv,av,st] = loadAtlas
    allen_atlas_path = nte.return_atlas_path;


    % Load CCF components
    fprintf('Loading atlas\n')

    % grey-scale "background signal intensity"
    tv = readNPY(fullfile(allen_atlas_path,'template_volume_10um.npy')); 

    % the number at each pixel labels the area, see note below
    av = readNPY(fullfile(allen_atlas_path,'annotation_volume_10um_by_index.npy')); 

    % a table of what all the labels mean
    st = nte.load_structure_tree(fullfile(allen_atlas_path,'structure_tree_safe_2017.csv'));
