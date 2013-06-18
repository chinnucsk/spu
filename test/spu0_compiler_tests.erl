%%==============================================================================
%% Copyright 2013 Jan Henry Nystrom <JanHenryNystrom@gmail.com>
%%
%% Licensed under the Apache License, Version 2.0 (the "License");
%% you may not use this file except in compliance with the License.
%% You may obtain a copy of the License at
%%
%% http://www.apache.org/licenses/LICENSE-2.0
%%
%% Unless required by applicable law or agreed to in writing, software
%% distributed under the License is distributed on an "AS IS" BASIS,
%% WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
%% See the License for the specific language governing permissions and
%% limitations under the License.
%%==============================================================================

%%%-------------------------------------------------------------------
%%% @doc
%%%   eunit unit tests for SPU(0) compiler.
%%% @end
%%%
%% @author Jan Henry Nystrom <JanHenryNystrom@gmail.com>
%% @copyright (C) 2013, Jan Henry Nystrom <JanHenryNystrom@gmail.com>
%%%-------------------------------------------------------------------
-module(spu0_compiler_tests).
-copyright('Jan Henry Nystrom <JanHenryNystrom@gmail.com>').

%% Includes
-include_lib("eunit/include/eunit.hrl").

%% ===================================================================
%% Tests.
%% ===================================================================

%%%-------------------------------------------------------------------
% Distro
%%%-------------------------------------------------------------------
parse_distro_compile_test_() ->
    [?_test(?assertMatch(_, spu0_compiler:compile(File))) ||
        File <- files(distro)].

parse_distro_src_test_() ->
    [?_test(?assertMatch(_,
                         spu0_compiler:compile(filename:basename(File),
                                               [{src_dir,
                                                 filename:dirname(File)}])))

     || File <- files(distro)].

parse_distro_src_atom_test_() ->
    [?_test(
        ?assertMatch(_,
                     spu0_compiler:compile(
                       list_to_atom(filename:basename(File)),
                       [{src_dir,filename:dirname(File)}])))
     || File <- files(distro)].


%% ===================================================================
%% Internal functions.
%% ===================================================================

files(distro) ->
    Dir = filename:join([code:lib_dir(spu),
                         "test",
                         "spu0"]),
    {ok, Files} = file:list_dir(Dir),
    [filename:join([Dir, File]) ||
        File <- Files, filename:extension(File) == ".spu0"].
