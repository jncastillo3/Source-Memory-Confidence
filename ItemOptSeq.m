%% load and format original and optX sequences
sequencesItemTest = [];

%load all of the sequences created for each run
for i = 1:7
    dnum = readtable(sprintf('ItemBlockSeqs/design%d.csv', i));
    sequencesItemTest = [sequencesItemTest; dnum];
end

%extract only condition and ISI from optimized sequences
optSeq = sequencesItemTest(:,[2 5]);

%rename conditions
conditions = {'s'; 'f'; 'l'};
optSeq.Condition = conditions(optSeq.Condition);
Cycle = [];
for i = 1:7
    c = repmat(i, 18, 1);
    Cycle = [Cycle; c];
end
optSeq = [optSeq, table(Cycle)];

%grab that subject's encodingList file
encodingList = load(sprintf('Subject Data/Subject%d_sess%d/Subject%d_Session%d_encodingList.mat', p.subNum, p.session, p.subNum, p.session));
encodingList = encodingList.encodingList;
    
%pull unique targets from encodingList
uniqueGrabBag = encodingList(ismember(encodingList.Block, 'passive'),:);
origTargetSeq = uniqueGrabBag(:,[3 6:10]);

%sort them all by face and scene
sortedAll = sortrows(origTargetSeq,6);
sortedFaces = sortedAll(ismember(sortedAll.Pair,'f'),:);
sortedScenes = sortedAll(ismember(sortedAll.Pair,'s'),:);

%now go into recogItemStimuli and pull out all of the lures we need
lureStim = recogItemstimuli(strcmp(recogItemstimuli.Studied, '0'),:);
a = cellfun('isempty',lureStim.Pair);
lureStim.Pair(a) = {'l'};
lureStim = lureStim(:, [3 6:10]);

newItemSeq = [];
for i = 1:length(unique(optSeq.Cycle))
    
    OrigtargetGrabs = origTargetSeq(origTargetSeq.Cycle == i,:); %isolate passive seq for block
    OrigGrabface = OrigtargetGrabs(ismember(OrigtargetGrabs.Pair,'f'),:); %separate faces and scenes
    OrigGrabscene = OrigtargetGrabs(ismember(OrigtargetGrabs.Pair,'s'),:);
    OrigGrabLure = lureStim(lureStim.Cycle == i,:); %isolates lures for that block
    
    for ii = 1:height(optSeq(ismember(optSeq.Cycle,i),:))
        if ismember(optSeq.Condition(ii), 'f')
            if height(OrigGrabface) == 1
                rowStim = OrigGrabface;
            else
                rowStim = datasample(OrigGrabface,1);
            end
        elseif ismember(optSeq.Condition(ii), 's')
            if height(OrigGrabscene) == 1
                rowStim = OrigGrabscene;
            else
                rowStim = datasample(OrigGrabscene,1);
            end
        elseif ismember(optSeq.Condition(ii), 'l')
            if height(OrigGrabLure) == 1
                rowStim = OrigGrabLure;
            else
                rowStim = datasample(OrigGrabLure,1);
            end
        end
        newItemSeq = [newItemSeq; rowStim];
        OrigGrabface = OrigGrabface(~ismember(OrigGrabface.Word, newItemSeq.Word),:); %removes words already sampled
        OrigGrabscene = OrigGrabscene(~ismember(OrigGrabscene.Word, newItemSeq.Word),:);
        OrigGrabLure = OrigGrabLure(~ismember(OrigGrabLure.Word, newItemSeq.Word),:);
    end
end


%% replace Word, pair, and studied cols with new sequence
recogItemstimuli.Word = newItemSeq.Word;
recogItemstimuli.SUBTLWF = newItemSeq.SUBTLWF;
recogItemstimuli.NumLet = newItemSeq.NumLet;
recogItemstimuli.Pair = newItemSeq.Pair;
recogItemstimuli.Studied = newItemSeq.Studied;
recogItemstimuli.ISI = optSeq.ISI;
