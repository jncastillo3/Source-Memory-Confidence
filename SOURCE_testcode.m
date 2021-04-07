%% RUN TEST PHASE OF SOURCE MEMORY TASK IN SCANNER
close all; clc; clear;
sca
clear PsychImaging

%% LOAD allSubsStimSeq FOR INDEXING LATER
fNameStimSequence = fullfile(pwd, 'Subject Data', 'allSubject_SourceMemory_StimSeq.mat');
load(fNameStimSequence)
p.testRoot = pwd; %set working directory

%% ENTER PARTICIPANT NUM AND SESSION + VERIFY
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
p.subNum = 3; %Change this every new session/subject
p.session = 1;
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

%load the data
recogList = allSubsRecog(allSubsRecog.Sub == p.subNum & allSubsRecog.Session == p.session,:);

%% Format recogList
% First, create test runs
p.nTestruns = p.nCycles*2;
Truns = [];
for i = 1:p.nTestruns
    Truni = repmat(i, 18, 1);
    Truns = [Truns; Truni];
end

%Organize stimuli for indexing during recog cycles
recogList.TrialUpTime = zeros(252, 1);
recogList.RespDelayOver = zeros(252, 1); %response delay prevents too early of a response
recogList.TrialDownTime = zeros(252, 1);
recogList.TrialDuration = zeros(252, 1);
recogList.RespExtendOver = zeros(252, 1); %extends response into null trial
recogList.ISItrials = zeros(252,1);
recogList.Run = Truns;

recogItemstimuli = recogList(ismember(recogList.Block, 'itemRecog'),:);
recogSourcestimuli = recogList(ismember(recogList.Block, 'sourceRecog'),:);

%run optimization in item stimuli
ItemOptSeq;

%% Fixed function inputs
debug = 0; %Want to debug (speeds it up) = 1
screen = 0; %For multiple screens = 1
refresh = 60; %Refresh rate for my laptop = 60, lab computers = 120
mac = 1; %tells us default device and use that in KbQueueCreate
restartExp = 0; %if exp crashed and needs to restart, this will skip intructions

if mac == 1
    device = PsychHID('Devices', -1);
else
    device = 0;
end

%% Timing Parameters
if debug == 1 %Speeds up presentation time if just debugging
    p.instructionDur = .01;
    p.blankDur = .01;
    p.respDelay = .01;
elseif debug ==0
    p.instructionDur = 2.5;
    p.testDur = 2; %Stimulus duration in seconds (2000ms) --> Matches Starns & Ksander
    p.blankDur = .01; %Blank screen in between stimuli during study (100ms) --> Matches Starns & Kasander
    p.respDelay = .5; %extend response period before feedback
    p.miniBlankDur = 0.01; %used to grab timing
end

%% Response keys
PsychDefaultSetup(2); %Sets up some defaults (e.g. UnifyingNames etc.)

% for QUEUE routines
p.keys_Navigation = zeros(1,256);
p.keys_Navigation(KbName({'5%','space','Escape'})) = 1;

p.keys_confidence = zeros(1,256);
p.keys_confidence(KbName({'1!','2@','3#','4$','Escape'})) = 1;
p.test = KbName({'1!','2@','3#','4$','Escape'});

%% Presentation Parameters
p.windowColor = [0 0 0]; %white [255 255 255]
p.whichScreen = screen; %=1 if using other monitor, = 0 if just laptop, IF CHANGING THIS NEED TO CHANGE REFRESH RATE TOO PROBABLY!!

if mac == 1
    Screen('Preference','SkipSyncTests', 1) %for now, skip sync tests
end

[p.window, p.windowRect] = Screen('OpenWindow', p.whichScreen, p.windowColor);

HideCursor;
if debug == 1
    ShowCursor %If running and need cursor back: ShowCursor
end

