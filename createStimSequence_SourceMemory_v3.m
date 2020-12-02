%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%% createStimSequence function called in Source Memory_v1
%% July 2017 DMW: creates randomized stimulus order for encoding session (containing repeated cycles of 4 blocks)
% and for recognition memory test session (source memory is created during
% the experiment because it relies on false alarms from recognition test)
%% October 2017 DMW: FOR ALL SUBJECTS (to be indexed on computers downstairs)
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

nPossibleSubjects = 1;
cd('/Users/nicolecastillo/Documents/SourceMemTask_Umass/SourceMemoryfMRI') %Set wd
p.root = pwd;

%% Specific Variables
p.nSampledWordsPerBlock = 6; %number of words sampled from the word pool during various blocks (i.e. encodingA and encodingC)
p.nBlocks = 4; %number of separate blocks within an encoding phase
p.nBlocksSample = 2; %number of blocks that sample new words in an encoding phase
p.nCycles = 1; %number of times an encoding phase is repeated in one session %CHANGE THIS BACK TO 10
p.freqLow = 2; %lower frequency criteria (oringally 4, lowered to 2)
p.freqHigh = 6; %upper frequency criteria

p.nSampledWordsTotal = (p.nBlocksSample*p.nSampledWordsPerBlock*p.nCycles) + (p.nSampledWordsPerBlock*p.nCycles); %total number of words sampled from the word pool within a session

stimuliOG = readtable(fullfile(p.root, '/CreateStimSeq/wordStimuli.xlsx')); %read in data file as table
stimuliOG = [stimuliOG(:,2) stimuliOG(:,8) stimuliOG(:,17)]; %select only variables of interest from large stimuli data file
stimuliOG = stimuliOG(~any(ismissing(stimuliOG),2),:); %get rid of extra blank rows in spreadsheet
stimuli = stimuliOG(stimuliOG.SUBTLWF >= p.freqLow & stimuliOG.SUBTLWF <= p.freqHigh, :); %filter stimuli for word frequency criteria (up to 1,291, from 412)

p.nPossibleSessions = floor(height(stimuli)/p.nSampledWordsTotal);

