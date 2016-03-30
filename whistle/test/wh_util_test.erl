%%%-------------------------------------------------------------------
%%% @copyright (C) 2010-2015, 2600Hz INC
%%% @doc
%%% Various utilities - a veritable cornicopia
%%% @end
%%% @contributors
%%%   James Aimonetti
%%%   Karl Anderson
%%%-------------------------------------------------------------------
-module(wh_util_test).

-include_lib("whistle/include/wh_types.hrl").

-ifdef(PROPER).
- include_lib("proper/include/proper.hrl").
-endif.
-include_lib("eunit/include/eunit.hrl").

-include_lib("whistle/include/wh_types.hrl").

%% PROPER TESTING
-ifdef(PROPER).

prop_to_integer() ->
    ?FORALL({F, I}
            ,{float(), integer()}
            ,begin
                 Is = [[Fun(N), N]
                        || Fun <- [fun wh_util:to_list/1
                                   ,fun wh_util:to_binary/1
                                  ],
                           N <- [F, I]
                      ],
                 lists:all(fun([FN, N]) ->
                                   erlang:is_integer(wh_util:to_integer(N))
                                       andalso erlang:is_integer(wh_util:to_integer(FN))
                           end
                           ,Is
                          )
             end).

prop_to_number() ->
    ?FORALL({F, I}
            ,{float(), integer()}
            ,begin
                 Is = [[Fun(N), N]
                       || Fun <- [fun wh_util:to_list/1
                                  ,fun wh_util:to_binary/1
                                 ],
                          N <- [F, I]
                      ],
                 lists:all(fun([FN, N]) ->
                                   erlang:is_number(wh_util:to_number(N))
                                       andalso erlang:is_number(wh_util:to_number(FN))
                           end
                           ,Is
                          )
             end).

prop_to_float() ->
    ?FORALL({F, I}
            ,{float(), integer()}
            ,begin
                 Fs = [[Fun(N), N]
                       || Fun <- [fun wh_util:to_list/1
                                  ,fun wh_util:to_binary/1
                                 ],
                          N <- [F, I]
                      ],
                 lists:all(fun([FN, N]) ->
                                   erlang:is_float(wh_util:to_float(N))
                                       andalso erlang:is_float(wh_util:to_float(FN))
                           end
                           ,Fs
                          )
             end).

prop_to_list() ->
    ?FORALL({A, L, B, I, F}
            ,{atom(), list(), binary(), integer(), float()}
            ,lists:all(fun(X) -> is_list(wh_util:to_list(X)) end, [A, L, B, I, F])
           ).

%%-type iolist() :: maybe_improper_list(char() | binary() | iolist(), binary() | []).
prop_to_binary() ->
    ?FORALL({A, L, B, I, F, IO}
            ,{atom(), list(range(0,255)), binary(), integer(), float(), iolist()}
            ,lists:all(fun(X) -> is_binary(wh_util:to_binary(X)) end, [A, L, B, I, F, IO])
           ).

prop_iolist_t() ->
    ?FORALL(IO, iolist(), is_binary(wh_util:to_binary(IO))).

prop_to_from_hex() ->
    ?FORALL({F}, {binary()},
            begin
                F =:= wh_util:from_hex_binary(wh_util:to_hex_binary(F))
            end).

prop_pretty_print_elapsed_s() ->
    ?FORALL({D, H, M, S}
            ,{non_neg_integer(), range(0,23), range(0, 59), range(0,59)}
            ,begin
                 Seconds = (D * ?SECONDS_IN_DAY) + (H * ?SECONDS_IN_HOUR) + (M * ?SECONDS_IN_MINUTE) + S,
                 Expected = lists:foldl(fun({0, "s"}, "") ->
                                                ["s", <<"0">>];
                                           ({0, _}, Acc) -> Acc;
                                           ({N, Unit}, Acc) -> [Unit, wh_util:to_binary(N) | Acc]
                                        end
                                        ,[]
                                        ,[{D, "d"}
                                          ,{H, "h"}
                                          ,{M, "m"}
                                          ,{S, "s"}
                                         ]),
                 Result = wh_util:pretty_print_elapsed_s(Seconds),
                 Result =:= iolist_to_binary(lists:reverse(Expected))
             end).


