%%%-------------------------------------------------------------------
%%% @author jiarj
%%% @copyright (C) 2017, <COMPANY>
%%% @doc
%%%
%%% @end
%%% Created : 09. 十一月 2017 11:09
%%%-------------------------------------------------------------------
-module(ali_mns_sign).
-author("jiarj").
-define(LINEFEEDS, <<"\n">>).

%% API
-export([
  sign/2
  , sign_string/1
  , signature/2
]).

sign(#{httpMethod := _HttpMethod} = Map, Key) ->
  Keybin = ali_utils:convent_to_binary(Key),
  SignStringReencoded = sign_string(Map),
  Signature = signature(SignStringReencoded, Keybin),
  Signature.

sign_string(Map) ->
  CommonFields = sign_fields_common(),
  F = fun
        (Key, Acc) ->
          Value = find(Key, Map),
          ValueBin = convert_value_to_qs(Value),
          AccNew = <<Acc/binary, ValueBin/binary, ?LINEFEEDS/binary>>,
          AccNew

      end,
  SignFieldsCommon = lists:foldl(F, <<>>, CommonFields),

  MsgFields = sign_fields_msg(),
  F2 = fun
         (Key2, Acc2) ->
           Value2 = find(Key2, Map),
           ValueBin2 = convert_value_to_qs(Value2),
           AccNew2 = <<Acc2/binary, ValueBin2/binary>>,
           AccNew2
       end,
  SignString = lists:foldl(F2, SignFieldsCommon, MsgFields),
  SignString.


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

signature(SignString, Key) when is_binary(SignString), is_binary(Key) ->
  HmacBin = crypto:hmac('sha', Key, SignString),
  Sig = base64:encode(HmacBin),
  Sig.

sign_fields_common() ->
  [httpMethod, contentMd5, contentType, date].
sign_fields_msg() ->
  [canonicalizedMNSHeaders, canonicalizedResource].

find(Key, Map) when (Key =:= contentMd5) or
  (Key =:= contentType) or
  (Key =:= canonicalizedMNSHeaders) ->
  Val = maps:get(Key, Map, <<"">>),
  Val;
find(Key, Map) ->
  case maps:find(Key, Map) of
    {ok, Val} -> Val;
    _ ->
      error(io:format("can't find key:~p in Req:~p~n",[Key,Map]))
  end.