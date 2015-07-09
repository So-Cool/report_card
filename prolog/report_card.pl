/**  <module> report_card

  Copyright (C) 2013-15 Kacper Sokol
  All rights reserved.

  This module extends functionality of KnowRob system with robot's log analysis,
  data extraction and report card generation. The details of the project are
  available on the report card blog and the corresponding wiki.

  Redistribution and use in source and binary forms, with or without
  modification, are permitted provided that the following conditions are met:
      * Redistributions of source code must retain the above copyright
        notice, this list of conditions and the following disclaimer.
      * Redistributions in binary form must reproduce the above copyright
        notice, this list of conditions and the following disclaimer in the
        documentation and/or other materials provided with the distribution.
      * Neither the name of the <organization> nor the
        names of its contributors may be used to endorse or promote products
        derived from this software without specific prior written permission.

  THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS" AND
  ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED
  WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE
  DISCLAIMED. IN NO EVENT SHALL <COPYRIGHT HOLDER> BE LIABLE FOR ANY
  DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES
  (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES;
  LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND
  ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT
  (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS
  SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.

  @author Kacper Sokol
  @license BSD
*/

:- module(report_card,
    [
      report_card_test/2,
      card_type/1,
      data_format/1,
      generate_report_card/0,
      generate_report_card/1
    ]).

:- use_module(library('semweb/rdfs')).
:- use_module(library('owl_parser')).
:- use_module(library('owl')).
:- use_module(library('rdfs_computable')).
:- use_module(library('knowrob_owl')).
:- use_module(library('real')).

:-  rdf_meta
    report_card_test(+, r).

:- rdf_db:rdf_register_ns(rdf, 'http://www.w3.org/1999/02/22-rdf-syntax-ns#', [keep(true)]).
:- rdf_db:rdf_register_ns(owl, 'http://www.w3.org/2002/07/owl#', [keep(true)]).
:- rdf_db:rdf_register_ns(knowrob, 'http://knowrob.org/kb/knowrob.owl#', [keep(true)]).
:- rdf_db:rdf_register_ns(xsd, 'http://www.w3.org/2001/XMLSchema#', [keep(true)]).

/**
 * R variables names and their meaning:
 * * trialTime      - overall time of the experiment
 * * overall.names  - names of top-level activities
 * * overall.counts - total time of each top level activity
 * * totalTime      - total time of top level activities
 */

%% temporary_directory(-TempDirectory) is det.
%
% Defines temporary directory location.
% Gets the path of a temporary directory directory - temp folder in user's home.
%
% @param TempDirectory  A string representing a path to the temporary directory
%
temporary_directory(TempDirectory) :-
  expand_file_name('~/temp', [TempDirectory]).

%% rc_temporary_directory(-RcTempDir) is det.
%
% Gets data specific temporary directory path.
%
% @param RcTempDir  Absolute path to the data specific directory
%
rc_temporary_directory(RcTempDir) :-
  temporary_directory(TempDir),
  get_experiment_info(experimentId, Rc),
  concat(TempDir, '/', D1),
  concat(D1, Rc, RcTempDir).

%% project_specific_path(+FileName, -AbsluteFilePath) is det.
%
% Gets project specific absolute file path from file-name.
%
% @param FileName         Local file name
% @param AbsluteFilePath  Absolute path to the file
%
project_specific_path(FileName, AbsluteFilePath) :-
  rc_temporary_directory(RcTempDir),
  concat(RcTempDir, '/', D1),
  concat(D1, FileName, AbsluteFilePath).

%% create_directory(+DirectoryPath) is det.
%
% Creates a directory if it does not exist; if the name is occupied by a file
% it produces a warning.
% .
%
% @param DirectoryPath  Absolute path to the directory
%
create_directory(DirectoryPath) :-
  ( exists_directory(DirectoryPath) ->  true
  ; exists_file(DirectoryPath)      -> (write(DirectoryPath), write(" is a file - cannot create temporary directory"), false)
  ;                                     make_directory(DirectoryPath)
  ).

% creates a temporary directory for the report card on file being consulted
:- temporary_directory(TempDirectory),
  create_directory(TempDirectory).

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

%% get_experiment_info(+Tag, -Info) is det.
%
% Gets general, experiment specific information such as:
% experimentId;
% creator, description, experiment, experimentName, robot;
% timeStart, timeEnd.
% If parameter cannot be retrieved the function returns "N/A".
%
% @param Tag   One of mention above experiment specifics to be extracted
% @param Info  Extracted experiment specific information
%
get_experiment_info(experimentId, Info) :-
  rdf_has(Task, rdf:type, knowrob:'RobotExperiment'),
  Origin = 'http://knowrob.org/kb/cram_log.owl#RobotExperiment_',
  concat(Origin, Info, Task), !.
