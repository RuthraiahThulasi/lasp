-module(derflow).
-include("derflow.hrl").
-include_lib("riak_core/include/riak_core_vnode.hrl").

-export([declare/0,
         bind/2,
         bind/3,
         read/1,
         produce/2,
         produce/3,
         consume/1,
         %%touch/1,
         extend/1,
         is_det/1,
         wait_needed/1,
         spawn_mon/4,
         get_stream/1]).

%% Public API

declare() ->
    _ = derflow_declare_fsm_sup:start_child([self()]),
    receive
        {ok, Id} ->
            {ok, Id}
    end.

bind(Id, Value) ->
    {ok, _} = derflow_vnode:bind(Id, Value),
    ok.

bind(Id, Function, Args) ->
    {ok, _} = derflow_vnode:bind(Id, Function, Args),
    ok.

read(Id) ->
    {ok, Value, _Next}= derflow_vnode:read(Id),
    {ok, Value}.

produce(Id, Value) ->
    derflow_vnode:bind(Id, Value).

produce(Id, Function, Args) ->
    derflow_vnode:bind(Id, Function, Args).

consume(Id) ->
    derflow_vnode:read(Id).

%%Not sure whether this is used or not
%touch(Id) ->
%    derflow_vnode:touch(Id).

extend(Id) ->
    derflow_vnode:next(Id).

is_det(Id) ->
    derflow_vnode:is_det(Id).

wait_needed(Id) ->
    derflow_vnode:wait_needed(Id).

%%TODO: Missing monitor and kill primitives

%% The rest of primitives are not in the paper. They are just utilities.
%% maybe we should just remove them

spawn_mon(Supervisor, Module, Function, Args) ->
    Pid = spawn(Module, Function, Args),
    Supervisor ! {'SUPERVISE', Pid, Module, Function, Args}.

get_stream(Stream)->
    internal_get_stream(Stream, []).

%% Internal functions

internal_get_stream(Head, Output) ->
    case read(Head) of
        {ok, nil, _} ->
            Output;
        {ok, Value, Next} ->
            internal_get_stream(Next, lists:append(Output, [Value]))
    end.
