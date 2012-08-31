function import_steinbruch_mpi(sessionList, experimenter, ephysTask)
% Parses a steinbruch import XML file to create a set of session entries
% 
% JC 2011-08-22
% AE 2012-08-30
%
% Currently written for ephys onlly

if nargin < 3, ephysTask = ''; end

% get tree structure
xml = xmlread(sessionList);
root = xml.getElementsByTagName('root').item(0);
tree = buildTree(struct('meta',struct,'children',struct),root);
s = collapseTree(tree);
writeScript(s, experimenter, ephysTask);

% ---------------------------------------------------------------------------- %
function treeNode = buildTree(treeNode,xmlNode)

% read meta data and children
children = xmlNode.getChildNodes;
for i = 0:children.getLength-1
    node = children.item(i);
    % ignore text
    if node.getNodeType == node.ELEMENT_NODE
        switch char(node.getTagName)

            % meta data for current node
            case 'meta'
                name = char(node.getAttribute('name'));
                treeNode.meta.(name) = eval(strtrim(char(node.getFirstChild.getNodeValue)));

            % default values for all following nodes in same hierarchy
            case 'default'
                childClass = char(node.getAttribute('class'));
                if ~isfield(treeNode.children,childClass)
                    treeNode.children.(childClass).default = struct;
                    treeNode.children.(childClass).instantiation = [];
                    treeNode.children.(childClass).instances = ...
                        repmat(newStruct,0,0);
                end
                treeNode.children.(childClass).default = ...
                    buildTree(newStruct,node);

                % how do concrete elements get instantiated?
                inst = char(node.getAttribute('instantiation'));
                treeNode.children.(childClass).instantiation = inst;

            % instances
            case 'instance'
                childClass = char(node.getAttribute('class'));
                if ~isfield(treeNode.children,childClass)
                    treeNode.children.(childClass).default = struct;
                    treeNode.children.(childClass).instances = ...
                        repmat(newStruct,0,0);
                end
                
                % check if this overwrites a present instance
                name = char(node.getAttribute('name'));
                instances = treeNode.children.(childClass).instances;
                ndx = strmatch(name,{instances.name}); %#ok
                if isempty(ndx) || isempty(name)
                    default = treeNode.children.(childClass).default;
                    default.name = name;
                    % check if children are instantiated manually
                    if node.hasAttribute('manual')
                        manual = char(node.getAttribute('manual'));
                        ndx = [0, strfind(manual,' '), length(manual)];
                        for j = 1:length(ndx)-1
                            type = manual(ndx(j)+1:ndx(j+1));
                            default.children.(type).instances = repmat(newStruct,0,0);
                        end
                    end
                    treeNode.children.(childClass).instances(end+1) = ...
                        buildTree(default,node);
                else
                    treeNode.children.(childClass).instances(ndx) = ...
                        buildTree(instances(ndx),node);
                end
        end
    end
end

function s = mergeStruct(s,s1)
f = fieldnames(s1);
if isempty (f), return; end
for i = 1:length(f)
    s.(f{i}) = s1.(f{i});
end

function s = collapseTree(tree, init)

if nargin < 2, s = struct('meta',struct);
else s = init; end

s.meta=mergeStruct(s.meta,tree.meta);

f = fields(tree.children);
for i = 1:length(f)
    if strcmp(tree.children.(f{i}).instantiation,'manual') ~= 1
        % only creat manual elements
        continue;
    end
    obj.meta = tree.children.(f{i}).default.meta;
    children = fieldnames(tree.children.(f{i}).default.children);
    for j = 1:length(children)
        obj.(children{j}) = struct;
        s.(f{i}) = obj;
    end
    for j = 1:length(tree.children.(f{i}).instances)
        a = collapseTree(tree.children.(f{i}).instances(j),obj);
        s.(f{i})(j) = a;
    end
end
    
% ---------------------------------------------------------------------------- %
function s = newStruct(name,meta,children)
if nargin < 1 || isempty(name), name = '<none>'; end
if nargin < 2 || isempty(meta), meta = struct; end
if nargin < 3 || isempty(children), children = struct; end
s = struct('name',name,'meta',meta,'children',children);

% ---------------------------------------------------------------------------- %
function n = matlabTimeToLabviewTime(n)
% Convert from matlab time (days since 0000) to labview time (ms since Jan
% 01 1904)
d = n - datenum('01-Jan-1904');
n = round(d * 1000 * 60 * 60 * 24);

% ---------------------------------------------------------------------------- %
function writeScript(s, experimenter, ephysTask)
% Takes in a structure of sessions
%   Subject
%   Sesssion
%   Tetrode
% 
% Needs to convert to an EphysDJ layout
%           Session
% Stimulation     Ephys
%         ClusStimSet
%
% For each Subject, look up SubjectId in EphysDj.  Insert if does not exist
% For each Session
%   create a Session entry (modify this script for experimenter)
%   look up in recording in RecDb.  Create appropriate entry in Ephys
%   create appropriate Stimualtion entry
%   link them in ClusDb

% Connect in this order.  Ensure EphysDj user has access to RecDb

%r = recDb();
%EphysDj();