get_experiment_info(Tag, Info) :-
  rdf_has(Task, rdf:type, knowrob:'RobotExperiment'),
  ( Tag = creator        ->  rdf_has(Task, knowrob:'creator', literal(type(xsd:string, Info)))
  ; Tag = description    ->  rdf_has(Task, knowrob:'description', literal(type(xsd:string, Info)))
  ; Tag = experiment     ->  rdf_has(Task, knowrob:'experiment', literal(type(xsd:string, Info)))
  ; Tag = experimentName ->  rdf_has(Task, knowrob:'experimentName', literal(type(xsd:string, Info)))
  ; Tag = robot          ->  rdf_has(Task, knowrob:'robot', literal(type(xsd:string, Info)))
  ; Tag = timeStart      -> (rdf_has(Task, knowrob:'timeStart', literal(type(xsd:string, At))), atom_number(At, Info))
  ; Tag = timeEnd        -> (rdf_has(Task, knowrob:'timeEnd', literal(type(xsd:string, At))), atom_number(At, Info))
  ), !.
get_experiment_info(_, 'N/A') :- !.

%% card_type(-Type) is nondet.
%
% Defines possible types of the report card.
%
% @param Type  Type of the report card.
%
card_type(default).
card_type(simplistic).
card_type(detailed).

%% data_format(-Format) is nondet.
%
% Defines possible data types in which experiment information can be exported.
%
% @param Format  Format in which to export the experiment data
%
data_format(r).
data_format(csv).

%% export_data is det.
%
% Exports the data used for the report card generation in *data_format(csv)*
% format.
%
export_data :-
  export_data(data_format(csv)).

%% export_data(:DataFormat) is det.
%
% Exports the data used for the report card generation in either R
% (data_format(r)) or CSV (data_format(csv)) format.
%
% @param DataFormat  Format in which the data are exported
%
export_data(data_format(csv)) :-
  rc_temporary_directory(RcTempDir),
  create_directory(RcTempDir),
  project_specific_path('RCdata.csv', Fname),
  <- write(+"overall.names", file = +Fname),
  <- 'write.table'('overall.names', file = +Fname, 'sep = " "', 'eol = " "', 'quote = FALSE', 'row.names = FALSE', 'col.names = FALSE', 'append = TRUE'),
  <- write(+"\n\noverall.counts", file = +Fname, 'append = TRUE'),
  <- 'write.table'('overall.counts', file = +Fname, 'sep = " "', 'eol = " "', 'quote = FALSE', 'row.names = FALSE', 'col.names = FALSE', 'append = TRUE'),
  <- write(+"\n\ntotalTime", file = +Fname, 'append = TRUE'),
  <- 'write.table'('totalTime', file = +Fname, 'sep = " "', 'eol = " "', 'quote = FALSE', 'row.names = FALSE', 'col.names = FALSE', 'append = TRUE'),
  <- write(+"\n\ntrialTime", file = +Fname, 'append = TRUE'),
  <- 'write.table'('trialTime', file = +Fname, 'sep = " "', 'eol = " "', 'quote = FALSE', 'row.names = FALSE', 'col.names = FALSE', 'append = TRUE'),
  <- write(+"\n", file = +Fname, 'append = TRUE'), !.
export_data(data_format(r)) :-
  rc_temporary_directory(RcTempDir),
  create_directory(RcTempDir),
  project_specific_path('RCdata.RData', Fname),
  <- save( 'list = c("overall.names", "overall.counts", "totalTime", "trialTime")', file = +Fname), !.

%% generate_overview(+RcHomeOs, -Section) is det.
%
% Generates filled template (tex file) of overview section in defined temporary
% directory.
%
% @param RcHomeOs     Absolute path to the temporary directory
% @param SectionPath  Absolute path to the filled template
%
generate_overview(RcHomeOs, SectionPath) :-
  % define section name as per latex template directory without ".tex" extension
  Section = 'overview',

  % get overall duration
  overall_duration(Tasks),
  overall_duration(Tasks, Time),
  atom_number(TotalTime, Time),
  totalTime <- TotalTime,

  % plot the pie
  overall_duration_2R(Tasks),
  overall_duration_piechart(TotalTimeFigure),

  % get basic experiment information
  get_experiment_info(experimentName, TrialName),
  get_experiment_info(experimentId  , TrialId),
  get_experiment_info(creator       , TrialCreator),
  get_experiment_info(experiment    , TrialType),
  get_experiment_info(robot         , RobotType),
  get_experiment_info(description   , TrialDescription),
  get_experiment_info(timeStart     , TimeStart),
  get_experiment_info(timeEnd       , TimeEnd),
  TrialTimeNumeric is TimeEnd - TimeStart,
  trialTime <- TrialTimeNumeric,
  atom_number(TrialTime, TrialTimeNumeric),

  jpl_datums_to_array([TrialName, TrialId, TrialCreator, TrialType, RobotType, TrialDescription, TrialTime, TotalTime, TotalTimeFigure], Strings),
  jpl_call( 'org.knowrob.report_card.Generator', section, [RcHomeOs, Section, Strings], SectionPath).

