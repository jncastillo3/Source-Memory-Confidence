%% load and format original and optX sequences
sequencesEncode = [];

%load all of the sequences created for each run
for i = 1:14
    dnum = readtable(sprintf('encodeBlockSeqs/design%d.csv', i));
    sequencesEncode = [sequencesEncode; dnum];
end

%extract only the condition and ISI length from encodingData
grabBag = sequencesEncode(:,[2 5]);

%rename conditions
conditions = {'s'; 'f'};
grabBag.Condition = conditions(grabBag.Condition);

%add block number for indexing 
studyBlocks = [];
for i = 1:14
    block = repmat(i,12,1);
    studyBlocks = [studyBlocks; block];
end
grabBag = [grabBag, table(studyBlocks)];

%% Passive encoding sequencing
%isolate blocks that are only for passive encoding from  OPTX sequence
grabBagPassive = grabBag(ismember(grabBag.studyBlocks,[1,3,5,7,9,11,13]),:);

%pull out columns from encodingList and separate by passive
origSeq = encodingList(:,6:10);
origSeq = [origSeq, table(studyBlocks)];
origSeqPassive = origSeq(ismember(origSeq.studyBlocks,[1,3,5,7,9,11,13]),:);

%sort encodingList pairs by face and scene 
sortedAll = sortrows(origSeqPassive,5);
sortedFaces = sortedAll(ismember(sortedAll.Pair,'f'),:);
sortedScenes = sortedAll(ismember(sortedAll.Pair,'s'),:);

%loop to create new sequence
newPassiveSeq = [];
for i = 1:height(grabBagPassive)
    if ismember(grabBagPassive.Condition(i), 'f') %if the condition in the optSeq is face
        if height(sortedFaces) == 1 %was crashing when there was one word left so this fixes that 
            rowStim = sortedFaces;
        else
            rowStim = datasample(sortedFaces,1);
        end
    elseif ismember(grabBagPassive.Condition(i), 's')
        if height(sortedScenes) == 1
            rowStim = sortedScenes;
        else
            rowStim = datasample(sortedScenes,1);
        end
    end
    newPassiveSeq = [newPassiveSeq; rowStim];
    sortedFaces = sortedFaces(~ismember(sortedFaces.Word, newPassiveSeq.Word),:); %removes words already sampled
    sortedScenes = sortedScenes(~ismember(sortedScenes.Word, newPassiveSeq.Word),:);
end

%% Recall encoding sequencing 
%relabel the passive blocks for indexing in recall again 
studyBlocks = [];
for i = 1:7
    block = repmat(i,12,1);
    studyBlocks = [studyBlocks; block];
end
newPassiveSeq.studyBlocks = studyBlocks;

%isolate recall blocks from optX
rblocks = [2,4,6,8,10,12,14];
grabBagRecall = grabBag(ismember(grabBag.studyBlocks, rblocks),:);
grabBagRecall.studyBlocks = studyBlocks;

%create new sequence
newRecallSeq = [];
for i = 1:length(unique(grabBagRecall.studyBlocks))
    
        passiveGrabs = newPassiveSeq(newPassiveSeq.studyBlocks == i,:); %isolate passive seq for block
        pgrabface = passiveGrabs(ismember(passiveGrabs.Pair,'f'),:); %separate faces and scenes
        pgrabscene = passiveGrabs(ismember(passiveGrabs.Pair,'s'),:);
        
    for ii = 1:height(grabBagRecall(ismember(grabBagRecall.studyBlocks,i),:))
        
        if ismember(grabBagRecall.Condition(ii), 'f')
            if height(pgrabface) == 1
                rowStim = pgrabface;
            else
                rowStim = datasample(pgrabface,1);
            end
        elseif ismember(grabBagRecall.Condition(ii), 's')
            if height(pgrabscene) == 1
                rowStim = pgrabscene;
            else
                rowStim = datasample(pgrabscene,1);
            end
        end
    newRecallSeq = [newRecallSeq; rowStim];
    pgrabface = pgrabface(~ismember(pgrabface.Word, newRecallSeq.Word),:); %removes words already sampled
    pgrabscene = pgrabscene(~ismember(pgrabscene.Word, newRecallSeq.Word),:);
    end
end
 
%% concatenate passive and recall sequences 
newStudySeq = [];

for i = 1:7
    newPassiveBlock = newPassiveSeq(newPassiveSeq.studyBlocks == i,:);
    newRecallBlock = newRecallSeq(newRecallSeq.studyBlocks == i,:);
    newStudySeq = [newStudySeq; newPassiveBlock; newRecallBlock];
end

%% replace Word and pair cols with new sequence
encodingList.Word = newStudySeq.Word;
encodingList.Pair = newStudySeq.Pair;
encodingList.SUBTLWF = newStudySeq.SUBTLWF;
encodingList.NumLet = newStudySeq.NumLet;
encodingList.Studied = newStudySeq.Studied;
encodingList.ISI = grabBag.ISI;

%finito!