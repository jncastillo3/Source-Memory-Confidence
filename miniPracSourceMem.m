close all; clc; clear;
sca
clear PsychImaging

%% Fixed function inputs
screen = 0; %For multiple screens = 1
refresh = 60; %Refresh rate for my laptop = 60, lab computers = 120
mac = 1; %tells us default device and use that in KbQueueCreate
if mac == 1
    device = PsychHID('Devices', -1);
else
    device = 0;
end

%% Establish directory and load needed files
participantListfName = fullfile(pwd, 'Subject Data', 'ParticipantList.mat');
if exist(participantListfName,'file') %Load participant list file
    load(participantListfName)
else
    participantList = table(zeros(200,1), zeros(200,1), cell(200,1), cell(200,1),...
        'VariableNames',{'SubNum','Session', 'Computer', 'Date'}); %If subject participant list file doesn't exist in working directory, create file
    save(participantListfName, 'participantList');
end
p.pracRoot = pwd; % Set wd

%% Timing Parameters
    p.instructionDur = 2.5;
    p.testDur = 2; %Stimulus duration in seconds (2000ms) --> Matches Starns & Ksander
    p.blankDur = .1; %Blank screen in between stimuli during study (100ms) --> Matches Starns & Kasander
    p.feedback = 1;   %Feedback time during study session
    p.respDelay = .5; %extend response period before feedback

%% Set up GUI & demographics prompt & save new data
% Create GUI and get subject number, etc. recorded in participantList file
prompt = {'Subject number', 'Session'}; %GUI answer box prompts
defAns = {'', ''}; %Fill in stock answers to the gui input boxes

validated = false; %Keep running GUI until participant confirms correct information
while ~validated
    box = inputdlg(prompt,'Enter Your Information...', 1, defAns); %Prompt at top of GUI
    p.subNum = box{1};
    p.sess = str2double(box{2});
    
    accept = confirmation_dialog(p.subNum, p.sess);
    if accept
        validated = true;
    end
end

Demographics(p.subNum, p.sess); %Calls Demographics script that puts up GUI calling for demographic info and saves it in a .txt file
[~, p.hostname] = system('hostname'); %Record computer experiment is on

%Add data as new line in participantList and save
lastEntry = find(participantList.SubNum,1,'last'); %Find the last nonzero element in SubNum
if isempty(lastEntry)
    nextLine = 1; %If there isn't a nonzero element in SubNum, start entry on line one
else
    nextLine = lastEntry +1; %If there is a nonzero element, + 1 for next line to be filled
end

participantList.SubNum(nextLine) = str2double(p.subNum);
participantList.Session(nextLine) = p.sess;
participantList.Computer(nextLine) = cellstr(p.hostname);
participantList.Date(nextLine) = {date};
save(participantListfName, 'participantList');

%% Response keys
PsychDefaultSetup(2); %Sets up some defaults (e.g. UnifyingNames etc.)

% for QUEUE routines
p.keys_Navigation = zeros(1,256);
p.keys_Navigation(KbName({'space','Escape'})) = 1;

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
p.nFeedbackStills = round(p.feedback*1000/p.frame_dur); %Feedback presentation time
p.nRespDelayStills = round(p.respDelay*1000/p.frame_dur); %response delay post-trial

% check that the actual refresh rate is what we expect it to be.
if abs(p.fps-p.RefreshRate)>5
    sca;
    disp('Set the refresh rate to the requested rate')
    clc;
    return;
end

HideCursor;
x = rng('shuffle');
p.rndSeedStudy = x.Seed;

%% font parameters
p.fontSize = 24;
p.textColor = [255 255 255]; % white. Black is [50 50 50]
p.wrapat=80;
p.indent=400;

% set up the font
Screen('TextFont',p.window, 'Arial');
Screen('TextSize',p.window, p.fontSize);
Screen('TextStyle', p.window, 0);
Screen('TextColor', p.window, p.textColor);

%% Required Text
%Create space text and placement
p.text_space = 'Press space to continue.';
p.text_begin = 'Press space to begin practice.';