% compute and store the center of the screen: p.windowRect contains the upper
% left coordinates (x,y) and the lower right coordinates (x,y)
p.xCenter = (p.windowRect(3) - p.windowRect(1))/2;
p.yCenter = (p.windowRect(4) - p.windowRect(2))/2;
p.center = [(p.windowRect(3) - p.windowRect(1))/2, (p.windowRect(4) - p.windowRect(2))/2];

% test the refresh properties of the display
p.RefreshRate = refresh;
p.fps=Screen('FrameRate',p.window);          % frames per second
p.ifi=Screen('GetFlipInterval', p.window);   % inter-frame-interval
if p.fps==0 %If fps does not register, then set the fps based on ifi
    p.fps=1/p.ifi;
end

% Translate the stim duration parameter into units of refresh rate
%each trial is ~2000 msec long, divided into xx frames lasting xx msec each
%Present [nFrames] 'stills' in every trial
p.frame_dur = p.ifi*1000; %frame duration in ms
p.nInstructionStills = round(p.instructionDur*1000/p.frame_dur); %Instruction presention
p.nBlankStills = round(p.blankDur*1000/p.frame_dur); %Blank/test presentation time
p.nRespDelayStills = round(p.respDelay*1000/p.frame_dur); %response delay post-trial
p.nMiniBlank = round(p.miniBlankDur*1000/p.frame_dur); %blank screen just to grab timing info

% check that the actual refresh rate is what we expect it to be.
if abs(p.fps-p.RefreshRate)>5
    sca;
    disp('Set the refresh rate to the requested rate')
    clc;
    return;
end

x = rng('shuffle');
p.rndSeedStudy = x.Seed;

%% font parameters
p.fontSize = 24;
p.textColor = [255 255 255]; % white. Black is [50 50 50]
p.wrapat=80;

% set up the font
Screen('TextFont',p.window, 'Arial');
Screen('TextSize',p.window, p.fontSize);
Screen('TextStyle', p.window, 0);
Screen('TextColor', p.window, p.textColor);

%% Required Text
%Create space text and placement
p.text_space = 'Ready to begin? Squeeze the ball to continue.';
p.tCenterSpace = [p.xCenter-RectWidth(Screen('TextBounds', p.window, p.text_space))/2  p.windowRect(4)*.8+40];

%Create test instructions text
text_testInstruction2 = ['Welcome back! You will now complete the final memory test.' ...
    '\n \n You will first be asked to rate your confidence that a word is OLD or NEW.' ...
    ' \n Later, you will rate your confidence that the word was studied with a FACE or a SCENE. \n \n Keep in mind that you will have a limited time to respond.'];

%Create practice trial text
p.text_test1 = '1                      2                      3                      4';
p.text_test2 = 'Definitely          Probably               Probably         Definitely';
p.text_test3source = 'Face                 Face                    Scene               Scene';

%Placement of Test text
p.tCenterTest1 = [p.xCenter-RectWidth(Screen('TextBounds', p.window, p.text_test1))/2  p.windowRect(4)*.68+40];
p.tCenterTest2 = [p.xCenter-RectWidth(Screen('TextBounds', p.window, p.text_test2))/2  p.windowRect(4)*.76+40];
p.tCenterTest3source = [p.xCenter-RectWidth(Screen('TextBounds', p.window, p.text_test3source))/2  p.windowRect(4)*.8+40];

% initiate test null trial tables
allITsourceData = cell2table(cell(0,13), 'VariableNames',{'SubNum','Session','Test','Run','Stars','TestBlockTrial','Response','RT','Accuracy','TrialUp','RespDelay','TrialDown','TrialDuration'});

%% source judgments
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

