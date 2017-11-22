%%%-------------------------------------------------------------------
%%% @author jiarj
%%% @copyright (C) 2017, <COMPANY>
%%% @doc
%%%
%%% @end
%%% Created : 13. 十一月 2017 10:46
%%%-------------------------------------------------------------------
-module(gs_aliyun_mns).
-author("jiarj").
-behaviour(gen_server).
-export([init/1, handle_call/3, handle_cast/2, handle_info/2, terminate/2, code_change/3]).
-export([start_link/0]).
-export([process/3]).
-define(SERVER, ?MODULE).
-define(CONTENTTYPE,<<"text/xml;charset=utf-8">>).
-define(XMNSVERSION,<<"2015-06-06">>).
-record(state, {accountId, accessId, accessKey, topic, smsSendList}).

%% API
%%====================================================================
%% Internal functions
%%====================================================================
start_link() ->
  gen_server:start_link({local, ?SERVER}, ?MODULE, [], []).
init([]) ->

  {ok, AccessId} = application:get_env(accessId),
  {ok, AccessKey} = application:get_env(accessKey),
  {ok, AccountId} = application:get_env(accountId),
  {ok, Topic} = application:get_env(topic),
  {ok, SmsSendList} = application:get_env(smsSendList),

  {ok, #state{accessId = AccessId
    , accessKey = AccessKey
    , accountId = AccountId
    , topic = Topic
    , smsSendList = SmsSendList
  }}.

process(MsgType,PhoneNum,ParameterMap) when is_atom(MsgType),is_map(ParameterMap)->
  gen_server:call(?SERVER, {process, #{
    msgType => MsgType,
    parameterMap => ParameterMap,
    mobile => PhoneNum}}).

handle_call({process, #{msgType := MsgType,
  parameterMap := ParameterMap,
  mobile := Mobile} = _Map}, _From,
    #state{accessId = AccessId, accessKey = AccessKey, accountId = AccountId, topic = Topic, smsSendList = SmsSendList} = State) ->
  {SignName , TemplateCode} = ali_utils:get_msg_param(MsgType,SmsSendList),

  Uri = get_uri(Topic),
  Host = get_host(AccountId),
  Url = <<Host/binary , Uri/binary>> ,
  HttpMethod = <<"POST">> ,
  Date = ali_utils:now_gtm(),
  Authorization = get_authorization(#{httpMethod => HttpMethod
    , contentType => ?CONTENTTYPE
    , date => Date
    , canonicalizedMNSHeaders => <<"x-mns-version:" , ?XMNSVERSION/binary ,"\n" >>
    , canonicalizedResource => Uri},AccessId, AccessKey),
  [Type, Num, SmsParams] = ali_utils:msg_convent(Mobile,ParameterMap),

  DirectSMS = jsx:encode([
    {'FreeSignName', SignName}
    , {'TemplateCode', TemplateCode}
    , {'Type' , Type }
    , {'Receiver' ,Num }
    , {'SmsParams' , SmsParams}
  ]),

  NewMap = #{
    url => Url
%%    , host => Host
    , date => Date
%%    , httpMethod => HttpMethod
    , contentType => ?CONTENTTYPE
%%    , canonicalizedResource => Uri
    , xmlversion => ?XMNSVERSION
    , authorization => Authorization
    , directSMS => DirectSMS
  },
  {reply, NewMap, State};
handle_call(_Request,_From, State) ->
  {noreply, State}.


handle_cast(_Request, State) ->
  {noreply, State}.

handle_info(_Info, State) ->
  {noreply, State}.

terminate(_Reason, _State) ->
  ok.

code_change(_OldVsn, State, _Extra) ->
  {ok, State}.

get_uri(Topic) ->
  TopicName = ali_utils:convent_to_binary(Topic),
  <<"/topics/", TopicName/binary, "/messages">>.

get_host(AccessId) ->
  AccessIdBin = ali_utils:convent_to_binary(AccessId),
  <<"http://", AccessIdBin/binary, ".mns.cn-hangzhou.aliyuncs.com">>.

get_authorization(Map,AccessId, AccessKey) ->
  Signature = ali_mns_sign:sign(Map, AccessKey),
  Signature2 = ali_utils:convent_to_binary(Signature),
  AccessId2 = ali_utils:convent_to_binary(AccessId),
  <<"MNS ", AccessId2/binary, ":", Signature2/binary>>.
