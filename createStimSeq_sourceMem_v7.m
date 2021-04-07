%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%% createStimSequence function used in Source Memory fMRI project
%% July 2017 DMW: creates randomized stimulus order for encoding session 
% (containing repeated cycles of 4 blocks) and for recognition memory test 
% session (source memory is created during the experiment because it relies
% on false alarms from recognition test) for behavioral study
%% October 2017 DMW: FOR ALL SUBJECTS (to be indexed on computers downstairs)
%% November 2020 JC: changed directory, increased word pool, and removed cued recall
%% February 2020 DMS: cleaned up script, omitted encoding block A
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

%% Specific Variables %-DMS: cleaned up variables that were not used again (i.e., p.nBlocks = 4)
p.nPossibleSubjects = 30;
p.stimRoot = pwd;
p.nSampledWordsPerBlock = 12; %number of words sampled from the word pool during blocks %-DMW: I believe this 12, no need to split it into 6 words in 2 blocks because we've removed the strengthening condition
p.nSampledNovelWordsPerBlock = 6;
p.nCycles = 7; %number of times an encoding phase is repeated in one session. Decreased from 10 to 8
p.freqLow = 2; %lower frequency criteria for word selection(oringally 4, lowered to 2)
p.freqHigh = 6; %upper frequency criteria for word selection
p.nSampledWordsTotal = (p.nSampledWordsPerBlock*p.nCycles) + (p.nSampledNovelWordsPerBlock*p.nCycles); %total number of words sampled from the word pool within a session

%% Apply frequency criteria to word stimuli selection & determine # sessions
stimuliOG = readtable(fullfile(p.stimRoot, 'wordStimuli.xlsx')); %read in data file as table
stimuliOG = [stimuliOG(:,2) stimuliOG(:,8) stimuliOG(:,17)]; %select only variables of interest from large stimuli data file
stimuliOG = stimuliOG(~any(ismissing(stimuliOG),2),:); %get rid of extra blank rows in spreadsheet
stimuli = stimuliOG(stimuliOG.SUBTLWF >= p.freqLow & stimuliOG.SUBTLWF <= p.freqHigh, :); %filter stimuli for word frequency criteria (up to 1,291, from 412)
p.nPossibleSessions = floor(height(stimuli)/p.nSampledWordsTotal);

%% Create encoding lists across subjects, sessions, and cycles
allSubsEncoding = [];
allSubsRecog = [];
for sub = 1:p.nPossibleSubjects
    subStimuli = stimuli; %assign stimuli list to new variable, so can delete used words from list for each subjects    
    for sess = 1:p.nPossibleSessions
        for cy = 1:p.nCycles 
            %create encodingPassive list for each cycle
            sampledWordIndices = randperm(height(subStimuli), p.nSampledWordsPerBlock);
            sampledWords = subStimuli(sampledWordIndices,:);
            pairs = [repmat({'s'}, p.nSampledWordsPerBlock/2,1); repmat({'f'}, p.nSampledWordsPerBlock/2, 1)];
            sampledWordsextra = table(repmat(sub, height(sampledWords), 1), repmat(sess, height(sampledWords), 1), repmat(cy, height(sampledWords), 1), repmat({'passive'}, height(sampledWords), 1), (1:height(sampledWords))', repmat({'1'}, height(sampledWords),1),...
                pairs(randperm(size(pairs,1))), cell(height(sampledWords),1), cell(height(sampledWords),1), cell(height(sampledWords),1),...
                'VariableNames',{'Sub', 'Session', 'Cycle', 'Block', 'BlockTrial', 'Studied', 'Pair', 'Response', 'RT', 'Correct'}); %adding other variables of interest
            sampledWords = [sampledWordsextra(:,1:5) sampledWords sampledWordsextra(:,6:end)];
            encodingPassive = sampledWords;
            
            %create encodingSrcJdg list for each cycle
            encodingSrcJdg = sampledWords(randperm(height(sampledWords)),:);
            encodingSrcJdg.Block = repmat({'source'}, height(encodingSrcJdg),1);
            encodingSrcJdg.BlockTrial = (1:height(encodingSrcJdg))';
            
            %combine encoding lists
            allSubsEncoding = [allSubsEncoding; encodingPassive; encodingSrcJdg];
            
            %delete used words
            subStimuli(sampledWordIndices,:) = [];
            
            %create recogNovel list for each cycle
            sampledNovelWordIndices = randperm(height(subStimuli), p.nSampledNovelWordsPerBlock);
            sampledNovelWords = subStimuli(sampledNovelWordIndices,:);
            sampledNovelWordsextra = table(repmat(sub, height(sampledNovelWords), 1), repmat(sess, height(sampledNovelWords), 1), repmat(cy, height(sampledNovelWords), 1), repmat({'itemRecog'}, height(sampledNovelWords), 1), (1:height(sampledNovelWords))', repmat({'0'}, height(sampledNovelWords),1),...
                cell(height(sampledNovelWords),1), cell(height(sampledNovelWords),1), cell(height(sampledNovelWords),1), cell(height(sampledNovelWords),1),...
                'VariableNames',{'Sub', 'Session', 'Cycle', 'Block', 'BlockTrial', 'Studied', 'Pair', 'Response', 'RT', 'Correct'}); %adding other variables of interest
            sampledNovelWords = [sampledNovelWordsextra(:,1:5) sampledNovelWords sampledNovelWordsextra(:,6:end)];
            
            %create recogNovel with encoding words (i.e., recogOld)
            recogItem = [encodingPassive; sampledNovelWords];
            recogItem = recogItem(randperm(height(recogItem)),:);
            recogItem.Block = repmat({'itemRecog'}, height(recogItem),1);
            recogItem.BlockTrial = (1:height(recogItem))';
            
            %create srcRecog list for each cycle
            recogSrc = recogItem(randperm(height(recogItem)),:);
            recogSrc.Block = repmat({'sourceRecog'}, height(recogSrc),1);
            recogSrc.BlockTrial = (1:height(recogSrc))';
            
            %delete used words
            subStimuli(sampledNovelWordIndices,:) = [];
            
            %combine encoding lists
            allSubsRecog = [allSubsRecog; recogItem; recogSrc];            
        end 
    end    
end


idcs = strfind(p.stimRoot, filesep); %find file separators in the directory
newStimDir = p.stimRoot(1:idcs(end)-1); %new directory is on folder backward of current

if ~exist([newStimDir, '/RunSourceTask/Subject Data/'], 'dir') %If subject data folder doesn't exist in working directory, create folder
    mkdir([newStimDir, '/RunSourceTask/Subject Data/']);
end

fNameStimSequence = fullfile(newStimDir, '/RunSourceTask/Subject Data', 'allSubject_SourceMemory_StimSeq.mat'); %-DMS: Again, matched this to what was on Box (so if someone downloads files from there, it's set to run)
save(fNameStimSequence, 'p', 'allSubsEncoding', 'allSubsRecog');

fNameStimSeqEncodingCSV = fullfile(newStimDir, '/RunSourceTask/Subject Data', 'allSubject_Encoding_SourceMemory_StimSeq.csv');
writetable(allSubsEncoding,fNameStimSeqEncodingCSV,'Delimiter',',','QuoteStrings',true)

fNameStimSeqRecogCSV = fullfile(newStimDir, '/RunSourceTask/Subject Data', 'allSubject_Recog_SourceMemory_StimSeq.csv');
writetable(allSubsRecog,fNameStimSeqRecogCSV,'Delimiter',',','QuoteStrings',true)
