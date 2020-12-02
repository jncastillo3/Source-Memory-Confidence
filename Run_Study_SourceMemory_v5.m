%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%% Source Memory_v3
%% July 2017 DMW: Study looking at source memory confidence ratings with 
% increased item memory strength
%% October 2017 DMW: adjusted GUI to double-check responses
% now loads participant file list with session #
% and GIANT stimSeq for each participant
%% November 2017 DMW: Rearranged order of encoding sessions (source then recall)
% Only one session (instead of multi-session), so enter in participant
% number and corrected RT to match first response given (instead of
% earliest key in que). Surprise test phase!
%% February 2019 DMW: (1) change confidence scale to 4-points (from 6)
% (2) separate testing phase (both item & scene) into blocks
% (3) provide feedback after testing blocks (re: HC accuracy & strategy)
% (4) emphasize incorrect HC really bad in beginning
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

close all; clc; clear; 
sca
clear PsychImaging

%% Establish needed files and directory
fileFolder = fileparts(mfilename('fullpath'));

cd(fileFolder) % Set wd  
p.root = pwd;

if ~exist([p.root, '\Subject Data\'], 'dir') %If subject data folder doesn't exist in working directory, create folder
    mkdir([p.root, '\Subject Data\']);
end

participantListfName = fullfile(p.root, 'Subject Data', 'ParticipantList.mat'); %Create participant list file name

if exist(participantListfName,'file') %If subject participant list file doesn't exist in working directory, create file
    load(participantListfName)
else
    participantList = table(zeros(200,1), cell(200,1), zeros(200,1), cell(200,1), cell(200,1), cell(200,1), zeros(200,1), cell(200,1),...
        'VariableNames',{'SubNum', 'Email', 'Session', 'Computer', 'Date', 'Credit', 'Age', 'Gender'}); %Create participant list if it doesn't yet exist
    save(participantListfName, 'participantList');
end

fNameStimSequence = fullfile(p.root, 'Subject Data', 'allSubject_SourceMemory_StimSeq.mat'); %Get allSubsStimSeq file for specific subject indexing below
load(fNameStimSequence)

p.root = pwd;
%% Function inputs
debug = 0; %Want to debug (speeds it up) = 1
screen = 0; %For multiple screens = 1
refresh = 60; %Refresh rate for my laptop = 60, lab computers = 120

if debug == 1 %Speeds up presentation time if just debugging
    instructionDur = .01;
    p.studyDur = .01;
    p.blankDur = .01;
    p.feedback = .01;
    p.testDur = .01;
    p.nCycles = 2;
elseif debug ==0
    instructionDur = .5; %Wait for response
    p.studyDur = 2; %Stimulus duration in seconds (2000ms) --> Matches Starns & Ksander
    p.blankDur = .1; %Blank screen in between stimuli during study (100ms) --> Matches Starns & Kasander
    p.feedback = 1;   %Feedback time during study session
    p.testDur = .5;
end

x = rng('shuffle');
p.rndSeed = x.Seed;

%% Set up prompt & save new date to participantList
% Create GUI and get subject number & other info recorded in
% participantList file
prompt = {'Subject number', 'Email', 'Age', 'SONA credit?'}; %GUI answer box prompts
defAns = {'', '@umass.edu', '18', 'y'}; %Fill in stock answers to the gui input boxes

validated = false; %Keep running GUI until participant confirms correct information
while ~validated
    box = inputdlg(prompt,'Enter Your Information...', 1, defAns); %Prompt at top of GUI
    p.subNum = box{1};
    p.email = box{2};
    p.age=str2double(box{3});
    p.credit=box{4};
    
    emailExist = strcmp(p.email, participantList.Email); %check to see if email exists in participant list
    if any(emailExist)
        p.sess = 2;
        %p.subNum = unique(participantList.SubNum(emailExist));
    else
        p.sess = 1;
        %p.subNum = max(participantList.SubNum) + 1;
    end
    
    accept = confirmation_dialog(p.subNum, p.email, p.sess);
    if accept
        validated = true;
    end
    
end

p.gender = Demographics(p.subNum, p.sess); %Calls Demographics script that puts up GUI calling for demographic info and saves it in a .txt file
[~, p.hostname] = system('hostname'); %Record computer experiment is on

%Add data as new line in participantList and save
lastEntry = find(participantList.SubNum,1,'last'); %Find the last nonzero element in SubNum
if isempty(lastEntry)
    nextLine = 1; %If there isn't a nonzero element in SubNum, start entry on line one
else
    nextLine = lastEntry +1; %If there is a nonzero element, + 1 for next line to be filled
end

participantList.SubNum(nextLine) = str2double(p.subNum);
participantList.Email(nextLine) = {p.email};
participantList.Session(nextLine) = p.sess;
participantList.Computer(nextLine) = cellstr(p.hostname);
participantList.Date(nextLine) = {date};
participantList.Credit(nextLine) = {p.credit};
participantList.Age(nextLine) = p.age;
participantList.Gender(nextLine) = {p.gender(6:end)};
save(participantListfName, 'participantList');

%% Create stimuli sequence for specific subject and session
subjectSubsetEncodingList = allSubsEncoding(allSubsEncoding.Sub == str2double(p.subNum),:);
encodingList = subjectSubsetEncodingList(subjectSubsetEncodingList.Session == p.sess,:);

subjectSubsetRecogList = allSubsRecog(allSubsRecog.Sub == str2double(p.subNum),:);
recogList = subjectSubsetRecogList(subjectSubsetRecogList.Session == p.sess,:);

%% Response keys
PsychDefaultSetup(2); %Sets up some defaults (e.g. UnifyingNames etc.)
KbName('UnifyKeyNames');

% for QUEUE routines
p.key_escape = zeros(1,256);
p.key_escape(KbName({'Escape'})) = 1;

p.keys_Navigation = zeros(1,256);
p.keys_Navigation(KbName({'return','space','delete','Escape'})) = 1;

p.keys_confidence = zeros(1,256);
p.keys_confidence(KbName({'1','2','3','4','Escape'})) = 1;

% originally, f = faces, s = scene. Now, 1 = face, 2 = scene
p.keys_studySource = zeros(1,256);
p.keys_studySource(KbName({'1','2', 'Escape'})) = 1;

p.keys_source = zeros(1,256);
p.keys_source(KbName({'1','2','3','4','Escape'})) = 1;

% p.keys_recall = zeros(1,256);
% p.keys_recall(KbName({'a','b','c','d','e','f','g','h','i','j','k','l','m', ...
%     'n','o','p','q','r','s','t','u','v','w','x','y','z', ...
%     'backspace', 'return', 'Escape'})) = 1;

% for indexing
p.space = KbName('space');
p.return = KbName('return');
p.escape = KbName('Escape');
p.confidence = KbName({'1!','2@','3#','4$','Escape'});
p.studySource = KbName({'1!', '2@', 'Escape'});
p.source = KbName({'1!','2@','3#','4$','Escape'});
% p.recall = KbName({'a','b','c','d','e','f','g','h','i','j','k','l','m', ...
%     'n','o','p','q','r','s','t','u','v','w','x','y','z', ...
%     'backspace', 'return', 'Escape'});

%% Presentation Parameters
p.windowColor = [0 0 0];
%p.windowColor = [255 255 255];
p.whichScreen = screen; %=1 if using other monitor, =0 if just laptop, IF CHANGING THIS NEED TO CHANGE REFRESH RATE TOO PROBABLY!!
Screen('Preference','SkipSyncTests', 1) %for now, skip sync tests 
[p.window, p.windowRect] = Screen('OpenWindow', p.whichScreen, p.windowColor);
HideCursor; %If debugging and need cursor back: ShowCursor

% compute and store the center of the screen: p.windowRect contains the upper
% left coordinates (x,y) and the lower right coordinates (x,y)
p.xCenter = (p.windowRect(3) - p.windowRect(1))/2;
p.yCenter = (p.windowRect(4) - p.windowRect(2))/2;
p.center = [(p.windowRect(3) - p.windowRect(1))/2, (p.windowRect(4) - p.windowRect(2))/2];

% test the refresh properties of the display
p.RefreshRate = refresh;
p.fps=Screen('FrameRate',p.window);          % frames per second
p.ifi=Screen('GetFlipInterval', p.window);   % inter-frame-interval
p.waitframes = 1;
p.waitduration = p.waitframes * p.ifi;
if p.fps==0         %If fps does not register, then set the fps based on ifi
    p.fps=1/p.ifi;
end
% Translate the stim duration parameter into units of refresh rate
%each trial is ~2000 msec long, divided into xx frames lasting xx msec each
%Present [nFrames] 'stills' in every trial
p.frame_dur = p.ifi*1000; %frame duration in ms
p.nStudyStills = round(p.studyDur*1000/p.frame_dur); %Study presentation time 30 16.67
p.nBlankStills = round(p.blankDur*1000/p.frame_dur); %Blank/test presentation time
p.nFeedbackStills = round(p.feedback*1000/p.frame_dur); %Feedback presentation time
p.nTestStills = round(p.testDur*1000/p.frame_dur); %Test presentation time

% check that the actual refresh rate is what we expect it to be.
if abs(p.fps-p.RefreshRate)>5
    sca;
    disp('Set the refresh rate to the requested rate')
    clc;
    return;
end

% font parameters --------------------------------------
p.fontSize = 24;
%p.textColor = [50 50 50]; %p.LUT(end,:);  % black
p.textColor = [255 255 255]; %p.LUT(end,:);  % white
p.wrapat=80;
p.indent=400;

% set up the font
Screen('TextFont',p.window, 'Arial');
Screen('TextSize',p.window, p.fontSize);
Screen('TextStyle', p.window, 0);
Screen('TextColor', p.window, p.textColor);

%% Required Images
% this needs to be updated. We can either create a loop that will randomly
% select one face/scene for each subject. Or, we can have these set up in
% advance so that it chooses the face/scene per session. 

% predefine all of the images for each counterbalance session here. Then
% create a loop that will randomly select one pair of images for each
% session without replacement. Do this in CreateStim. 

% example scene for instructions
filenameSceneExample=strcat(p.root, '/ImageStimuli/Scene41.jpg');
matrixSceneExample = importdata(filenameSceneExample);
[sceneExampleHeight, sceneExampleWidth, x]= size(matrixSceneExample);
texture_SceneExample = Screen('MakeTexture', p.window, matrixSceneExample);

%scene 1
filenameScene=strcat(p.root, '/ImageStimuli/Scene11.jpg');
matrixScene = importdata(filenameScene);
[sceneHeight, sceneWidth, x]= size(matrixScene);
texture_Scene = Screen('MakeTexture', p.window, matrixScene);

%face 1 
filenameFace=strcat(p.root, '/ImageStimuli/CFD-WM-257-161-N_resized2.jpg');
matrixFace = importdata(filenameFace);
[faceHeight, faceWidth, x]= size(matrixFace);
texture_Face = Screen('MakeTexture', p.window, matrixFace);

%% Required Text
%Create space and enter text
p.text_space = '[Press Space Bar to continue]';
p.text_enter = '[Press Enter to continue]';
% Placement of space and enter text
p.tCenterSpace = [p.xCenter-RectWidth(Screen('TextBounds', p.window, p.text_space))/2  p.windowRect(4)*.8+40];
p.tCenterEnter = [p.xCenter-RectWidth(Screen('TextBounds', p.window, p.text_enter))/2  p.windowRect(4)*.8+40];

%Create study instructions text
text_studyInstruction1 = ['This is a memory test. Several short lists of words will appear on the screen either paired with an image'...
    ' or alone. When these words first appear no response is necessary, just pay close attention. After the first presentation, there will be a short test.'];
% text_studyInstruction2 = ['If a word list was shown alone, then you will be asked to fill in the blanks when the first'...
     % ' letter of the word is given to create a word you have just seen. Here is an example.'];
text_studyInstruction3 = ['In this test, you will be asked to identify which image appeared with the word'...
    ' Here is an example.'];

%Create study example text
% text_studyExample1 = ['You saw the word: \n \n crocodile \n \n and later you are asked to fill in the blanks of the following word: \n \n c _ _ _ _ _ _ _ _'...
     % '\n \n Correct answer: crocodile'];
text_studyExample2 = ['If you saw the following image-word pair: \n \n \n \n \n \n and later you are asked if the word was seen with a \n face'...
    ' (''1'' key) or scene (''2'' key). Correct answer: 2'];
text_studyExample3 = 'crocodile';

%Create test instructions text
text_testInstruction1 = 'You will be given the correct answer after each of your responses.';
text_testInstruction2 = ['Great work! There will now be two surprise final memory tests. Each test will present a long list of words on the screen. Some of the words you will have seen '...
    'during the first phase of the experiment and other words will be new.'];
text_testInstruction3 = ['First, you will be asked to rate your confidence that the current word on the screen is an old or new word '...
    'with the numbered keys 1-4.'];
text_testInstruction4 = ['If you think the word is new, you will use the keys 1 and 2 \n \n  where 1 = the word is definitely new '...
    '\n and 2 = the word is probably new'];
text_testInstruction5 = ['If you think the word is old, you will use the keys 3 and 4 \n \n '...
    '\n where 3 = the word is probably old \n 6 = the word is definitely old \n\n Let''s try an example.'];

%Create test practice text
text_testPractice1 = ['The symbol ''O'' represents an old word and the symbol ''N'' represents a new word. The number of O''s or N''s represent '...
    'how confident you are in that choice. For example, below you see: \n \n OO \n \n so the correct response would be pressing the ''4'' key.'];
text_testPractice2 = 'Let''s try a few more examples.';

%Create test instructions text Part 2
text_testInstruction6 = 'Then you will be asked to rate your confidence that the current word on the screen was previously seen with an image of a face or a scene.';
text_testInstruction7 = ['If you think the word was seen with a face, you will use the keys 1 and 2 \n \n  1 = the image was definitely a face '...
    '\n 2 = the image was probably a face'];
text_testInstruction8 = ['If you think the word was seen with a scene, you will use the keys 3 and 4 \n \n 3 = the image was probably a scene '...
    '\n 4 = the image was definitely a scene. \n\n Let''s try an example.'];

%Create test practice text Part 2
text_testPractice3 = ['The symbol ''F'' represents word seen with a face and the symbol ''S'' represents a word seen with a scene. The number of F''s or S''s represent '...
    'how confident you are in that choice. For example, below you see: \n \n S \n \n so the correct response would be pressing the '','' key.'];
text_testPractice4 = 'Let''s try a few more examples.';

%Create Questions? Begin! text
text_Questions = 'Any questions?';
text_Begin = 'If not, lets begin.';
%Placement of Questions? Begin! text
tCenterQuestions = [p.xCenter-RectWidth(Screen('TextBounds', p.window, text_Questions))/2  p.yCenter-160];
tCenterBegin = [p.xCenter-RectWidth(Screen('TextBounds', p.window, text_Begin))/2  p.yCenter-90];

%Create Study text
text_study1 = '1                    2                                  3                    4';
text_study2 = 'Definitely             Probably                      Probably              Definitely';
text_study3 = 'Face                    Face                         Scene                 Scene';

%Placement of Study text
tCenterStudy1 = [p.xCenter-RectWidth(Screen('TextBounds', p.window, text_study1))/2  p.windowRect(4)*.68+40];
tCenterStudy2 = [p.xCenter-RectWidth(Screen('TextBounds', p.window, text_study2))/2  p.windowRect(4)*.76+40];
tCenterStudy3 = [p.xCenter-RectWidth(Screen('TextBounds', p.window, text_study3))/2  p.windowRect(4)*.8+40];

%Create Test text
text_test1 = '1                2             3               4';
text_test2 = 'Definitely New                      Definitely Old';
%Placement of Test text
tCenterTest1 = [p.xCenter-RectWidth(Screen('TextBounds', p.window, text_test1))/2  p.windowRect(4)*.72+40];
tCenterTest2 = [p.xCenter-RectWidth(Screen('TextBounds', p.window, text_test2))/2  p.windowRect(4)*.8+40];

%Create reminder of 'f' and 's' responses
text_encoding1 = 'Scene                                            Face';
text_encoding2 = '[Press ''1'']                                 [Press ''2'']';
tCenterEncoding1 = [p.xCenter-RectWidth(Screen('TextBounds', p.window, text_encoding1))/2  p.windowRect(4)*.72+40];
tCenterEncoding2 = [p.xCenter-RectWidth(Screen('TextBounds', p.window, text_encoding2))/2  p.windowRect(4)*.8+40];

%Create End text
text_End1 = 'Congratulations! You have finished the experiment!';
text_End2 = 'Thank you for your participation.';
%Placement of End text
tCenterEnd1 = [p.xCenter-RectWidth(Screen('TextBounds', p.window, text_End1))/2  p.yCenter-160];
tCenterEnd2 = [p.xCenter-RectWidth(Screen('TextBounds', p.window, text_End2))/2  p.yCenter-90];

%% Run Experiment
KbQueueCreate(1, p.keys_Navigation);
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Study Phase General Instructions

while 1
    %Presenting Instructions
    DrawFormattedText(p.window, text_studyInstruction1, 'center', 'center', p.textColor, p.wrapat, 0, 0, 2);
    DrawFormattedText(p.window, p.text_space, 'center', p.tCenterSpace(2), p.textColor);  %space bar prompt
    Screen('Flip', p.window);
    
    KbQueueCreate;
    KbQueueStart; %Start listening to input after wait time
    WaitSecs(instructionDur); %Try to make sure they read it, instead of just clicking
    [pressed, resp] = KbQueueCheck;
    if pressed
        if resp(KbName('Escape')); sca; return; end
        if resp(p.space) %Space ends while loop for next screen flip
            break;
        end
    end
    
end
KbQueueStop;
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Study Phase Source Instructions
while 1
    %Presenting Instructions
    DrawFormattedText(p.window, text_studyInstruction3, 'center', 'center', p.textColor, p.wrapat, 0, 0, 2);
    DrawFormattedText(p.window, p.text_space, 'center', p.tCenterSpace(2), p.textColor);  %space bar prompt
    Screen('Flip', p.window);
    
    WaitSecs(instructionDur); %Try to make sure they read it, instead of just clicking
    KbQueueStart; %Start listening to input after wait time
    [pressed, resp] = KbQueueCheck;
    if pressed
        if resp(KbName('Escape')); sca; return; end
        if resp(p.space) %Space ends while loop for next screen flip
            break;
        end
    end
    
end
KbQueueStop;
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Study Phase Source Example
while 1
    %Presenting Instructions
    DrawFormattedText(p.window, text_studyExample2, 'center', 'center', p.textColor, p.wrapat, 0, 0, 2);
    DrawFormattedText(p.window, p.text_space, 'center', p.tCenterSpace(2), p.textColor);  %space bar prompt
    DrawFormattedText(p.window, text_studyExample3, p.xCenter+50, p.yCenter, p.textColor);
    Screen('DrawTexture', p.window, texture_SceneExample , [], [p.xCenter-50-(sceneWidth/3) p.yCenter-120 p.xCenter-50  p.yCenter-120+(sceneHeight/3)]);
    Screen('DrawingFinished', p.window);
    Screen('Flip', p.window);
    
    WaitSecs(instructionDur); %Try to make sure they read it, instead of just clicking
    KbQueueStart; %Start listening to input after wait time
    [pressed, resp] = KbQueueCheck;
    if pressed
        if resp(KbName('Escape')); sca; return; end
        if resp(p.space) %Space ends while loop for next screen flip
            break;
        end
    end
    
end
KbQueueStop;

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Study Phase Recall Instructions
% while 1
%     %Presenting Instructions
%     DrawFormattedText(p.window, text_studyInstruction2, 'center', 'center', p.textColor, p.wrapat, 0, 0, 2);
%     DrawFormattedText(p.window, p.text_space, 'center', p.tCenterSpace(2), p.textColor);  %space bar prompt
%     Screen('Flip', p.window);
%     
%     WaitSecs(instructionDur); %Try to make sure they read it, instead of just clicking
%     KbQueueStart; %Start listening to input after wait time
%     [pressed, resp] = KbQueueCheck;
%     if pressed
%         if resp(KbName('Escape')); sca; return; end
%         if resp(p.space) %Space ends while loop for next screen flip
%             break;
%         end
%     end
%     
% end
% KbQueueStop;
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% % Study Phase Recall Example
% while 1
%     %Presenting Instructions
%     DrawFormattedText(p.window, text_studyExample1, 'center', 'center', p.textColor, p.wrapat, 0, 0, 2);
%     DrawFormattedText(p.window, p.text_space, 'center', p.tCenterSpace(2), p.textColor);  %space bar prompt
%     Screen('Flip', p.window);
%     
%     WaitSecs(instructionDur); %Try to make sure they read it, instead of just clicking
%     KbQueueStart; %Start listening to input after wait time
%     [pressed, resp] = KbQueueCheck;
%     if pressed
%         if resp(KbName('Escape')); sca; return; end
%         if resp(p.space) %Space ends while loop for next screen flip
%             break;
%         end
%     end
%     
% end
% KbQueueStop;

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% End of Study Phase Instructions
while 1
    %Presenting Instructions
    DrawFormattedText(p.window, text_testInstruction1, 'center', 'center', p.textColor, p.wrapat, 0, 0, 2);
    DrawFormattedText(p.window, p.text_space, 'center', p.tCenterSpace(2), p.textColor);  %space bar prompt
    Screen('Flip', p.window);
    
    WaitSecs(instructionDur); %Try to make sure they read it, instead of just clicking
    KbQueueStart; %Start listening to input after wait time
    [pressed, resp] = KbQueueCheck;
    if pressed
        if resp(KbName('Escape')); sca; return; end
        if resp(p.space) %Space ends while loop for next screen flip
            break;
        end
    end
    
end
KbQueueStop;

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Last time to check in
while 1
    %Presenting Instructions
    DrawFormattedText(p.window, 'If you have any questions, please notify the experimenter at this time.', 'center', 'center', p.textColor,  p.wrapat, 0, 0, 2); % "If you have any questions"
    DrawFormattedText(p.window, p.text_space, 'center', p.tCenterSpace(2), p.textColor);  % space bar prompt
    
    Screen('Flip', p.window);
    WaitSecs(instructionDur); %Try to make sure they read it, instead of just clicking
    KbQueueStart; %Start listing to input after wait time
    
    [pressed, resp] = KbQueueCheck;
    if pressed
        if resp(KbName('Escape')); sca; return; end
        if resp(p.space) %Space ends while loop for next screen flip
            break;
        end
    end
    
end
KbQueueStop;

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% The experiment will now begin
while 1
    %Presenting Instructions
    DrawFormattedText(p.window, 'The experiment will now begin.', 'center', 'center', p.textColor,  p.wrapat, 0, 0, 2); % "If you have any questions"
    DrawFormattedText(p.window, p.text_space, 'center', p.tCenterSpace(2), p.textColor);  % space bar prompt
    
    Screen('Flip', p.window);
    WaitSecs(instructionDur); %Try to make sure they read it, instead of just clicking
    KbQueueStart; %Start listing to input after wait time
    
    [pressed, resp] = KbQueueCheck;
    if pressed
        if resp(KbName('Escape')); sca; return; end
        if resp(p.space) %Space ends while loop for next screen flip
            break;
        end
    end
    
end
KbQueueStop;

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%Encoding phase cycled over n times

%Organize encoding stimuli for indexing during cycles
encodingAstimuli = encodingList(ismember(encodingList.Block, 'encodingA'),:);
%encodingBstimuli = encodingList(ismember(encodingList.Block, 'encodingB'),:);
encodingCstimuli = encodingList(ismember(encodingList.Block, 'encodingC'),:);
encodingDstimuli = encodingList(ismember(encodingList.Block, 'encodingD'),:);

encodingData = [];

for cycle = 1:p.nCycles
    %% Encoding PhaseC: Passive viewing
    
     KbQueueCreate(1, p.keys_Navigation);
     
    while 1
        %Presenting Instructions
        DrawFormattedText(p.window, 'Pay attention to the following words. No response is needed.', 'center', 'center', p.textColor,  p.wrapat, 0, 0, 2); % "If you have any questions"
        DrawFormattedText(p.window, p.text_space, 'center', p.tCenterSpace(2), p.textColor);  % space bar prompt
        
        Screen('Flip', p.window);
        WaitSecs(instructionDur); %Try to make sure they read it, instead of just clicking
        KbQueueStart; %Start listing to input after wait time
        
        [pressed, resp] = KbQueueCheck;
        if pressed
            if resp(KbName('Escape')); sca; return; end
            if resp(p.space) %Space ends while loop for next screen flip
                break;
            end
        end
        
    end
    KbQueueStop;
    
    encodingCcycleStimuli = encodingCstimuli(ismember(encodingCstimuli.Cycle, cycle),:);
    
    KbQueueCreate(1,p.key_escape); %New queue
    
    now = GetSecs;
    start = now;
    for encodingCTrial = 1:max(encodingCcycleStimuli.BlockTrial)
        %Create text for viewing with stimuli for each trial
        text_encodingCStimuli = encodingCcycleStimuli.Word{encodingCTrial};
        %Selection of image
        if strcmp(char(encodingCcycleStimuli.Pair(encodingCTrial)), 'f')
            trialImage = texture_Face;
        else strcmp(char(encodingCcycleStimuli.Pair(encodingCTrial)), 's')
            trialImage = texture_Scene;
        end
        
        KbQueueStart; % start listening for input
        
        %Presenting Stimuli
        for presentation = 1:p.nStudyStills %Prsenting each word for a preset duration           
            DrawFormattedText(p.window, text_encodingCStimuli, p.xCenter+50, p.yCenter, p.textColor);
            Screen('DrawTexture', p.window, trialImage , [], [p.xCenter-50-(sceneWidth/3) p.yCenter-120 p.xCenter-50  p.yCenter-120+(sceneHeight/3)]);
            Screen('DrawingFinished', p.window);          
            now = Screen('Flip', p.window, now + (p.waitframes - 0.5) * p.ifi);
            [pressed, resp] = KbQueueCheck;
            if pressed
                if resp(KbName('Escape')); sca; return; end
            end
            
        end
        
        for presentation = 1:p.nBlankStills %Display a blank screen in between
            Screen('Flip', p.window);
        end
        
    end
    
    KbQueueStop;    
    
    %% Encoding PhaseD: Source with feedback
    
    KbQueueCreate(1,p.keys_Navigation);
    
    while 1
        %Presenting Instructions
        DrawFormattedText(p.window, 'Press ''1'' if the word was seen with a face and ''2'' if the word was seen with a scene.', 'center', 'center', p.textColor,  p.wrapat, 0, 0, 2); % "If you have any questions"
        DrawFormattedText(p.window, p.text_space, 'center', p.tCenterSpace(2), p.textColor);  % space bar prompt
        
        Screen('Flip', p.window);
        WaitSecs(instructionDur); %Try to make sure they read it, instead of just clicking
        KbQueueStart; %Start listing to input after wait time
        
        [pressed, resp] = KbQueueCheck;
        if pressed
            if resp(KbName('Escape')); sca; return; end
            if resp(p.space) %Space ends while loop for next screen flip
                break;
            end
        end
        
    end
    KbQueueStop;
    
    
    encodingDcycleStimuli = encodingDstimuli(ismember(encodingDstimuli.Cycle, cycle),:);
    
    for encodingDTrial = 1:max(encodingDcycleStimuli.BlockTrial)
        text_encodingDStimuli = encodingDcycleStimuli.Word{encodingDTrial}; %Create text for viewing with stimuli for each trial
        tCenterStudyStimuli = [p.xCenter-RectWidth(Screen('TextBounds', p.window, text_encodingDStimuli))/2  p.yCenter-40]; %Placement of stimuli for study
        
        KbQueueCreate(1,p.keys_studySource); %New queue
            
        for presentation = 1:p.nTestStills %Prsenting each word for a preset duration
            DrawFormattedText(p.window, text_encodingDStimuli, 'center', tCenterStudyStimuli(2), p.textColor); % "Cow"
            DrawFormattedText(p.window, text_encoding1, 'center', tCenterStudy1(2),[],p.wrapat,[],[],1.5); % "Face Scene"
            DrawFormattedText(p.window, text_encoding2, 'center', tCenterStudy2(2),[],p.wrapat,[],[],1.5); % "[Press 'f']      [Press 's']"
            Screen('DrawingFinished', p.window);
            now = Screen('Flip', p.window, now + (p.waitframes - 0.5) * p.ifi);
        end
        KbQueueStart;
        
        while 1
            [pressed, resp] = KbQueueCheck;
            if pressed              
                if resp(KbName('Escape')); sca; return;
                else any(resp(p.studySource))
                    encodingDcycleStimuli.Response(encodingDTrial) = cellstr(KbName(find(resp,1,'first')));
                    %encodingDcycleStimuli.RT(encodingDTrial) = num2cell(GetSecs - start);
                    break;
                end

            end
        end
        KbQueueStop;
        
        for presentation = 1:p.nBlankStills %Display a blank screen in between
            Screen('Flip', p.window);
        end
        
        for presentationFeedback = 1:p.nFeedbackStills
            
            if strcmp(char(encodingDcycleStimuli.Pair(encodingDTrial)), 'f')
                trialImage = texture_Face;
            else strcmp(char(encodingDcycleStimuli.Pair(encodingDTrial)), 's')
                trialImage = texture_Scene;
            end
            
            
            Screen('DrawTexture', p.window, trialImage, [], [p.xCenter-((sceneWidth/2)/2) p.yCenter-((sceneHeight/2)/2) p.xCenter+((sceneWidth/2)/2)  p.yCenter+((sceneHeight/2)/2)]);
            
            %CHECK OUT Screen('DrawTexture', p.window, texture_SceneExample , [], [p.xCenter-50-(sceneWidth/3) p.yCenter-120 p.xCenter-50  p.yCenter-120+(sceneHeight/3)]);

            Screen('DrawingFinished', p.window);
            Screen('Flip', p.window, now + (p.waitframes - 0.5) * p.ifi)
        end
        
        if strcmp(encodingDcycleStimuli.Pair(encodingDTrial), encodingDcycleStimuli.Response(encodingDTrial))
            encodingDcycleStimuli.Correct(encodingDTrial) = {1};
                        
        else
            encodingDcycleStimuli.Correct(encodingDTrial) = {0};
            
        end 
              
    end
    
    encodingDcycleStimuli(:,{'Block'}) = {'e_Source'};
                 
    encodingData = [encodingData; encodingDcycleStimuli]; %Save encodingD responses for each cycle
    
    KbQueueStop;   
    
    
    %% Encoding PhaseA: Passive viewing
    KbQueueCreate(1,p.keys_Navigation);
    
    while 1
        %Presenting Instructions
        DrawFormattedText(p.window, 'Pay attention to the following words. No response is needed.', 'center', 'center', p.textColor,  p.wrapat, 0, 0, 2); % "If you have any questions"
        DrawFormattedText(p.window, p.text_space, 'center', p.tCenterSpace(2), p.textColor);  % space bar prompt
        
        Screen('Flip', p.window);
        WaitSecs(instructionDur); %Try to make sure they read it, instead of just clicking
        KbQueueStart; %Start listing to input after wait time
        
        [pressed, resp] = KbQueueCheck;
        if pressed
            if resp(KbName('Escape')); sca; return; end
            if resp(p.space) %Space ends while loop for next screen flip
                break;
            end
        end
        
    end
    KbQueueStop;
    
    encodingAcycleStimuli = encodingAstimuli(ismember(encodingAstimuli.Cycle, cycle),:);
    
    KbQueueCreate(1,p.key_escape); %New queue
    
    now = GetSecs;
    start = now;
    for encodingATrial = 1:max(encodingAcycleStimuli.BlockTrial)
        %Create text for viewing with stimuli for each trial
        text_encodingAStimuli = encodingAcycleStimuli.Word{encodingATrial};
        %Placement of stimuli for study
        tCenterStudyStimuli = [p.xCenter-RectWidth(Screen('TextBounds', p.window, text_encodingAStimuli))/2  p.yCenter-40];
        
        KbQueueStart; % start listening for input
        
        %Presenting Stimuli
        for presentation = 1:p.nStudyStills %Prsenting each word for a preset duration
            DrawFormattedText(p.window, text_encodingAStimuli, 'center', tCenterStudyStimuli(2), p.textColor); % "Cow"
            Screen('DrawingFinished', p.window);
            now = Screen('Flip', p.window, now + (p.waitframes - 0.5) * p.ifi);
            [pressed, resp] = KbQueueCheck;
            if pressed
                if resp(KbName('Escape')); sca; return; end
            end
            
        end
        
        for presentation = 1:p.nBlankStills %Display a blank screen in between
            Screen('Flip', p.window);
        end
        
    end
    
    KbQueueStop;
    
    %% Encoding PhaseB: Recall with feedback
%     KbQueueCreate(1,p.keys_Navigation);
%     
%     while 1
%         %Presenting Instructions
%         DrawFormattedText(p.window, 'Fill in the missing letters to create a word you have just seen.', 'center', 'center', p.textColor,  p.wrapat, 0, 0, 2); % "If you have any questions"
%         DrawFormattedText(p.window, p.text_space, 'center', p.tCenterSpace(2), p.textColor);  % space bar prompt
%         
%         Screen('Flip', p.window);
%         WaitSecs(instructionDur); %Try to make sure they read it, instead of just clicking
%         KbQueueStart; %Start listing to input after wait time
%         
%         [pressed, resp] = KbQueueCheck;
%         if pressed
%             if resp(KbName('Escape')); sca; return; end
%             if resp(p.space) %Space ends while loop for next screen flip
%                 break;
%             end
%         end
%         
%     end
%     KbQueueStop;
%     
%     encodingBcycleStimuli = encodingBstimuli(ismember(encodingBstimuli.Cycle, cycle),:);
%     
%     for encodingBTrial = 1:max(encodingBcycleStimuli.BlockTrial)
%         text_encodingBStimuli = encodingBcycleStimuli.Word{encodingBTrial}; %Create text for viewing with stimuli for each trial
%         tCenterStudyStimuli = [p.xCenter-RectWidth(Screen('TextBounds', p.window, text_encodingBStimuli))/2  p.yCenter-40]; %Placement of stimuli for study
%         response = text_encodingBStimuli;
%         rt = [];
%         exitFlag = {'OK'};
%         slack = .5;
%         
%         KbQueueCreate(1,p.keys_recall); %New queue
%         
%         % first flip is occasionally missed.
%         vbl = Screen('Flip', p.window);
%         firstFlip = 1;
%         
%         % This while loop will attempt a flip at every refresh cycle. Super precise
%         % timing (wrt stimulus presentation, rather than response times) isn't
%         % generally an issue while the participant is making a response (e.g., if
%         % the last letter they typed takes a moment extra to display, they'll be
%         % fine). Still, this function often exits without dropping any flips!
%         
%         while 1
%             %responseText = char(response);
%             prompt = 'What studied word fills in the blanks? \n \n';
%             DrawFormattedText(p.window, prompt, 'center', tCenterQuestions(2),  p.textColor,  p.wrapat, 0, 0, 2);
%             DrawFormattedText(p.window, response, 'center', tCenterStudyStimuli(2), p.textColor); % "Cow"
%             DrawFormattedText(p.window, '[Press Enter to Continue]', 'center', p.tCenterSpace(2), p.textColor);
%             Screen('DrawingFinished', p.window);
%             
%             % timing information returned (trial start, reaction time), is in
%             % reference to when the prompt was first flipped to the participant.
%             vbl = Screen('Flip', p.window, vbl + (slack * p.ifi));
%             
%             if firstFlip
%                 tStart = vbl;
%                 KbQueueStart;
%                 firstFlip = 0;
%             end
%             
%             [pressed, resp] = KbQueueCheck;
%             if pressed
% %                 key_press_time = resp(resp~=0);
% %                 rt_curent = num2cell(key_press_time - tStart);
% %                 rt = [rt rt_current];
%                 if resp(p.return) % exit flag and empty responses
%                     exitFlag = {'Return'};
%                     emptyResp = {'Return'};
%                     keyName = emptyResp;
%                 elseif resp(p.escape)
%                     exitFlag = {'ESCAPE'};
%                     emptyResp = {'Escape'};
%                     keyName = emptyResp;
%                 elseif any(resp(p.recall))
%                     exitFlag = {'OK'};
%                     keyName = cellstr(KbName(find(resp, 1, 'first')));
%                 end
%                 
%                 switch keyName{1}
%                     case 'BackSpace'
%                         if ~strcmp(response(3), '_') %~isempty(response{1})
%                             %response = {response{1}(1:end-1)};
%                             if ~isempty(min(strfind(response, '_')))
%                                 response(min(strfind(response, '_'))-2) = '_';
%                             else
%                                 response(length(response)) = '_';
%                             end
%                         end
%                     case {'Return', 'ESCAPE'}
%                     otherwise
%                         %response = {[response{1}, keyName{1}]};
%                         if ~isempty(min(strfind(response, '_')))
%                             response(min(strfind(response, '_'))) = keyName{1};
%                         end
%                 end
%                 
%                 % extra switch necessary for robot trials, where the last response
%                 % might not be just Return
%                 switch exitFlag{1}
%                     case {'Return'}
%                         
%                         response(strfind(response, ' ')) = [];
%                         encodingBcycleStimuli.Response(encodingBTrial) = cellstr(response);
%                         
%                         if strcmp(encodingBcycleStimuli.Studied(encodingBTrial), encodingBcycleStimuli.Response(encodingBTrial))
%                             encodingBcycleStimuli.Correct(encodingBTrial) = {1};
%                         else
%                             encodingBcycleStimuli.Correct(encodingBTrial) = {0};
%                         end
%                         
%                         for presentationFeedback = 1:p.nFeedbackStills
%                             DrawFormattedText(p.window, char(encodingBcycleStimuli.Studied(encodingBTrial)), 'center', tCenterStudyStimuli(2), p.textColor); % "Cow"
%                             Screen('DrawingFinished', p.window);
%                             Screen('Flip', p.window, now + (p.waitframes - 0.5) * p.ifi)
%                         end
%                         
%                         break;                      
%                         
%                     case {'ESCAPE'}
%                         sca; return;
%                 end
%                 
%             end
%             
%         end
%     end
%     
%     slack = .5;
%     vbl = Screen('Flip', p.window);
%     tEnd = Screen('Flip', p.window, vbl + (slack * p.ifi));
%     
%     if strcmp(text_encodingBStimuli, response)
%         response = {'NO RESPONSE'};
%         encodingBcycleStimuli.Response(encodingBTrial) = response;
%         encodingBcycleStimuli.Correct(encodingBTrial) = {0};        
%     end
%     
%     encodingBcycleStimuli(:,{'Block'}) = {'e_Recall'};
%     
%     encodingData = [encodingData; encodingBcycleStimuli]; %Sav encodingB responses for each cycle
%     
%     KbQueueStop;
%     KbQueueFlush;
%     KbQueueRelease;
    
end
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
KbQueueCreate(1,p.keys_Navigation);
% Test Phase Instructions for Possible New Words
while 1
    %Presenting Instructions
    DrawFormattedText(p.window, text_testInstruction2, 'center', 'center', p.textColor, p.wrapat, 0, 0, 2);
    DrawFormattedText(p.window, p.text_space, 'center', p.tCenterSpace(2), p.textColor);  %space bar prompt
    Screen('Flip', p.window);
    
    WaitSecs(instructionDur); %Try to make sure they read it, instead of just clicking
    KbQueueStart; %Start listening to input after wait time
    [pressed, resp] = KbQueueCheck;
    if pressed
        if resp(KbName('Escape')); sca; return; end
        if resp(p.space) %Space ends while loop for next screen flip
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
    
    WaitSecs(instructionDur); %Try to make sure they read it, instead of just clicking
    KbQueueStart; %Start listening to input after wait time
    [pressed, resp] = KbQueueCheck;
    if pressed
        if resp(KbName('Escape')); sca; return; end
        if resp(p.space) %Space ends while loop for next screen flip
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
    
    WaitSecs(instructionDur); %Try to make sure they read it, instead of just clicking
    KbQueueStart; %Start listening to input after wait time
    [pressed, resp] = KbQueueCheck;
    if pressed
        if resp(KbName('Escape')); sca; return; end
        if resp(p.space) %Space ends while loop for next screen flip
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
    
    WaitSecs(instructionDur); %Try to make sure they read it, instead of just clicking
    KbQueueStart; %Start listening to input after wait time
    [pressed, resp] = KbQueueCheck;
    if pressed
        if resp(KbName('Escape')); sca; return; end
        if resp(p.space) %Space ends while loop for next screen flip
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
    
    WaitSecs(instructionDur); %Try to make sure they read it, instead of just clicking
    KbQueueStart; %Start listening to input after wait time
    [pressed, resp] = KbQueueCheck;
    if pressed
        if resp(KbName('Escape')); sca; return; end
        if resp(p.space) %Space ends while loop for next screen flip
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
    DrawFormattedText(p.window, p.text_space, 'center', p.tCenterSpace(2), p.textColor);  %space bar prompt
    Screen('Flip', p.window);
    
    WaitSecs(instructionDur); %Try to make sure they read it, instead of just clicking
    KbQueueStart; %Start listening to input after wait time
    [pressed, resp] = KbQueueCheck;
    if pressed
        if resp(KbName('Escape')); sca; return; end
        if resp(p.space) %Space ends while loop for next screen flip
            break;
        end
    end
    
end
KbQueueStop;

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Test Phase Practice O/N Ratings
old_new_practice_stim = repmat({'OO'; 'O'; 'N'; 'NN'}, 4, 1); %Create list of stimuli
old_new_practice_answer = repmat({'4'; '3'; '2'; '1'}, 4, 1); %With corresponding correct answer
old_new_practice_og = [old_new_practice_stim old_new_practice_answer];
old_new_practice_indices = randperm(length(old_new_practice_og));
old_new_practice_seq = old_new_practice_og(old_new_practice_indices', :);

%Present list of stimuli with feedback
KbQueueCreate(1,p.keys_confidence); %New queue

practiceONResponse = cell(length(old_new_practice_seq),1);
practiceONDuration = cell(length(old_new_practice_seq),1);

now = GetSecs;
start = now;
for pracONtrial = 1:length(old_new_practice_seq)
    %Create text and feedback for practice with stimuli for each trial
    text_PracticeOldNewStimuli = old_new_practice_seq{pracONtrial, 1};
    text_PracticeOldNewAnswer = old_new_practice_seq{pracONtrial, 2};
    text_PracticeOldNewFeedback = [ 'Correct answer is ', text_PracticeOldNewAnswer, '.'];
    
    %Placement of stimuli for study
    tCenterStudyStimuli = [p.xCenter-RectWidth(Screen('TextBounds', p.window, text_PracticeOldNewStimuli))/2  p.yCenter-40];
    
    %Presenting Stimuli
    for presentation = 1:p.nBlankStills %Presenting each word for a preset duration to avoid hitting the word twice
        DrawFormattedText(p.window, text_PracticeOldNewStimuli, 'center', tCenterStudyStimuli(2), p.textColor); % "Cow"
        DrawFormattedText(p.window, text_test1, 'center', tCenterStudy1(2),[],p.wrapat,[],[],1.5); % "1 2 3 4"
        DrawFormattedText(p.window, text_test2, 'center', tCenterStudy2(2),[],p.wrapat,[],[],1.5); % "New      Old"
        Screen('DrawingFinished', p.window);
        now = Screen('Flip', p.window, now + (p.waitframes - 0.5) * p.ifi);
    end
    KbQueueStart; %Start listening for input
    
    while 1
        % input
        [pressed, resp] = KbQueueCheck([]);
        if pressed
            practiceONResponse(pracONtrial) = cellstr(KbName(find(resp, 1, 'first')));
            practiceONResponseCheck = KbName(find(resp, 1, 'first'));
            key_press_time = min(resp(resp~=0));
            practiceONDuration(pracONtrial) = num2cell(key_press_time - now);
            if resp(KbName('Escape')); sca; return; end
            if any(resp(p.confidence))
                if strcmp(practiceONResponseCheck(1), text_PracticeOldNewAnswer)
                    for presentationFeedback = 1:p.nFeedbackStills
                        DrawFormattedText(p.window, 'Correct!', 'center', tCenterStudyStimuli(2), p.textColor);
                        Screen('DrawingFinished', p.window);
                        Screen('Flip', p.window, now + (p.waitframes - 0.5) * p.ifi)
                    end
                else
                    for presentationFeedback = 1:p.nFeedbackStills
                        DrawFormattedText(p.window, text_PracticeOldNewFeedback, 'center', tCenterStudyStimuli(2), p.textColor);
                        Screen('DrawingFinished', p.window);
                        Screen('Flip', p.window, now + (p.waitframes - 0.5) * p.ifi)
                    end
                end
                break;
            end
        end
    end
    
    KbQueueStop;
    
end
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Transition to Next Test Phase Face/Scene Task Instructions
KbQueueCreate(1,p.keys_Navigation);
while 1
    %Presenting Instructions
    DrawFormattedText(p.window, 'Great work!', 'center', 'center', p.textColor, p.wrapat, 0, 0, 2);
    DrawFormattedText(p.window, p.text_space, 'center', p.tCenterSpace(2), p.textColor);  %space bar prompt
    Screen('Flip', p.window);
    
    WaitSecs(instructionDur); %Try to make sure they read it, instead of just clicking
    KbQueueStart; %Start listening to input after wait time
    [pressed, resp] = KbQueueCheck;
    if pressed
        if resp(KbName('Escape')); sca; return; end
        if resp(p.space) %Space ends while loop for next screen flip
            break;
        end
    end
    
end
KbQueueStop;

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Test Phase Check In
while 1
    %Presenting Instructions
    DrawFormattedText(p.window, 'If you have any questions, please notify the experimenter at this time.', 'center', 'center', p.textColor,  p.wrapat, 0, 0, 2); % "If you have any questions"
    DrawFormattedText(p.window, p.text_space, 'center', p.tCenterSpace(2), p.textColor);  % space bar prompt
    
    Screen('Flip', p.window);
    WaitSecs(instructionDur); %Try to make sure they read it, instead of just clicking
    KbQueueStart; %Start listing to input after wait time
    
    [pressed, resp] = KbQueueCheck;
    if pressed
        if resp(KbName('Escape')); sca; return; end
        if resp(p.space) %Space ends while loop for next screen flip
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
    
    WaitSecs(instructionDur); %Try to make sure they read it, instead of just clicking
    KbQueueStart; %Start listening to input after wait time
    [pressed, resp] = KbQueueCheck;
    if pressed
        if resp(KbName('Escape')); sca; return; end
        if resp(p.space) %Space ends while loop for next screen flip
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
    
    WaitSecs(instructionDur); %Try to make sure they read it, instead of just clicking
    KbQueueStart; %Start listening to input after wait time
    [pressed, resp] = KbQueueCheck;
    if pressed
        if resp(KbName('Escape')); sca; return; end
        if resp(p.space) %Space ends while loop for next screen flip
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
    
    WaitSecs(instructionDur); %Try to make sure they read it, instead of just clicking
    KbQueueStart; %Start listening to input after wait time
    [pressed, resp] = KbQueueCheck;
    if pressed
        if resp(KbName('Escape')); sca; return; end
        if resp(p.space) %Space ends while loop for next screen flip
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
    
    WaitSecs(instructionDur); %Try to make sure they read it, instead of just clicking
    KbQueueStart; %Start listening to input after wait time
    [pressed, resp] = KbQueueCheck;
    if pressed
        if resp(KbName('Escape')); sca; return; end
        if resp(p.space) %Space ends while loop for next screen flip
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
    DrawFormattedText(p.window, p.text_space, 'center', p.tCenterSpace(2), p.textColor);  %space bar prompt
    Screen('Flip', p.window);
    
    WaitSecs(instructionDur); %Try to make sure they read it, instead of just clicking
    KbQueueStart; %Start listening to input after wait time
    [pressed, resp] = KbQueueCheck;
    if pressed
        if resp(KbName('Escape')); sca; return; end
        if resp(p.space) %Space ends while loop for next screen flip
            break;
        end
    end
    
end
KbQueueStop;

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Test Phase Practice S/F Ratings
face_scene_practice_stim = repmat({'FF'; 'F'; 'S'; 'SS'}, 4, 1); %Create list of stimuli
face_scene_practice_answer = repmat({'1'; '2'; '3'; '4'}, 4, 1); %With corresponding correct answer
face_scene_practice_og = [face_scene_practice_stim face_scene_practice_answer];
face_scene_practice_indices = randperm(length(face_scene_practice_og));
face_scene_practice_seq = face_scene_practice_og(face_scene_practice_indices', :);

%Present list of stimuli with feedback
KbQueueCreate(1,p.keys_source); %New queue

practiceFSResponse = cell(length(face_scene_practice_seq),1);
practiceFSDuration = cell(length(face_scene_practice_seq),1);

now = GetSecs;
start = now;
for pracFStrial = 1:length(face_scene_practice_seq)
    %Create text and feedback for practice with stimuli for each trial
    text_PracticeFaceSceneStimuli = face_scene_practice_seq{pracFStrial, 1};
    text_PracticeFaceSceneAnswer = face_scene_practice_seq{pracFStrial, 2};
    text_PracticeFaceSceneFeedback = [ 'Correct answer is ', text_PracticeFaceSceneAnswer];
    
    %Placement of stimuli for study
    tCenterStudyStimuli = [p.xCenter-RectWidth(Screen('TextBounds', p.window, text_PracticeFaceSceneStimuli))/2  p.yCenter-40];
    
    %Presenting Stimuli
    for presentation = 1:p.nBlankStills %Presenting each word for a preset duration to avoid hitting the word twice
        DrawFormattedText(p.window, text_PracticeFaceSceneStimuli, 'center', tCenterStudyStimuli(2), p.textColor); % "Cow"
        DrawFormattedText(p.window, text_study1, 'center', tCenterStudy1(2),[],p.wrapat,[],[],1.5); % "1 2 3 4"
        DrawFormattedText(p.window, text_study2, 'center', tCenterStudy2(2),[],p.wrapat,[],[],1.5); % "New      Old"
        DrawFormattedText(p.window, text_study3, 'center', tCenterStudy3(2),[],p.wrapat,[],[],1.5); % "New      Old"
        Screen('DrawingFinished', p.window);
        now = Screen('Flip', p.window, now + (p.waitframes - 0.5) * p.ifi);
    end
    KbQueueStart; %Start listening for input
    
    while 1
        % input
        [pressed, resp] = KbQueueCheck([]);
        if pressed
            practiceFSResponse(pracFStrial) = cellstr(KbName(find(resp, 1, 'first')));
            practiceFSResponseCheck = KbName(find(resp, 1, 'first'));
            key_press_time = min(resp(resp~=0));
            practiceFSDuration(pracFStrial)= num2cell(key_press_time - now);
            if resp(KbName('Escape')); sca; return; end
            if any(resp(p.source))
                if strcmp(practiceFSResponseCheck(1), text_PracticeFaceSceneAnswer)
                    for presentationFeedback = 1:p.nFeedbackStills
                        DrawFormattedText(p.window, 'Correct!', 'center', tCenterStudyStimuli(2), p.textColor);
                        Screen('DrawingFinished', p.window);
                        Screen('Flip', p.window, now + (p.waitframes - 0.5) * p.ifi)
                    end
                else
                    for presentationFeedback = 1:p.nFeedbackStills
                        DrawFormattedText(p.window, text_PracticeFaceSceneFeedback, 'center', tCenterStudyStimuli(2), p.textColor);
                        Screen('DrawingFinished', p.window);
                        Screen('Flip', p.window, now + (p.waitframes - 0.5) * p.ifi)
                    end
                end
                break;
            end
        end
    end
    
    KbQueueStop;
    
end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Transition to Actual Experiment
KbQueueCreate(1,p.keys_Navigation);
while 1
    %Presenting Instructions
    DrawFormattedText(p.window, 'Great work!', 'center', 'center', p.textColor, p.wrapat, 0, 0, 2);
    DrawFormattedText(p.window, p.text_space, 'center', p.tCenterSpace(2), p.textColor);  %space bar prompt
    Screen('Flip', p.window);
    
    WaitSecs(instructionDur); %Try to make sure they read it, instead of just clicking
    KbQueueStart; %Start listening to input after wait time
    [pressed, resp] = KbQueueCheck;
    if pressed
        if resp(KbName('Escape')); sca; return; end
        if resp(p.space) %Space ends while loop for next screen flip
            break;
        end
    end
    
end
KbQueueStop;

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%% Testing session
%Organize encoding stimuli for indexing during cycles
recogAstimuli = recogList(ismember(recogList.Block, 'testA'),:);
recogBstimuli = recogList(ismember(recogList.Block, 'testB'),:);

recogData = [];

% Transition to test phase
KbQueueCreate(1,p.keys_Navigation);
while 1
    %Presenting Instructions
    DrawFormattedText(p.window, 'During the actual memory test, you will not be told the correct answer.', 'center', 'center', p.textColor, p.wrapat, 0, 0, 2);
    DrawFormattedText(p.window, p.text_space, 'center', p.tCenterSpace(2), p.textColor);  %space bar prompt
    Screen('Flip', p.window);
    
    WaitSecs(instructionDur); %Try to make sure they read it, instead of just clicking
    KbQueueStart; %Start listening to input after wait time
    [pressed, resp] = KbQueueCheck;
    if pressed
        if resp(KbName('Escape')); sca; return; end
        if resp(p.space) %Space ends while loop for next screen flip
            break;
        end
    end
    
end
KbQueueStop;

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Last time to check in
while 1
    %Presenting Instructions
    DrawFormattedText(p.window, 'If you have any questions, please notify the experimenter at this time.', 'center', 'center', p.textColor,  p.wrapat, 0, 0, 2); % "If you have any questions"
    DrawFormattedText(p.window, p.text_space, 'center', p.tCenterSpace(2), p.textColor);  % space bar prompt
    
    Screen('Flip', p.window);
    WaitSecs(instructionDur); %Try to make sure they read it, instead of just clicking
    KbQueueStart; %Start listing to input after wait time
    
    [pressed, resp] = KbQueueCheck;
    if pressed
        if resp(KbName('Escape')); sca; return; end
        if resp(p.space) %Space ends while loop for next screen flip
            break;
        end
    end
    
end
KbQueueStop;

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%% SPLIT
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%% EXPERIMENT
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%% HERE
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%% !!!

% Transition
while 1
    %Presenting Instructions
    DrawFormattedText(p.window, 'Now the second part of the experiment will begin.', 'center', 'center', p.textColor,  p.wrapat, 0, 0, 2); % "If you have any questions"
    DrawFormattedText(p.window, p.text_space, 'center', p.tCenterSpace(2), p.textColor);  % space bar prompt
    
    Screen('Flip', p.window);
    WaitSecs(instructionDur); %Try to make sure they read it, instead of just clicking
    KbQueueStart; %Start listing to input after wait time
    
    [pressed, resp] = KbQueueCheck;
    if pressed
        if resp(KbName('Escape')); sca; return; end
        if resp(p.space) %Space ends while loop for next screen flip
            break;
        end
    end
    
end
KbQueueStop;

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% The experiment will now begin
while 1
    %Presenting Instructions
    DrawFormattedText(p.window, 'Rate your confidence that the current word on the screen is an old or new word', 'center', 'center', p.textColor,  p.wrapat, 0, 0, 2); % "If you have any questions"
    DrawFormattedText(p.window, p.text_space, 'center', p.tCenterSpace(2), p.textColor);  % space bar prompt
    
    Screen('Flip', p.window);
    WaitSecs(instructionDur); %Try to make sure they read it, instead of just clicking
    KbQueueStart; %Start listing to input after wait time
    
    [pressed, resp] = KbQueueCheck;
    if pressed
        if resp(KbName('Escape')); sca; return; end
        if resp(p.space) %Space ends while loop for next screen flip
            break;
        end
    end
    
end
KbQueueStop;

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% The experiment will now begin
while 1
    %Presenting Instructions
    DrawFormattedText(p.window, 'Here is a reminder of the keys.', 'center', 'center', p.textColor,  p.wrapat, 0, 0, 2); % "If you have any questions"
    DrawFormattedText(p.window, p.text_space, 'center', p.tCenterSpace(2), p.textColor);  % space bar prompt
    
    Screen('Flip', p.window);
    WaitSecs(instructionDur); %Try to make sure they read it, instead of just clicking
    KbQueueStart; %Start listing to input after wait time
    
    [pressed, resp] = KbQueueCheck;
    if pressed
        if resp(KbName('Escape')); sca; return; end
        if resp(p.space) %Space ends while loop for next screen flip
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
    
    WaitSecs(instructionDur); %Try to make sure they read it, instead of just clicking
    KbQueueStart; %Start listening to input after wait time
    [pressed, resp] = KbQueueCheck;
    if pressed
        if resp(KbName('Escape')); sca; return; end
        if resp(p.space) %Space ends while loop for next screen flip
            break;
        end
    end
    
end
KbQueueStop;

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Test Phase Old Ratings Instructions
while 1
    %Presenting Instructions
    new_instructionsON = strsplit(text_testInstruction5, '\\n\\n Let''s try an example.');
    
    DrawFormattedText(p.window, new_instructionsON{1}, 'center', 'center', p.textColor, p.wrapat, 0, 0, 2);
    DrawFormattedText(p.window, p.text_space, 'center', p.tCenterSpace(2), p.textColor);  %space bar prompt
    Screen('Flip', p.window);
    
    WaitSecs(instructionDur); %Try to make sure they read it, instead of just clicking
    KbQueueStart; %Start listening to input after wait time
    [pressed, resp] = KbQueueCheck;
    if pressed
        if resp(KbName('Escape')); sca; return; end
        if resp(p.space) %Space ends while loop for next screen flip
            break;
        end
    end
    
end
KbQueueStop;

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% The experiment will now begin
while 1
    %Presenting Instructions
    DrawFormattedText(p.window, 'Let''s begin.', 'center', 'center', p.textColor,  p.wrapat, 0, 0, 2); % "If you have any questions"
    DrawFormattedText(p.window, p.text_space, 'center', p.tCenterSpace(2), p.textColor);  % space bar prompt
    
    Screen('Flip', p.window);
    WaitSecs(instructionDur); %Try to make sure they read it, instead of just clicking
    KbQueueStart; %Start listing to input after wait time
    
    [pressed, resp] = KbQueueCheck;
    if pressed
        if resp(KbName('Escape')); sca; return; end
        if resp(p.space) %Space ends while loop for next screen flip
            break;
        end
    end
    
end
KbQueueStop;

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Test Phase O/N Ratings

%Present list of stimuli with feedback
KbQueueCreate(1,p.keys_confidence); %New queue

now = GetSecs;
start = now;

recogAstimuli = recogList(ismember(recogList.Block, 'testA'),:);
recogBstimuli = recogList(ismember(recogList.Block, 'testB'),:);

for ONtrial = 1:height(recogAstimuli)
    %Create text and feedback for practice with stimuli for each trial
    text_OldNewStimuli = recogAstimuli.Word{ONtrial, 1};
    
    %Placement of stimuli for study
    tCenterStudyStimuli = [p.xCenter-RectWidth(Screen('TextBounds', p.window, text_OldNewStimuli))/2  p.yCenter-40];
    
    %Presenting Stimuli
    for presentation = 1:p.nTestStills %Presenting each word for a preset duration to avoid hitting the word twice
        DrawFormattedText(p.window, text_OldNewStimuli, 'center', tCenterStudyStimuli(2), p.textColor); % "Cow"
        DrawFormattedText(p.window, text_test1, 'center', tCenterStudy1(2),[],p.wrapat,[],[],1.5); % "1 2 3 4 5 6"
        DrawFormattedText(p.window, text_test2, 'center', tCenterStudy2(2),[],p.wrapat,[],[],1.5); % "New      Old"
        Screen('DrawingFinished', p.window);
        now = Screen('Flip', p.window, now + (p.waitframes - 0.5) * p.ifi);
    end
    KbQueueStart; %Start listening for input
    
    while 1
        % input
        [pressed, resp] = KbQueueCheck([]);
        if pressed
            if resp(KbName('Escape')); sca; return;
            elseif any(resp(p.confidence))
                key_press_time = min(resp(resp~=0));
                recogAstimuli.Response(ONtrial) = cellstr(KbName(find(resp == key_press_time)));
                recogAstimuli.RT(ONtrial) = num2cell(key_press_time - now);
                
                break;
            end
        end
    end
    
 numbered_answer = recogAstimuli.Response{ONtrial};
    
    if str2double(numbered_answer(1)) <= 3
        if recogAstimuli.Studied{ONtrial} == '0'
            recogAstimuli.Correct{ONtrial} = '1';
        else
            recogAstimuli.Correct{ONtrial} = '0';
        end
    else
        if recogAstimuli.Studied{ONtrial} == '0'
            recogAstimuli.Correct{ONtrial} = '0';
        else
            recogAstimuli.Correct{ONtrial} = '1';
        end
    end
   
    for presentation = 1:p.nBlankStills %Display a blank screen in between
        Screen('Flip', p.window);
    end
    
    KbQueueStop;
end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Find false alarms and add
newWordsOnly = recogAstimuli(strcmp(recogAstimuli.Studied, '0'),:);
falseAlarms = newWordsOnly(strcmp(newWordsOnly.Correct,'0'),:);
p.nFalseAlarms = height(falseAlarms);

oldWordsOnly = recogAstimuli(strcmp(recogAstimuli.Studied, '1'),:);

fa_recogBstimuli = [oldWordsOnly; falseAlarms];
source_indices = randperm(height(fa_recogBstimuli));
fa_recogBstimuli_seq = fa_recogBstimuli(source_indices, :);

fa_recogBstimuli_seq.Block = repmat({'testB'}, height(fa_recogBstimuli_seq), 1);

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% The experiment will now begin

KbQueueCreate(1,p.keys_Navigation); %New queue

while 1
    %Presenting Instructions
    DrawFormattedText(p.window, 'Rate your confidence that the current word on the screen was paired with a face or a scene.', 'center', 'center', p.textColor,  p.wrapat, 0, 0, 2); % "If you have any questions"
    DrawFormattedText(p.window, p.text_space, 'center', p.tCenterSpace(2), p.textColor);  % space bar prompt
    
    Screen('Flip', p.window);
    WaitSecs(instructionDur); %Try to make sure they read it, instead of just clicking
    KbQueueStart; %Start listing to input after wait time
    
    [pressed, resp] = KbQueueCheck;
    if pressed
        if resp(KbName('Escape')); sca; return; end
        if resp(p.space) %Space ends while loop for next screen flip
            break;
        end
    end
    
end
KbQueueStop;

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% The experiment will now begin
while 1
    %Presenting Instructions
    DrawFormattedText(p.window, 'Here is a reminder of the keys.', 'center', 'center', p.textColor,  p.wrapat, 0, 0, 2); % "If you have any questions"
    DrawFormattedText(p.window, p.text_space, 'center', p.tCenterSpace(2), p.textColor);  % space bar prompt
    
    Screen('Flip', p.window);
    WaitSecs(instructionDur); %Try to make sure they read it, instead of just clicking
    KbQueueStart; %Start listing to input after wait time
    
    [pressed, resp] = KbQueueCheck;
    if pressed
        if resp(KbName('Escape')); sca; return; end
        if resp(p.space) %Space ends while loop for next screen flip
            break;
        end
    end
    
end
KbQueueStop;

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Test Phase New Ratings Instructions
while 1
    %Presenting Instructions
    DrawFormattedText(p.window, text_testInstruction7, 'center', 'center', p.textColor, p.wrapat, 0, 0, 2);
    DrawFormattedText(p.window, p.text_space, 'center', p.tCenterSpace(2), p.textColor);  %space bar prompt
    Screen('Flip', p.window);
    
    WaitSecs(instructionDur); %Try to make sure they read it, instead of just clicking
    KbQueueStart; %Start listening to input after wait time
    [pressed, resp] = KbQueueCheck;
    if pressed
        if resp(KbName('Escape')); sca; return; end
        if resp(p.space) %Space ends while loop for next screen flip
            break;
        end
    end
    
end
KbQueueStop;

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Test Phase Old Ratings Instructions
while 1
    %Presenting Instructions
    new_instructionsSF = strsplit(text_testInstruction8, '\\n\\n Let''s try an example.');
    
    DrawFormattedText(p.window, new_instructionsSF{1}, 'center', 'center', p.textColor, p.wrapat, 0, 0, 2);
    DrawFormattedText(p.window, p.text_space, 'center', p.tCenterSpace(2), p.textColor);  %space bar prompt
    Screen('Flip', p.window);
    
    WaitSecs(instructionDur); %Try to make sure they read it, instead of just clicking
    KbQueueStart; %Start listening to input after wait time
    [pressed, resp] = KbQueueCheck;
    if pressed
        if resp(KbName('Escape')); sca; return; end
        if resp(p.space) %Space ends while loop for next screen flip
            break;
        end
    end
    
end
KbQueueStop;

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% The experiment will now begin

while 1
    %Presenting Instructions
    DrawFormattedText(p.window, 'Let''s begin.', 'center', 'center', p.textColor,  p.wrapat, 0, 0, 2); % "If you have any questions"
    DrawFormattedText(p.window, p.text_space, 'center', p.tCenterSpace(2), p.textColor);  % space bar prompt
    
    Screen('Flip', p.window);
    WaitSecs(instructionDur); %Try to make sure they read it, instead of just clicking
    KbQueueStart; %Start listing to input after wait time
    
    [pressed, resp] = KbQueueCheck;
    if pressed
        if resp(KbName('Escape')); sca; return; end
        if resp(p.space) %Space ends while loop for next screen flip
            break;
        end
    end
    
end
KbQueueStop;

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Test Phase S/F Ratings

%Present list of stimuli with feedback
KbQueueCreate(1,p.keys_source); %New queue

now = GetSecs;
start = now;

for SFtrial = 1:height(fa_recogBstimuli_seq)
    %Create text and feedback for practice with stimuli for each trial
    text_SFStimuli = fa_recogBstimuli_seq.Word{SFtrial, 1};
    
    %Placement of stimuli for study
    tCenterStudyStimuli = [p.xCenter-RectWidth(Screen('TextBounds', p.window, text_SFStimuli))/2  p.yCenter-40];
    
    %Presenting Stimuli
    for presentation = 1:p.nTestStills %Presenting each word for a preset duration to avoid hitting the word twice
        DrawFormattedText(p.window, text_SFStimuli, 'center', tCenterStudyStimuli(2), p.textColor); % "Cow"
        DrawFormattedText(p.window, text_study1, 'center', tCenterStudy1(2),[],p.wrapat,[],[],1.5); % "1 2 3 4 5 6"
        DrawFormattedText(p.window, text_study2, 'center', tCenterStudy2(2),[],p.wrapat,[],[],1.5); % "New      Old"
        DrawFormattedText(p.window, text_study3, 'center', tCenterStudy3(2),[],p.wrapat,[],[],1.5);        
        Screen('DrawingFinished', p.window);
        now = Screen('Flip', p.window, now + (p.waitframes - 0.5) * p.ifi);
    end
    KbQueueStart; %Start listening for input
    
    while 1
        % input
        [pressed, resp] = KbQueueCheck([]);
        if pressed
            if any(resp(p.source))
                key_press_time = min(resp(resp~=0));
                fa_recogBstimuli_seq.Response(SFtrial) = cellstr(KbName(find(resp == key_press_time)));
                fa_recogBstimuli_seq.RT(SFtrial) = num2cell(key_press_time - now);
                break;
            elseif resp(KbName('Escape')); sca; return;
            end
        end
    end
    
    if strcmp(fa_recogBstimuli_seq.Pair{SFtrial}, 'f')
        
        if any(strcmp(fa_recogBstimuli_seq.Response{SFtrial}, {'z', 'x', 'c'}))
            fa_recogBstimuli_seq.Correct{SFtrial} = '1';
        else
            fa_recogBstimuli_seq.Correct{SFtrial} = '0';
        end
    elseif strcmp(fa_recogBstimuli_seq.Pair{SFtrial}, 's')
        if any(strcmp(fa_recogBstimuli_seq.Response{SFtrial}, {'z', 'x', 'c'}))
            fa_recogBstimuli_seq.Correct{SFtrial} = '0';
        else
            fa_recogBstimuli_seq.Correct{SFtrial} = '1';
        end
    else
        fa_recogBstimuli_seq.Correct{SFtrial} = '0';
    end
    
    for presentation = 1:p.nBlankStills %Display a blank screen in between
        Screen('Flip', p.window);
    end
    
    KbQueueStop;
end

fa_recogBstimuli_seq.BlockTrial = (1:height(fa_recogBstimuli_seq))';
fa_recogBstimuli_seq(:,{'Block'}) = {'t_Source'};
recogAstimuli(:,{'Block'}) = {'t_Item'};
recogData = [recogAstimuli; fa_recogBstimuli_seq];

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% End Experiment
  
%Presenting Instructions
Screen('DrawText', p.window, text_End1, tCenterEnd1(1), tCenterEnd1(2), p.textColor);
DrawFormattedText(p.window,text_End2,'center', tCenterEnd2(2),[],p.wrapat,[],[],1.5);
%DrawFormattedText(p.window, p.text_space, 'center', p.tCenterSpace(2), p.textColor);  %space bar prompt

Screen('Flip', p.window);
WaitSecs(5);

%% Save Data
encodingData.SessionTrial = (1:height(encodingData))';
recogData.SessionTrial = (1:height(recogData))';

fName2=[p.root, '\Subject Data\', 'Subject', p.subNum, '_Source_Session', num2str(p.sess), 'StudyData.csv'];
fName3=[p.root, '\Subject Data\', 'Subject', p.subNum, '_Source_Session', num2str(p.sess), 'TestData.csv'];

if exist(fName2,'file')
    fName2=[p.root, '\Subject Data\', 'Subject', p.subNum, '_Source_Session', num2str(p.sess), 'StudyData_CONFLICT.csv'];
end

if exist(fName3,'file')
    fName3=[p.root, '\Subject Data\', 'Subject', p.subNum, '_Source_Session', num2str(p.sess), 'TestData_CONFLICT.csv'];
end


%% Double check if subject file exists already and save conflict file if it does to check later (just in case)
fName = fullfile(p.root, 'Subject Data', ['Subject', p.subNum, '_Source_Session', num2str(p.sess), '.mat']); %mat file name everything will be saved in

if exist(fName,'file')
    fName = fullfile(p.root, 'Subject Data', ['Subject', p.subNum, '_Source_Session', num2str(p.sess), '_CONFLICT.mat']);
end

save(fName, 'p', 'encodingData', 'recogData');

writetable(encodingData,fName2,'Delimiter',',','QuoteStrings',true)
writetable(recogData,fName3,'Delimiter',',','QuoteStrings',true)

sca
%end