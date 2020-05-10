loggerx
=====
一款基于otp21以上的logger拓展


### 使用方式,以loggerx_pid_h为例
##### 1. 配置sys.config
```
  {loggerx,[
    {logger,[
      {handler, abc, loggerx_pid_h, #{
        formatter => {logger_formatter, #{single_line => true, template=> [time, " ", level, ": ", msg, "\n"]}},
        config => #{}
      }}
    ]}
  ]}
```
##### 2.开启
```
开启方式1：
application:start(loggerx).

开启方式2:
logger:add_handlers(loggerx).
```

### 组件
#### loggerx_pid_h
用途：远程注入到logger中，然后实时获取远程的日志内容(binary)

```
$rebar3 compile
$ erl -config config/sys-pid -pa `rebar3 path`
1> application:start(loggerx).
ok
2> loggerx_pid_h:add_pid(abc,self()).
ok
3> logger:info("abc").
ok
4> flush().
Shell got {log,<0.96.0>,<<"2020-05-10T10:23:23.924678+08:00 info: abc\n">>}
ok
```
#### loggerx_stat_h
用途：统计一段时间内日志的各等级的数量

配置参数：
| key | type | note |
| --- | --- | --- |
| stat_interval| integer | 统计间隔，默认300秒|
| stat_callback| {M,F} or function/2 |  回调函数，如果达到限制，回调函数被触发 M:F(Total::#{},Gap::#{})|
| stat_limit| map::#{} | eg:#{error => 10} ,如果300内错误日志数量达到10条，回调函数被触发|

```
$rebar3 compile
===> Verifying dependencies...
===> Compiling loggerx
$ erl -config config/sys-stat -pa `rebar3 path`
1> application:start(loggerx).
ok
2> F = fun(X) -> logger:error("error:~p",[X]) end.
#Fun<erl_eval.7.126501267>

3> lists:foreach(F,lists:seq(1,20)).
ok

# wait for a while,and print stat statistics
total:#{error => 20,info => 1}
gap:#{error => 20,info => 1}
```