p.tCenterSpace = [p.xCenter-RectWidth(Screen('TextBounds', p.window, p.text_space))/2  p.windowRect(4)*.8+40];

%Create test instructions text
text_testInstruction2 = ['Welcome! Today you will be completing a memory test.' ...
    '\n \n You will first learn a series of image-word pairs. Then you will be asked to rate your confidence that a word is OLD or NEW,' ...
    ' \n and whether it was studied with a FACE or a SCENE.'];
text_testInstruction3 = ['To begin, you will be asked to rate your confidence that the current word on the screen is an old or new word '...
    'with the numbered keys 1-4.'];
text_testInstruction4 = ['If you think the word is new, you will use the keys 1 and 2 \n \n  where 1 = the word is DEFINITELY new '...
    '\n and 2 = the word is PROBABLY new'];
text_testInstruction5 = ['If you think the word is old, you will use the keys 3 and 4 \n \n '...
    '\n where 3 = the word is PROBABLY old \n 4 = the word is DEFINITELY old \n\n Let''s try an example.'];
text_testInstruction6 = 'Next, you will be asked to rate your confidence that the current word on the screen was previously seen with an image of a FACE or a SCENE.';
text_testInstruction7 = ['If you think the word was seen with a face, you will use the keys 1 and 2 \n \n  1 = the image was DEFINITELY a face '...
    '\n 2 = the image was PROBABLY a face'];
text_testInstruction8 = ['If you think the word was seen with a scene, you will use the keys 3 and 4 \n \n 3 = the image was PROBABLY a scene '...
    '\n 4 = the image was DEFINITELY a scene. \n\n Let''s try an example.'];
text_testInstruction9 = ['After each response you will be presented with a series of stars, like this: \n \n *   *   * \n \n  Using the botton box, '...
        'please indicate how many stars you see on the screen. Here, the correct answer is ''3.'''];

%Create test practice text
text_testPractice1 = ['The symbol ''O'' represents an old word and the symbol ''N'' represents a new word. The number of O''s or N''s represent '...
    'how confident you are in that choice. For example, below you see: \n \n OO \n \n so the correct response would be pressing the ''4'' key, or ''Definitely Old.'''];
text_testPractice2 = 'Let''s try a few more examples.';
text_testPractice3 = ['The symbol ''F'' represents word seen with a face and the symbol ''S'' represents a word seen with a scene. The number of F''s or S''s represent '...
    'how confident you are in that choice. For example, below you see: \n \n S \n \n so the correct response would be pressing the ''3'' key, or ''Probably Scene.'''];
text_testPractice4 = 'Let''s try a few more examples.';

%Create practice trial text
p.text_test1 = '1                      2                      3                      4';
p.text_test2 = 'Definitely          Probably               Probably         Definitely';
p.text_test3item = 'New                  New                     Old                   Old';
p.text_test3source = 'Face                 Face                    Scene               Scene';

%Placement of Test text
p.tCenterTest1 = [p.xCenter-RectWidth(Screen('TextBounds', p.window, p.text_test1))/2  p.windowRect(4)*.68+40];
p.tCenterTest2 = [p.xCenter-RectWidth(Screen('TextBounds', p.window, p.text_test2))/2  p.windowRect(4)*.76+40];
p.tCenterTest3item = [p.xCenter-RectWidth(Screen('TextBounds', p.window, p.text_test3item))/2  p.windowRect(4)*.8+40];
p.tCenterTest3source = [p.xCenter-RectWidth(Screen('TextBounds', p.window, p.text_test3source))/2  p.windowRect(4)*.8+40];

%create null task stimuli probs for test phase 
Pisi = [.5 .375 .125];
isiLength = [2 3 4];

% encoding null trials 
allITprac1Data = cell2table(cell(0,12), 'VariableNames',{'SubNum','Session','Test','Stars','EncodingBlockTrial','Response','RT','Accuracy','TrialUp','RespDelay','TrialDown','TrialDuration'});
allITprac2Data = cell2table(cell(0,12), 'VariableNames',{'SubNum','Session','Test','Stars','EncodingBlockTrial','Response','RT','Accuracy','TrialUp','RespDelay','TrialDown','TrialDuration'});