prop_pretty_print_bytes() ->
    ?FORALL({T, G, M, K, B}
            ,{range(0,3), range(0,1023), range(0,1023), range(0,1023), range(0,1023)}
            ,begin
                 Bytes = (T * ?BYTES_T) + (G * ?BYTES_G) + (M * ?BYTES_M) + (K * ?BYTES_K) + B,
                 Expected = iolist_to_binary(
                              lists:reverse(
                                lists:foldl(fun({0, "B"}, "") ->
                                                    ["B", <<"0">>];
                                               ({0, _}, Acc) -> Acc;
                                               ({N, Unit}, Acc) -> [Unit, wh_util:to_binary(N) | Acc]
                                            end
                                           ,[]
                                           ,[{T, "T"}
                                            ,{G, "G"}
                                            ,{M, "M"}
                                            ,{K, "K"}
                                            ,{B, "B"}
                                            ])
                               )
                             ),
                 Result = wh_util:pretty_print_bytes(Bytes),
                 ?WHENFAIL(io:format("~pT ~pG ~pM ~pK ~pB (~pb): ~p =:= ~p~n", [T, G, M, K, B, Bytes, Result, Expected])
                          ,Result =:= Expected
                          )
             end).

proper_test_() ->
    {"Runs the module's PropEr tests during eunit testing",
     {'timeout', 15000,
      [
       ?_assertEqual([], proper:module(?MODULE, [{'to_file', 'user'}]))
      ]}}.

-endif.

pad_binary_test() ->
    ?assertEqual(<<"1234500000">>, wh_util:pad_binary(<<"12345">>, 10, <<"0">>)).

greg_secs_to_unix_secs_test() ->
    GregSecs = wh_util:current_tstamp(),
    ?assertEqual(GregSecs - ?UNIX_EPOCH_IN_GREGORIAN, wh_util:gregorian_seconds_to_unix_seconds(GregSecs)).

unix_secs_to_greg_secs_test() ->
    UnixSecs = 1000000000,
    ?assertEqual(UnixSecs + ?UNIX_EPOCH_IN_GREGORIAN, wh_util:unix_seconds_to_gregorian_seconds(UnixSecs)).

microsecs_to_secs_test() ->
    Microsecs = 1310157838405890,
    Secs = 1310157838,
    ?assertEqual(Secs, wh_util:microseconds_to_seconds(Microsecs)).

elapsed_test() ->
    Start = {1401,998570,817606},
    Now = {1401,998594,798064},

    ?assertEqual(wh_util:elapsed_us(Start, Now), 23980458),
    ?assertEqual(wh_util:elapsed_ms(Start, Now), 23980),
    ?assertEqual(wh_util:elapsed_s(Start, Now), 23),

    StartDateTime = {{2014,6,5},{20,7,7}},
    StartTimestamp = calendar:datetime_to_gregorian_seconds(StartDateTime),

    NowDateTime = {{2014,6,5},{20,7,9}},
    NowTimestamp = calendar:datetime_to_gregorian_seconds(NowDateTime),

    ?assertEqual(wh_util:elapsed_s(StartTimestamp, NowTimestamp), 2),
    ?assertEqual(wh_util:elapsed_ms(StartTimestamp, NowTimestamp), 2000),
    ?assertEqual(wh_util:elapsed_us(StartTimestamp, NowTimestamp), 2000000).

join_binary_test() ->
    ?assertEqual(<<"foo">>, wh_util:join_binary([<<"foo">>], <<", ">>)),
    ?assertEqual(<<"foo, bar">>, wh_util:join_binary([<<"foo">>, <<"bar">>], <<", ">>)),
    ?assertEqual(<<"foo, bar, baz">>, wh_util:join_binary([<<"foo">>, <<"bar">>, <<"baz">>], <<", ">>)).

ucfirst_binary_test() ->
    ?assertEqual(<<"Foo">>, wh_util:ucfirst_binary(<<"foo">>)),
    ?assertEqual(<<"Foo">>, wh_util:ucfirst_binary(<<"Foo">>)),
    ?assertEqual(<<"FOO">>, wh_util:ucfirst_binary(<<"FOO">>)),
    ?assertEqual(<<"1oo">>, wh_util:ucfirst_binary(<<"1oo">>)),
    ?assertEqual(<<"100">>, wh_util:ucfirst_binary(<<"100">>)),
    ?assertEqual(<<"1FF">>, wh_util:ucfirst_binary(<<"1FF">>)).

lcfirst_binary_test() ->
    ?assertEqual(<<"foo">>, wh_util:lcfirst_binary(<<"foo">>)),
    ?assertEqual(<<"foo">>, wh_util:lcfirst_binary(<<"Foo">>)),
    ?assertEqual(<<"fOO">>, wh_util:lcfirst_binary(<<"FOO">>)),
    ?assertEqual(<<"1oo">>, wh_util:lcfirst_binary(<<"1oo">>)),
    ?assertEqual(<<"100">>, wh_util:lcfirst_binary(<<"100">>)),
    ?assertEqual(<<"1FF">>, wh_util:lcfirst_binary(<<"1FF">>)).

