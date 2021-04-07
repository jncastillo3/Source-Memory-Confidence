%% RUN STUDY PHASE OF SOURCE MEMORY TASK IN SCANNER
close all; clc; clear;
sca
clear PsychImaging

%% LOAD allSubsStimSeq FOR INDEXING LATER
fNameStimSequence = fullfile(pwd, 'Subject Data', 'allSubject_SourceMemory_StimSeq.mat');
load(fNameStimSequence)
p.testRoot = pwd; %set working directory

%% ENTER PARTICIPANT NUM AND SESSION + VERIFY
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

p.subNum = 3; %Change this every new session/subject!!!
p.session = 1;

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%create a subject folder where data for that session will be saved
fName_check = fullfile(p.testRoot, '/Subject Data', ['Subject', num2str(p.subNum), '_sess', num2str(p.session)]);
restartExp = 1; %if exp crashed and needs to restart, this will skip intructions

%check whether a folder for that subject already exists. If so, throw error. If not, create folder and load data
if restartExp == 0 %this ensures that we'll be able to retstart the exp if it crashes and we need to redo a run
    if isfolder(fName_check)
        sca;
        error('Test folder for subject %d and session %d already exists! Check that inputs are correct.', p.subNum, p.session);
    else
        mkdir('Subject Data', ['Subject',num2str(p.subNum),'_sess',num2str(p.session)]);
        encodingList = allSubsEncoding(allSubsEncoding.Sub == p.subNum & allSubsEncoding.Session == p.session,:);
        
        %call encode OptSeq code to adjust condition order and ISI
        encodeOptSeq;
        
        %save encodingList separately within subject data folder
        encodefName = fullfile(p.testRoot, 'Subject Data', sprintf('/Subject%s_sess%s',num2str(p.subNum), num2str(p.session)),['/Subject', num2str(p.subNum), '_Session', num2str(p.session), '_encodingList.mat']); %csv file name encodingList will be saved in
        save(encodefName, 'encodingList')
    end
else
    %if restarting, load the SAME optimized encodingList saved in subs folder, don't create new
    encodingList = load(sprintf('Subject Data/Subject%d_sess%d/Subject%d_Session%d_encodingList.mat', p.subNum, p.session, p.subNum, p.session));
    encodingList = encodingList.encodingList;
end

encodingData = [];

%% Fixed function inputs
debug = 0; %Want to debug (speeds it up) = 1
screen = 0; %For multiple screens = 1
refresh = 60; %Refresh rate for my laptop = 60, lab computers = 120
mac = 1; %tells us default device and use that in KbQueueCreate

if mac == 1
    device = PsychHID('Devices', -1);
else
    device = 0;
end

%% Timing Parameters
if debug == 1 %Speeds up presentation time if just debugging
    p.instructionDur = .01;
    p.studyDur = .01;
    p.blankDur = .01;
    p.feedback = .01;
    p.respDelay = .01;
elseif debug ==0
    p.instructionDur = 2.5;
    p.studyDur = 2;
    p.blankDur = .1; %Blank screen in between stimuli during study (100ms) --> Matches Starns & Kasander
    p.feedback = 1;   %Feedback time during study session
    p.respDelay = .5; %extend response period before feedback
    p.FixStills = .5; %how long the green dot stays on screen for after each null miniblock
    p.miniBlankDur = 0.01; %used to grab timing
end

%% Response keys
PsychDefaultSetup(2); %Sets up some defaults (e.g. UnifyingNames etc.)

% for QUEUE routines
p.keys_Navigation = zeros(1,256);
p.keys_Navigation(KbName({'5%','space','Escape'})) = 1;

p.keys_source = zeros(1,256);
p.keys_source(KbName({'1!','2@', 'Escape'})) = 1; %1 = face, 2 = scene

p.keys_confidence = zeros(1,256);
p.keys_confidence(KbName({'1!','2@','3#','4$','Escape'})) = 1;
p.test = KbName({'1!','2@','3#','4$','Escape'});

%% Presentation Parameters
p.windowColor = [0 0 0]; %white [255 255 255]
p.whichScreen = screen; %=1 if using other monitor, = 0 if just laptop, IF CHANGING THIS NEED TO CHANGE REFRESH RATE TOO PROBABLY!!

