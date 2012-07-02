%{
aod.TuningCurve (imported) # A scan site

->aod.TracePreprocessed
->stimulation.MultiDimInfo
---
r2                    : double   # The unfiltered trace
preferred_orientation : double   # The preferred orientation
significance          : double   # Significance by ANOVA
ori                   : longblob # Orientations
mean_resp             : longblob # Mean response
ind_responses         : longblob # Individual responses
%}

classdef TuningCurve < dj.Relvar & dj.AutoPopulate
    properties(Constant)
        table = dj.Table('aod.TuningCurve');
        %popRel = pro(aod.TracePreprocessed) * pro(acq.AodStimulationLink) * pro(stimulation.MultiDimInfo);
        popRel = aod.TracePreprocessed * acq.AodStimulationLink * stimulation.MultiDimInfo;
    end

    methods 
        function self = TuningCurve(varargin)
            self.restrict(varargin{:})
        end
    
        function makeTuples( this, key )
            % Import a spike set
            
            tuple = key;
            
            trace = fetch(aod.TracePreprocessed & key, '*');
                       
            event = fetch(stimulation.StimTrialEvents(key, 'event_type="showSubStimulus"'),'*');
            trials = fetch(stimulation.StimTrials(key),'*');
            conditions = fetch(stimulation.StimConditions(key),'*');

            assert(length(event) == length(trials), 'Code not written for multiple presentations');

            ori = arrayfun(@(x) conditions(x.trial_params.conditions).condition_info.orientation, trials);
            times = [event.event_time];
            on_times = fetch(stimulation.StimTrialEvents(key, 'event_type="showStimulus"'),'*');
            on_times = [on_times.event_time];
            off_times = fetch(stimulation.StimTrialEvents(key, 'event_type="endStimulus"'),'*');
            off_times = [off_times.event_time];
            
            st = mean(off_times - on_times);
            
            idx = times > (trace.t0 + 1000 * length(trace.trace) / trace.fs - 8000);
            times(idx) = [];
            ori(idx) = [];
            
            idx = on_times > (trace.t0 + 1000 * length(trace.trace) / trace.fs - 8000);
            on_times(idx) = [];
            
            pre = round(4 * trace.fs);
            post = round(4 * trace.fs);

            on_resp = zeros(pre+post+1,1);
            
            offset = round(0 * trace.fs);
            len = round(2 * trace.fs);
            pre_len = round(1 * trace.fs);
            
            for i = 1:length(times)
                idx = round((times(i) - trace.t0) / 1000 * trace.fs);
                if idx > length(trace.trace)
                    disp('Experiment stopped prematurely');
                    break;
                end
                sample(i) = idx;
                resp(i) = mean(trace.trace(offset + (sample(i):sample(i)+len)));
                pre_resp(i) = mean(trace.trace(sample(i) + (-pre_len:-1)));
            end
            
            oris = sort(unique(ori(1:length(resp))));
            ori(length(resp)+1:end) = [];
            for j = 1:length(oris)
                mr(j) = mean(resp(ori == oris(j)) - pre_resp(ori == oris(j)));
                
                ori_samples = round((on_times(ori == oris(j)) - trace.t0) / 1000 * trace.fs);
                ori_samples = bsxfun(@plus,ori_samples,(-pre:post)');
                ori_responses = trace.trace(ori_samples);
                ori_resp(:,j) = mean(ori_responses,2);
                ind_responses{j} = bsxfun(@minus,ori_responses,ori_responses(pre,:));
            end
            
            for i = 1:length(on_times)
                idx = round((on_times(i) - trace.t0) / 1000 * trace.fs);
                if (idx + post) > length(trace.trace)
                    disp('Experiment stopped prematurely');
                    break;
                end
                
                on_resp(:,i) = trace.trace(idx + (-pre:post));
            end
            on_resp = mean(on_resp,2);
            
            [~,idx] = max(mr);
            [p table stats] = anova1(resp,ori(1:length(sample)),'off');
            
            tuple.significance = p;
            tuple.r2 = table{2,2} / table{4,2};
            tuple.preferred_orientation = oris(idx);
            tuple.ori = oris;
            tuple.mean_resp = mr;
            tuple.ind_responses(:,1) = ori(1:length(sample));
            tuple.ind_responses(:,2) = resp;
            insert(aod.TuningCurve, tuple);
        end
        
        function plot( this )
            tc = fetch(this, '*');
            plot(tc.ori,tc.mean_resp,tc.ind_responses(:,1),tc.ind_responses(:,2),'k.')
        end
        
%             figure(1);
%             subplot(321);
%             plot((-pre:post) / trace.fs,on_resp);
%             subplot(323);
%             plot(ori(1:length(sample)), resp,'.',oris,mr);
%             %ylim([-0.05 0.4])
%             subplot(325);
%             plot(times,ones(size(times)),'.',trace.t0 + (0:length(trace.trace)-1) *1000 / trace.fs,trace.trace)
%             
%             subplot(3,2,[2 4 6]);
%             plot((-pre:post) / trace.fs,bsxfun(@plus,ori_resp*4,1:size(ori_resp,2)),[0 0],[0 17],'k',[st st]/1000,[0 17],'k')
%             xlim([-pre post] / trace.fs);
%             
%             figure(2)
%             if exist('h','var')
%                 linkaxes(h,'off');
%             end
%             for i = 1:size(ori_resp,2), h(i) = subplot(4,ceil(size(ori_resp,2) / 4),i); plot((-pre:post) / trace.fs,ind_responses{i}); end
%             linkaxes(h,'xy'); xlim([0 4]);
%             
    end
end
