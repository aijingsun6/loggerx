-module(loggerx_stat_h).

-behaviour(gen_server).

%% logger callbacks
-export([
  log/2,
  adding_handler/1,
  removing_handler/1,
  changing_config/3,
  filter_config/1
]).

%% gen_server callbacks
-export([
  init/1,
  handle_call/3,
  handle_cast/2,
  handle_info/2,
  terminate/2,
  code_change/3
]).
-define(DEFAULT_CALL_TIMEOUT, 5000).
-define(STAT_KEYS, [
  stat_interval, % integer
  stat_callback, % {M,F} | F/2
  stat_limit % #{Level => Limit}
]).

-record(state, {
  config = #{},
  stat_total = #{},
  stat = #{}
}).

adding_handler(Config) ->
  C = maps:get(config, Config, #{}),
  C2 = maps:merge(default_config(), C),
  {ok, Pid} = gen_server:start(?MODULE, [C2], []),
  {ok, Config#{config => C2#{ctrl_pid => Pid}}}.

removing_handler(#{config := #{ctrl_pid := Pid}}) ->
  gen_server:stop(Pid).

changing_config(_SetOrUpdate, _OldConfig, #{config := #{ctrl_pid := Pid}} = NewConfig) ->
  C = maps:get(config, NewConfig, #{}),
  Reply = gen_server:call(Pid, {changing_config, C}, ?DEFAULT_CALL_TIMEOUT),
  C2 = maps:merge(C, Reply),
  {ok, NewConfig#{config=> C2}}.

filter_config(Config) ->
  Config.

log(LogEvent, #{config := #{ctrl_pid := Pid}}) ->
  Level = maps:get(level, LogEvent, info),
  gen_server:cast(Pid, {level, Level}).

%% gen_server callbacks
init([#{stat_interval := Interval} = C]) ->
  process_flag(trap_exit, true),
  erlang:send_after(Interval, self(), stat),
  {ok, #state{config = C, stat = #{}, stat_total = #{}}}.

handle_call({changing_config, NewConfig}, _From, #state{config = C} = State) ->
  C2 = maps:merge(C, NewConfig),
  {reply, C2, State#state{config = C2}};
handle_call(_Request, _From, State) ->
  {reply, ok, State}.

handle_cast({level, Level}, #state{stat = SM, stat_total = STM} = State) ->
  SM2 = add_cnt(Level, SM),
  STM2 = add_cnt(Level, STM),
  {noreply, State#state{stat = SM2, stat_total = STM2}};
handle_cast(_Request, State) ->
  {noreply, State}.

handle_info(stat, #state{config = #{stat_interval := Interval}} = State) ->
  erlang:send_after(Interval, self(), stat),
  check_stat(State),
  {noreply, State#state{stat = #{}}};
handle_info(_Info, State) ->
  {noreply, State}.

terminate(_Reason, _State) ->
  ok.

code_change(_OldVsn, State, _Extra) ->
  {ok, State}.

%% ======

stat_func(Total, Gap) ->
  io:format("total:~p~n", [Total]),
  io:format("gap:~p~n", [Gap]).

default_config() ->
  #{
    stat_interval => 300000,
    stat_callback => fun stat_func/2,
    stat_limit => #{error => 100}
  }.

add_cnt(Level, M) ->
  C = maps:get(Level, M, 0),
  maps:put(Level, C + 1, M).

check_limit([], _) -> true;
check_limit([{Level, Limit} | L], M) ->
  C = maps:get(Level, M, 0),
  case C >= Limit of
    true -> false;
    false -> check_limit(L, M)
  end.

check_stat(#state{stat_total = STM, stat = SM, config = #{stat_limit:=Limit, stat_callback:= CB}}) ->
  L = maps:to_list(Limit),
  case check_limit(L, SM) of
    true ->
      pass;
    false ->
      case CB of
        {Mod, F} -> catch Mod:F(STM, SM);
        Func when is_function(Func, 2) -> catch Func(STM, SM);
        _ -> pass
      end
  end.