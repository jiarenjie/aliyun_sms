%%%-------------------------------------------------------------------
%% @doc aliyun_sms public API
%% @end
%%%-------------------------------------------------------------------

-module(aliyun_sms).

-behaviour(application).
-include_lib("xmerl/include/xmerl.hrl").
%% Application callbacks
-export([start/2, stop/1]).
-export([single_sms/3,batch_sms/3]).

%%====================================================================
%% API
%%====================================================================

start(_StartType, _StartArgs) ->
    aliyun_sms_sup:start_link().

%%--------------------------------------------------------------------
stop(_State) ->
    ok.

%%====================================================================
%% Internal functions
%%====================================================================


single_sms(MsgType, PhoneNum, ParameterMap) when is_atom(MsgType),is_map(ParameterMap) ->
%%    M = ali_utils:default_modle(),
    {ok,GateWay} = application:get_env(aliyun_sms,gateWay),
    M = ali_utils:default_modle(GateWay),
    Acc = M:process(MsgType,PhoneNum,ParameterMap),
    send_sms(Acc).

batch_sms(MsgType, PhoneNums, ParameterMap)  when is_atom(MsgType),is_map(ParameterMap),is_list(PhoneNums)->
    M = ali_utils:default_modle(),
    Acc = M:process(MsgType,PhoneNums,ParameterMap),
    send_sms(Acc).

send_sms(#{
    url := Url
    , date := Date
    , contentType := Type
    , xmlversion := XmlVersion
    , authorization := Authorization
    , directSMS := DirectSMS
} = Req)when is_map(Req) ->
    Header = [
        {"Date",ali_utils:convent_to_string(Date)}
        ,{"Authorization",ali_utils:convent_to_string(Authorization)}
        ,{"x-mns-version" , ali_utils:convent_to_string(XmlVersion)}
    ],
%%  todo template to get xml
    Vals = [
        {directSMS,DirectSMS}
    ],
    {ok,Body} = ali_msg_dtl:render(Vals),
%%  send http post
    lager:info("Url:~p",[Url]),
    lager:info("Header:~p",[Header]),
    lager:info("Type:~p",[Type]),
    lager:info("DirectSMS:~ts",[DirectSMS]),
    lager:info("Body:~ts",[Body]),
    {ok,{_,_,Body2}} = http_utils:http_post(Url,Header,Type,Body),
%%  解析response xml
    {XmlElt, _} = xmerl_scan:string(Body2),
    try
        [#xmlText{value = MessageId }] = xmerl_xpath:string("/Message/MessageId/text()", XmlElt),
        lager:info("MessageId:~p",[MessageId]),
        {ok,MessageId}
    catch
        _:_  ->
            [#xmlText{value = Code }] = xmerl_xpath:string("/Error/Code/text()", XmlElt),
            lager:error("Code:~p",[Code]),
            [#xmlText{value = RequestId }] = xmerl_xpath:string("/Error/RequestId/text()", XmlElt),
            lager:error("RequestId:~p",[RequestId]),
            {error,RequestId,Code}
    end;
send_sms(Url)when is_binary(Url)->
    {ok,{_,_,Body}} = http_utils:http_get(binary_to_list(Url)),
    {XmlElt, _} = xmerl_scan:string(Body),

    try
        [#xmlText{value = RequestId }] = xmerl_xpath:string("/SendSmsResponse/RequestId/text()", XmlElt),
        {ok,RequestId}
    catch
        _:_ ->
            [#xmlText{value = Code }] = xmerl_xpath:string("/Error/Code/text()", XmlElt),
            lager:error("Code:~p",[Code]),
            [#xmlText{value = RequestId }] = xmerl_xpath:string("/Error/RequestId/text()", XmlElt),
            lager:error("Message:~p",[RequestId]),
            {error,RequestId,Code}
    end.