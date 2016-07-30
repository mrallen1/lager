-module(lager_file_open).

-compile(export_all).

-include_lib("eunit/include/eunit.hrl").

-define(DIRNAMES, ["./test1", "./test2", "./test3", "./test4", "./test5"]).
-define(FILENAMES, ["log1.log", "log2.log", "log3.log", "log4.log", "log5.log"]).

one_of(L) when is_list(L) ->
    lists:nth(random:uniform(length(L)), L);
one_of(_) -> error(bad_arg).

file_open_test() ->
    ?debugMsg("Removing files"),
    os:cmd("rm -rf test[0-5]"),
    timer:sleep(10),
    ok = file_open(10).

file_open(0) ->
    ok;
file_open(N) ->
    ?debugFmt("Test run: ~p~n", [N]),
    D = one_of(?DIRNAMES),
    F = one_of(?FILENAMES),
    Path = filename:join(D, F),
    ?debugFmt("Path: ~p~n", [Path]),
    {ok, {FD, Inode, Size}} = case N rem 2 == 0 of
        true ->
            ?debugMsg("Using unbuffered writes"),
            lager_util:open_logfile(Path, undefined);
        false ->
            ?debugMsg("Using buffered writes"),
            lager_util:open_logfile(Path, {64*1024, 1000})
    end,
    ?debugFmt("Inode: ~p, Size: ~p~n", [Inode, Size]),
    ok = write(FD, random:uniform(100)),
    true = filelib:is_regular(Path),
    ok = file:close(FD),
    file_open(N-1).


write(_FD, 0) ->
    ok;
write(FD, N) ->
    ?debugFmt("Writing message ~p", [N]),
    M = "This is message " ++ integer_to_list(N) ++ "\n",
    ok = file:write(FD, list_to_binary(M)),
    write(FD, N - 1).
