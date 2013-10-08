%%%-------------------------------------------------------------------
%%% @copyright (C) 2011, VoIP INC
%%% @doc
%%%
%%% Handle client requests for phone_number documents
%%%
%%% @end
%%%-------------------------------------------------------------------
-module(wnm_other).

-export([find_numbers/2]).
-export([acquire_number/1]).
-export([disconnect_number/1]).

-include("../wnm.hrl").


-define(DEFAULT_COUNTRY, <<"US">>).
-define(WNM_OTHER_CONFIG_CAT, <<"number_manager.other">>).

%%--------------------------------------------------------------------
%% @public
%% @doc
%% Query the local system for a quanity of available numbers
%% in a rate center
%% @end
%%--------------------------------------------------------------------
-spec find_numbers/2 :: (ne_binary(), pos_integer()) -> {'error', _}.
find_numbers(Number, Quantity) ->
	DefaultCountry = whapps_config:get(?WNM_OTHER_CONFIG_CAT, <<"default_country">>, ?DEFAULT_COUNTRY),
	find_numbers(Number, Quantity, DefaultCountry).

find_numbers(Number, Quantity, Country) ->
	case whapps_config:get(?WNM_OTHER_CONFIG_CAT, <<"url">>) of
		'undefined' ->
			{'error', 'non_available'};
		Url ->
			get_numbers(Url, Country, Number, Quantity)
	end.

%%--------------------------------------------------------------------
%% @public
%% @doc
%% Acquire a given number from the carrier
%% @end
%%--------------------------------------------------------------------
-spec acquire_number/1 :: (wnm_number()) -> wnm_number().
acquire_number(#number{number=Num}=Number) ->
	DefaultCountry = whapps_config:get(?WNM_OTHER_CONFIG_CAT, <<"default_country">>, ?DEFAULT_COUNTRY),
	case whapps_config:get(?WNM_OTHER_CONFIG_CAT, <<"url">>) of
		'undefined' ->
			Error = <<"Unable to acquire numbers missing provider url">>,
    		wnm_number:error_carrier_fault(Error, Number);
		Url ->
			Hosts = case whapps_config:get(?WNM_OTHER_CONFIG_CAT, <<"endpoints">>) of
                        'undefined' -> [];
                        Endpoint when is_binary(Endpoint) ->
	                        [Endpoint];
                        Endpoints ->
                        	[E || E <- Endpoints]
                    end,
			ReqBody0 = wh_json:set_value(<<"data">>, wh_json:new(), wh_json:new()),
			ReqBody1 = wh_json:set_value([<<"data">>, <<"numbers">>], [Num], ReqBody0),
			ReqBody = wh_json:set_value([<<"data">>, <<"hosts">>], Hosts, ReqBody1),
			Uri = <<Url/binary, DefaultCountry/binary, "/order">>,
			case ibrowse:send_req(binary:bin_to_list(Uri), [], 'put', wh_json:encode(ReqBody)) of
				{'error', Reason} ->
					lager:error("number lookup failed: ~p", [Reason]),
    				wnm_number:error_carrier_fault(Reason, Number);
				{'ok', "200", _Headers, Body} ->
					format_put_resp(Body, Number);
				{'ok', _Status, _Headers, Body} ->
					lager:error("number lookup failed: ~p", [Body]),
					wnm_number:error_carrier_fault(Body, Number)
			end
	end.

	


%%--------------------------------------------------------------------
%% @public
%% @doc
%% Release a number from the routing table
%% @end
%%--------------------------------------------------------------------
-spec disconnect_number/1 :: (wnm_number()) -> wnm_number().
disconnect_number(Number) -> Number.


get_numbers(Url, Country, Number, Quantity) ->
	ReqBody = <<"?pattern=", Number/binary, "&limit=", Quantity/binary>>,
	Uri = <<Url/binary, Country/binary, "/search", ReqBody/binary>>,
	case ibrowse:send_req(binary:bin_to_list(Uri), [], 'get') of
		{'error', Reason} ->
			lager:error("number lookup error: ~p", [Reason]),
			{'error', 'non_available'};
		{'ok', "200", _Headers, Body} ->
			format_get_resp(wh_json:decode(Body));
		{'ok', _Status, _Headers, Body} ->
			lager:error("number lookup failed: ~p ~p", [_Status, Body]),
			{'error', 'non_available'}
	end.

format_get_resp(Body) ->
	case wh_json:get_value(<<"status">>, Body) of
		<<"success">> ->
			Numbers = wh_json:get_value(<<"data">>, Body, wh_json:new()),
			{'ok', Numbers};
		_Error ->
			lager:error("number lookup resp error: ~p", [_Error]),
			{'error', 'non_available'}
	end.

format_put_resp(Body, Number) ->
	io:format("MARKER0 ~p~n", [Body]),
	case wh_json:get_value(<<"status">>, Body) of
		<<"success">> ->
			Number;
		Error ->
			lager:error("number lookup resp error: ~p", [Error]),
			wnm_number:error_carrier_fault(Error, Number)
	end.




