function ccf_bregma_tform = return_CCF2Bregma_tform

% ~~~~ Make transform matrix from CCF to bregma/mm coordinates

% (translation values from our bregma estimate: AP/ML from Paxinos, DV from
% rough MRI estimate)
bregma_ccf = [540,44,570]; % [AP,DV,ML]
ccf_translation_tform = eye(4)+[zeros(3,4);-bregma_ccf([3,1,2]),0];

% (reflect AP/ML, scale DV value from Josh Siegle, convert 10um to 1mm)
scale = [-1,-1,0.9434]./100; % [AP,ML,DV]
ccf_scale_tform = eye(4).*[scale,1]';

% (rotation values from IBL estimate)
ap_rotation = 5; % 5 degrees nose-down
ccf_rotation_tform = ...
    [1 0 0 0; ...
    0 cosd(ap_rotation) -sind(ap_rotation) 0; ...
    0 sind(ap_rotation) cosd(ap_rotation) 0; ...
    0 0 0 1];

ccf_bregma_tform_matrix = ccf_translation_tform*ccf_rotation_tform*ccf_scale_tform;
ccf_bregma_tform = affine3d(ccf_bregma_tform_matrix);