to_lower_binary_test() ->
    ?assertEqual(<<"foo">>, wh_util:to_lower_binary(<<"foo">>)),
    ?assertEqual(<<"foo">>, wh_util:to_lower_binary(<<"Foo">>)),
    ?assertEqual(<<"foo">>, wh_util:to_lower_binary(<<"FoO">>)),
    ?assertEqual(<<"f00">>, wh_util:to_lower_binary(<<"f00">>)),
    ?assertEqual(<<"f00">>, wh_util:to_lower_binary(<<"F00">>)).

to_upper_binary_test() ->
    ?assertEqual(<<"FOO">>, wh_util:to_upper_binary(<<"foo">>)),
    ?assertEqual(<<"FOO">>, wh_util:to_upper_binary(<<"Foo">>)),
    ?assertEqual(<<"FOO">>, wh_util:to_upper_binary(<<"FoO">>)),
    ?assertEqual(<<"F00">>, wh_util:to_upper_binary(<<"f00">>)),
    ?assertEqual(<<"F00">>, wh_util:to_upper_binary(<<"F00">>)).

to_lower_string_test() ->
    ?assertEqual("foo", wh_util:to_lower_string("foo")),
    ?assertEqual("foo", wh_util:to_lower_string("Foo")),
    ?assertEqual("foo", wh_util:to_lower_string("FoO")),
    ?assertEqual("f00", wh_util:to_lower_string("f00")),
    ?assertEqual("f00", wh_util:to_lower_string("F00")).

to_upper_string_test() ->
    ?assertEqual("FOO", wh_util:to_upper_string("foo")),
    ?assertEqual("FOO", wh_util:to_upper_string("Foo")),
    ?assertEqual("FOO", wh_util:to_upper_string("FoO")),
    ?assertEqual("F00", wh_util:to_upper_string("f00")),
    ?assertEqual("F00", wh_util:to_upper_string("F00")).

strip_binary_test() ->
    ?assertEqual(<<"foo">>, wh_util:strip_binary(<<"foo">>)),
    ?assertEqual(<<"foo">>, wh_util:strip_binary(<<"foo ">>)),
    ?assertEqual(<<"foo">>, wh_util:strip_binary(<<" foo ">>)),
    ?assertEqual(<<"foo">>, wh_util:strip_binary(<<"  foo  ">>)),
    ?assertEqual(<<"foo">>, wh_util:strip_binary(<<"     foo">>)),

    ?assertEqual(<<"foo">>, wh_util:strip_left_binary(<<"foo">>, $\s)),
    ?assertEqual(<<"foo">>, wh_util:strip_left_binary(<<" foo">>, $\s)),
    ?assertEqual(<<"foo ">>, wh_util:strip_left_binary(<<" foo ">>, $\s)),
    ?assertEqual(<<"foo ">>, wh_util:strip_left_binary(<<"foo ">>, $\s)),

    ?assertEqual(<<"foo">>, wh_util:strip_right_binary(<<"foo">>, $\s)),
    ?assertEqual(<<" foo">>, wh_util:strip_right_binary(<<" foo">>, $\s)),
    ?assertEqual(<<" foo">>, wh_util:strip_right_binary(<<" foo ">>, $\s)),
    ?assertEqual(<<"foo">>, wh_util:strip_right_binary(<<"foo ">>, $\s)).

to_boolean_test() ->
    All = [<<"true">>, "true", 'true', <<"false">>, "false", 'false'],
    NotAll = [0, 123, 1.23, "123", "abc", 'abc', <<"abc">>, <<"123">>, {'what', 'is', 'this', 'doing', 'here'}],
    ?assertEqual('true', lists:all(fun(X) ->
                                           try wh_util:to_boolean(X) of
                                               _ -> 'true'
                                           catch _:_ -> 'false'
                                           end
                                   end
                                   ,All
                                  )
                ),
    ?assertEqual('true', lists:all(fun(X) ->
                                           try wh_util:to_boolean(X) of
                                               _ -> 'false'
                                           catch _:_ -> 'true'
                                           end
                                   end
                                   ,NotAll
                                  )
                ).

strip_test() ->
    ?assertEqual(wh_util:strip_binary(<<"...Hello.....">>, $.), <<"Hello">>).

