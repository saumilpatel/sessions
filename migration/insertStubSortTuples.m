function insertStubSortTuples(detectKeys)
% Insert stub tuples for spikes sorting that has been done already
% AE 2012-09-18

tuples = fetch(detect.Sets(detectKeys), '*');
for tuple = tuples'
    
    key = rmfield(tuple, 'detect_set_path');
    key.sort_method_num = 2;
    
    inserti(sort.Params, key);
    populate(sort.Sets, key);
    update(sort.Sets(key), 'sort_set_path', strrep(tuple.detect_set_path, '/tetdata', '/klusters'));
    
    keys = fetch(sort.Electrodes(key));
    inserti(sort.TetrodesMoGAutomatic, keys);
    inserti(sort.TetrodesMoGManual, keys);
    
    % from TetrodesMoGFinalize
    inserti(sort.TetrodesMoGFinalize, keys);
    
    for key = keys'
        
        if count(sort.TetrodesMoGUnits(key))
            continue
        end
        
        sortPath = fetch1(sort.Sets(key), 'sort_set_path');
        resultFile = fullfile(getLocalPath(sortPath), sprintf('resultTT%d.mat', key.electrode_num));
        try
            job = getfield(load(resultFile, 'ourJob'), 'ourJob'); %#ok
        catch %#ok
            try
                job = getfield(load(resultFile, 'job'), 'job'); %#ok
            catch %#ok
                fprintf('File resultTT%d.mat not found or could not be read. Skipping this electrode.\n\n', key.electrode_num)
                del(sort.Electrodes(key))
                continue
            end
        end
        job.status = 2;
        
        % Compute posteriors
        modelFile = fullfile(getLocalPath(sortPath), sprintf('modelTT%d.mat', key.electrode_num));
        model = getfield(load(modelFile), 'model'); %#ok
        nUnits = numel(model.cluster);
        nSpikes = size(job.X, 1);
        p = zeros(nSpikes, nUnits);
        for i = 1:nUnits
            c = model.cluster(i);
            for j = 1:numel(c.prior);
                p(:,i) = p(:,i) + c.prior(j) * clus_mvn(job.X, c.mean(j,:), c.covMat(:,:,j));
            end
        end
        sp = sum(p, 2);
        p = bsxfun(@rdivide, p, sp);
        [~, assignment] = max(p, [], 2);
        
        % deal with outliers
        outliers = sp == 0;
        p(outliers, :) = 0;
        assignment(outliers) = 0;
        
        % insert single units into TetrodesMoGUnits
        spikeFile = getLocalPath(fetch1(detect.Electrodes(key), 'detect_electrode_file'));
        for i = 2:nUnits % 1 = MUA
            tup = key;
            tup.cluster_number = i - 1;
            tt = ah_readTetData(getLocalPath(spikeFile), 'index', find(assignment == i));
            waveform = cellfun(@(x) mean(x, 2), tt.w, 'UniformOutput', false);
            tup.mean_waveform = [waveform{:}];
            tup.snr = max(cellfun(@(x) (max(x) - min(x)) / mean(std(x)), waveform));
            tup.fp = mean(1 - p(assignment == i, i));
            tup.fn = sum(p(assignment ~= i, i)) / sum(assignment == i);
            insert(sort.TetrodesMoGUnits, tup);
        end
    end
    
end

