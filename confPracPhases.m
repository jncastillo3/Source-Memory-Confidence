% Test Phase Practice O/N Ratings
if test == 1
    practice_stim = repmat({'NN'; 'N'; 'O'; 'OO'}, reps, 1); %Create list of stimuli
    ratingType = p.text_test3item;
elseif test == 2
    practice_stim = repmat({'FF'; 'F'; 'S'; 'SS'}, reps, 1); %Create list of stimuli
    ratingType = p.text_test3source;
end

practice_answer = repmat({'1'; '2'; '3'; '4'}, reps, 1); %With corresponding correct answer
practice_og = [practice_stim practice_answer];
practice_indices = randperm(length(practice_og));
practice_seq = practice_og(practice_indices', :);

%Present list of stimuli with feedback
KbQueueCreate(device,p.keys_confidence); %New queue

pracResponse = cell(length(practice_seq),1);
pracDuration = cell(length(practice_seq),1);

vbl = GetSecs;

for pracTrial = 1:length(practice_seq)
    text_PracticeStimuli = practice_seq{pracTrial, 1}; %Create text and feedback for practice with stimuli for each trial
    text_PracticeAnswer = practice_seq{pracTrial, 2};
    text_PracticeFeedback = [ 'Correct answer is ', text_PracticeAnswer, '.'];
    
    %Placement of stimuli for study
    tCenterStudyStimuli = [p.xCenter-RectWidth(Screen('TextBounds', p.window, text_PracticeStimuli))/2  p.yCenter-40];
    
    %Presenting Stimuli
    firstFlip = 1;
    for presentation = 1:p.nBlankStills %Presenting each word for a preset duration to avoid hitting the word twice
        DrawFormattedText(p.window, text_PracticeStimuli, 'center', tCenterStudyStimuli(2), p.textColor); % "Cow"
        DrawFormattedText(p.window, p.text_test1, 'center', p.tCenterTest1(2),[],p.wrapat,[],[],1.5); % "1 2 3 4"
        DrawFormattedText(p.window, p.text_test2, 'center', p.tCenterTest2(2),[],p.wrapat,[],[],1.5); % "def/pos/pos/def"
        DrawFormattedText(p.window, ratingType, 'center', p.tCenterTest3item(2),[],p.wrapat,[],[],1.5); % "New      Old"
        Screen('DrawingFinished', p.window);
        vbl = Screen('Flip', p.window, vbl - (.5 * p.ifi));
        if firstFlip
            p.prac_stim_up(pracTrial) = vbl; %%Save Up/Down time to confirm trial presentation is correct. Should be saved for analysis too (in bigger table?) -DMS
            firstFlip = 0;
        end
        p.prac_stim_RespDelayOver(pracTrial) = vbl;
    end
    
    %shift resp window
    KbQueueStart; %Start listening for input after 100ms
    responded = 0;
    
    while GetSecs <= p.prac_stim_up(pracTrial) + p.testDur
        if responded
            DrawFormattedText(p.window, text_PracticeStimuli, 'center', tCenterStudyStimuli(2), p.textColor); % "Cow"
            DrawFormattedText(p.window, p.text_test1, 'center', p.tCenterTest1(2),p.textColor - 150,p.wrapat,[],[],1.5); % "1 2 3 4"
            DrawFormattedText(p.window, p.text_test2, 'center', p.tCenterTest2(2),p.textColor - 150,p.wrapat,[],[],1.5); % "defpos/pos/def"
            DrawFormattedText(p.window, ratingType, 'center', p.tCenterTest3item(2),p.textColor - 150,p.wrapat,[],[],1.5); % "New   Old"
            Screen('DrawingFinished', p.window);
            vbl = Screen('Flip', p.window, vbl - (.5 * p.ifi));
        elseif ~responded
            [pressed, resp] = KbQueueCheck([]);
            if pressed
                responded = 1;
                if resp(KbName('Escape')); sca; return;
                else
                    key_press_time = min(resp(resp~=0));
                    pracResponse(pracTrial) = cellstr(KbName(find(resp, 1, 'first')));
                    pracResponseCheck = KbName(find(resp, 1, 'first'));
                    pracDuration(pracTrial) = num2cell(key_press_time - p.prac_stim_up(pracTrial));
                end
            end
        end
    end
    
    %extend respond period into isi
    firstFlip = 1;
    for presentation = 1:p.nRespDelayStills %Present blank screen for late responses
        vbl = Screen('Flip', p.window, vbl - (.5 * p.ifi)); %Flip blank screen and get end trial timing
        if firstFlip
            p.prac_stim_down(pracTrial) = vbl;
            firstFlip = 0;
        end
        p.prac_stim_RespExtendOver(pracTrial) = vbl;
        if ~responded
            [pressed, resp] = KbQueueCheck([]);
            if pressed
                responded = 1;
                if resp(KbName('Escape')); sca; return;
                else
                    key_press_time = min(resp(resp~=0));
                    pracResponse(pracTrial) = cellstr(KbName(find(resp, 1, 'first')));
                    pracResponseCheck = KbName(find(resp, 1, 'first'));
                    pracDuration(pracTrial) = num2cell(key_press_time - p.prac_stim_up(pracTrial));
                end
            end
        end
    end
    KbQueueStop;
    
    if responded == 1
        if strcmp(pracResponseCheck(1), text_PracticeAnswer)
            Accuracy = {1};
            for presentationFeedback = 1:p.nFeedbackStills
                DrawFormattedText(p.window, 'Correct!', 'center', tCenterStudyStimuli(2), p.textColor);
                Screen('DrawingFinished', p.window);
                vbl = Screen('Flip', p.window, vbl - (.5 * p.ifi));
            end
        else
            Accuracy = {0};
            for presentationFeedback = 1:p.nFeedbackStills
                DrawFormattedText(p.window, text_PracticeFeedback, 'center', tCenterStudyStimuli(2), p.textColor);
                Screen('DrawingFinished', p.window);
                vbl = Screen('Flip', p.window, vbl - (.5 * p.ifi));
            end
        end
    else
        Accuracy = {[]};
        for presentationFeedback = 1:p.nFeedbackStills
            DrawFormattedText(p.window, text_PracticeFeedback, 'center', tCenterStudyStimuli(2), p.textColor);
            Screen('DrawingFinished', p.window);
            vbl = Screen('Flip', p.window, vbl - (.5 * p.ifi));
        end
    end
    
    %ISI STAR TASK
    ISI = randsample(isiLength, 1, true, Pisi);
    starsNullTask_v3
    
    %test 1 = O/N, and test 2 = S/F
    %timing 1 = behavioral, timing 2 = scanner. These using different
    %starting variables
    if test == 1
        if timing == 1
            pracONDataTrial=[{str2double(p.subNum)}, {p.sess}, {'ONPrac'}, {text_PracticeStimuli}, ...
                text_PracticeAnswer, pracResponse(pracTrial), {Accuracy}, {pracDuration(pracTrial)}, (p.prac_stim_up(pracTrial) - p.startStudy), ...
                ((p.prac_stim_RespDelayOver(pracTrial) - p.startStudy) - (p.prac_stim_up(pracTrial) - p.startStudy)), (p.prac_stim_down(pracTrial) - p.startStudy),...
                ((p.prac_stim_RespExtendOver(pracTrial) - p.startStudy) - (p.prac_stim_down(pracTrial) - p.startStudy)), (p.prac_stim_down(pracTrial) - p.prac_stim_up(pracTrial)), ISI];
            practiceConfData1 = [practiceConfData1; pracONDataTrial];
        elseif timing == 2
            pracONDataTrial=[{str2double(p.subNum)}, {p.sess}, {'ONPrac'}, {text_PracticeStimuli}, ...
                text_PracticeAnswer, pracResponse(pracTrial), {Accuracy}, {pracDuration(pracTrial)}, (p.prac_stim_up(pracTrial) - p.startInstruct), ...
                ((p.prac_stim_RespDelayOver(pracTrial) - p.startInstruct) - (p.prac_stim_up(pracTrial) - p.startInstruct)), (p.prac_stim_down(pracTrial) - p.startInstruct),...
                ((p.prac_stim_RespExtendOver(pracTrial) - p.startInstruct) - (p.prac_stim_down(pracTrial) - p.startInstruct)), (p.prac_stim_down(pracTrial) - p.prac_stim_up(pracTrial))];
            practiceConfData1 = [practiceConfData1; pracONDataTrial];
        end
    elseif test == 2
        if timing == 1
            pracFSDataTrial=[{str2double(p.subNum)}, {p.sess}, {'FSPrac'}, {text_PracticeStimuli}, ...
                text_PracticeAnswer, pracResponse(pracTrial), {Accuracy}, {pracDuration(pracTrial)}, (p.prac_stim_up(pracTrial) - p.startStudy), ...
                ((p.prac_stim_RespDelayOver(pracTrial) - p.startStudy) - (p.prac_stim_up(pracTrial) - p.startStudy)), (p.prac_stim_down(pracTrial) - p.startStudy),...
                ((p.prac_stim_RespExtendOver(pracTrial) - p.startStudy) - (p.prac_stim_down(pracTrial) - p.startStudy)), (p.prac_stim_down(pracTrial) - p.prac_stim_up(pracTrial)), ISI];
            practiceConfData2 = [practiceConfData2; pracFSDataTrial];
        elseif timing == 2
            pracFSDataTrial=[{str2double(p.subNum)}, {p.sess}, {'FSPrac'}, {text_PracticeStimuli}, ...
                text_PracticeAnswer, pracResponse(pracTrial), {Accuracy}, {pracDuration(pracTrial)}, (p.prac_stim_up(pracTrial) - p.startInstruct), ...
                ((p.prac_stim_RespDelayOver(pracTrial) - p.startInstruct) - (p.prac_stim_up(pracTrial) - p.startInstruct)), (p.prac_stim_down(pracTrial) - p.startStudy),...
                ((p.prac_stim_RespExtendOver(pracTrial) - p.startInstruct) - (p.prac_stim_down(pracTrial) - p.startInstruct)), (p.prac_stim_down(pracTrial) - p.prac_stim_up(pracTrial))];
            practiceConfData2 = [practiceConfData2; pracFSDataTrial];
        end
    end
end