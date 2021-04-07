%THIS VERSION IS USED IN THE FULL LENGTH SCANNER VERSION

%Randomize presentation of stars
ITstim = {'*'; '*   *'; '*   *   *'; '*   *   *   *'};
ITstim_answer = {'1'; '2'; '3'; '4'};
ITstim_mat = [ITstim ITstim_answer];

%response text
p.text_test1 = '1                      2                      3                      4';
p.tCenterTest1 = [p.xCenter-RectWidth(Screen('TextBounds', p.window, p.text_test1))/2  p.windowRect(4)*.68+40];

Pstim = [.25 .25 .25 .25]; %probability of each star
ITstim_seq = datasample(ITstim_mat, ISI, 'Weights', Pstim, 'Replace', true); %choose the stimuli, with replacement, based in the ISI length and probability

%Begin star null trials
for starITtrial = 1:length(ITstim_seq)
    text_PracticeIT = ITstim_seq{starITtrial,1};
    tCenterTestStimuli = [p.xCenter-RectWidth(Screen('TextBounds', p.window, text_PracticeIT))/2  p.yCenter-40];
    firstFlip = 1;
    
    %Presenting Stimuli
    for presentation = 1:p.nBlankStills %Present screen without looking for response for 100ms response window delay (in case of accidental button presses)
        DrawFormattedText(p.window, text_PracticeIT, 'center', tCenterTestStimuli(2), p.textColor);
        DrawFormattedText(p.window, p.text_test1, 'center', p.tCenterTest1(2),[],p.wrapat,[],[],1.5); % "1 2 3 4"
        Screen('DrawingFinished', p.window);
        vbl = Screen('Flip', p.window, vbl - (.5 * p.ifi));
        if firstFlip;
            p.test_stim_null_up(starITtrial) = vbl; %%As is, currently rewriting each null break. Should save in larger table to confirm timing still. -DMS
            firstFlip = 0;
        end
        p.test_stim_null_RespDelayOver(starITtrial) = vbl; %%As is, currently rewriting each null break. Should save in larger table to confirm timing still. -DMS
    end
    
    KbQueueCreate(device, p.keys_confidence);
    KbQueueStart; %Start listening for input
    responded = 0; %Used later for response dimming
    
        while GetSecs <= p.test_stim_null_up(starITtrial) + 1.5 %%NEED TO REPLACE 1.5 WITH ACTUAL ISI length -DMS
            if responded;
                %If response made, dim the reminder of key options
                DrawFormattedText(p.window, text_PracticeIT, 'center', tCenterTestStimuli(2), p.textColor);
                DrawFormattedText(p.window, p.text_test1, 'center', p.tCenterTest1(2),p.textColor - 150,p.wrapat,[],[],1.5); % "1 2 3 4"
                Screen('DrawingFinished', p.window);
                vbl = Screen('Flip', p.window, vbl - (.5 * p.ifi));
            elseif ~responded
                %Else, keep screen as is (will be the same as last flipped)
                [pressed, resp] = KbQueueCheck([]);
                if pressed;
                    responded = 1;
                    if resp(KbName('Escape')); sca; return;
                    elseif any(resp(p.test));
                        response = cellstr(KbName(find(resp, 1, 'first')));
                        key_press_time = min(resp(resp~=0));
                        RT = {key_press_time - p.test_stim_null_up(starITtrial)};
                        accuracy = {contains(response,ITstim_seq(starITtrial,2))};
                    end
                else
                    responded = 0;
                    response = {[]};
                    RT = {[]};
                    accuracy = {[]};
                end
            end
        end
    KbQueueStop;
    
    for presentation = 1:p.nBlankStills %Display a blank screen in between
        vbl = Screen('Flip', p.window, vbl - (.5 * p.ifi));
        p.test_stim_null_down(starITtrial) = vbl;
    end
    
    if test == 1
        ITdata=[{p.subNum}, {p.session}, {'e_passive'}, {run}, {str2double(ITstim_seq(starITtrial,2))}, ...
            encodingPassiveTrial, response, {RT}, {accuracy}, (p.test_stim_null_up(starITtrial) - p.RunStart), ...
            ((p.test_stim_null_RespDelayOver(starITtrial) - p.RunStart) - (p.test_stim_null_up(starITtrial) - p.RunStart)),...
            (p.test_stim_null_down(starITtrial) - p.RunStart), ...
            (p.test_stim_null_down(starITtrial) - p.test_stim_null_up(starITtrial))];
        allITencodingPassiveData = [allITencodingPassiveData; ITdata];
    elseif test == 2
        ITdata=[{p.subNum}, {p.session}, {'e_recall'}, {run}, {str2double(ITstim_seq(starITtrial,2))}, ...
            encodingSourceTrial, response, {RT}, {accuracy}, (p.test_stim_null_up(starITtrial) - p.RunStart), ...
            ((p.test_stim_null_RespDelayOver(starITtrial) - p.RunStart) - (p.test_stim_null_up(starITtrial) - p.RunStart)),...
            (p.test_stim_null_down(starITtrial) - p.RunStart), ...
            (p.test_stim_null_down(starITtrial) - p.test_stim_null_up(starITtrial))];
        allITencodingRecallData = [allITencodingRecallData; ITdata];
    elseif test == 3
        ITdata=[{p.subNum}, {p.session}, {'t_Item'}, {run}, {str2double(ITstim_seq(starITtrial,2))}, ...
            ONtrial, response, {RT}, {accuracy}, (p.test_stim_null_up(starITtrial) - p.RunStart), ...
            ((p.test_stim_null_RespDelayOver(starITtrial) - p.RunStart) - (p.test_stim_null_up(starITtrial) - p.RunStart)),...
            (p.test_stim_null_down(starITtrial) - p.RunStart), ...
            (p.test_stim_null_down(starITtrial) - p.test_stim_null_up(starITtrial))];
        allITitemData = [allITitemData; ITdata];
    elseif test == 4
        ITdata=[{p.subNum}, {p.session}, {'t_Source'}, {run}, {str2double(ITstim_seq(starITtrial,2))}, ...
            SFtrial, response, {RT}, {accuracy}, (p.test_stim_null_up(starITtrial) - p.RunStart), ...
            ((p.test_stim_null_RespDelayOver(starITtrial) - p.RunStart) - (p.test_stim_null_up(starITtrial) - p.RunStart)),...
            (p.test_stim_null_down(starITtrial) - p.RunStart), ...
            (p.test_stim_null_down(starITtrial) - p.test_stim_null_up(starITtrial))];
        allITsourceData = [allITsourceData; ITdata];
    end
    
end