uri_test() ->
    ?assertEqual(<<"http://test.com/path1/path2">>, wh_util:uri(<<"http://test.com">>, [<<"path1">>, <<"path2">>])),
    ?assertEqual(<<"http://192.168.0.1:8888/path1/path2">>, wh_util:uri(<<"http://192.168.0.1:8888/">>, [<<"path1">>, <<"path2">>])),
    ?assertEqual(<<"http://test.com/path1/path2">>, wh_util:uri(<<"http://test.com/">>, [<<"path1/">>, <<"path2/">>])).

suffix_binary_test() ->
    ?assertEqual('true', wh_util:suffix_binary(<<"34">>, <<"1234">>)),
    ?assertEqual('false', wh_util:suffix_binary(<<"34">>, <<"12345">>)),
    ?assertEqual('false', wh_util:suffix_binary(<<"1234">>, <<"1">>)).

rfc1036_test() ->
    Tests = [{ {{2015,4,7},{1,3,2}}, <<"Tue, 07 Apr 2015 01:03:02 GMT">>}
             ,{ {{2015,12,12},{12,13,12}}, <<"Sat, 12 Dec 2015 12:13:12 GMT">>}
             ,{ 63595733389, <<"Wed, 08 Apr 2015 17:29:49 GMT">>}
            ],
    lists:foreach(fun({Date, Expected}) ->
                          ?assertEqual(Expected, wh_util:rfc1036(Date))
                  end, Tests).

iso8601_test() ->
    Tests = [{ {{2015,4,7},{1,3,2}}, <<"2015-04-07">>}
             ,{ {{2015,12,12},{12,13,12}}, <<"2015-12-12">>}
             ,{ 63595733389, <<"2015-04-08">>}
            ],
    lists:foreach(fun({Date, Expected}) ->
                          ?assertEqual(Expected, wh_util:iso8601(Date))
                  end, Tests).

resolve_uri_test() ->
    RawPath = <<"http://pivot/script.php">>,
    Relative = <<"script2.php">>,

    ?assertEqual(<<"http://pivot/script2.php">>, wh_util:resolve_uri(RawPath, Relative)),
    ?assertEqual(<<"http://pivot/script2.php">>, wh_util:resolve_uri(RawPath, <<"/", Relative/binary>>)).

account_formats_test_() ->
    AccountId = <<A:2/binary, B:2/binary, Rest/binary>> = wh_util:rand_hex_binary(16),
    AccountDbUn = list_to_binary(["account/", A, "/", B, "/", Rest]),
    AccountDbEn = list_to_binary(["account%2F", A, "%2F", B, "%2F", Rest]),

    {Y, M, _} = erlang:date(),
    Year = wh_util:to_binary(Y),
    Month = wh_util:pad_month(M),

    MODb = list_to_binary([AccountId, "-", Year, Month]),
    MODbEn = list_to_binary([AccountDbEn, "-", Year, Month]),

    Formats = [AccountId, AccountDbUn, AccountDbEn
               ,MODb, MODbEn
              ],
    Funs = [{fun(F) -> wh_util:format_account_id(F, 'raw') end, AccountId}
            ,{fun(F) -> wh_util:format_account_id(F, 'unencoded') end, AccountDbUn}
            ,{fun(F) -> wh_util:format_account_id(F, 'encoded') end, AccountDbEn}
            ,{fun wh_util:format_account_mod_id/1, MODbEn}
           ],
    [{format_title(Format, Expected)
      ,?_assertEqual(Expected, Fun(Format))
     }
     || {Fun, Expected} <- Funs,
        Format <- Formats
    ].

format_title(Format, Expected) ->
    wh_util:to_list(
      iolist_to_binary(
        ["Converting ", Format, " to ", Expected]
       )
     ).


pretty_print_bytes_test() ->
    Tests = [{0, <<"0B">>}
            ,{1, <<"1B">>}
            ,{2, <<"2B">>}

            ,{?BYTES_K-1, <<"1023B">>}
            ,{?BYTES_K, <<"1K">>}
            ,{?BYTES_K+1, <<"1K1B">>}

            ,{?BYTES_M-1, <<"1023K1023B">>}
            ,{?BYTES_M, <<"1M">>}
            ,{?BYTES_M+1, <<"1M1B">>}

            ,{?BYTES_G-1, <<"1023M1023K1023B">>}
            ,{?BYTES_G, <<"1G">>}
            ,{?BYTES_G+1, <<"1G1B">>}

            ,{?BYTES_T-1, <<"1023G1023M1023K1023B">>}
            ,{?BYTES_T, <<"1T">>}
            ,{?BYTES_T+1, <<"1T1B">>}
            ],
    [?assertEqual({Bytes, Formatted}, {Bytes, wh_util:pretty_print_bytes(Bytes)})
     || {Bytes, Formatted} <- Tests
    ].
