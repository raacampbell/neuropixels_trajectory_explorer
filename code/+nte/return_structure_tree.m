function st = return_structure_tree

    allen_atlas_path = nte.return_atlas_path;

    % a table of what all the labels mean
    st = nte.load_structure_tree(fullfile(allen_atlas_path,'structure_tree_safe_2017.csv'));