for i = 1:length(s.Subject)
    subj = s.Subject(i);
    subjDj = acq.Subjects(sprintf('subject_name="%s"',subj.meta.subjectName));
    if count(subjDj) == 0
        subject_id = max(fetchn(acq.Subjects,'subject_id')) + 1;
        insert(acq.Subjects,struct('subject_name',s.meta.subjectName,'subject_id',subject_id));
    else
        subject_id = fetch1(subjDj, 'subject_id') %#ok
    end
    
    for j = 1:length(subj.Session)
        sess = subj.Session(j);
        
        % generate fake stim file according to Tolias lab standards
        m = sess.meta;
        session_date = regexp(m.cheetahDir, '([0-9]+)-([0-9]+)-([0-9]+)_([0-9]+)-([0-9]+)-([0-9]+)', 'tokens');
        session_date = cellfun(@str2double, session_date{1}, 'UniformOutput', false);
        session_datetime = sprintf('%04d-%02d-%02d_%02d-%02d-%02d', session_date{:});
        stimFile = sprintf('/stor01/stimulation/%s/%s/%s.mat', m.subject, session_datetime, m.expType);
        if 1||~exist(getLocalPath(stimFile), 'file')
            stim = genStimFileMPI(m.qnxFile, m.cheetahDir, m.expType, m.chtEvtBegin, m.chtEvtEnd, getLocalPath(stimFile));
        else
            stim = getfield(load(getLocalPath(stimFile)), 'stim'); %#ok
        end
        
        % Create the session structure to insert
        sessStruct = struct;
        sessStruct.setup = 99;
        sessStruct.session_start_time = matlabTimeToLabviewTime(datenum(session_date{:}));
        sessStruct.subject_id = subject_id;
        sessKey = sessStruct;
        sessStruct.session_datetime = session_datetime;
        sessStruct.experimenter = experimenter;
        sessStruct.session_path = m.cheetahDir;
        sessStruct.recording_software = 'Neuralynx';
        sessStruct.hammer = 0;
        
        % Create the ephys structure to insert
        ephysStruct = sessKey;
        ephysStruct.ephys_start_time = sessStruct.session_start_time;
        ephysKey = ephysStruct;
        ephysStruct.ephys_task = ephysTask;
        ephysStruct.ephys_path = sessStruct.session_path;

        % detect.Params & Sets
        detectionSetParamStruct = ephysKey;
        detectionSetParamStruct.detect_method_num = fetch1(detect.Methods('detect_method_name="Tetrodes"'),'detect_method_num');
        detectionSetParamStructKey = detectionSetParamStruct;
        detectionSetParamStruct.ephys_processed_path = sessStruct.session_path;
        
        detectionSetStruct = detectionSetParamStructKey;
        detectionSetStructKey = detectionSetStruct;
        detectionSetStruct.detect_set_path = sessStruct.session_path;
        
        inserti(acq.Sessions, sessStruct);
        inserti(acq.Ephys, ephysStruct);
        inserti(detect.Params, detectionSetParamStruct);
        inserti(detect.Sets, detectionSetStruct)

        % determine electrodes & preamp gains
        for tet = sess.Tetrode
            detectionElectrodeStruct = detectionSetStructKey;
            detectionElectrodeStruct.electrode_num = tet.meta.tetrodeNumber;
            detectionElectrodeStruct.detect_electrode_file = sprintf('%sSc%d.Ntt', detectionSetStruct.detect_set_path, tet.meta.tetrodeNumber);
            inserti(detect.Electrodes, detectionElectrodeStruct);
            
            gainStruct = ephysKey;
            gainStruct.electrode_num = tet.meta.tetrodeNumber;
            gainStruct.preamp_gain = tet.meta.amplifierGain / 1000;
            inserti(acq.AmplifierGains, gainStruct);
        end
        
        % sort.Params & Sets
        methods = {'MultiUnit', 'MoKsm'};
        for iMethod = 1 : numel(methods)
            sortSetParamStruct = detectionSetParamStructKey;
            sortSetParamStruct.sort_method_num = fetch1(sort.Methods(struct('sort_method_name', methods{iMethod})), 'sort_method_num');
            
            sortSetStruct = sortSetParamStruct;
            sortSetStruct.sort_set_path = sprintf('/processed/%s/%s/%s/spikes/Tetrodes/%s', m.subject, session_datetime, session_datetime, methods{iMethod});
            
            inserti(sort.Params, sortSetParamStruct);
            inserti(sort.Sets, sortSetStruct);
            inserti(sort.Electrodes, fetch((sort.Sets * detect.Electrodes) & detectionSetStruct));
        end
        
        % Create stimulation structure
        stimulationStruct = sessKey;
        stimulationStruct.stim_start_time = sessStruct.session_start_time;
        stimulationKey = stimulationStruct;
        stimulationStruct.stim_path = fileparts(stimFile);
        
        stimulationStruct.exp_type = m.expType;
        stimulationStruct.total_trials = length(stim.params.trials);
        stimulationStruct.correct_trials = sum([stim.params.trials.correctResponse]==1 & [stim.params.trials.validTrial]);
        stimulationStruct.incorrect_trials = sum([stim.params.trials.correctResponse]==0 & [stim.params.trials.validTrial]);
        inserti(acq.Stimulation, stimulationStruct);
        
        % create fake stimulation sync
        stimSyncStruct = stimulationKey;
        stimSyncStruct.sync_network = 1;
        stimSyncStruct.sync_diode = 1;
        inserti(acq.StimulationSync, stimSyncStruct);
        inserti(acq.StimulationSyncDiode, dj.struct.join(stimulationKey, ephysKey));
        
        % Create clus set stim structure
        ephysStimLinkStruct = dj.struct.join(ephysKey, stimulationKey);
        inserti(acq.EphysStimulationLink, ephysStimLinkStruct);
    end
end
    