if mac == 1
    Screen('Preference','SkipSyncTests', 1) %skip sync tests
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
p.nStudyStills = round(p.studyDur*1000/p.frame_dur); %Study presentation time 30 16.67
p.nBlankStills = round(p.blankDur*1000/p.frame_dur); %Blank/test presentation time
p.nFeedbackStills = round(p.feedback*1000/p.frame_dur); %Feedback presentation time
p.nRespDelayStills = round(p.respDelay*1000/p.frame_dur); %response delay post-trial
p.nFixationStills = round(p.FixStills*1000/p.frame_dur); %how long reen fixation stays on
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

%% Counterbalance conditions
CBcond = matfile('counterbalConds.mat'); %defines counterbalances faces/scenes for each session
CBcond = CBcond.orgCB;

pair = CBcond(p.subNum, p.session); %based on subnum and session, chooses the faces and scenes for that session
faceFName = fullfile(p.testRoot, 'ResizedFaces', ['face', num2str(pair),'.jpg']);
sceneFName = fullfile(p.testRoot, 'ResizedScenes', ['scene', num2str(pair),'.jpg']);

%select the scene image
matrixScene = importdata(sceneFName);
[sceneHeight, sceneWidth, ~]= size(matrixScene);
texture_Scene = Screen('MakeTexture', p.window, matrixScene);

%select the face image
matrixFace = importdata(faceFName);
[faceHeight, faceWidth, ~]= size(matrixFace);
texture_Face = Screen('MakeTexture', p.window, matrixFace);

%% Required Text
%Create continue text and placement
p.text_space = 'Ready to begin? Squeeze the ball to continue.';
p.tCenterSpace = [p.xCenter-RectWidth(Screen('TextBounds', p.window, p.text_space))/2  p.windowRect(4)*.8+40];

%Create study introduction  text
text_studyInstruction1 = ['Welcome! In this first part of the experiment you will study a series of image-word pairs. \n \n ' ...
    'No response is necessary during study, but do pay close attention. After each block of study, you will be asked to recall which image each word was paired with.'];

%Create 'f' and 's' responses
text_encoding1 = 'Face                                          Scene';
text_encoding2 = '[Press ''1'']                                   [Press ''2'']';
tCenterEncoding1 = [p.xCenter-RectWidth(Screen('TextBounds', p.window, text_encoding1))/2  p.windowRect(4)*.72+40];
tCenterEncoding2 = [p.xCenter-RectWidth(Screen('TextBounds', p.window, text_encoding2))/2  p.windowRect(4)*.8+40];

% initiate encoding null trial tables
allITencodingPassiveData = cell2table(cell(0,13), 'VariableNames',{'SubNum','Session','Test','Run','Stars','EncodingBlockTrial','Response','RT','Accuracy','TrialUp','RespDelay','TrialDown','TrialDuration'});
allITencodingRecallData = cell2table(cell(0,13), 'VariableNames',{'SubNum','Session','Test','Run','Stars','EncodingBlockTrial','Response','RT','Accuracy','TrialUp','RespDelay','TrialDown','TrialDuration'});

%% Run Experiment
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Study Phase General Instructions
ListenChar(-1); %Supress keypresses in matlab command window
KbQueueCreate(device, p.keys_Navigation);

if restartExp == 0 %if experiment crashed and need to restart, it'll skip the intro instructions
    while 1
        %Presenting Instructions
        DrawFormattedText(p.window, text_studyInstruction1, 'center', 'center', p.textColor, p.wrapat, 0, 0, 2);
        DrawFormattedText(p.window, p.text_space, 'center', p.tCenterSpace(2), p.textColor);  %space bar prompt
        p.startStudy = Screen('Flip', p.window);
        
        KbQueueStart; %Start listening to input after wait time
        [pressed, resp] = KbQueueCheck;
        if pressed
            if resp(KbName('Escape')); sca; return; end
            if resp(KbName('space')) %Space ends while loop for next screen flip
                break;
            end
        end
    end
end
KbQueueStop;

