%%%-------------------------------------------------------------------
%%% @author jiarj
%%% @copyright (C) 2017, <COMPANY>
%%% @doc
%%%
%%% @end
%%% Created : 09. 十一月 2017 13:45
%%%-------------------------------------------------------------------
-module(ali_utils).
-author("jiarj").
-compile(export_all).
-include_lib("eunit/include/eunit.hrl").

-define(DELIMIT,<<$,>>).
%% API

%%msg => [{<<"15556430332">>,[{customer,<<"jiarenjie">>}]}] to map
msg_convent(List) ->
  [Type,Num, Map] = case length(List) of
                 1 ->
%%      todo singleContent
                   [Msg] = List,
                   convert_single(Msg);
                 _ ->
%%      todo multiContent
                   convert_multi(List, [<<"">>, #{}])
               end,
  [Type,Num,jsx:encode(Map)].
%% Mobile = [<<"110">>,"10010",10086], ParameterMap = #{ customer => <<"test">>}
msg_convent(Mobiles,ParameterMap) when is_list(Mobiles),is_map(ParameterMap)->
  Lists = lists:map(fun(Mobile)-> {convent_to_atom(Mobile),ParameterMap} end,Mobiles),
  SmsParams =jsx:encode(maps:from_list(Lists)),
  [<<"multiContent">>, convent_mobile(Mobiles), SmsParams];
msg_convent(Mobile,ParameterMap) when is_map(ParameterMap)->
  MobileBinary =convent_to_binary(Mobile),
  [<<"singleContent">>, MobileBinary, jsx:encode(ParameterMap)].

convert_multi([], [NumAcc,MapAcc]) ->
  << $, , Rest/binary>> = NumAcc,
  [<<"multiContent">>,Rest,MapAcc];
convert_multi([Msg | Rest], [NumAcc, MapAcc]) ->
%%  Keys = template_key(),
%%  PvMap = maps:from_list(lists:zip(Keys,Vals)),
  [_ , Num, PvMap] = convert_single(Msg),
  NewMapAcc = maps:put(binary_to_atom(Num, utf8), PvMap, MapAcc),
  NewNumAcc = <<NumAcc/binary, ?DELIMIT/binary, Num/binary>>,
  convert_multi(Rest, [NewNumAcc, NewMapAcc]).

convert_single({Num, PV}) ->
  NumAtom = convent_to_binary(Num),
  PvMap = maps:from_list(PV),
  [<<"singleContent">>,NumAtom, PvMap].

convent_mobile(Mobiles) when is_list(Mobiles) ->
  MobilesBinary = lists:map(fun(Mobile)-> convent_to_binary(Mobile)  end,Mobiles),
  list_to_binary(lists:join(<<$,>>,MobilesBinary));
convent_mobile(Mobiles) ->
  convent_to_binary(Mobiles).


get_msg_param(MsgType, SmsSendList)->
  Map = proplists:get_value(MsgType,SmsSendList),
  {ok,SignName} = maps:find(signName,Map),
  {ok,TemplateCode} = maps:find(templateCode,Map),
  {list_to_binary_utf8(SignName),list_to_binary_utf8(TemplateCode)}.

list_to_binary_utf8(List) when is_list(List) ->
  unicode:characters_to_binary(List).

default_modle()->
  {ok,GateWay} = application:get_env(gateWay),
  default_modle(GateWay).
default_modle(aliyun_sms)->
  gs_aliyun_sms;
default_modle(aliyun_mns)->
  gs_aliyun_mns.

convent_to_binary(Num) when is_list(Num) ->
  erlang:list_to_binary(Num);
convent_to_binary(Num) when is_atom(Num) ->
  erlang:atom_to_binary(Num, utf8);
convent_to_binary(Num) when is_integer(Num) ->
  erlang:integer_to_binary(Num);
convent_to_binary(Num) when is_binary(Num) ->
  Num.


convent_to_atom(Num) when is_atom(Num) ->
  Num;
convent_to_atom(Num) when is_list(Num) ->
  list_to_atom(Num);
convent_to_atom(Num) when is_integer(Num) ->
  erlang:binary_to_atom(erlang:integer_to_binary(Num),utf8);
convent_to_atom(Num) when is_binary(Num) ->
  erlang:binary_to_atom(Num,utf8).

convent_to_string(Num) when is_list(Num) ->
  Num;
convent_to_string(Num) when is_atom(Num) ->
  erlang:atom_to_list(Num);
convent_to_string(Num) when is_binary(Num) ->
  erlang:binary_to_list(Num).


get_uuid()->
  UUID = list_to_binary(os:cmd("uuidgen")),
  remove_tail_char(UUID,1)
.

remove_tail_char(Bin,Bit) when is_integer(Bit),is_binary(Bin) ->
  Len = byte_size(Bin),
  Len1 = Len - Bit,
  <<Bin1:Len1/binary, _Tail:Bit/binary>> = Bin,
  Bin1.

now_gtm() ->
%%  {{Year, Month, Day}, {Hour, Minute, Second}} = calendar:now_to_local_time(erlang:now()),
  {{Year, Month, Day}, {Hour, Minute, Second}} = calendar:universal_time(),
  Week = calendar:day_of_the_week({Year, Month, Day}),
  WeekList = day(Week),
  MonthList = month_to_list(Month),
  String = lists:flatten(
    io_lib:format("~s, ~2..0w ~s ~4..0w ~2..0w:~2..0w:~2..0w GMT",
      [WeekList, Day, MonthList, Year, Hour, Minute, Second])),
  convent_to_binary(String).

now_utc() ->
  {MegaSecs, Secs, MicroSecs} = erlang:now(),
  {{Year, Month, Day}, {Hour, Minute, Second}} =
    calendar:now_to_universal_time({MegaSecs, Secs, MicroSecs}),
  lists:flatten(
    io_lib:format("~4..0w-~2..0w-~2..0wT~2..0w:~2..0w:~2..0wZ",
      [Year, Month, Day, Hour, Minute, Second])).

day(1) -> "Mon";
day(2) -> "Tue";
day(3) -> "Wed";
day(4) -> "Thu";
day(5) -> "Fri";
day(6) -> "Sat";
day(7) -> "Sun".

month_to_list(1) -> "Jan";
month_to_list(2) -> "Feb";
month_to_list(3) -> "Mar";
month_to_list(4) -> "Apr";
month_to_list(5) -> "May";
month_to_list(6) -> "Jun";
month_to_list(7) -> "Jul";
month_to_list(8) -> "Aug";
month_to_list(9) -> "Sep";
month_to_list(10) -> "Oct";
month_to_list(11) -> "Nov";
month_to_list(12) -> "Dec".

list_to_month("Jan") -> 1;
list_to_month("Feb") -> 2;
list_to_month("Mar") -> 3;
list_to_month("Apr") -> 4;
list_to_month("May") -> 5;
list_to_month("Jun") -> 6;
list_to_month("Jul") -> 7;
list_to_month("Aug") -> 8;
list_to_month("Sep") -> 9;
list_to_month("Oct") -> 10;
list_to_month("Nov") -> 11;
list_to_month("Dec") -> 12.

%%======================test==========================
get_msg_param_test()->
  SmsSendList = [
    {sms_type_jrj_test_mobile_verify,#{ signName => "郏仁杰" ,templateCode => "SMS_110555021"}}
  ],
  Result = get_msg_param(sms_type_jrj_test_mobile_verify,SmsSendList),
  ?assertEqual({<<233,131,143,228,187,129,230,157,176>>,<<"SMS_110555021">>},Result).
convent_mobile_test()->
  Mobiles = [<<"110">>,"10010",10086],
  Result = convent_mobile(Mobiles),
  ?assertEqual(<<"110,10010,10086">>,Result).
msg_convent_test()->

  Mobiles = [<<"110">>,"10010",10086],
  ParameterMap = #{ customer => <<"test">>},
  Result = msg_convent(Mobiles,ParameterMap),
  ?assertEqual([<<"multiContent">>,<<"110,10010,10086">>,
    <<"{\"10010\":{\"customer\":\"test\"},\"10086\":{\"customer\":\"test\"},\"110\":{\"customer\":\"test\"}}">>],Result).
