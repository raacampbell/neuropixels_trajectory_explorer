function draw_top_down_ccf(av, st)
    % Draw a top-down view of the Allen Atlas in coords from bregma
    %
    % function nte.utils.draw_top_down_ccf(av, st)
    %
    % Inputs [Optional]
    % av - the Allen atlas volume
    % st - the structure tree of the atlas
    %
    % The atlas (av) and the structure list (st) will be loaded if not supplied
    % Supplying them will speed up appearance of the figure. see:
    % nte.return_atlas and nte.return_structure_tree
    %
    % Example function calls
    % nte.utils.draw_top_down_ccf;
    %
    % av = nte.return_atlas;
    % nte.utils.draw_top_down_ccf(av)
    %


    if nargin < 1 || isempty(av)
        av = nte.return_atlas;
    end

    if nargin < 2 || isempty(st)
        st = nte.return_structure_tree;
    end


    % Get first brain pixel from top-down, get annotation at that point
    [~,top_down_depth] = max(av>1, [], 2);
    top_down_depth = squeeze(top_down_depth);

    [xx,yy] = meshgrid(1:size(top_down_depth,2), 1:size(top_down_depth,1));
    top_down_annotation = reshape(av(sub2ind(size(av),yy(:),top_down_depth(:),xx(:))), size(av,1), size(av,3));

    % Get all labelled areas
    used_areas = unique(top_down_annotation(:));

    % Restrict to only cortical areas
    structure_id_path = cellfun(@(x) textscan(x(2:end),'%d', 'delimiter',{'/'}),st.structure_id_path);

    ctx_path = [997,8,567,688,695,315];
    ctx_idx = find(cellfun(@(id) length(id) > length(ctx_path) & ...
        all(id(min(length(id),length(ctx_path))) == ctx_path(min(length(id),length(ctx_path)))),structure_id_path));

    plot_areas = intersect(used_areas,ctx_idx);

    % Get outlines and names of all areas
    dorsal_cortical_areas = ...
        struct('boundaries',cell(size(plot_areas)),'names',cell(size(plot_areas)));
    for curr_area_idx = 1:length(plot_areas)
        dorsal_cortical_areas(curr_area_idx).boundaries = ...
            bwboundaries(top_down_annotation == plot_areas(curr_area_idx));
        % (dorsal areas are all "layer 1" - remove that)
        dorsal_cortical_areas(curr_area_idx).names = ...
            regexprep(st.safe_name(plot_areas(curr_area_idx)),'..ayer 1','');
    end

    % Convert boundary units to stereotaxic coordinates in mm
    bregma = [540,44,570];
    boundaries_stereotax = cellfun(@(area) cellfun(@(outline) ...
        [bregma(1)-outline(:,1),outline(:,2)-bregma(3)]/100,area,'uni',false), ...
        {dorsal_cortical_areas.boundaries},'uni',false);
    [dorsal_cortical_areas.boundaries_stereotax] = boundaries_stereotax{:};


    %% Draw top-down cortical areas (in mm)

    brain_color = 'k';
    grid_color = [0.5,0.5,0.5];
    bregma_color = 'r';
    grid_spacing = 1; % in mm

    figure; 

    ax = axes; hold on; axis equal; grid on;
    ax.GridColor = grid_color;
    xticks(ax,-5:grid_spacing:5);
    yticks(ax,-5:grid_spacing:5);

    % Draw cortical boundaries
    cellfun(@(x) cellfun(@(x) plot(x(:,2),x(:,1),'color',brain_color),x,'uni',false), ...
        {dorsal_cortical_areas.boundaries_stereotax},'uni',false);

    % Write area labels (left hemisphere)
    cellfun(@(x,y) text('Position',fliplr(mean(x{1},1)),'String',y), ...
        {dorsal_cortical_areas.boundaries_stereotax}, ...
        {dorsal_cortical_areas.names});
    cellfun(@(x,y) plot(mean(x{1}(:,2)),mean(x{1}(:,1)),'.b'), ...
        {dorsal_cortical_areas.boundaries_stereotax});

    % Plot bregma
    plot(0,0,'.','color',bregma_color','MarkerSize',20);