%Create End text + placement
text_End1 = 'Congratulations! You have finished the practice! \n \n You will now complete the actual experiment in the scanner.';

%% Run Experiment
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
ListenChar(0);
p.startStudy = GetSecs;

KbQueueCreate(device,p.keys_Navigation);
% Test Phase Instructions for Possible New Words
while 1
    %Presenting Instructions
    DrawFormattedText(p.window, text_testInstruction2, 'center', 'center', p.textColor, p.wrapat, 0, 0, 2);
    DrawFormattedText(p.window, p.text_space, 'center', p.tCenterSpace(2), p.textColor);  %space bar prompt
    Screen('Flip', p.window);
    
    WaitSecs(p.respDelay); %Try to make sure they read it, instead of just clicking
    KbQueueStart; %Start listening to input after wait time
    [pressed, resp] = KbQueueCheck;
    if pressed
        if resp(KbName('Escape')); sca; return; end
        if resp(KbName('space')) %Space ends while loop for next screen flip
            break;
        end
    end
end
KbQueueStop;

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%star task instructions 
while 1
    %Presenting Instructions
    DrawFormattedText(p.window, text_testInstruction9, 'center', 'center', p.textColor, p.wrapat, 0, 0, 2);
    DrawFormattedText(p.window, p.text_space, 'center', p.tCenterSpace(2), p.textColor);  %space bar prompt
    Screen('Flip', p.window);
    
    WaitSecs(p.respDelay); %Try to make sure they read it, instead of just clicking
    KbQueueStart; %Start listening to input after wait time
    [pressed, resp] = KbQueueCheck;
    if pressed
        if resp(KbName('Escape')); sca; return; end
        if resp(KbName('space')) %Space ends while loop for next screen flip
            break;
        end
    end
end
KbQueueStop;

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Test Phase Old/New Task Instructions
while 1
    %Presenting Instructions
    DrawFormattedText(p.window, text_testInstruction3, 'center', 'center', p.textColor, p.wrapat, 0, 0, 2);
    DrawFormattedText(p.window, p.text_space, 'center', p.tCenterSpace(2), p.textColor);  %space bar prompt
    Screen('Flip', p.window);
    
    WaitSecs(p.respDelay); %Try to make sure they read it, instead of just clicking
    KbQueueStart; %Start listening to input after wait time
    [pressed, resp] = KbQueueCheck;
    if pressed
        if resp(KbName('Escape')); sca; return; end
        if resp(KbName('space')) %Space ends while loop for next screen flip
            break;
        end
    end
end
KbQueueStop;

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Test Phase New Ratings Instructions
while 1
    %Presenting Instructions
    DrawFormattedText(p.window, text_testInstruction4, 'center', 'center', p.textColor, p.wrapat, 0, 0, 2);
    DrawFormattedText(p.window, p.text_space, 'center', p.tCenterSpace(2), p.textColor);  %space bar prompt
    Screen('Flip', p.window);
    
    WaitSecs(p.respDelay); %Try to make sure they read it, instead of just clicking
    KbQueueStart; %Start listening to input after wait time
    [pressed, resp] = KbQueueCheck;
    if pressed
        if resp(KbName('Escape')); sca; return; end
        if resp(KbName('space')) %Space ends while loop for next screen flip
            break;
        end
    end
end
KbQueueStop;

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Test Phase Old Ratings Instructions
while 1
    %Presenting Instructions
    DrawFormattedText(p.window, text_testInstruction5, 'center', 'center', p.textColor, p.wrapat, 0, 0, 2);
    DrawFormattedText(p.window, p.text_space, 'center', p.tCenterSpace(2), p.textColor);  %space bar prompt
    Screen('Flip', p.window);
    
    WaitSecs(p.respDelay); %Try to make sure they read it, instead of just clicking
    KbQueueStart; %Start listening to input after wait time
    [pressed, resp] = KbQueueCheck;
    if pressed
        if resp(KbName('Escape')); sca; return; end
        if resp(KbName('space')) %Space ends while loop for next screen flip
            break;
        end
    end
