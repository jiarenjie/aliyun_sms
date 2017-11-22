%%%-------------------------------------------------------------------
%% @doc aliyun_sms top level supervisor.
%% @end
%%%-------------------------------------------------------------------

-module(aliyun_sms_sup).

-behaviour(supervisor).

%% API
-export([start_link/0]).

%% Supervisor callbacks
-export([init/1]).

-define(SERVER, ?MODULE).


%%====================================================================
%% API functions
%%====================================================================

start_link() ->
    supervisor:start_link({local, ?SERVER}, ?MODULE, []).

%%====================================================================
%% Supervisor callbacks
%%====================================================================

%% Child :: {Id,StartFunc,Restart,Shutdown,Type,Modules}
init([]) ->
    %%    {ok, { {one_for_all, 0, 1}, []} }.
%%    {ok,GateWay} = application:get_env(gateWay),
    M = ali_utils:default_modle(),
    RestartStrategy = {one_for_one, 4, 60},
    Children = [
        {M,
            {M, start_link, []},
            permanent, 2000, supervisor, [M]}
    ],
    {ok, {RestartStrategy, Children}}.

%%====================================================================
%% Internal functions
%%====================================================================
