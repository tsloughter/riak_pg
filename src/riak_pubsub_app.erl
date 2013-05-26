%% @author Christopher Meiklejohn <christopher.meiklejohn@gmail.com>
%% @copyright 2013 Christopher Meiklejohn.
%% @doc Application.

-module(riak_pubsub_app).
-author('Christopher Meiklejohn <christopher.meiklejohn@gmail.com>').

-behaviour(application).

%% Application callbacks
-export([start/2,
         stop/1]).

%% ===================================================================
%% Application callbacks
%% ===================================================================

start(_StartType, _StartArgs) ->
    case riak_pubsub_sup:start_link() of
        {ok, Pid} ->
            ok = riak_core:register(riak_pubsub,
                                    [{vnode_module, riak_pubsub_vnode}]),
            ok = riak_core_node_watcher:service_up(riak_pubsub, self()),

            ok = riak_core:register(riak_pubsub_publish,
                                    [{vnode_module, riak_pubsub_publish_vnode}]),
            ok = riak_core_node_watcher:service_up(riak_pubsub_publish, self()),

            ok = riak_core:register(riak_pubsub_subscribe,
                                    [{vnode_module, riak_pubsub_subscribe_vnode}]),
            ok = riak_core_node_watcher:service_up(riak_pubsub_subscribe, self()),

            ok = riak_core_ring_events:add_guarded_handler(
                    riak_pubsub_ring_event_handler, []),

            ok = riak_core_node_watcher_events:add_guarded_handler(
                    riak_pubsub_node_event_handler, []),

            EntryRoute = {["riak_pubsub"], riak_pubsub_wm_ping, []},
            webmachine_router:add_route(EntryRoute),

            {ok, Pid};
        {error, Reason} ->
            {error, Reason}
    end.

stop(_State) ->
    ok.
