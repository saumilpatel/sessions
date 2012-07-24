function import_steinbruch(sessionList)
% Parses a steinbruch import XML file to create a set of session entries
% 
% JC 2011-08-22
%
% Currently written for ephys onlly
% 
% Needs to access both recDb and EphysDj.

import ephys.*;
import sessions.*;

% get tree structure
xml = xmlread(sessionList);
root = xml.getElementsByTagName('root').item(0);
tree = buildTree(struct('meta',struct,'children',struct),root);
s = collapseTree(tree);
writeScript(s);

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
                ndx = strmatch(name,{instances.name});
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
else, s = init; end

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
function writeScript(s)
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
    subjDj = sessions.Subjects(sprintf('subject_name="%s"',subj.meta.subjectName));
    if count(subjDj) == 0
        subject_id = max(fetchn(Subjects,'subject_id')) + 1;
        insert(sessions.Subjects,struct('subject_name',s.meta.subjectName,'subject_id',subject_id));
    else
        subject_id = fetch1(subjDj, 'subject_id')
    end
    
    for j = 1:length(subj.Session)
        sess = subj.Session(j);
        beh = getfield(load(fullfile(getLocalPath(sess.meta.stimulationDir), ...
            'behInfo.mat')),'beh');
        if isempty(beh.processedFolder)
            continue;
        end
        acq = getfield(load(fullfile(getLocalPath(beh.processedFolder),'sessionInfo')),'acq');
        
        % Create the session structure to insert
        sessStruct = struct;
        sessStruct.setup = sess.meta.setup;
        idx = strfind(acq.folder,'/');
        session_date = acq.folder(idx(end)+1:end);
        sessStruct.session_start_time = matlabTimeToLabviewTime(datenum(session_date,'yyyy-mm-dd_HH-MM-SS'));
        sessStruct.subject_id = subject_id;
        sessKey = sessStruct;
        sessStruct.session_datetime = datestr(datenum(session_date,'yyyy-mm-dd_HH-MM-SS'),'yyyy-mm-dd HH:MM:SS');
        sessStruct.experimenter = 'James';
        sessStruct.session_path = acq.folder;
        sessStruct.hammer = 'TRUE';
        if count(sessions.Sessions(sessStruct)) ~= 0
            continue;
        end
        
        % Create the ephys structure to insert
        recInfo = acq.recSessions(beh.recIndex);
        ephysStruct = sessKey;
        ephysStruct.ephys_start_time = matlabTimeToLabviewTime(datenum(recInfo.startTime,'yyyy-mm-dd HH:MM:SS'));
        ephysKey = ephysStruct;
        ephysStruct.ephys_stop_time = matlabTimeToLabviewTime(datenum(recInfo.endTime,'yyyy-mm-dd HH:MM:SS'));
        if isfield(sess,'Tetrode')
            if length(sess.Tetrode) <= 3
                ephysStruct.ephys_task = 'TwoTetrodes';
            else
                error('Not sure what to use here');
                ephysStruct.task = 'Chronic Tetrode';
            end
        elseif isfield(sess,'Electrode')
            ephysStruct.ephys_task = 'UtahArray';
        else
            error 'Unable to determine session type.  No tetrodes or electrodes';
        end
        ephysStruct.ephys_path = [acq.folder '/' recInfo.folder];

        
        detectionSetParamStruct = ephysKey;
        detectionSetParamStruct.detection_method = 'Utah';
        detectionSetParamStructKey = detectionSetParamStruct;
        detectionSetParamStruct.ephys_processed_directory = beh.processedFolder;
        
        detectionSetStruct = detectionSetParamStructKey;
        detectionSetStructKey = detectionSetStruct;
        detectionSetStruct.detection_set_directory = [detectionSetParamStruct.ephys_processed_directory '/' recInfo.folder sess.meta.clusterSet];

        sessStruct.session_stop_time = ephysStruct.ephys_stop_time;
        inserti(sessions.Sessions, sessStruct);
        inserti(sessions.Ephys, ephysStruct);
        inserti(ephys.DetectionSetParam, detectionSetParamStruct);
        inserti(ephys.DetectionSet, detectionSetStruct)
        
        % Todo determine electrodes
        fileNames = dir(fullfile(getLocalPath(detectionSetStruct.detection_set_directory),'*.Htt'));
        for i = 1:length(fileNames)
            detectionElectrodeStruct = detectionSetStructKey;
            detectionElectrodeStruct.electrode_number = sscanf(fileNames(i).name,'Sc%u.Htt');
            detectionElectrodeStruct.detection_electrode_filename = getGlobalPath(fullfile(detectionSetStruct.detection_set_directory, fileNames(i).name));
            inserti(ephys.DetectionElectrode, detectionElectrodeStruct);
        end
        
        % Deal with newer file format
        fileNames = dir(fullfile(getLocalPath(detectionSetStruct.detection_set_directory),'*.Hsp'));
        for i = 1:length(fileNames)
            detectionElectrodeStruct = detectionSetStructKey;
            detectionElectrodeStruct.electrode_number = sscanf(fileNames(i).name,'Sc%u.Hsp');
            detectionElectrodeStruct.detection_electrode_filename = getGlobalPath(fullfile(detectionSetStruct.detection_set_directory, fileNames(i).name));
            inserti(ephys.DetectionElectrode, detectionElectrodeStruct);
        end
        
        clusterSetParamStruct = detectionSetStructKey;
        clusterSetParamStruct.clustering_method = 'MultiUnit';
        clusterSetParamStructKey = clusterSetParamStruct;
        inserti(ephys.ClusterSetParam,clusterSetParamStruct);
        
        % Create stimulation structure
        stimulationStruct = sessKey;
        stimulationStruct.stim_start_time = sessKey.session_start_time + round(beh.startTime);
        stimulationKey = stimulationStruct;
        stimulationStruct.stim_stop_time = sessKey.session_start_time + round(beh.endTime);
        stimulationStruct.stim_path = getGlobalPath(getLocalPath(beh.folder));
        
        % Get rid of variant
        stimulationStruct.stim_path = strrep(stimulationStruct.stim_path,'Synched','');
        stimulationStruct.stim_path = strrep(stimulationStruct.stim_path,'Synced','');
        
        stimulationStruct.exp_type = sess.meta.expType;
        stim = getfield(load(fullfile(getLocalPath(beh.folder), beh.file)),'stim');
        stimulationStruct.total_trials = length(stim.params.trials);
        stimulationStruct.correct_trials = sum([stim.params.trials.correctResponse]==1 & [stim.params.trials.validTrial]);
        stimulationStruct.incorrect_trials = sum([stim.params.trials.correctResponse]==0 & [stim.params.trials.validTrial]);
        inserti(sessions.Stimulation, stimulationStruct);
        
%         % TODO: Attach the monitor size/resolution to something in DB
%         if isfield(sess,'arrayLocation')
%             disp('Need to populate location information')
%             utahStruct = ephysKey;
%             utahStruct.array_location = sess.meta.arrayLocation;
%             % inserti(UtayInfo, utahStruct);
%         elseif isfield(sess,'Tetrode') && isfield(sess.Tetrode(1).meta, 'tetrodeNumber')
%             disp('Need to populate nonchronic meta information');
%             for k = 1:length(sess.Tetrode)
%                 nonchronicStruct = ephysKey;
%                 nonchronicStruct.tetrode_number = sess.Tetrode(k).meta.tetrodeNumber;
%                 nonchronicStruct.tetrode_location = sess.Tetrode(k).meta.gridLocation;
%                 nonchronicStruct.gri_number = sess.meta.gridNumber;
%                 nonchronicStruct.grid_orientation = sess.meta.gridOrientation;
%                 % inserti(NonchronicTetrodeInfo,nonchronicStruct);
%             end
%         end
        
        % Create clus set stim structure
        ephysStimLinkStruct = dj.utils.structJoin(ephysKey, stimulationKey);
        inserti(ephys.EphysStimLink, ephysStimLinkStruct);
    end
end
    