%%%-------------------------------------------------------------------
%%% @author jiarj
%%% @copyright (C) 2017, <COMPANY>
%%% @doc
%%%
%%% @end
%%% Created : 15. 十一月 2017 14:54
%%%-------------------------------------------------------------------
-module(ali_sms_sign).
-author("jiarj").

%% API
-export([sign/2 ,sort_query_string/1,sign_by_sortQueryString/2,sign_url_encode/3]).


sign(#{httpMethod := HttpMethod} = Map, Key) when is_binary(Key) ->
  KeyBin = ali_utils:convent_to_binary(Key),
  SortQueryString = sort_query_string(Map),
  SignStringEncoded = sign_by_sortQueryString(SortQueryString,HttpMethod),
  Signature = signature(SignStringEncoded, <<KeyBin/binary ,"&">>),
  Signature.

sign_url_encode(SortQueryString,HttpMethod,Key)->
  KeyBin = ali_utils:convent_to_binary(Key),
  SignStringEncoded = sign_by_sortQueryString(SortQueryString,HttpMethod),
  Signature = signature(SignStringEncoded, <<KeyBin/binary ,"&">>),
  specialUrlEncode(Signature).

sign_by_sortQueryString(SortQueryString,HttpMethod)->
  SpecialUrlEncodeSortQueryString = specialUrlEncode(SortQueryString),
  MethodBin = convert_key_to_qs(HttpMethod),
  SignString4Sign = <<MethodBin/binary, "&%2F&", SpecialUrlEncodeSortQueryString/binary>>,
  SignString4Sign.


sort_query_string(Map) ->
  RequireKeys = req_base_params() ++ req_service_params(),
  OptionKeys =  req_option_params(),
  RequirequeryString =  require_queryString(RequireKeys,Map),
  OptionqueryString =  option_queryString(OptionKeys,Map),
  QueryStringSort = lists:sort(RequirequeryString ++ OptionqueryString),
  ali_utils:remove_tail_char(list_to_binary(QueryStringSort),1).


require_queryString(Keys , Map)->
  F = fun
        (Key, Acc) ->
          AccNewRet = case maps:find(Key, Map) of
                        {ok, Value} ->
                          KeyBin = specialUrlEncode(convert_key_to_qs(Key)),
                          ValueBin = specialUrlEncode(convert_value_to_qs(Value)),
                          AccNew = <<KeyBin/binary, "=", ValueBin/binary, "&">>,
                          [AccNew|Acc];
                        _ ->
                          error(io:format("can't find key:~p in Req:~p~n",[Key,Map]))
                      end,
          AccNewRet
      end,
  lists:foldl(F, [], Keys).

option_queryString(Keys , Map)->
  F = fun
        (Key, Acc) ->
          AccNewRet = case maps:find(Key, Map) of
                        {ok, Value} ->
                          KeyBin = specialUrlEncode(convert_key_to_qs(Key)),
                          ValueBin = specialUrlEncode(convert_value_to_qs(Value)),
                          AccNew = <<KeyBin/binary, "=", ValueBin/binary, "&">>,
                          [AccNew|Acc];
                        error ->
                          %% not found this key ,omit it
                          Acc
                      end,
          AccNewRet
      end,
  lists:foldl(F, [], Keys).


convert_key_to_qs(post) ->
  <<"POST">>;
convert_key_to_qs(get) ->
  <<"GET">>;
convert_key_to_qs(Key) when is_atom(Key) ->
  <<LeadChar:1/binary, Rest/binary>> = atom_to_binary(Key, utf8),
  UpperChar = string:to_upper(binary_to_list(LeadChar)),
  UpperBin = list_to_binary(UpperChar),
  <<UpperBin/binary, Rest/binary>>.
convert_value_to_qs(Value) when is_atom(Value) ->
  atom_to_binary(Value, utf8);
convert_value_to_qs(Value) when is_map(Value) ->
  jsx:encode(Value);
convert_value_to_qs(Value) when is_integer(Value) ->
  integer_to_binary(Value);
convert_value_to_qs(Value) when is_list(Value) ->
  list_to_binary(Value);
convert_value_to_qs(Value) when is_binary(Value) ->
  Value.



req_base_params()->
  [accessKeyId , timestamp  , signatureMethod , signatureVersion , signatureNonce ].
req_service_params()->
  [action , version , regionId , phoneNumbers , signName , templateCode ].
req_option_params()->
  [format , templateParam , outId ].

signature(SignString, Key) ->
  HmacBin = crypto:hmac('sha', Key, SignString),
  Sig = base64:encode(HmacBin),
  Sig.

specialUrlEncode(Bin)->
  Urlencode = cow_qs:urlencode(Bin),
  UrlencodeReplace = binary:replace(Urlencode,<<"+">>,<<"%20">>,[global]),
  UrlencodeReplace2 = binary:replace(UrlencodeReplace,<<"*">>,<<"%2A">>,[global]),
  binary:replace(UrlencodeReplace2,<<"%7E">>,<<"~">>,[global]).


