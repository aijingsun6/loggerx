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
===> Verifying dependencies...
===> Compiling loggerx
$ erl -config config/sys-pid -pa `rebar3 path`
1> application:start(loggerx).
ok
2> loggerx_pid_h:add
add_pid/2         adding_handler/1
2> loggerx_pid_h:add_pid(abc,self()).
ok
3> logger:info("abc").
ok
4> flush().
Shell got {log,<0.96.0>,<<"2020-05-10T10:23:23.924678+08:00 info: abc\n">>}
ok
```

