-module(ct_tty_hook).
-author('simon.zelazny@erlang-solutions.com').

%% @doc Add the following line in your *.spec file to enable
%% reasonable, tty error reporting for your common tests:
%% {ct_hooks, [ct_tty_hook]}.

%% Callbacks
-export([id/1]).
-export([init/2]).

-export([pre_init_per_suite/3]).
-export([post_init_per_suite/4]).
-export([pre_end_per_suite/3]).
-export([post_end_per_suite/4]).

-export([pre_init_per_group/3]).
-export([post_init_per_group/4]).
-export([pre_end_per_group/3]).
-export([post_end_per_group/4]).

-export([pre_init_per_testcase/3]).
-export([post_end_per_testcase/4]).

-export([on_tc_fail/3]).
-export([on_tc_skip/3]).

-export([terminate/1]).
-record(state, { total, suite_total, ts, tcs, data }).

%% @doc Return a unique id for this CTH.
id(_Opts) ->
    "ct_tty_hook_001".

%% @doc Always called before any other callback function. Use this to initiate
%% any common state.
init(_Id, _Opts) ->
    {ok, #state{ total = 0, data = [] }}.

%% @doc Called before init_per_suite is called.
pre_init_per_suite(_Suite,Config,State) ->
    {Config, State#state{ suite_total = 0, tcs = [] }}.

%% @doc Called after init_per_suite.
post_init_per_suite(_Suite,_Config,Return,State) ->
    {Return, State}.

%% @doc Called before end_per_suite.
pre_end_per_suite(_Suite,Config,State) ->
    {Config, State}.

%% @doc Called after end_per_suite.
post_end_per_suite(Suite,_Config,Return,State) ->
    Data = {suites, Suite, State#state.suite_total, lists:reverse(State#state.tcs)},
    {Return, State#state{ data = [Data | State#state.data] ,
                          total = State#state.total + State#state.suite_total } }.

%% @doc Called before each init_per_group.
pre_init_per_group(_Group,Config,State) ->
    {Config, State}.

%% @doc Called after each init_per_group.
post_init_per_group(_Group,_Config,Return,State) ->
    {Return, State}.

%% @doc Called after each end_per_group.
pre_end_per_group(_Group,Config,State) ->
    {Config, State}.

%% @doc Called after each end_per_group.
post_end_per_group(_Group,_Config,Return,State) ->
    {Return, State}.

%% @doc Called before each test case.
pre_init_per_testcase(_TC,Config,State) ->
    {Config, State#state{ ts = now(), total = State#state.suite_total + 1 } }.

%% @doc Called after each test case.
post_end_per_testcase(TC,_Config,Return,State) ->
    TCInfo = {testcase, TC, Return, timer:now_diff(now(), State#state.ts)},
    {Return, State#state{ ts = undefined, tcs = [TCInfo | State#state.tcs] } }.

%% @doc Called after post_init_per_suite, post_end_per_suite, post_init_per_group,
%% post_end_per_group and post_end_per_testcase if the suite, group or test case failed.
on_tc_fail(_TC, _Reason, State) ->
    State.

%% @doc Called when a test case is skipped by either user action
%% or due to an init function failing.
on_tc_skip(_TC, Reason, State) ->
    case Reason of
        %% Just quit if files were not build correctly
        {tc_user_skip, "Make failed"} -> erlang:halt(1);
        _                             -> State
    end.

%% @doc Called when the scope of the CTH is done
terminate(State) ->
    lists:foreach(fun (SuiteData) ->
                          print_suite(SuiteData)
                  end,
                  State#state.data),
    ok.


aggregate_results(Cases) ->
    Oks =   [ C || {testcase, _, ok, _} =         C <- Cases ],
    Fails = [ C || {testcase, _, {error, _}, _} = C <- Cases ],
    {length(Oks), length(Fails)}.

print_suite({suites, Name,_, TestCases}) ->
    case aggregate_results(TestCases) of
        {Oks, 0} -> print_suite_ok(Name, Oks);
        {Oks, Fails} -> print_suite_failed(Name,Oks,Fails,TestCases)
    end, ok.

print_suite_ok(Name, OkCount) ->
    io:format("~n====== Suite OK: ~p (All ~p tests passed)~n",
           [Name, OkCount]).
print_suite_failed(Name, OkCount, FailCount, Cases) ->
    ct:pal("~n====== Suite FAILED: ~p (~p of ~p tests failed)~n",
           [Name, FailCount, OkCount+FailCount]),
    lists:foreach(fun maybe_print_test_case/1, Cases).

maybe_print_test_case({testcase, _Name,ok,_})              -> ok;
maybe_print_test_case({testcase, Name,{error, Content},_}) ->
    io:format("~n====== Test name: ~p", [Name]),
    io:format("~n====== Reason:    ~p~n", [Content]).
