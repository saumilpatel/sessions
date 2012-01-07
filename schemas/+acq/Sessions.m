%{
acq.Sessions (manual) # list of sessions

->acq.Subjects
setup                    : tinyint unsigned  # setup number
session_start_time       : bigint            # start session timestamp
---
session_stop_time = NULL : bigint            # end of session timestamp
experimenter \
    : enum('James','Alex','Mani','Allison','Tori','Jacob','Dimitri','Cathryn','Manolis') \
    # name of person running the exp
session_path             : varchar(255)      # path to the data
session_datetime = NULL  : datetime          # readable format of session start
%}

classdef Sessions < dj.Relvar
    properties(Constant)
        table = dj.Table('acq.Sessions');
    end
    
    methods
        function self = Sessions(varargin)
            self.restrict(varargin{:})
        end
        
        function offset = getTimeOffset(self)
            % Timezone offset (in ms) between session_start_time (in UTC)
            % and local time for session matching the tuple in relvar self.
            [utc, local] = fetch1(self, 'session_start_time', 'session_datetime');
            utc = datenum('01-Jan-1904') + double(utc) / 1000 / 60 / 60 / 24;
            local = datenum(local);
            offset = round((local - utc) * 24) * 60 * 60 * 1000;
        end
    end
end
