-module(boss_web_controller_cowboy).

-export([dispatch_cowboy/1]).

%% cowboy dispatch rule for static content
dispatch_cowboy(Applications) ->
    AppStaticDispatches = create_cowboy_dispatches(Applications),

    BossDispatch	= [{'_', boss_mochicow_handler, [{loop, {boss_mochicow_handler, loop}}]}],
    % [{"/", boss_mochicow_handler, []}],
    %Dispatch		= [{'_',

    Dispatch		= [{'_', AppStaticDispatches ++ BossDispatch}],
    SSLEnabled = boss_env:get_env(ssl_enable, false),
    CowboyListener        = get_listener(SSLEnabled),
    cowboy:set_env(CowboyListener, dispatch, cowboy_router:compile(Dispatch)).

-spec(get_listener(boolean()) -> boss_https_listener|boss_http_listener).
get_listener(true) -> boss_https_listener;
get_listener(false) -> boss_http_listener.

create_cowboy_dispatches(Applications) ->
    lists:map(fun create_dispatch/1, Applications).

-spec(create_dispatch(atom()) -> {string(), cowboy_static, [_]}).
create_dispatch(AppName) ->
    BaseURL             = boss_env:get_env(AppName, base_url, "/"),
    StaticPrefix        = boss_env:get_env(AppName, static_prefix, "/static"),
    Path                = BaseURL ++ StaticPrefix,
    Handler             = cowboy_static,
    Opts                = [
			   {directory, {priv_dir, AppName, [<<"static">>]}},
			   {mimetypes, {fun mimetypes:path_to_mimes/2, default}}
			  ],
    {Path ++ "[...]", Handler, Opts}.
      