%% BEGIN EXPERIMENT; Passive viewing
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%Create run vector
p.nEncodeRuns = p.nCycles;
Eruns = [];
for i = 1:p.nEncodeRuns
    Eruni = repmat(i, 24, 1);
    Eruns = [Eruns; Eruni];
end

%creates a vector for stimuli placement (image/text locations)
stimPlacement = [];
for i = 1:p.nEncodeRuns
    RunStimPlacement = [ones(6, 1); repmat(2, 6, 1)];
    RunStimPlacement = RunStimPlacement(randperm(numel(RunStimPlacement)));
    stimPlacement = [stimPlacement; RunStimPlacement];
end
imgLoc1 = [490.4 350 690.4 550]; textLoc1 = p.xCenter+50; %image on LEFT. Used a peter Scarfe demonstration to figure this out. Squares were *41 and *59
imgLoc2 = [749.6 350 949.6 550]; textLoc2 = p.xCenter-150; %image of RIGHT

%add runs and stim placement to stimuli table. Also subsets into passive and source recall phase
encodingList.Run = Eruns;
encodingPassiveStim = encodingList(ismember(encodingList.Block, 'passive'),:);
encodingPassiveStim.StimPlacement = stimPlacement;
encodingPassiveData =[];
encodingSourceStim = encodingList(ismember(encodingList.Block, 'source'),:);

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Begin runs
for run = 2:p.nEncodeRuns %this range can be adjusted in exp needs to be restarted
    
    KbQueueCreate(device, p.keys_Navigation);
    while 1
        if run == 1 || restartExp == 1
            DrawFormattedText(p.window, 'The task is about to begin.', 'center', 'center', [0, 255, 0]);
        else
            DrawFormattedText(p.window, 'Ready to begin next block? Squeeze the ball to continue.', 'center', 'center', [0, 255, 0], p.wrapat, 0, 0, 2);
        end
        Screen('Flip', p.window);
        WaitSecs(2);
        KbQueueStart;
        [pressed, resp] = KbQueueCheck;
        if pressed
            if resp(KbName('Escape')); sca; return; end
            if resp(KbName('space')) %Space ends while loop for next screen flip
                break;
            end
        end
    end
    
    % spacebar AND the trigger need to be pressed to start a run
    % Wait for scanner trigger to start 5s fixation cross
    while 1
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
    
    %Presenting Instructions
    firstFlip = 1;
    for presentation = 1:p.nInstructionStills
        DrawFormattedText(p.window, 'Pay attention to the following image-words pairs.', 'center', 'center', p.textColor,  p.wrapat, 0, 0, 2); % "If you have any questions"
        vbl = Screen('Flip', p.window);
        if run == 1
            if firstFlip;
                p.startExp = vbl;
                firstFlip = 0;
            end
        end
        KbQueueStart; %Start listing to input after wait time
        [pressed, resp] = KbQueueCheck;
        if pressed
            if resp(KbName('Escape')); sca; return;
            end
        end
    end
    KbQueueStop;
    
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    %subset passive view stimuli for particular run
    encodingPassiveCycleStim = encodingPassiveStim(ismember(encodingPassiveStim.Run, run),:);
    encodingPassiveCycleStim = removevars(encodingPassiveCycleStim,{'Response','RT','Correct'});
    
    KbQueueCreate(device, p.keys_Navigation); %New queue
    vbl = GetSecs;
    
    %This selects the word for the trial, and the assigned image that goes with it
    for encodingPassiveTrial = 1:max(encodingPassiveCycleStim.BlockTrial)
        text_encodingPassiveStimuli = encodingPassiveCycleStim.Word{encodingPassiveTrial}; %create text for each trial
        
        if strcmp(char(encodingPassiveCycleStim.Pair(encodingPassiveTrial)), 'f') %Selection of image
            trialImage = texture_Face;
        else
            strcmp(char(encodingPassiveCycleStim.Pair(encodingPassiveTrial)), 's')
            trialImage = texture_Scene;
        end
        
        % Randomly place the image/text order on the left or right side of the screen
        % 1 == image on right, text on left
        % 2 == image on left, text on right
        imageplacement = encodingPassiveCycleStim.StimPlacement(encodingPassiveTrial);
        if imageplacement == 1
            imgLoc = imgLoc1;
            textLoc = textLoc1;
        else
            imgLoc = imgLoc2;
            textLoc = textLoc2;
        end
        
        KbQueueStart; %start listening for input
        firstFlip = 1; %First flip is occasionally missed
        
        %Presenting Stimuli
        for presentation = 1:p.nStudyStills %Prsenting each word for a preset duration
            DrawFormattedText(p.window, text_encodingPassiveStimuli, textLoc, p.yCenter, p.textColor);
            Screen('DrawTexture', p.window, trialImage , [], imgLoc);
            
            Screen('DrawingFinished', p.window);
            vbl = Screen('Flip', p.window, vbl - (.5 * p.ifi));
            if firstFlip;
                p.study_passive_up(encodingPassiveTrial) = vbl; %%Save Up/Down time to confirm trial presentation is correct
                encodingPassiveCycleStim.TrialUpTime(encodingPassiveTrial) = p.study_passive_up(encodingPassiveTrial) - p.RunStart;
                firstFlip = 0;
            end
            [pressed, resp] = KbQueueCheck;
            if pressed
                if resp(KbName('Escape')); sca; return;
                end
            end
        end
        
        %Display a brief blank screen in between
        for presentation = 1:p.nBlankStills
            vbl = Screen('Flip', p.window, vbl - (.5 * p.ifi));
            p.study_passive_down(encodingPassiveTrial) = vbl;
            encodingPassiveCycleStim.TrialDownTime(encodingPassiveTrial) = p.study_passive_down(encodingPassiveTrial) - p.RunStart;
            encodingPassiveCycleStim.TrialDuration(encodingPassiveTrial) = ((p.study_passive_down(encodingPassiveTrial) - p.RunStart) - (p.study_passive_up(encodingPassiveTrial) - p.RunStart));
        end
        
        % RUN STARS NULL TASK
        test = 1; %indicates passive viewing
        ISI = floor(encodingPassiveCycleStim.ISI(encodingPassiveTrial)/1.5);
        encodingPassiveCycleStim.ISItrials(encodingPassiveTrial) = ISI; %will record # of null trials completed
        starsNullTask_v2 %run null task script
        
        % this grabs the start of the null trials for later use
        startNull = allITencodingPassiveData.TrialUp(allITencodingPassiveData.EncodingBlockTrial == encodingPassiveTrial & allITencodingPassiveData.Run == run); %ISI duration
        startNull = startNull(1);
        
        %Display a green fixation after nulls to signal next study trial
        for presentation = 1:p.nFixationStills
            Screen('DrawDots', p.window, p.center, 5 , [0, 255, 0], [], 2, []);
            Screen('Flip', p.window, vbl - (.5 * p.ifi));
        end
        
        firstFlip = 1;
        for presentation = 1:p.nMiniBlank %Display a blank screen
            vbl = Screen('Flip', p.window, vbl - (.5 * p.ifi));
            if firstFlip
                p.ISIactual(encodingPassiveTrial) = vbl;
                encodingPassiveCycleStim.ISIactual(encodingPassiveTrial) = ((p.ISIactual(encodingPassiveTrial) - p.RunStart) - startNull); %determines total length of isi including green fixation
                firstFlip = 0;
            end
        end
    end
    
    %save passive encoding data in table
    encodingPassiveData = [encodingPassiveData; encodingPassiveCycleStim];
    KbQueueStop;
    restartExp = 0; %set back equal to zero after restart
    
    %% Source with feedback
    KbQueueCreate(device,p.keys_Navigation);
    
    %present instructions for source recall block
    for presentation = 1:p.nInstructionStills
        DrawFormattedText(p.window, 'Press ''1'' if the word was seen with a face and ''2'' if the word was seen with a scene.', 'center', 'center', p.textColor,  p.wrapat, 0, 0, 2); % "If you have any questions"
        vbl = Screen('Flip', p.window, vbl - (.5 * p.ifi));
        
        KbQueueStart; %Start listing to input after wait time
        [pressed, resp] = KbQueueCheck;
        if pressed
            if resp(KbName('Escape')); sca; return;
            end
        end
    end
    KbQueueStop;
    
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    encodingSourceCycleStimuli = encodingSourceStim(ismember(encodingSourceStim.Run, run),:);
    
    %select word
    for encodingSourceTrial = 1:max(encodingSourceCycleStimuli.BlockTrial)
        text_encodingSourceStimuli = encodingSourceCycleStimuli.Word{encodingSourceTrial}; %Create text for viewing with stimuli for each trial
        tCenterStudyStimuli = [p.xCenter-RectWidth(Screen('TextBounds', p.window, text_encodingSourceStimuli))/2  p.yCenter-40]; %Placement of stimuli for study
        
        %shift response windown by presenting each word without collecting response
        KbQueueCreate(device,p.keys_source); %New queue
        firstFlip = 1;
        for presentation = 1:p.nBlankStills
            DrawFormattedText(p.window, text_encodingSourceStimuli, 'center', tCenterStudyStimuli(2), p.textColor); % "Cow"
            DrawFormattedText(p.window, text_encoding1, 'center', tCenterEncoding1(2),[],p.wrapat,[],[],1.5); % "Face Scene"
            DrawFormattedText(p.window, text_encoding2, 'center', tCenterEncoding2(2),[],p.wrapat,[],[],1.5); % "[Press 'f']      [Press 's']"
            Screen('DrawingFinished', p.window);
            vbl = Screen('Flip', p.window, vbl - (.5 * p.ifi));
            if firstFlip;
                p.study_source_up(encodingSourceTrial) = vbl; %% Save Up/Down time to confirm trial presentation is correct
                encodingSourceCycleStimuli.TrialUpTime(encodingSourceTrial) = p.study_source_up(encodingSourceTrial) - p.RunStart;
                firstFlip = 0;
            end
        end
        p.study_source_RespDelayStart(encodingSourceTrial) = vbl; %% Again, just testing timing
        encodingSourceCycleStimuli.RespDelayOver(encodingSourceTrial) = ((p.study_source_RespDelayStart(encodingSourceTrial)-p.RunStart) - (p.study_source_up(encodingSourceTrial) - p.RunStart));
        
        %begin response window
        KbQueueStart; %Start listening for input after 100ms
        responded = 0; %Used later for response dimming
        
        while GetSecs <= p.study_source_up(encodingSourceTrial) + p.studyDur
            if responded
                %once response is recorded, dim responses on screen
                DrawFormattedText(p.window, text_encodingSourceStimuli, 'center', tCenterStudyStimuli(2), p.textColor); % "Cow"
                DrawFormattedText(p.window, text_encoding1, 'center', tCenterEncoding1(2), p.textColor - 150, p.wrapat,[],[],1.5); % "1 2 3 4"
                DrawFormattedText(p.window, text_encoding2, 'center', tCenterEncoding2(2), p.textColor - 150, p.wrapat,[],[],1.5); % "def   def"
                Screen('DrawingFinished', p.window);
                vbl = Screen('Flip', p.window, vbl - (.5 * p.ifi));
            elseif ~responded
                [pressed, resp] = KbQueueCheck([]);
                if pressed
                    responded = 1;
                    if resp(KbName('Escape')); sca; return;
                    else
                        key_press_time = min(resp(resp~=0));
                        encodingSourceCycleStimuli.Response(encodingSourceTrial) = cellstr(KbName(find(resp,1,'first')));
                        encodingSourceCycleStimuli.RT(encodingSourceTrial) = num2cell(key_press_time - p.study_source_up(encodingSourceTrial));
                    end
                end
            end
        end
        
        % extend response period by .5 seconds before feedback
        firstFlip = 1;
        for presentation = 1:p.nRespDelayStills %Display a blank screen in between where resp can still be recorded
            vbl = Screen('Flip', p.window, vbl - (.5 * p.ifi)); %Flip blank screen and get end trial timing
            if firstFlip;
                p.study_source_down(encodingSourceTrial) = vbl;
                firstFlip = 0;
                encodingSourceCycleStimuli.TrialDownTime(encodingSourceTrial) = p.study_source_down(encodingSourceTrial) - p.RunStart;
                encodingSourceCycleStimuli.TrialDuration(encodingSourceTrial) = (p.study_source_down(encodingSourceTrial) - p.RunStart) - (p.study_source_up(encodingSourceTrial) - p.RunStart);
            end
            p.study_source_RespDelayEnd(encodingSourceTrial) = vbl;
            encodingSourceCycleStimuli.RespExtendOver(encodingSourceTrial) = (p.study_source_RespDelayEnd(encodingSourceTrial) - p.RunStart) - (p.study_source_down(encodingSourceTrial) - p.RunStart);
            if ~responded
                [pressed, resp] = KbQueueCheck([]);
                if pressed
                    responded = 1;
                    if resp(KbName('Escape')); sca; return;
                    else
                        key_press_time = min(resp(resp~=0));
                        encodingSourceCycleStimuli.Response(encodingSourceTrial) = cellstr(KbName(find(resp == key_press_time)));
                        encodingSourceCycleStimuli.RT(encodingSourceTrial) = num2cell(key_press_time - p.study_source_up(encodingSourceTrial));
                    end
                end
            end
        end
        KbQueueStop;
        
        %present feedback after response made
        firstFlip = 1;
        for presentationFeedback = 1:p.nFeedbackStills
            if strcmp(char(encodingSourceCycleStimuli.Pair(encodingSourceTrial)), 'f')
                trialImage = texture_Face;
            else
                strcmp(char(encodingSourceCycleStimuli.Pair(encodingSourceTrial)), 's')
                trialImage = texture_Scene;
            end
            Screen('DrawTexture', p.window, trialImage, [], [p.xCenter-((sceneWidth/2)/2) p.yCenter-((sceneHeight/2)/2) p.xCenter+((sceneWidth/2)/2)  p.yCenter+((sceneHeight/2)/2)]);
            Screen('DrawingFinished', p.window);
            vbl = Screen('Flip', p.window, vbl - (.5 * p.ifi));
            if firstFlip
                p.study_feedback_up(encodingSourceTrial) = vbl;
                firstFlip = 0;
            end
        end
        
        firstFlip = 1;
        for presentation = 1:p.nBlankStills %present blank screen to get trial down time
            vbl = Screen('Flip', p.window, vbl - (.5 * p.ifi));
            if firstFlip
                p.study_feedback_down(encodingSourceTrial) = vbl;
                encodingSourceCycleStimuli.FeedbackDur(encodingSourceTrial) = (p.study_feedback_down(encodingSourceTrial)-p.RunStart) - (p.study_feedback_up(encodingSourceTrial)-p.RunStart);
            end
        end
        
        %record accuracy
        if responded == 1
            numbered_answer = encodingSourceCycleStimuli.Response{encodingSourceTrial};
            if str2double(numbered_answer(1)) == 1
                if strcmp(encodingSourceCycleStimuli.Pair(encodingSourceTrial), 'f')
                    encodingSourceCycleStimuli.Correct(encodingSourceTrial) = {1};
                else
                    encodingSourceCycleStimuli.Correct(encodingSourceTrial) = {0};
                end
            else
                if strcmp(encodingSourceCycleStimuli.Pair(encodingSourceTrial), 's')
                    encodingSourceCycleStimuli.Correct(encodingSourceTrial) = {1};
                else
                    encodingSourceCycleStimuli.Correct(encodingSourceTrial) = {0};
                end
            end
        end
        
        % RUN NULL STARS TASK
        test = 2;
        ISI = floor(encodingSourceCycleStimuli.ISI(encodingSourceTrial)/1.5);
        encodingSourceCycleStimuli.ISItrials(encodingSourceTrial) = ISI;
        starsNullTask_v2
        
        %again, gives us full ISI length
        startNull = allITencodingRecallData.TrialUp(allITencodingRecallData.EncodingBlockTrial == encodingSourceTrial & allITencodingRecallData.Run == run); %ISI duration
        startNull = startNull(1);
        
        for presentation = 1:p.nFixationStills
            Screen('DrawDots', p.window, p.center, 5 , [0, 255, 0], [], 2, []);
            Screen('Flip', p.window, vbl - (.5 * p.ifi));
        end
        
        firstFlip = 1;
        for presentation = 1:p.nMiniBlank %Display a blank screen
            vbl = Screen('Flip', p.window, vbl - (.5 * p.ifi));
            if firstFlip
                p.ISIactual(encodingSourceTrial) = vbl;
                encodingSourceCycleStimuli.ISIactual(encodingSourceTrial) = ((p.ISIactual(encodingSourceTrial) - p.RunStart) - startNull);
                firstFlip = 0;
            end
        end
        
    end
    
    %save source recall data to table
    encodingSourceCycleStimuli(:,{'Block'}) = {'e_Source'};
    encodingData = [encodingData; encodingSourceCycleStimuli]; %Save source responses for each cycle
    KbQueueStop;
    
    KbQueueCreate(device,p.keys_Navigation);
    
    %present number of runs completed
    for presentation = 1:p.nInstructionStills
        DrawFormattedText(p.window, ['Part ' num2str(run) ' out of 7 complete.'], 'center', 'center', p.textColor,  p.wrapat, 0, 0, 2); % "If you have any questions"
        vbl = Screen('Flip', p.window, vbl - (.5 * p.ifi));
        KbQueueStart; %Start listing to input after wait time
        [pressed, resp] = KbQueueCheck;
        if pressed
            if resp(KbName('Escape')); sca; return;
            end
        end
    end
    
    %for MR technician -- know when to end the scan
    while 1
        %Presenting Instructions
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
    
    %% SAVE run data
    % this is going to save the passive and source recall data into a .mat
    % and csv after EVERY run. Will not move on to next run without saving outside of the workspace.
    % If script crashes and needs to restart run, will save that run's data
    % with _conflict
    encodingNullData = [allITencodingPassiveData; allITencodingRecallData];
    encodingData = encodingData(:,[1 2 3 15 4:11 13 12 16:21 14 22 23]); 
    removevars(encodingData, 'Cycle');
    encodingPassiveData = encodingPassiveData(:,[1 2 3 12 4:10 13:16 11 17 18]);
    removevars(encodingPassiveData, 'Cycle');
    
    encodefName_mat = fullfile(p.testRoot, 'Subject Data', sprintf('/Subject%s_sess%s',num2str(p.subNum), num2str(p.session)),['/Subject', num2str(p.subNum), '_encode_Session', num2str(p.session), '_run', num2str(run), '.mat']); %mat file name everything will be saved in
    encodefName_csv = fullfile(p.testRoot, 'Subject Data', sprintf('/Subject%s_sess%s',num2str(p.subNum), num2str(p.session)),['/Subject', num2str(p.subNum), '_encode_Session', num2str(p.session), '_run', num2str(run), '.csv']); %csv file name everything will be saved in
    
    if exist(encodefName_mat,'file')
        encodefName_mat = fullfile(p.testRoot, 'Subject Data', sprintf('/Subject%s_sess%s',num2str(p.subNum), num2str(p.session)), ['/Subject', num2str(p.subNum), '_encode_Session', num2str(p.session), '_run', num2str(run), '_CONFLICT.mat']);
    end
    if exist(encodefName_csv,'file')
        encodefName_csv = fullfile(p.testRoot, 'Subject Data', sprintf('/Subject%s_sess%s',num2str(p.subNum), num2str(p.session)), ['Subject', num2str(p.subNum), '_encode_Session', num2str(p.session), '_run', num2str(run), '_CONFLICT.csv']); %mat file name everything will be saved in
    end
    
    save(encodefName_mat, 'encodingPassiveData','encodingData', 'p', 'allITencodingPassiveData','allITencodingRecallData');
    writetable(encodingData, encodefName_csv,'Delimiter',',','QuoteStrings',true)
    
end

% encoding phase is over. Let them know they will now do test phase
while 1
    %Presenting Instructions
    DrawFormattedText(p.window, 'Great work! You will now complete the final memory test.', 'center', 'center', [255, 255, 255], p.wrapat, 0, 0, 2);
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

%END EXPERIMENT
ListenChar(1); %start collecting keyboard input again
sca;
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%