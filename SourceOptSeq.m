%% source sequence
%take run data for all words that were used in the item block 
%THAT 1 WILL CHANGE
itemStimlastblock = recogItemstimuli(ismember(recogItemstimuli.Run, run-1),:);

% Find false alarms in LAST ITEM RECOG CYCLE'S DATA. Keep FA and targets
newWords = itemStimlastblock(strcmp(itemStimlastblock.Studied, '0'),:);
falseAlarms = newWords(strcmp(newWords.Correct,'0'),:); %new words judged old
sourceStimToTest = [itemStimlastblock(strcmp(itemStimlastblock.Studied, '1'),:); falseAlarms]; %targets and FA

%figure out how many false alarms there are 
chooseDesign = height(falseAlarms);

%Based on that length, choose the corresponding sequence 
design  = readtable(sprintf('SourceBlockSeqs/design%d.csv', chooseDesign));

%extract only condition and ISI from optimized sequences
optSeq = design(:,[2 5]);
conditions = {'s'; 'f'; 'l'};
optSeq.Condition = conditions(optSeq.Condition);

%remove anything that isnt a lure or target so that is matches the length
%of design
sourceStimToRemove = find(~ismember(itemStimlastblock.Word, sourceStimToTest.Word));
WordsToRemove = string(itemStimlastblock.Word(sourceStimToRemove,:));

for i = 1:length(WordsToRemove) %loops through and removes anything that isnt a target or FA
    deleteRow = strcmp(WordsToRemove(i),itemStimlastblock.Word);
    itemStimlastblock(deleteRow,:) = [];
end

%Pick out relevant columns
origSeq = itemStimlastblock(:,6:10);

%sort everything by face, scene and lure 
sortedFaces = origSeq(ismember(origSeq.Pair,'f'),:);
sortedScenes = origSeq(ismember(origSeq.Pair,'s'),:);
sortedLures = origSeq(ismember(origSeq.Pair,'l'),:);

%fill the stimuli seq based on design and stimuli from item conf block 
newSourceSeq = [];
for i = 1:height(optSeq)
    if ismember(optSeq.Condition(i), 'f') %if the condition in the optSeq is face
        if height(sortedFaces) == 1 %was crashing when there was one word left so this fixes that 
            rowStim = sortedFaces;
        else
            rowStim = datasample(sortedFaces,1);
        end
    elseif ismember(optSeq.Condition(i), 's')
        if height(sortedScenes) == 1
            rowStim = sortedScenes;
        else
            rowStim = datasample(sortedScenes,1);
        end
    elseif ismember(optSeq.Condition(i), 'l')
        if height(sortedLures) == 1
            rowStim = sortedLures;
        else
            rowStim = datasample(sortedLures,1);
        end
    end
    newSourceSeq = [newSourceSeq; rowStim];
    sortedFaces = sortedFaces(~ismember(sortedFaces.Word, newSourceSeq.Word),:); %removes words already sampled
    sortedScenes = sortedScenes(~ismember(sortedScenes.Word, newSourceSeq.Word),:);
    sortedLures = sortedLures(~ismember(sortedLures.Word, newSourceSeq.Word),:);
end

%% replace Word, pair, and studied cols with new sequence
recogSourcestimuli = itemStimlastblock;

recogSourcestimuli.Word = newSourceSeq.Word;
recogSourcestimuli.SUBTLWF = newSourceSeq.SUBTLWF;
recogSourcestimuli.NumLet = newSourceSeq.NumLet;
recogSourcestimuli.Pair = newSourceSeq.Pair;
recogSourcestimuli.Studied = newSourceSeq.Studied;
recogSourcestimuli.ISI = optSeq.ISI;