end
KbQueueStop;

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Test Phase Old/New Practice Instructions
while 1
    %Presenting Instructions
    DrawFormattedText(p.window, text_testPractice1, 'center', 'center', p.textColor, p.wrapat, 0, 0, 2);
    DrawFormattedText(p.window, p.text_space, 'center', p.tCenterSpace(2), p.textColor);  %space bar prompt
    Screen('Flip', p.window);
    
    WaitSecs(p.respDelay); %Try to make sure they read it, instead of just clicking
    KbQueueStart; %Start listening to input after wait time
    [pressed, resp] = KbQueueCheck;
    if pressed
        if resp(KbName('Escape')); sca; return; end
        if resp(KbName('space')) %Space ends while loop for next screen flip
            break;
        end
    end
end
KbQueueStop;

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Test Phase Practice Start
while 1
    %Presenting Instructions
    DrawFormattedText(p.window, text_testPractice2, 'center', 'center', p.textColor, p.wrapat, 0, 0, 2);
    DrawFormattedText(p.window, p.text_begin, 'center', p.tCenterSpace(2), p.textColor);  %space bar prompt
    Screen('Flip', p.window);
    
    WaitSecs(p.respDelay); %Try to make sure they read it, instead of just clicking
    KbQueueStart; %Start listening to input after wait time
    [pressed, resp] = KbQueueCheck;
    if pressed
        if resp(KbName('Escape')); sca; return; end
        if resp(KbName('space')) %Space ends while loop for next screen flip
            break;
        end
    end
end
KbQueueStop;

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% RUN PRAC ON SCRIPT
test = 1; timing = 1; % test = O/N (1), timing = use p.startStudy
reps = 3; %this will change how many times each symbol is shown (3 times, for 12 trials total)
practiceConfData1 = cell2table(cell(0,14), 'VariableNames',{'SubNum','Session','Test','Stimulus','Answer','Response','Accuracy','RT','TrialUp','RespDelay','TrialDown','RespExtend','TrialDuration','ISItrials'});

confPracPhases; %run the script
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

% Transition to Next Test Phase Face/Scene Task Instructions
KbQueueCreate(device,p.keys_Navigation);
while 1
    %Presenting Instructions
    DrawFormattedText(p.window, 'Great work!', 'center', 'center', p.textColor, p.wrapat, 0, 0, 2);
    DrawFormattedText(p.window, p.text_space, 'center', p.tCenterSpace(2), p.textColor);  %space bar prompt
    Screen('Flip', p.window);
    
    WaitSecs(p.respDelay);
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

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Test Phase Face/Scene Practice Instructions
while 1
    %Presenting Instructions
    DrawFormattedText(p.window, text_testInstruction6, 'center', 'center', p.textColor, p.wrapat, 0, 0, 2);
    DrawFormattedText(p.window, p.text_space, 'center', p.tCenterSpace(2), p.textColor);  %space bar prompt
    Screen('Flip', p.window);
    
    WaitSecs(p.respDelay); %Try to make sure they read it, instead of just clicking
    KbQueueStart; %Start listening to input after wait time
    [pressed, resp] = KbQueueCheck;
    if pressed
        if resp(KbName('Escape')); sca; return; end
        if resp(KbName('space')) %Space ends while loop for next screen flip
            break;
        end
    end
end
KbQueueStop;

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Test Phase Face Ratings Practice Instructions
while 1
    %Presenting Instructions
    DrawFormattedText(p.window, text_testInstruction7, 'center', 'center', p.textColor, p.wrapat, 0, 0, 2);
    DrawFormattedText(p.window, p.text_space, 'center', p.tCenterSpace(2), p.textColor);  %space bar prompt
    Screen('Flip', p.window);
    
    WaitSecs(p.respDelay);
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

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Test Phase Scene Ratings Practice Instructions
while 1
    %Presenting Instructions
    DrawFormattedText(p.window, text_testInstruction8, 'center', 'center', p.textColor, p.wrapat, 0, 0, 2);
    DrawFormattedText(p.window, p.text_space, 'center', p.tCenterSpace(2), p.textColor);  %space bar prompt
    Screen('Flip', p.window);
    
    WaitSecs(p.respDelay); %Try to make sure they read it, instead of just clicking
    KbQueueStart; %Start listening to input after wait time
    [pressed, resp] = KbQueueCheck;
    if pressed
        if resp(KbName('Escape')); sca; return; end
        if resp(KbName('space')) %Space ends while loop for next screen flip
            break;
        end
    end