allSubsEncoding = [];
allSubsRecog = [];
for sub = 1:nPossibleSubjects
    %% Create Sampled EncodingA List without words sharing first letter and length in same block
    encodingA = [];
    encodingCOld = [];
    encodingCNew = [];
    subStimuli = stimuli; %assign stimuli list to new variable, so can delete used words from list for each subjects
    
    for s = 1:p.nPossibleSessions
        
        cycleStart = 1;
        word_list_validated = false;
        while word_list_validated == false
            flag = 0;
            disp('Started from the top')
            
            for c = cycleStart:p.nCycles
                
                sampledWordIndices = randperm(height(subStimuli), p.nSampledWordsPerBlock);
                sampledWords = subStimuli(sampledWordIndices,:);
                
                first_letter = cellfun(@(y) y(1), sampledWords.Word');
                str_length = cellfun(@(y) length(y), sampledWords.Word');
                
                unique_letters = unique(first_letter);
                if length(unique_letters) < length(first_letter)
                    for i = unique_letters
                        y = first_letter == i;
                        str_lengths = str_length(y);
                        if length(unique(str_lengths)) < length(str_lengths)
                            flag = 1;
                            break;
                        end
                    end
                end
                
                if(flag == 1)
                    cycleStart = c;
                    break
                else
                    
                    sampledWordsextra = table(repmat(s, height(sampledWords), 1), repmat(c, height(sampledWords), 1), repmat({'encodingA'}, height(sampledWords), 1), (1:height(sampledWords))', cell(height(sampledWords),1),...
                        cell(height(sampledWords),1), cell(height(sampledWords),1), cell(height(sampledWords),1), cell(height(sampledWords),1),...
                        'VariableNames',{'Session', 'Cycle', 'Block', 'BlockTrial', 'Studied', 'Pair', 'Response', 'RT', 'Correct'}); %adding other variables of interest
                    sampledWords = [sampledWordsextra(:,1:4) sampledWords sampledWordsextra(:,5:end)];
                    
                    %create encodingB (cued recall) list for each cycle
%                     encodingB = sampledWords;
%                     encodingB(:,{'Block'}) = {'encodingB'}; %replace block variable
%                     wholeWord = encodingB.Word;
%                     firstLetter = cell({});
%                     
%                     for w = 1:length(wholeWord) %creating list with first letter of word and other letters replaced by dash
%                         word = wholeWord{w,:};
%                         firstLetter(w,1) = {[word(1) repmat(' _', 1, length(word)-1)]};
%                     end
%                     
%                     encodingB.Word = firstLetter;
%                     encodingBWordIndices = randperm(height(encodingB), height(encodingB)); %randomize order for encodingB presentation
%                     encodingBRandom = encodingB(encodingBWordIndices,:);
%                     encodingBRandom.BlockTrial = (1:height(encodingBRandom))';
%                     encodingBAnswers = encodingBRandom;
%                     encodingBAnswers.Word = sampledWords.Word(encodingBWordIndices,:);
%                     encodingBRandom.Studied = encodingBAnswers.Word;
                    
                    %create encodingC list for each cycle
                    %old words
                    encodingCOldsampled = sampledWords;
                    encodingCOldsampled(:,{'Studied'}) = {'1'};
                    encodingCOldsampled(:,{'Block'}) = {'encodingC'}; %replace block variable
                    
                    encodingCOld = [encodingCOld; encodingCOldsampled];
                    
                    encodingA = [encodingA; sampledWords]; %encodingBRandom];
                    subStimuli(sampledWordIndices,:) = [];
                end
                
            end
            
            if(flag == 0)
                word_list_validated = true;
            end
            
        end
    end
    
    totalEncodingSessionList=[];
    totalRecogSessionList=[];
    
    sampledWordIndices2 = randperm(height(subStimuli));
    sampledWords2 = subStimuli(sampledWordIndices2,:);
    
    encodingCNewSample = sampledWords2(1:p.nSampledWordsPerBlock*p.nCycles*p.nPossibleSessions,:); %assign 1st 1:n as encodingC new words
    testASample = sampledWords2(p.nSampledWordsPerBlock*p.nCycles*p.nPossibleSessions+1:p.nSampledWordsPerBlock*p.nCycles*p.nPossibleSessions*2,:); %assign 2nd n+1:# as testA words
    
    for s2 = 1:p.nPossibleSessions
      
        encodingCNewWords = encodingCNewSample(p.nSampledWordsPerBlock*p.nCycles*(s2-1) + 1:p.nSampledWordsPerBlock*p.nCycles*s,:);
        testAwords = testASample(p.nSampledWordsPerBlock*p.nCycles*(s2-1) + 1:p.nSampledWordsPerBlock*p.nCycles*s2,:);

        totalCycleList = [];
        for c2 = 1:p.nCycles
            %new encodingC words
            encodingCNew = encodingCNewWords(p.nSampledWordsPerBlock*c2-p.nSampledWordsPerBlock+1:p.nSampledWordsPerBlock*c2,:); %subsetting from greater list
            encodingCNewExtra = table(repmat(s2, height(encodingCNew), 1), repmat(c2, height(encodingCNew), 1), repmat({'encodingC'}, height(encodingCNew), 1), (1:height(encodingCNew))', cell(height(encodingCNew),1),...
                cell(height(encodingCNew),1), cell(height(encodingCNew),1), cell(height(encodingCNew),1), cell(height(encodingCNew),1),...
                'VariableNames',{'Session', 'Cycle', 'Block', 'BlockTrial', 'Studied', 'Pair', 'Response', 'RT', 'Correct'}); %adding other variables of interest
            encodingCNew = [encodingCNewExtra(:,1:4) encodingCNew encodingCNewExtra(:,5:end)];
            encodingCNew(:,{'Studied'}) = {'0'};
            
            sessionOnly = encodingCOld(encodingCOld.Session == s2,:);
            sessionAndCycle = sessionOnly(sessionOnly.Cycle == c2, :);
            
            %create paired image (equally scene and face for old and new words)
            possibleImages = [repmat({'s'}, 1, height(sessionAndCycle)/2) repmat({'f'}, 1, height(sessionAndCycle)/2)];
            Perm1 = randperm(length(possibleImages));
            sessionAndCycle.Pair = possibleImages(Perm1)';
            Perm2 = randperm(length(possibleImages));
            encodingCNew.Pair = possibleImages(Perm2)';
            
            %combine encodingC new and old list, then randomize order
            encodingC = [encodingCNew; sessionAndCycle];
            encodingCWordIndices = randperm(height(encodingC), height(encodingC));
            encodingCRandom = encodingC(encodingCWordIndices,:);
            encodingCRandom.BlockTrial = (1:height(encodingCRandom))';
            
            %create encodingD list for each cycle (same as encodingC, but
            %different order)
            encodingD = encodingC;
            encodingD(:,{'Block'}) = {'encodingD'}; %replace block variable
            encodingDWordIndices = randperm(height(encodingD), height(encodingD));
            encodingDRandom = encodingD(encodingDWordIndices,:);
            encodingDRandom.BlockTrial = (1:height(encodingDRandom))';
            
            %combine blocks into one cycle list
            sessionOnlyRest = encodingA(encodingA.Session == s2,:);
            sessionAndCycleRest = sessionOnlyRest(sessionOnlyRest.Cycle == c2, :);
            
            cycleList = [sessionAndCycleRest; encodingCRandom;encodingDRandom];
            totalCycleList = [totalCycleList; cycleList];
            
        end
        
        sessionTrial = table((1:height(totalCycleList))', 'VariableNames',{'SessionTrial'});
        totalCycleList = [totalCycleList(:,1) sessionTrial totalCycleList(:,2:end)];
        totalEncodingSessionList = [totalEncodingSessionList; totalCycleList];
        
        %create testA list
        testAOld = totalCycleList(ismember(totalCycleList.Block, 'encodingD'), :);
        testAOld(:,{'Block'}) = {'testA'}; %replace block variable
        testAOld(:,{'Studied'}) = {'1'}; %replace studied variable
        
        testANew = [testAOld(1:height(testAwords),1:5) testAwords testAOld(1:height(testAwords),9:end)];
        testANew(:,{'Cycle'}) = num2cell(zeros(height(testANew), 1));
        testANew(:,{'BlockTrial'}) = num2cell(zeros(height(testANew), 1));
        testANew(:,{'Studied'}) = {'0'};
        testANew(:,{'Pair'}) = cell(height(testANew),1);
        
        testA = [testAOld; testANew];
        testAWordIndices = randperm(height(testA), height(testA));
        testARandom = testA(testAWordIndices,:);
        testARandom.BlockTrial = (1:height(testARandom))';
        
        testB = testAOld;
        testBWordIndices = randperm(height(testB), height(testB));
        testBRandom = testB(testBWordIndices,:);
        testBRandom(:,{'Block'}) = {'testB'}; %replace block variable
        testBRandom.BlockTrial = (1:height(testBRandom))';
        
        recogList = [testARandom; testBRandom];        
        recogList.SessionTrial = (1:height(recogList))';
        
        totalRecogSessionList = [totalRecogSessionList; recogList];
         
    end
    
    subjectIDEnc = table(repmat(sub, height(totalEncodingSessionList), 1), 'VariableNames',{'Sub'}); %adding other variables of interest
    subjectIDRec = table(repmat(sub, height(totalRecogSessionList), 1), 'VariableNames',{'Sub'}); %adding other variables of interest
    
    totalEncodingSessionList = [subjectIDEnc totalEncodingSessionList];
    totalRecogSessionList = [subjectIDRec totalRecogSessionList];
    
    allSubsEncoding = [allSubsEncoding; totalEncodingSessionList];
    allSubsRecog = [allSubsRecog; totalRecogSessionList];
 
end

fNameStimSequence = fullfile(p.root, 'RunExp/Subject Data', 'allSubject_SourceMemory_StimSeq.mat');
save(fNameStimSequence, 'p', 'allSubsEncoding', 'allSubsRecog');

fNameStimSeqEncodingCSV = fullfile(p.root, 'RunExp/Subject Data', 'allSubject_Encoding_SourceMemory_StimSeq.csv');
writetable(allSubsEncoding,fNameStimSeqEncodingCSV,'Delimiter',',','QuoteStrings',true)

fNameStimSeqRecogCSV = fullfile(p.root, 'RunExp/Subject Data', 'allSubject_Recog_SourceMemory_StimSeq.csv');
writetable(allSubsRecog,fNameStimSeqRecogCSV,'Delimiter',',','QuoteStrings',true)