-ifndef(KZT_HRL).

-include_lib("kazoo/include/kz_types.hrl").
-include_lib("kazoo/include/kz_log.hrl").

-type ok_return() :: {'ok', kapps_call:call()}.
-type stop_return() :: {'stop', kapps_call:call()}.
-type usurp_return() :: {'usurp', kapps_call:call()}.
-type request_return() :: {'request', kapps_call:call()}.

-type exec_element_return() ::
        ok_return() |
        stop_return() |
        usurp_return() |
        request_return().

-type exec_return() :: exec_element_return().

-define(KZT_USER_VARS, <<"user_vars">>).

-define(CONFIG_CAT, <<"pivot">>).

-define(TTS_CONFIG_CAT, <<"speech">>).
-define(TTS_SIZE_LIMIT, 4000).

-define(STATUS_QUEUED, <<"queued">>).
-define(STATUS_RINGING, <<"ringing">>).
-define(STATUS_ANSWERED, <<"in-progress">>).
-define(STATUS_COMPLETED, <<"completed">>).
-define(STATUS_BUSY, <<"busy">>).
-define(STATUS_FAILED, <<"failed">>).
-define(STATUS_NOANSWER, <<"no-answer">>).
-define(STATUS_CANCELED, <<"canceled">>).

-define(APP_NAME, <<"translator">>).
-define(APP_VERSION, <<"4.0.0">>).

-define(DEFAULT_TTS_ENGINE, kapps_config:get_binary(?TTS_CONFIG_CAT, <<"tts_provider">>, <<"flite">>)).
-define(DEFAULT_TTS_LANG, kapps_config:get_binary(?TTS_CONFIG_CAT, <<"tts_language">>, <<"en-US">>)).
-define(DEFAULT_TTS_VOICE, kapps_config:get_binary(?TTS_CONFIG_CAT, <<"tts_voice">>, <<"male">>)).

-define(KZT_HRL, 'true').
-endif.
