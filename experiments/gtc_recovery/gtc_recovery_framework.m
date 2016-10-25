function gtc_recovery_ALGORITHM(varargin )
% gtc_recovery_ALGORITHM( varargin )
%
% Before calling this, be sure to add paths to the algorithm(s)
% that this script calls.
%
% VARARGIN INPUTS:
%   'fname'         - name of file; default set to 'senate'
%   'fsuffix'       - suffix for filename; default set to ''
%   'load_dir'      - directory of fname  (default '../../data')
%   'save_dir'      - directory to save results in (default './results')
%
%   'seed_aug'      - Augment the initial seed set with 2 new seeds; default=false;
%   'subgraph'      - Extract initial subgraph? default=false
%
ALGORITHM_NAME = 'ALGORITHM'; % FILL IN YOUR ALG NAME HERE

%%
% PARAMETERS
%%
p = inputParser;
p.addOptional('fname', 'senate') ;
p.addOptional('load_dir', '../../data/') ;
p.addOptional('save_dir', './results/') ;
p.addOptional('fsuffix', '') ;
p.addOptional('seed_aug', false, @islogical) ;
p.addOptional('subgraph', false, @islogical) ;
p.parse(varargin{:});

fname = p.Results.fname;
load_dir = p.Results.load_dir;
save_dir = p.Results.save_dir;
fsuffix = p.Results.fsuffix;
seed_aug_flag = p.Results.seed_aug;
subgraph_flag = p.Results.subgraph;

name_tag = '';
if subgraph_flag == true, name_tag = '-subg'; end
if seed_aug_flag == true, name_tag = [name_tag, '-aug']; end

% LOAD GROUND TRUTH INFORMATION
load( [load_dir, fname, fsuffix, '.mat'] );
load( ['./gtc_rand_data/', fname, '-rand-comms.mat' ]);
C = C(:, C_rand_inds);

addpath ../../baseline_codes/;
addpath ../../;
addpath ../../util;

% Load GT community info
% INITIALIZE
comm_sizes = full(sum(C,1));
NUM_COMMS = size(C,2);

clus_stats.precisions = cell( NUM_COMMS, 1 );
clus_stats.recalls = cell( NUM_COMMS, 1 );
clus_stats.F1s = cell( NUM_COMMS, 1 );
clus_stats.jaccards = cell( NUM_COMMS, 1 );
clus_stats.conductances= cell( NUM_COMMS, 1 );
clus_stats.sizes = cell( NUM_COMMS, 1 );
clus_stats.runtimes = cell( NUM_COMMS, 1 );

fprintf('\n%s data loaded, beginning trials\n', fname);

for which_comm=1:NUM_COMMS,

    fprintf('\nStarting community %d out of %d\n', which_comm, NUM_COMMS);
    % Get COMM info
    comm_inds = find( C(:,which_comm) );
    comm_size = length( comm_inds );

    % Get Seeds
    %seeds_to_use = community_stats.seeds_used{which_comm};
    seeds_to_use = comm_inds; % for each node, run algorithm with that node as seed set

    this_precision = zeros( length(seeds_to_use),1);
    this_recall = zeros( length(seeds_to_use),1);
    this_F1 = zeros( length(seeds_to_use),1);
    this_size = zeros( length(seeds_to_use),1);
    this_runtime = zeros( length(seeds_to_use),1);
    this_cond = zeros( length(seeds_to_use),1);
    this_jaccard = zeros( length(seeds_to_use),1);

    % COMPUTE ON EACH SEED
    for which_seed=1:length(seeds_to_use),
        fprintf('\tseed %d out of %d ', which_seed,length(seeds_to_use));
        seed = seeds_to_use(which_seed);

        tic;
        if subgraph_flag == true,
          init_subg = subgraph_extraction(A, seed, 'ppr_auto_tune', true);
          A_sub = A(init_subg,init_subg);
          seed = find( init_subg == seed );
          if seed_aug_flag == true,
            new_seeds = seed_augment(A_sub, seed, 'num_new_seeds', 2, 'subgraph_size', 0);
            seed = union(seed, new_seeds);
          end
          % CALL ALGORITHM HERE
          % [ cluster_output ] = ALGORITHM(A_sub, seed);
          temp_clus

          cluster_output = init_subg(temp_clus);
        else % no subgraph
          if seed_aug_flag == true,
            new_seeds = seed_augment(A, seed, 'num_new_seeds', 2, 'subgraph_size', 0);
            seed = union(seed, new_seeds);
          end
          % CALL ALGORITHM HERE
          % [ cluster_output ] = ALGORITHM(A, seed);

        end


        timet = toc; fprintf(' time = %f \n',timet );
        this_runtime(which_seed) = timet;

        % record stats
        [F1, precision, recall, Jaccard_Index] = acc_stats( comm_inds, cluster_output );
        [cond] = cut_cond(A, cluster_output);

        this_precision(which_seed) = precision;
        this_recall(which_seed) = recall;
        this_F1(which_seed) = F1;
        this_size(which_seed) = length(cluster_output);
        this_cond(which_seed) = cond;
        this_jaccard(which_seed) = Jaccard_Index;
    end

    % We can easily obtain "mean, median, best" after experiments are done.
    clus_stats.precisions{which_comm} = this_precision;
    clus_stats.recalls{which_comm} = this_recall;
    clus_stats.F1s{which_comm} = this_F1;
    clus_stats.jaccards{which_comm} = this_jaccard;
    clus_stats.sizes{which_comm} = this_size;
    clus_stats.runtimes{which_comm} = this_runtime;
    clus_stats.conductances{which_comm} = this_cond;
end
fprintf('\nDone with %s \n\n ', fname );
save( [ save_dir, fname, '-', ALGORITHM_NAME, name_tag, '-gtc-recovery.mat'], 'clus_stats','-v7.3');
end % END OUTER FUNCTION