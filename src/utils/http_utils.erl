%%%-------------------------------------------------------------------
%%% @author jiarj
%%% @copyright (C) 2017, <COMPANY>
%%% @doc
%%%
%%% @end
%%% Created : 13. 十一月 2017 10:34
%%%-------------------------------------------------------------------
-module(http_utils).
-author("jiarj").
-compile(export_all).

%% API


http_get(URL) ->
  Method = get,
  Headers = [],
  HTTPOptions = [],
  Options = [],
%%  {ok,{_,_,Body}}=httpc:request(Method,{URL,Headers},HTTPOptions,Options).
  httpc:request(Method,{URL,Headers},HTTPOptions,Options).

http_post(URL,Header,Type, Body) ->
  Method = post,
  HTTPOptions = [],
  Options = [],
  httpc:request(Method, {
    ali_utils:convent_to_string(URL)
    , Header
    , ali_utils:convent_to_string(Type)
    , ali_utils:convent_to_binary(Body)
%%    ,Body
  }, HTTPOptions, Options).