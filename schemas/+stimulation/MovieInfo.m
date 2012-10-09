%{
stimulation.MovieInfo (computed) # my newest table
->stimulation.StimTrialGroup
-----
natural_movies : int unsigned          # Number of natural movies shown
ps_movies      : int unsigned          # Number of phase scrambled movies shown
num_trials     : int unsigned          # Minimal number of presentations
movie_id       : longblob              # The unique id for this movie sequence
movie_types    : longblob              # The type of movie
movie_num      : longblob              # The number of the movie
movie_times    : longblob              # The times of the movies
movie_length   : int unsigned          # Stimulus length (ms)
%}

classdef MovieInfo < dj.Relvar & dj.Automatic

	properties(Constant)
		table = dj.Table('stimulation.MovieInfo')
        popRel = stimulation.StimTrialGroup & acq.Stimulation('exp_type="MoviesExperiment"');
	end

	methods
		function self = MovieInfo(varargin)
			self.restrict(varargin)
		end
	end

	methods(Access=protected)

		function makeTuples(self, key)
            
            tuple = key;
            stimInfo = fetch(stimulation.StimTrialGroup(key), '*');
            conditions = fetch(stimulation.StimConditions & key,'*');
            trials = fetch(stimulation.StimTrials * stimulation.StimTrialEvents ...
                & key & 'event_type="showStimulus"','*');
            
            tuple.movie_times = zeros(length(trials),1);
            tuple.movie_types = zeros(length(trials),1);
            tuple.movie_num  = zeros(length(trials),1);
            tuple.movie_id  = zeros(length(trials),1);
            
            tuple.movie_length = stimInfo.stim_constants.DelayPeriod;
            
            for i = 1:length(trials)
                tuple.movie_times(i) = trials(i).event_time;
                tuple.movie_id(i) = trials(i).trial_params.condition;
                tuple.movie_types(i) = conditions(tuple.movie_id(i)).condition_info.movieStat;
                tuple.movie_num(i) = conditions(tuple.movie_id(i)).condition_info.movieNumber;
            end
            
            tuple.natural_movies = length(unique(tuple.movie_num(tuple.movie_types==1)));
            tuple.ps_movies = length(unique(tuple.movie_num(tuple.movie_types==2)));

            n = hist(tuple.movie_id, unique(tuple.movie_id));
            tuple.num_trials = min(n);
            
            self.insert(tuple);
        end
    end
    
    methods    
        function G = makeDesignMatrix(self, times, basis_duration)
            assert(count(self) == 1, 'Only design for one relvar');
            
            if nargin < 3, basis_duration = 1000; end
            
            num_basis = fetch1(self, 'movie_length') / basis_duration;
            movie_ids = fetch1(self, 'movie_id');
            movie_times = fetch1(self, 'movie_times');
            
            G = zeros(length(times), num_basis * length(unique(movie_ids)));
            
            for i = 1:length(movie_times)
                for j = 1:num_basis
                    idx = times >= movie_times(i) + (j-1) * basis_duration & ...
                        times < movie_times(i) + j * basis_duration;
                    G(idx, j + (movie_ids(i) - 1) * num_basis) = 1;
                end
            end
        end
	end
end