%% generate_actions(+RcHomeOs, -Section) is det.
%
% Generates filled template (tex file) of actions section in defined temporary
% directory.
%
% @param RcHomeOs     Absolute path to the temporary directory
% @param SectionPath  Absolute path to the filled template
%
generate_actions(RcHomeOs, SectionPath) :-
  Section = 'actions',
  %% jpl_datums_to_array([], Strings),
  jpl_new('[Ljava.lang.String;', 0, Strings),
  jpl_call( 'org.knowrob.report_card.Generator', section, [RcHomeOs, Section, Strings], SectionPath).

%% generate_statistics(+RcHomeOs, -Section) is det.
%
% Generates filled template (tex file) of statistics section in defined temporary
% directory.
%
% @param RcHomeOs     Absolute path to the temporary directory
% @param SectionPath  Absolute path to the filled template
%
generate_statistics(RcHomeOs, SectionPath) :-
  Section = 'statistics',
  %% jpl_datums_to_array([], Strings),
  jpl_new('[Ljava.lang.String;', 0, Strings),
  jpl_call( 'org.knowrob.report_card.Generator', section, [RcHomeOs, Section, Strings], SectionPath).

%% generate_failures(+RcHomeOs, -Section) is det.
%
% Generates filled template (tex file) of failures section in defined temporary
% directory.
%
% @param RcHomeOs     Absolute path to the temporary directory
% @param SectionPath  Absolute path to the filled template
%
generate_failures(RcHomeOs, SectionPath) :-
  Section = 'failures',
  %% jpl_datums_to_array([], Strings),
  jpl_new('[Ljava.lang.String;', 0, Strings),
  jpl_call( 'org.knowrob.report_card.Generator', section, [RcHomeOs, Section, Strings], SectionPath).

%% generate_summary(+RcHomeOs, -Section) is det.
%
% Generates filled template (tex file) of summary section in defined temporary
% directory.
%
% @param RcHomeOs     Absolute path to the temporary directory
% @param SectionPath  Absolute path to the filled template
% 
generate_summary(RcHomeOs, SectionPath) :-
  Section = 'summary',
  %% jpl_datums_to_array([], Strings),
  jpl_new('[Ljava.lang.String;', 0, Strings),
  jpl_call( 'org.knowrob.report_card.Generator', section, [RcHomeOs, Section, Strings], SectionPath).

%% generate_report_card is det.
%
% Generates the report card of *card_type(default)* type.
%
generate_report_card :-
  generate_report_card(card_type(default)).

%% generate_report_card(:CardType) is det.
%
% Generates the report card of given flavour - with predefined sections.
%
% @param CardType  Type of the report card to be generated
%
generate_report_card(card_type(default)) :-
  % initialisation
  rc_temporary_directory(RcTempDir),
  create_directory(RcTempDir),
  prolog_to_os_filename(RcTempDir, RcHomeOs),

  % report card content
  generate_overview(RcHomeOs, Introduction),
  generate_actions(RcHomeOs, Actions),
  generate_statistics(RcHomeOs, Statistics),
  generate_failures(RcHomeOs, Failures),
  generate_summary(RcHomeOs, Summary),

  get_experiment_info(experimentId  , TrialId),
  jpl_datums_to_array([Introduction, Actions, Statistics, Failures, Summary], Strings),
  jpl_call( 'org.knowrob.report_card.Generator', rc, [RcHomeOs, TrialId, Strings], RcPdf),

  % data exporting and information outputting
  export_data(data_format(csv)),
  export_data(data_format(r)),
  write('Your report card is available at:\n'),
  write(RcPdf), !.
generate_report_card(card_type(simplistic)) :-
  rc_temporary_directory(RcTempDir),
  create_directory(RcTempDir),
  true,
  export_data(data_format(csv)),
  export_data(data_format(r)), !.
generate_report_card(card_type(detailed)) :-
  rc_temporary_directory(RcTempDir),
  create_directory(RcTempDir),
  true,
  export_data(data_format(csv)),
  export_data(data_format(r)), !.

%% top_level_task(-Task) is nondet.
%
% Finds a task that is at the top of the hierarchy i.e. it is no subtask of any
% other task.
%
% @param Task  Top level task
%
top_level_task(Task) :-
  task(Task),
  \+ subtask(_, Task).

%% top_level_task_duration(+Task, -Duration) is det.
%
% Finds the duration (in seconds) of a top level task.
%
% @param Task      Top level task
% @param Duration  Duration of specified task
%
top_level_task_duration(Task, Duration) :-
  task(Task),
  \+ subtask(_, Task),
  task_duration(Task, Duration).

