%% -*-erlang-*-
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
%%%   SPU0 lexer.
%%% @end
%%%
%% @author Jan Henry Nystrom <JanHenryNystrom@gmail.com>
%% @copyright (C) 2013, Jan Henry Nystrom <JanHenryNystrom@gmail.com>
%%%-------------------------------------------------------------------

%% ===================================================================
%% Definitions.
%% ===================================================================
Definitions.

O       = [0-7]
D       = [0-9]
H       = [0-9a-fA-F]
U       = [A-Z]
L       = [a-z]
A       = ({U}|{L}|{D}|_|@)
WS      = ([\000-\s]|%.*)
Float   = {D}+\.{D}+((E|e)(\+|\-)?{D}+)?
Base    = {D}+#{H}+
Integer = {D}+
Atom    = {L}{A}*
Var     = ({U}|_){A}*
Char    = \$(\\{O}{O}{O}|\\\^.|\\.|.)
Single  = []()[}{|!?/;:,.*+#>=-]
String  = "(\\\^.|\\.|[^"])*"
QAtom   = '(\\\^.|\\.|[^'])*'

%'"

Rules.
{Float}   : {token, #float{line = TokenLine, value=list_to_float(TokenChars)}}.
{Base}    : base(TokenLine, TokenChars).
{Integer} : {token, #integer{line=TokenLine,value=list_to_integer(TokenChars)}}.
{Atom}    : mk(atom, TokenChars, TokenLine, TokenLen).
{QAtom}   : mk(quoted_atom, TokenChars, TokenLine, TokenLen).
{Var}     : {token, #var{line = TokenLine, name = list_to_atom(TokenChars)}}.
{String}  : mk(string, TokenChars, TokenLine, TokenLen).
{Char}    : {token, #char{line = TokenLine, value = cc_convert(TokenChars)}}.
->        : {token, {'->', TokenLine}}.
~>        : {token, {'~>', TokenLine}}.
<~        : {token, {'<~', TokenLine}}.
\|\|      : {token, {'||', TokenLine}}.
==        : {token, {'==', TokenLine}}.
/=        : {token, {'/=', TokenLine}}.
>=        : {token, {'>=', TokenLine}}.
=>        : {token, {'=>', TokenLine}}.
<         : {token, {'<', TokenLine}}.
`         : {token, {'`', TokenLine}}.
{Single}  : {token, {list_to_atom(TokenChars), TokenLine}}.
\.{WS}    : {end_token, {dot, TokenLine}}.
{WS}+     : skip_token.

%% ===================================================================
%% Erlang code.
%% ===================================================================
Erlang code.

%% API
-export([file/1]).

%% Includes
-include_lib("spu/src/spu0_scan.hrl").

%% Defines
-define(OCT(O), O >= $0, O =< $7).

%%====================================================================
%% API
%%====================================================================

%%--------------------------------------------------------------------
%% Function: file(FileName) -> Tokens.
%% @doc
%%   Tokenizes a .spu0 file.
%% @end
%%--------------------------------------------------------------------
-spec file(string()) -> [_].
%%--------------------------------------------------------------------
file(File) ->
    {ok, Bin} = file:read_file(File),
    case string(binary_to_list(Bin)) of
        {ok, Tokens, _} -> {ok, Tokens};
        Error -> Error
    end.

%%====================================================================
%% Internal functions
%%====================================================================

mk(quoted_atom, TokenChars, TokenLine, TokenLen) ->
    mk(atom, string_gen(unquote(TokenChars, TokenLen)), TokenLine, TokenLen);
mk(atom, TokenChars, TokenLine, _) ->
    case catch list_to_atom(TokenChars) of
        {'EXIT', _} -> {error, "illegal atom " ++ TokenChars};
        Atom ->
            case reserved_word(Atom) of
                true -> {token, {Atom, TokenLine}};
                false -> {token, #atom{line = TokenLine, name = Atom}}
            end
    end;
mk(string, TokenChars, TokenLine, TokenLen) ->
   {token, #string{line = TokenLine,
                   value = string_gen(unquote(TokenChars, TokenLen))}}.

unquote(Quoted, Length) -> lists:sublist(Quoted, 2, Length - 2).

reserved_word('after') -> true;
reserved_word('case') -> true;
reserved_word('end') -> true;
reserved_word('fun') -> true;
reserved_word('of') -> true;
reserved_word('receive') -> true;
reserved_word('when') -> true;
reserved_word('bnot') -> true;
reserved_word('not') -> true;
reserved_word('div') -> true;
reserved_word('rem') -> true;
reserved_word('band') -> true;
reserved_word('and') -> true;
reserved_word('bor') -> true;
reserved_word('bxor') -> true;
reserved_word('bsl') -> true;
reserved_word('bsr') -> true;
reserved_word('or') -> true;
reserved_word('xor') -> true;
reserved_word(_) -> false.

base(L, Cs) ->
    H = string:chr(Cs, $#),
    case list_to_integer(string:substr(Cs, 1, H - 1)) of
        B when B > 16 -> {error, "illegal base"};
        B ->
            case base(string:substr(Cs, H + 1), B, 0) of
                error -> {error, "illegal based number"};
                N -> {token, #integer{line = L, value = N}}
            end
    end.

base([C | Cs], Base, SoFar) when C >= $0, C =< $9, C < Base + $0 ->
    Next = SoFar * Base + (C - $0),
    base(Cs, Base, Next);
base([C | Cs], Base, SoFar) when C >= $a, C =< $f, C < Base + $a - 10 ->
    Next = SoFar * Base + (C - $a + 10),
    base(Cs, Base, Next);
base([C | Cs], Base, SoFar) when C >= $A, C =< $F, C < Base + $A - 10 ->
    Next = SoFar * Base + (C - $A + 10),
    base(Cs, Base, Next);
base([_ | _], _, _) ->
    error;  %Unknown character
base([], _, N) ->
    N.

cc_convert([$$, $\\ | Cs]) -> hd(string_escape(Cs));
cc_convert([$$, C]) -> C.

string_gen([]) -> [];
string_gen([$\\ | Cs]) -> string_escape(Cs);
string_gen([C | Cs]) -> [C | string_gen(Cs)].

string_escape([O1, O2, O3 | S]) when ?OCT(O1), ?OCT(O2), ?OCT(O3) ->
    [(O1*8 + O2)*8 + O3 - 73*$0 | string_gen(S)];
string_escape([$^, C | Cs]) ->
    [C band 31 | string_gen(Cs)];
string_escape([C | Cs]) when C >= $\000, C =< $\s ->
    string_gen(Cs);
string_escape([C | Cs]) ->
    [escape_char(C) | string_gen(Cs)].

escape_char($n) -> $\n; %\n = LF
escape_char($r) -> $\r; %\r = CR
escape_char($t) -> $\t; %\t = TAB
escape_char($v) -> $\v; %\v = VT
escape_char($b) -> $\b; %\b = BS
escape_char($f) -> $\f; %\f = FF
escape_char($e) -> $\e; %\e = ESC
escape_char($s) -> $\s; %\s = SPC
escape_char($d) -> $\d; %\d = DEL
escape_char(C) -> C.
