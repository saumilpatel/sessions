%{
acq.SessionsCleanup (computed) # cleanup before processing can be done

->acq.Sessions
---
%}

classdef SessionsCleanup < dj.Relvar & dj.AutoPopulate
    properties(Constant)
        table = dj.Table('acq.SessionsCleanup');
        popRel = acq.Sessions('subject_id > 0') - acq.SessionsIgnore;
    end
    
    methods
        function self = SessionsCleanup(varargin)
            self.restrict(varargin{:})
        end
        
        function makeTuples(self, key)
            if ~fetch1(acq.Sessions(key), 'hammer')
                cleanup(key);
            end
            insert(self, key);
        end
    end
end
