function av = return_atlas
    allen_atlas_path = nte.return_atlas_path;

    % the number at each pixel labels the area, see note below
    av = readNPY(fullfile(allen_atlas_path,'annotation_volume_10um_by_index.npy')); 