%run can be any even number
    for run = 2
        
        %run optimization for source
        SourceOptSeq;
        recogSourcestimuli.Run(recogSourcestimuli.Run ~= run) = run; %update run index
        
        KbQueueCreate(device, p.keys_Navigation);
        while 1
            %Presenting Instructions
            DrawFormattedText(p.window, 'Ready to begin? Squeeze the ball to continue.', 'center', 'center', [0, 255, 0], p.wrapat, 0, 0, 2);
            Screen('Flip', p.window);
            WaitSecs(1);
            KbQueueStart;
            [pressed, resp] = KbQueueCheck;
            if pressed
                if resp(KbName('Escape')); sca; return; end
                if resp(KbName('space')) %Space ends while loop for next screen flip
                    break;
                end
            end
        end
        
        % press space and trigger to start run
        % Wait for scanner trigger to start 5s fixation cross
        while 1
            KbQueueStart; %Start listing for trigger
            [pressed, resp] = KbQueueCheck;
            if pressed
                if resp(KbName('Escape')); sca; return; end
                if resp(KbName('5%')) %Space ends while loop for next screen flip
                    break;
                end
            end
        end
        KbQueueStop;
        
        % Start 5s fixation cross
        Screen('DrawLine', p.window, [255 255 255], (p.xCenter -15), (p.yCenter), (p.xCenter +15), (p.yCenter), 4);
        Screen('DrawLine', p.window, [255 255 255], (p.xCenter), (p.yCenter-15), (p.xCenter), (p.yCenter+15), 4);
        p.RunStart = Screen('Flip', p.window); % start of the scan
        WaitSecs(5);
        
        %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
        % The experiment will now begin
        KbQueueCreate(device, p.keys_Navigation);
        for presentation = 1:p.nInstructionStills
            DrawFormattedText(p.window, 'Now, rate your confidence that the word on screen was paired with a FACE or a SCENE.', 'center', 'center', p.textColor,  p.wrapat, 0, 0, 2); % "If you have any questions"
            vbl = Screen('Flip', p.window);
            KbQueueStart;
            [pressed, resp] = KbQueueCheck;
            if pressed
                if resp(KbName('Escape')); sca; return;
                end
            end
        end
        KbQueueStop;
        
        %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
        % Test Phase S/F Ratings
        %Present list of stimuli with feedback
        
        beginSourceRun = find(recogSourcestimuli.Run == run,1);
        endSourceRun = find(recogSourcestimuli.Run == run,1, 'last');
        
        KbQueueCreate(device, p.keys_confidence);
        
        for SFtrial = beginSourceRun:endSourceRun
            text_SFStimuli = recogSourcestimuli.Word{SFtrial, 1};
            tCenterTestStimuli = [p.xCenter-RectWidth(Screen('TextBounds', p.window, text_SFStimuli))/2  p.yCenter-40]; %Placement of stimuli for study
            
            firstFlip = 1; %First flip is occasionally missed
            %Presenting Stimuli
            for presentation = 1:p.nBlankStills %Present screen without looking for response for 100ms response window delay (in case of accidental button presses)
                DrawFormattedText(p.window, text_SFStimuli, 'center', tCenterTestStimuli(2), p.textColor); % "Cow"
                DrawFormattedText(p.window, p.text_test1, 'center', p.tCenterTest1(2),[],p.wrapat,[],[],1.5); % "1 2 3 4 5 6"
                DrawFormattedText(p.window, p.text_test2, 'center', p.tCenterTest2(2),[],p.wrapat,[],[],1.5); % "New      Old"
                DrawFormattedText(p.window, p.text_test3source, 'center', p.tCenterTest3source(2),[],p.wrapat,[],[],1.5);
                Screen('DrawingFinished', p.window);
                vbl = Screen('Flip', p.window, vbl - (.5 * p.ifi));
                if firstFlip
                    p.test_source_up(SFtrial) = vbl; %%Save Up/Down time to confirm trial presentation is correct (currently off by .0387s- issue?). Should be saved for analysis too (in bigger table?) -DMS
                    recogSourcestimuli.TrialUpTime(SFtrial) = p.test_source_up(SFtrial) - p.RunStart;
                    firstFlip = 0;
                end
                p.test_source_RespDelayOver(SFtrial) = vbl; %%Again, just testing timing (currently off on avg by 0.1536s- issue?), but may want to save in bigger table (new column) just in case -DMS
            end
            recogSourcestimuli.RespDelayOver(SFtrial) = (p.test_source_RespDelayOver(SFtrial)  - p.RunStart) - (p.test_source_up(SFtrial) - p.RunStart);
            
            %Shift response window
            KbQueueStart; %Start listening for input
            responded = 0; %Used later for response dimming
            
            while GetSecs <= p.test_source_up(SFtrial) + p.testDur
                if responded
                    %If response made, dim the reminder of key options
                    DrawFormattedText(p.window, text_SFStimuli, 'center', tCenterTestStimuli(2), p.textColor); % "Cow"
                    DrawFormattedText(p.window, p.text_test1, 'center', p.tCenterTest1(2),p.textColor - 150,p.wrapat,[],[],1.5); % "1 2 3 4 5 6"
                    DrawFormattedText(p.window, p.text_test2, 'center', p.tCenterTest2(2),p.textColor - 150,p.wrapat,[],[],1.5); % "New      Old"
                    DrawFormattedText(p.window, p.text_test3source, 'center', p.tCenterTest3source(2),p.textColor - 150,p.wrapat,[],[],1.5);
                    Screen('DrawingFinished', p.window);
                    vbl = Screen('Flip', p.window, vbl - (.5 * p.ifi));
                elseif ~responded
                    [pressed, resp] = KbQueueCheck([]);
                    if pressed
                        responded = 1;
                        if resp(KbName('Escape')); sca; return;
                        elseif any(resp(p.test))
                            key_press_time = min(resp(resp~=0));
                            recogSourcestimuli.Response(SFtrial) = cellstr(KbName(find(resp == key_press_time)));
                            recogSourcestimuli.RT(SFtrial) = num2cell(key_press_time - p.test_source_up(SFtrial));
                        end
                    end
                end
            end
            
            %Extend response window time into ISI
            firstFlip = 1;
            for presentation = 1:p.nRespDelayStills %Present blank screen for late responses
                vbl = Screen('Flip', p.window, vbl - (.5 * p.ifi)); %Flip blank screen and get end trial timing
                if firstFlip
                    p.test_source_down(SFtrial) = vbl;
                    firstFlip = 0;
                    recogSourcestimuli.TrialDownTime(SFtrial) = p.test_source_down(SFtrial) - p.RunStart;
                    recogSourcestimuli.TrialDuration(SFtrial) = (p.test_source_down(SFtrial)- p.RunStart) - (p.test_source_up(SFtrial) - p.RunStart);
                end
                p.test_source_RespExtendOver(SFtrial) = vbl;
                recogSourcestimuli.RespExtendOver(SFtrial) = (p.test_source_RespExtendOver(SFtrial)  - p.RunStart) - (p.test_source_down(SFtrial) - p.RunStart);
                if ~responded
                    [pressed, resp] = KbQueueCheck([]);
                    if pressed
                        responded = 1;
                        if resp(KbName('Escape')); sca; return;
                        elseif any(resp(p.test))
                            key_press_time = min(resp(resp~=0));
                            recogSourcestimuli.Response(SFtrial) = cellstr(KbName(find(resp == key_press_time)));
                            recogSourcestimuli.RT(SFtrial) = num2cell(key_press_time - p.test_source_up(SFtrial));
                        end
                    end
                end
            end
            KbQueueStop;
            
            if responded == 1
                if strcmp(recogSourcestimuli.Pair{SFtrial}, 'f')
                    if any(strcmp(recogSourcestimuli.Response{SFtrial}, {'1', '2'}))
                        recogSourcestimuli.Correct{SFtrial} = '1';
                    else
                        recogSourcestimuli.Correct{SFtrial} = '0';
                    end
                elseif strcmp(recogSourcestimuli.Pair{SFtrial}, 's')
                    if any(strcmp(recogSourcestimuli.Response{SFtrial}, {'1', '2'}))
                        recogSourcestimuli.Correct{SFtrial} = '0';
                    else
                        recogSourcestimuli.Correct{SFtrial} = '1';
                    end
                else
                    recogSourcestimuli.Correct{SFtrial} = '0';
                end
            end
            
            for presentation = 1:p.nBlankStills %Display a blank screen in between
                vbl = Screen('Flip', p.window, vbl - (.5 * p.ifi));
            end
            
            test = 4;
            ISI = floor(recogItemstimuli.ISI(SFtrial)/1.5);
            recogSourcestimuli.ISItrials(SFtrial) = ISI;
            starsNullTask_v2;
            
            startNull = allITsourceData.TrialUp(allITsourceData.TestBlockTrial == SFtrial & allITsourceData.Run == run);
            startNull = startNull(1);
            
            %Quick fixation to indicate start of test trials again
            for presentation = 1:p.nRespDelayStills % Display a blank screen in between .5s
                Screen('DrawDots', p.window, p.center, 5 , [0, 255, 0], [], 2, []);
                Screen('Flip', p.window, vbl - (.5 * p.ifi));
            end
            
            firstFlip = 1;
            for presentation = 1:p.nMiniBlank %Display a blank screen to get timing
                vbl = Screen('Flip', p.window, vbl - (.5 * p.ifi));
                if firstFlip
                    p.testSourceFixationDown(SFtrial) = vbl;
                    recogSourcestimuli.ISIactual(SFtrial) = ((p.testSourceFixationDown(SFtrial) - p.RunStart) - startNull);
                    firstFlip = 0;
                end
            end
            
        end
        
        % overall feedback
        cycleDataNaN_source = recogSourcestimuli(ismember(recogSourcestimuli.Run, run),:);
        cycleData_source = cycleDataNaN_source(~cellfun(@isempty,cycleDataNaN_source.Response),:);
        acc_raw = str2double(cycleData_source.Correct);
        accuracy_overall = round(nanmean(acc_raw)*100);
        
        % high confidence accuracy
        getHCresp = cycleData_source(ismember(cycleData_source.Response, {'1!', '4$'}),:);
        raw_hc_accuracy_source = str2double(getHCresp.Correct);
        if isempty(raw_hc_accuracy_source)
            p.hc_accuracy = 0;
        else
            hc_accuracy = round(nanmean(raw_hc_accuracy_source)*100);
        end
        
        pos_feedback_overall = sprintf('Your overall accuracy for this block was %d percent. Great job! Keep it up.', accuracy_overall);
        neutral_feedback_overall = sprintf('Your overall accuracy for this block was %d percent. This is a decent score, but there''s room for improvement.', accuracy_overall);
        neg_feedback_overall = sprintf('Your overall accuracy for this block was %d percent. Try your best to respond as accurately as possible.', accuracy_overall);
        
        pos_feedback_hc = sprintf('\n \n \n \n \n On trials where you said ''definitely,'' your accuracy was %d percent. Good self knowledge!', hc_accuracy);
        neutral_feedback_hc = sprintf('\n \n \n \n \n On trials where you said ''definitely,'' your accuracy was %d percent. Try to reserve ''definitely'' for when you are sure.', hc_accuracy);
        neg_feedback_hc = sprintf('\n \n \n \n \n On trials where you said ''definitely,'' your accuracy was %d percent. Only say ''definitely'' when you are absolutely sure.', hc_accuracy);
        
        %give feedback based on score
        if accuracy_overall > 90
            DrawFormattedText(p.window, pos_feedback_overall, 'center', 'center', p.textColor,  p.wrapat, 0, 0, 2);
        elseif 70 < accuracy_overall && accuracy_overall < 90
            DrawFormattedText(p.window, neutral_feedback_overall, 'center', 'center', p.textColor,  p.wrapat, 0, 0, 2);
        elseif accuracy_overall < 70
            DrawFormattedText(p.window, neg_feedback_overall, 'center', 'center', p.textColor,  p.wrapat, 0, 0, 2);
        end
        
        if hc_accuracy > 90
            DrawFormattedText(p.window, pos_feedback_hc, 'center', 'center', p.textColor,  p.wrapat, 0, 0, 2);
        elseif 70 < hc_accuracy && hc_accuracy < 90
            DrawFormattedText(p.window, neutral_feedback_hc, 'center', 'center', p.textColor,  p.wrapat, 0, 0, 2);
        elseif hc_accuracy < 70
            DrawFormattedText(p.window, neg_feedback_hc, 'center', 'center', p.textColor,  p.wrapat, 0, 0, 2);
        end
        
        Screen('Flip', p.window);
        WaitSecs(6);
        
        for presentation = 1:p.nInstructionStills
            DrawFormattedText(p.window, ['Part ' num2str(run) ' out of 14 complete.'], 'center', 'center', p.textColor,  p.wrapat, 0, 0, 2); % "If you have any questions"
            vbl = Screen('Flip', p.window, vbl - (.5 * p.ifi));
            
            KbQueueStart; %Start listing to input after wait time
            [pressed, resp] = KbQueueCheck;
            if pressed
                if resp(KbName('Escape')); sca; return;
                end
            end
        end
        
        KbQueueCreate(device, p.keys_Navigation);
        while 1
            DrawFormattedText(p.window, 'End run.', 'center', 'center', [255, 0, 0], p.wrapat, 0, 0, 2);
            Screen('Flip', p.window);
            
            WaitSecs(1);
            KbQueueStart;
            [pressed, resp] = KbQueueCheck;
            if pressed
                if resp(KbName('Escape')); sca; return; end
                if resp(KbName('space')) %Space ends while loop for next screen flip
                    break;
                end
            end
        end
        KbQueueStop;
        
        %% Save data
        recogSourcestimuli = recogSourcestimuli(:,[1 2 3 20 4:11 13 12 14:22]); 

        testfName_mat = fullfile(p.testRoot, 'Subject Data', sprintf('/Subject%s_sess%s',num2str(p.subNum), num2str(p.session)), ['/Subject', num2str(p.subNum), '_tSource_Session', num2str(p.session), '_run', num2str(run), '.mat']); %mat file name everything will be saved in
        testfName_csv = fullfile(p.testRoot, 'Subject Data', sprintf('/Subject%s_sess%s',num2str(p.subNum), num2str(p.session)), ['/Subject', num2str(p.subNum), '_tsource_Session', num2str(p.session), '_run', num2str(run), '.csv']); %csv file name everything will be saved in
        
        if exist(testfName_mat,'file')
            testfName_mat = fullfile(p.testRoot, 'Subject Data', sprintf('/Subject%s_sess%s',num2str(p.subNum), num2str(p.session)), ['/Subject', num2str(p.subNum), '_tSource_Session', num2str(p.session), '_run', num2str(run), '_CONFLICT.mat']);
        end
        if exist(testfName_csv,'file')
            testfName_csv = fullfile(p.testRoot, 'Subject Data', sprintf('/Subject%s_sess%s',num2str(p.subNum), num2str(p.session)), ['/Subject', num2str(p.subNum), '_tSource_Session', num2str(p.session), '_run', num2str(run), '_CONFLICT.csv']); %mat file name everything will be saved in
        end
        
        save(testfName_mat, 'recogSourcestimuli','p', 'allITsourceData','hc_accuracy','accuracy_overall');
        writetable(recogSourcestimuli, testfName_csv,'Delimiter',',','QuoteStrings',true)
        
    end
    
    sca;
