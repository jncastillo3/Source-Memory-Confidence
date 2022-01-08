# Source Memory Confidence
fMRI scripts to run source memory decision task: a paradigm developed to understand the relationship between item memory and source confidence. This repository contains only source code for the experimental tasks, and does **not** include required stimuli (word lists and image stimuli).

**The study phase is comprised of two tasks:**
1. Passive viewing: item-word pairs are presented on the screen for 2 seconds. No task. 12 trials.
2. Source Recall: each word from the passive view is presented and subjects have 2 seconds to recall whether it was studied with a face or a scene. 12 trials.

After each trial, a null task in completed. A number of asterisks 1-4 appear on screen and subjects respond with how many stars are presented. The number of null trials completed after each study trial varies, and depends on the length of the ISI determined by OptSeq. Each trial lasts 1.5 seconds. 

In the study phase, a single run in the scanner is comprised of one block of passive viewing, and one block of source recall, totalling 3 minutes. 7 runs total. 

**The test phase is comprised of two tasks as well:**
1. Item confidence judgements: Each word previously studied (along with 6 new lures) is presented on screen. Subjects have 2 seconds to rate their confidence that the word of old or new (ranging from def new for def old). 18 trials.
2. Source confidence judgements: Each word previously studied, along with all item judgements that were false alarmed to in the previous block are tested here. Subjects are instructed to rate their confidence that the word was studied with a face or a scene (ranging from def face to def scene) in 2 seconds. 

Null task is completed after each trial here, too. 

Each block of confidence judegments in a single run and takes about 2.5 minutes to complete. 14 runs total (7 item, and 7 source)

Note: there are two ways to run the experiment. The 'RunFullExperiment' scripts will run the complete study and test phases with no pauses in the sequence of tasks. If, however, the task crashes and you need to restart one of the tasks, you can use the '_testcode' scripts to restart that block.'