end
KbQueueStop;

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Test Phase Scene/Face Practice Instructions 2
while 1
    %Presenting Instructions
    DrawFormattedText(p.window, text_testPractice3, 'center', 'center', p.textColor, p.wrapat, 0, 0, 2);
    DrawFormattedText(p.window, p.text_space, 'center', p.tCenterSpace(2), p.textColor);  %space bar prompt
    Screen('Flip', p.window);
    
    WaitSecs(p.respDelay); %Try to make sure they read it, instead of just clicking
    KbQueueStart; %Start listening to input after wait time
    [pressed, resp] = KbQueueCheck;
    if pressed
        if resp(KbName('Escape')); sca; return; end
        if resp(KbName('space')) %Space ends while loop for next screen flip
            break;
        end
    end
end
KbQueueStop;

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Test Phase Practice Start 2
while 1
    %Presenting Instructions
    DrawFormattedText(p.window, text_testPractice4, 'center', 'center', p.textColor, p.wrapat, 0, 0, 2);
    DrawFormattedText(p.window, p.text_begin, 'center', p.tCenterSpace(2), p.textColor);  %space bar prompt
    Screen('Flip', p.window);
    
    WaitSecs(p.respDelay); %Try to make sure they read it, instead of just clicking
    KbQueueStart; %Start listening to input after wait time
    [pressed, resp] = KbQueueCheck;
    if pressed
        if resp(KbName('Escape')); sca; return; end
        if resp(KbName('space')) %Space ends while loop for next screen flip
            break;
        end
    end
end
KbQueueStop;

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% RUN PRACTICE SF SCRIPT
test = 2; %test = S/F 
practiceConfData2 = cell2table(cell(0,14), 'VariableNames',{'SubNum','Session','Test','Stimulus','Answer','Response','Accuracy','RT','TrialUp','RespDelay','TrialDown','RespExtend','TrialDuration','ISItrials'});
confPracPhases; %run the script

%save one file with all confidence practice data and ISI data 
practiceConfData = [practiceConfData1; practiceConfData2];
practiceNullTask = [allITprac1Data; allITprac2Data];
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

% Transition to Actual scanner Experiment
KbQueueCreate(device,p.keys_Navigation);
while 1
    %Presenting Instructions
    DrawFormattedText(p.window, 'Great work!', 'center', 'center', p.textColor, p.wrapat, 0, 0, 2);
    DrawFormattedText(p.window, p.text_space, 'center', p.tCenterSpace(2), p.textColor);  %space bar prompt
    Screen('Flip', p.window);
    
    WaitSecs(p.respDelay); %Try to make sure they read it, instead of just clicking
    KbQueueStart; %Start listening to input after wait time
    [pressed, resp] = KbQueueCheck;
    if pressed
        if resp(KbName('Escape')); sca; return; end
        if resp(KbName('space')) %Space ends while loop for next screen flip
            break;
        end
    end
end
KbQueueStop;

ListenChar(1); %start collecting keyboard input again

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% End Experiment
%Presenting Instructions
DrawFormattedText(p.window, text_End1,'center', 'center', p.textColor, p.wrapat, 0, 0, 2);

Screen('Flip', p.window);
WaitSecs(5);

%% save data
% double check if a file already exists under this name
fName = fullfile(p.pracRoot, 'Subject Data/miniPracData', ['Subject', p.subNum, '_Practice_Session', num2str(p.sess), '.mat']); %mat file name everything will be saved in

if exist(fName,'file')
   fName = fullfile(p.pracRoot, 'Subject Data/miniPracData', ['Subject', p.subNum, '_Practice_Session', num2str(p.sess), '_CONFLICT.mat']);
end
 
save(fName, 'practiceConfData','practiceNullTask','p');
sca %end experiment