-module(loggerx_app).

-behaviour(application).

-export([start/2, stop/1]).

start(_StartType, _StartArgs) ->
  case loggerx_sup:start_link() of
    {ok, Pid} ->
      ok = logger:add_handlers(loggerx),
      {ok, Pid};
    Err -> Err
  end.

stop(_State) ->
  ok.

%% internal functions