%% top_level_task_duration_type(+Task, -Duration, -Type) is det.
%
% Finds the duration (in seconds) and type of a top level task.
%
% @param Task      Top level task
% @param Duration  Duration of specified task
% @param Type      Type of specified task
%
top_level_task_duration_type(Task, Duration, Type) :-
  task(Task),
  \+ subtask(_, Task),
  task_duration(Task, Duration),
  task_type(Task, Type).

%% overall_duration(-Tasks) is det.
%
% Finds all top level tasks i.e. ones that are at the top of hierarchy;
% then combines them to produce unique names and corresponding duration sum.
%
% @param Tasks  A list of pairs (task name, task duration)
%
overall_duration(Tasks) :-
  % find all top level tasks
  findall((T, D), top_level_task_duration_type(_, D, T), TDs),
  % combine them by name
  combine_tasks(TDs, Tasks).

%% combine_tasks(+TaskDurationS, -Tasks) is det.
%
% Combines a list of pairs (task name, task duration) where task names can
% repeat into a list of pairs with unique task names and combined task duration
% for pairs with the same task name.
%
% @param TaskDurationS  A list of pairs (task name, task duration) where task
%                       names can repeat
% @param Tasks          A list of pairs (task name, task duration) where task
%                       names are unique
%
combine_tasks(TaskDurationS, Tasks) :-
  combine_tasks(TaskDurationS, [], Tasks).
combine_tasks([(T, D)|TaskDurationS], TDs, Tasks) :-
  (  member( (T, S), TDs )
     % already in the list
  -> (NS is S + D,
      NT = T,
      findall((Tm, Dm), (member((Tm, Dm), TDs), T \= Tm), NewTDs)
      )
     % not yet in the list
  ;  (NewTDs = TDs,
      NT = T,
      NS = D
     )
  ),
  combine_tasks(TaskDurationS, [(NT, NS)|NewTDs], Tasks).
combine_tasks([], Tasks, Tasks).

%% overall_duration(+Tasks, -Time) is det.
%
% Sums task duration for all tasks in the list.
%
% @param Task  A list of pairs (task name, task duration) where task names are
%              the same for all pairs
% @param Time  Summed task durations
%
overall_duration(Tasks, Time) :-
  overall_duration(Tasks, 0, Time).
overall_duration([(_, S)|RTs], I, Time) :-
  NI is S + I,
  overall_duration(RTs, NI, Time).
overall_duration([], Time, Time).

%% overall_duration_2R(+Tasks) is det.
%
% Exports top level task names and durations to R.
%
% @param Tasks  A list of top level tasks - (task name, task duration) pairs -
%               - with unique task names
%
overall_duration_2R(Tasks) :-
  split_tuple(Tasks, [Nms, Numbers]),
  remove_knowrob(Nms, Names),
  % initialise R variable
  'overall.names'  <- Names,
  'overall.counts' <- Numbers.

%% overall_duration_piechart(-PieChart) is det.
%
% Plots pie chart (with use of R) of top level tasks durations.
%
% @param PieChart  Absolute path to the created pie chart
%
overall_duration_piechart(PieChart) :-
  project_specific_path('OverallDuration.pdf', PieChart),
  <- pdf(file = +PieChart),
  <- pie('overall.counts', labels = 'overall.names', main = +"Overall time"),
  <- invisible('dev.off()').

%% split_tuple(+LoT, -LoL) is det.
%
% Transforms a list of pairs into list of two lists containing correspondingly
% all first and all second pairs elements - unzips the list of pairs.
%
% @param LoT  List of pairs
% @param LoL  List of two lists
%
split_tuple(LoT, LoL) :-
  split_tuple(LoT, [[],[]], LoL).
split_tuple([(A,B)|LoTs], [Al, Bl], LoL) :-
  split_tuple(LoTs, [[A|Al], [B|Bl]], LoL).
split_tuple([], LoL, LoL).

%% remove_knowrob(+Before, -After) is det.
%
% Removes knowrob package name (header) from all elements in the input list.
%
% @param Before  List of elements with knowrob header
% @param After   List of elements with removed knowrob header
%
remove_knowrob(Before, After) :-
  remove_knowrob(Before, [], After).
remove_knowrob([A|Before], Middle, After) :-
  A0 = 'http://knowrob.org/kb/knowrob.owl#',
  concat(A0, A1, A),
  append(Middle, [A1], MA),
  remove_knowrob(Before, MA, After).
remove_knowrob([], A, A).

%% report_card_test(+Value1, +Value2) is det.
%
% Test the report_card module. The first value must be one less than the second
% value.
%
% @param Value1  First test value
% @param Value2  Second test value
%
report_card_test(Value1, Value2) :-
  Value2 is Value1+1.
