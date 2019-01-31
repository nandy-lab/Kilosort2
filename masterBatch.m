addpath(genpath('D:/GitHub/KiloSort2')) % path to kilosort folder
addpath('D:/GitHub\npy-matlab')

pathToYourConfigFile = 'D:/GitHub/KiloSort2/configFiles'; % take from Github folder and put it somewhere else (together with the master_file)
run(fullfile(pathToYourConfigFile, 'configFile384.m'))

chanMapList = {'neuropixPhase3A_kilosortChanMap', ...
    'neuropixPhase3B1_kilosortChanMap', 'neuropixPhase3B2_kilosortChanMap'};

fdir = {'Loewi\posterior', 'Loewi\frontal', 'WillAllen', ...
    'Waksman/ZO', 'Waksman/K1', 'Waksman/ZNP1', ...
    'Robbins/K1', 'Robbins/K3', 'Robbins/ZNP1', ...
    'Josh\probeA', 'Josh\probeF', 'Josh\probeD', 'Bekesy/ZO', 'Bekesy/K1'};
NTOT = [384 384 385 385 385 385 385 385 385 384 384 384 385 385];
iMap = [1 1 1 1 1 1 1 1 1 1 1 1 3 2];
%%
% common options for every probe

ops.sorting     = 2; % type of sorting, 2 is by rastermap, 1 is old
ops.trange      = [0 1900]; % TIME RANGE IN SECONDS TO PROCESS

% find the binary file in this folder
rootrootZ = 'F:/Spikes\';

% path to whitened, filtered proc file (on a fast SSD)
rootH = 'H:\DATA\Spikes\temp\';
ops.fproc       = fullfile(rootH, 'temp_wh.dat'); % proc file on a fast SSD


for j = 1 %1:numel(fdir)
    fprintf('%s\n', fdir{j})

    ops.chanMap = fullfile(pathToYourConfigFile, [chanMapList{iMap(j)} '.mat']);
    ops.NchanTOT    = NTOT(j); % total number of channels in your recording
    rootZ = fullfile(rootrootZ, fdir{j});

    fs          = [dir(fullfile(rootZ, '*.bin')) dir(fullfile(rootZ, '*.dat'))];
    fname       = fs(1).name;
    ops.fbinary = fullfile(rootZ,  fname);
    ops.rootZ   = rootZ;

    % preprocess data to create temp_wh.dat
    rez = preprocessDataSub(ops);

    % pre-clustering to re-order batches by depth
    fname = fullfile(rootZ, 'rez.mat');
    if exist(fname, 'file')
        % just load the file if we already did this
        dr = load(fname);
        rez.iorig = dr.rez.iorig;
        rez.ccb = dr.rez.ccb;
        rez.ccbsort = dr.rez.ccbsort;
    else
        rez = clusterSingleBatches(rez);
        save(fname, 'rez', '-v7.3');
    end

    % main optimization
    rez = learnAndSolve8b(rez);

    % final splits
    rez = splitAllClusters(rez);

    % this saves to Phy
    rezToPhy(rez, rootZ);

    % discard features in final rez file (too slow to save)
    rez.cProj = [];
    rez.cProjPC = [];

    % save final results as rez2
    fname = fullfile(rootZ, 'rez2.mat');
    save(fname, 'rez', '-v7.3');

%     loadManualSorting;
end
