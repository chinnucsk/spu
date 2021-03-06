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
%%%   SPU0 parser.
%%% @end
%%%
%% @author Jan Henry Nystrom <JanHenryNystrom@gmail.com>
%% @copyright (C) 2013, Jan Henry Nystrom <JanHenryNystrom@gmail.com>
%%%-------------------------------------------------------------------

%% ===================================================================
%% Nonterminals.
%% ===================================================================
Nonterminals
form
attribute attr_val
function function_clauses function_clause
clause_args clause_guard clause_body
expr expr_100 expr_200 expr_400 expr_500
expr_600 expr_700 expr_800 expr_900
expr_max
map map_expr map_exprs map_index
sequence tail
lc_expr lc_exprs
map_comprehension mc_expr mc_exprs
sequence_generator
binary_comprehension
case_expr cr_clause cr_clauses receive_expr
fun_expr fun_clause fun_clauses atom_or_var integer_or_var
function_call argument_list
exprs guard
atomic strings
prefix_op mult_op add_op comp_op
binary bin_elements bin_element bit_expr
opt_bit_size_expr bit_size_expr opt_bit_type_list bit_type_list bit_type.

%% ===================================================================
%% Terminals.
%% ===================================================================
Terminals
char integer float atom string var

'(' ')' ',' '->' '~>' '<~' '{' '}' '[' ']' '|' '||' ';' ':' '`'
'after' 'case' 'end' 'fun' 'of' 'receive' 'when'
'bnot' 'not'
'*' '/' 'div' 'rem' 'band' 'and'
'+' '-' 'bor' 'bxor' 'bsl' 'bsr' 'or' 'xor'
'==' '/=' '>=' '>' '=>'
'<'
'!' '='
% helper
dot.

%% ===================================================================
%% Expected shit/reduce conflicts.
%% ===================================================================
Expect 1.

%% ===================================================================
%% Rootsymbol.
%% ===================================================================
Rootsymbol form.

%% ===================================================================
%% Rules.
%% ===================================================================

form -> attribute dot : '$1'.
form -> function dot  : '$1'.

attribute -> '-' atom attr_val      : build_attribute('$2', '$3').

attr_val -> expr                    : ['$1'].
attr_val -> expr ',' exprs          : ['$1' | '$3'].
attr_val -> '(' expr ',' exprs ')'  : ['$2' | '$4'].

function -> function_clauses : build_function('$1').

function_clauses -> function_clause                      : ['$1'].
function_clauses -> function_clause ';' function_clauses : ['$1' | '$3'].

function_clause -> atom clause_args clause_guard clause_body :
    #atom{line = Line, name = Name} = '$1',
    #clause_p{line = Line, name = Name, args = '$2', guard = '$3', body = '$4'}.

clause_args -> argument_list : #argument_list{args = Args} = '$1', Args.

clause_guard -> 'when' guard : '$2'.
clause_guard -> '$empty'     : [].

clause_body -> '->' exprs    : '$2'.


expr -> '`' expr '`' : #exception_p{line = line('$1'), expr = '$2'}.
expr -> expr_100     : '$1'.

expr_100 -> expr_200 '=' expr_100 :
    #match_p{line = line('$2'), left = '$1', right = '$3'}.
expr_100 -> expr_200 '!' expr_100 : mkop('$1', '$2', '$3').
expr_100 -> expr_200              : '$1'.

expr_200 -> expr_400 comp_op expr_400 : mkop('$1', '$2', '$3').
expr_200 -> expr_400                  : '$1'.

expr_400 -> expr_400 add_op expr_500 : mkop('$1', '$2', '$3').
expr_400 -> expr_500                 : '$1'.

expr_500 -> expr_500 mult_op expr_600 : mkop('$1', '$2', '$3').
expr_500 -> expr_600                  : '$1'.

expr_600 -> prefix_op expr_700 : mkop('$1', '$2').
expr_600 -> expr_700           : '$1'.

expr_700 -> function_call : '$1'.
expr_700 -> expr_800      : '$1'.

expr_800 -> expr_900 ':' expr_max :
    #remote_p{line = line('$2'), module = '$1', function = '$3'}.
expr_800 -> expr_900              : '$1'.

expr_900 -> expr_max : '$1'.

expr_max -> var                  : '$1'.
expr_max -> atomic               : '$1'.
expr_max -> map                  : '$1'.
expr_max -> sequence             : '$1'.
expr_max -> binary               : '$1'.
expr_max -> map_comprehension    : '$1'.
expr_max -> sequence_generator   : '$1'.
expr_max -> binary_comprehension : '$1'.
expr_max -> '(' expr ')'         : '$2'.
expr_max -> case_expr            : '$1'.
expr_max -> receive_expr         : '$1'.
expr_max -> fun_expr             : '$1'.

map -> '{' '}' :
    #map_p{line = line('$1')}.
map -> atom '{' '}' :
    #atom{line = Line, name = Name} = '$1',
    #map_p{line = Line, name = Name}.
map -> atom '{' var '}' :
    #atom{line = Line, name = Name} = '$1',
    #map_p{line = Line, name = Name, vars = ['$3']}.
map -> '{' map_expr map_exprs :
    #map_p{line = line('$1'), exprs = ['$2' | '$3']}.
map -> '{' map_expr map_exprs var '}' :
    #map_p{line = line('$1'), exprs = ['$2' | '$3'], vars = ['$4']}.
map -> atom '{' map_expr map_exprs :
    #atom{line = Line, name = Name} = '$1',
    #map_p{line = Line, name = Name, exprs = ['$3' | '$4']}.
map -> atom '{' map_expr map_exprs var '}' :
    #atom{line = Line, name = Name} = '$1',
    #map_p{line = Line, name = Name, exprs = ['$3' | '$4'], vars = ['$5']}.

map_exprs -> '|'                    : [].
map_exprs -> '}'                    : [].
map_exprs -> ',' map_expr map_exprs : ['$2' | '$3'].

map_expr ->  map_index '~>' expr :
    #index_p{line = line('$1'), direction = right, index = '$1', expr = '$3'}.
map_expr ->  expr '<~' map_index :
    #index_p{line = line('$1'), direction = left, index = '$3', expr = '$1'}.

map_index -> atom     : '$1'.
map_index -> var      : '$1'.
map_index -> integer  : '$1'.

sequence -> '[' ']'       : #nil_p{line = line('$1')}.
sequence -> '[' expr tail : #cons_p{line = line('$1'), car = '$2', cdr = '$3'}.

tail -> ']'           : #nil_p{line = line('$1')}.
tail -> '|' expr ']'  : '$2'.
tail -> ',' expr tail : #cons_p{line = line('$2'), car = '$2', cdr = '$3'}.

binary -> '<' '>'              : #bin_p{line = line('$1')}.
binary -> '<' bin_elements '>' : #bin_p{line = line('$1'), elements = '$2'}.

bin_elements -> bin_element                  : ['$1'].
bin_elements -> bin_element ',' bin_elements : ['$1' | '$3'].

bin_element -> bit_expr opt_bit_size_expr opt_bit_type_list :
        #bin_element_p{line = line('$1'), expr = '$1', size = '$2', type='$3'}.

bit_expr -> prefix_op expr_max : mkop('$1', '$2').
bit_expr -> expr_max           : '$1'.

opt_bit_size_expr -> ':' bit_size_expr : '$2'.
opt_bit_size_expr -> '$empty'          : default.

opt_bit_type_list -> '/' bit_type_list : '$2'.
opt_bit_type_list -> '$empty'          : default.

bit_type_list -> bit_type '-' bit_type_list : ['$1' | '$3'].
bit_type_list -> bit_type                   : ['$1'].

bit_type -> atom             : #atom{name = Name} = '$1', Name.
bit_type -> atom ':' integer :
    #atom{name = Name} = '$1',
    #integer{value = Value} = '$3',
   {Name, Value}.

bit_size_expr -> expr_max : '$1'.

map_comprehension -> '{' expr '||' mc_exprs '}' :
    #map_c_p{line = line('$1'), map = '$2', c_exprs = '$4'}.

mc_exprs -> mc_expr              : ['$1'].
mc_exprs -> mc_expr ',' mc_exprs : ['$1' | '$3'].

mc_expr -> expr             : '$1'.
mc_expr -> expr '=>' expr   : #gen_p{line = line('$2'), left='$1', right='$3'}.

sequence_generator -> '{' expr '=>' '}' : #seq_gen_p{line=line('$1'),left='$2'}.

binary_comprehension -> '<' binary '||' lc_exprs '>' :
    #bin_c_p{line = line('$1'), bin = '$2', c_exprs = '$4'}.

lc_exprs -> lc_expr              : ['$1'].
lc_exprs -> lc_expr ',' lc_exprs : ['$1' | '$3'].

lc_expr -> expr             : '$1'.
lc_expr -> expr '=>' binary : #gen_p{line = line('$2'), left='$1', right='$3'}.

%% N.B. This is called from expr_700.

function_call -> expr_800 argument_list :
    #argument_list{args = Args} = '$2',
    #call_p{line = line('$1'), func = '$1', args = Args}.

case_expr -> 'case' expr 'of' cr_clauses 'end' :
    #case_p{line = line('$1'), expr = '$2', clauses = '$4'}.

cr_clauses -> cr_clause                : ['$1'].
cr_clauses -> cr_clause ';' cr_clauses : ['$1' | '$3'].

cr_clause -> expr clause_guard clause_body :
    #clause_p{line = line('$1'), args = ['$1'], guard = '$2', body = '$3'}.

receive_expr -> 'receive' cr_clauses 'end' :
    #receive_p{line = line('$1'), clauses = '$2'}.
receive_expr -> 'receive' 'after' expr clause_body 'end' :
    #receive_p{line = line('$1'), after_expr = '$3', after_body = '$4'}.
receive_expr -> 'receive' cr_clauses 'after' expr clause_body 'end' :
    #receive_p{line = line('$1'),
               clauses = '$2',
               after_expr = '$4',
               after_body = '$5'}.

fun_expr -> 'fun' atom '/' integer :
    #atom{name = Name} = '$2',
    #integer{value = Arity} = '$4',
    #fun_p{line = line('$1'), function = Name, arity = Arity}.
fun_expr -> 'fun' atom_or_var ':' atom_or_var '/' integer_or_var :
    Module = case '$2' of
               #atom{name = M} -> M;
               MV = #var{} -> MV
           end,
    Func = case '$4' of
               #atom{name = F} -> F;
               FV = #var{} -> FV
           end,
    Arity = case '$6' of
                #integer{value = I} -> I;
                AV = #var{} -> AV
           end,
    #fun_p{line = line('$1'), module = Module, function = Func, arity = Arity}.
fun_expr -> 'fun' fun_clauses 'end' :
    build_fun(line('$1'), '$2').

atom_or_var -> atom : '$1'.
atom_or_var -> var  : '$1'.

integer_or_var -> integer : '$1'.
integer_or_var -> var     : '$1'.

fun_clauses -> fun_clause                       : ['$1'].
fun_clauses -> fun_clause ';' 'fun' fun_clauses : ['$1' | '$4'].

fun_clause -> argument_list clause_guard clause_body :
    #argument_list{line = Line, args = Args} = '$1',
    #clause_p{line = Line, name = 'fun', args = Args, guard = '$2', body='$3'}.

argument_list -> '(' ')'       : #argument_list{line = line('$1')}.
argument_list -> '(' exprs ')' : #argument_list{line = line('$1'), args = '$2'}.

exprs -> expr           : ['$1'].
exprs -> expr ',' exprs : ['$1' | '$3'].

guard -> exprs           : ['$1'].
guard -> exprs ';' guard : ['$1' | '$3'].

atomic -> char    : '$1'.
atomic -> integer : '$1'.
atomic -> float   : '$1'.
atomic -> atom    : '$1'.
atomic -> strings : '$1'.

strings -> string         : '$1'.
strings -> string strings :
    #string{line = Line, value = String1} = '$1',
    #string{value = String2} = '$2',
    #string{line = Line, value = String1 ++ String2}.


prefix_op -> '+'    : '$1'.
prefix_op -> '-'    : '$1'.
prefix_op -> 'bnot' : '$1'.
prefix_op -> 'not'  : '$1'.

mult_op -> '/'    : '$1'.
mult_op -> '*'    : '$1'.
mult_op -> 'div'  : '$1'.
mult_op -> 'rem'  : '$1'.
mult_op -> 'band' : '$1'.
mult_op -> 'and'  : '$1'.

add_op -> '+'    : '$1'.
add_op -> '-'    : '$1'.
add_op -> 'bor'  : '$1'.
add_op -> 'bxor' : '$1'.
add_op -> 'bsl'  : '$1'.
add_op -> 'bsr'  : '$1'.
add_op -> 'or'   : '$1'.
add_op -> 'xor'  : '$1'.

comp_op -> '=='  : '$1'.
comp_op -> '/='  : '$1'.
comp_op -> '>='  : '$1'.
comp_op -> '>'   : '$1'.

%% ===================================================================
%% Erlang Code.
%% ===================================================================
Erlang code.

%% API
-export([parse_form/1, next_form/1]).

-export([file/1]).

%% Includes
-include_lib("spu/src/spu0_scan.hrl").
-include_lib("spu/src/spu0_parse.hrl").

%% Defines
-record(argument_list, {line :: integer(),
                        args = [] :: [_]}).

%%====================================================================
%% API
%%====================================================================

%%--------------------------------------------------------------------
%% Function: 
%% @doc
%%   
%% @end
%%--------------------------------------------------------------------
% -spec 
%%--------------------------------------------------------------------
parse_form(Tokens) -> parse(Tokens).

%%--------------------------------------------------------------------
%% Function: 
%% @doc
%%   
%% @end
%%--------------------------------------------------------------------
-spec next_form([tuple()]) -> {tuple(), [tuple()]}.
%%--------------------------------------------------------------------
next_form(Tokens) -> next_form(Tokens, []).

next_form([Dot = {dot, _} | T], Acc) -> {lists:reverse([Dot | Acc]), T};
next_form([H | T], Acc) -> next_form(T, [H | Acc]).

%%--------------------------------------------------------------------
%% Function: file(FileName) -> .
%% @doc
%%   Parses a .spu0 file.
%% @end
%%--------------------------------------------------------------------
-spec file(string()) -> {ok, _} | {error, _}.
%%--------------------------------------------------------------------
file(File) ->
    case spu0_scan:file(File) of
        {ok, Tokens} -> fold_tokens(Tokens);
        Error -> Error
    end.

%%====================================================================
%% Internal functions
%%====================================================================

build_attribute(#atom{line = La, name = module}, [#atom{name = Module}]) ->
    #attribute_p{line = La, name = module, value = Module};
build_attribute(#atom{line = La, name = export}, [ExpList]) ->
    #attribute_p{line = La, name = export, value = farity_list(ExpList)};
build_attribute(#atom{line = La, name = file}, A = [#string{}, #integer{}]) ->
    [#string{value = Name}, #integer{value = Line}] = A,
    #attribute_p{line = La, name = file, value = {Name, Line}};
build_attribute(#atom{line = La, name = Attr}, [Expr0]) ->
    Expr = attribute_farity(Expr0),
    #attribute_p{line = La, name = Attr, value = term(Expr)};
build_attribute(#atom{line = La, name = Attr}, _) ->
    error_bad_decl(La, Attr).

attribute_farity(#cons_p{line = L, car = H, cdr = T}) ->
    {cons, L, attribute_farity(H), attribute_farity(T)};
attribute_farity(Op = #op_p{op = '/', left = #atom{}, right = #integer{}}) ->
    #op_p{line = L, left = Name, right = Arity} = Op,
    {tuple, L, [Name, Arity]};
attribute_farity(Other) ->
    Other.

error_bad_decl(L, S) ->
    return_error(L, io_lib:format("bad ~w declaration", [S])).

farity_list(#nil_p{}) -> [];
farity_list(C = #cons_p{car = #op_p{op='/', left=#atom{}, right=#integer{}}}) ->
    #cons_p{car = #op_p{left = #atom{name = A}, right = #integer{value = I}},
            cdr = T} = C,
    [{A, I} | farity_list(T)];
farity_list(Other) ->
    return_error(line(Other), "bad function arity").

term(Expr) ->
    case catch {ok, normalise(Expr)} of
        {ok, Norm} -> Norm;
        _ -> return_error(line(Expr), "bad attribute")
    end.

build_function(Cs = [#clause_p{line = Line, name = Name, args = Args} | _]) ->
    Arity = length(Args),
    #func_p{line = Line,
            name = Name,
            arity = Arity,
            clauses = check_clauses(Cs, Name, Arity)}.

build_fun(Line, Cs = [#clause_p{line = Line, args = Args} | _]) ->
    Arity = length(Args),
    #func_p{line = Line,
            name = 'fun',
            arity = Arity,
            clauses = check_clauses(Cs, 'fun', Arity)}.

check_clauses(Cs, Name, Arity) ->
    Check = fun (Clause = #clause_p{name = N, args = As})
                  when N =:= Name, length(As) =:= Arity -> Clause;
                (#clause_p{line = L}) ->
                    return_error(L, "head mismatch")
            end,
    [Check(C) || C <- Cs].

normalise(#char{value = C}) -> C;
normalise(#integer{value = I}) -> I;
normalise(#float{value = F}) -> F;
normalise(#atom{name = A}) -> A;
normalise(#string{value = S}) -> S;
normalise(#nil_p{}) -> [];
normalise(#cons_p{car = Head, cdr = Tail}) -> [normalise(Head)|normalise(Tail)];
normalise({bin, _, Fs}) ->
    EvalFun = fun(E, _) -> {value, normalise(E), []} end,
    {value, Binary, _} = eval_bits:expr_grp(Fs, [], EvalFun, [], true),
    Binary;
%% Special case for unary +/-.
normalise(#op_p{op = '+', right = #char{value = C}}) -> C;
normalise(#op_p{op = '+', right = #integer{value = I}}) -> I;
normalise(#op_p{op = '+', right = #float{value = F}}) -> F;
%%Weird, but compatible!
normalise(#op_p{op = '-', right = #char{value = C}}) -> -C;
normalise(#op_p{op = '-', right = #integer{value = I}}) -> -I;
normalise(#op_p{op = '-', right = #float{value = F}}) -> -F;
normalise(X) -> erlang:error({badarg, X}).

mkop({Op, Pos}, A) -> #unop_p{line = Pos, op = Op, right = A}.
mkop(L, {Op, Pos}, R) -> #op_p{line = Pos, op = Op, left = L, right = R}.

line(Tuple) when is_tuple(Tuple) -> element(2, Tuple).

fold_tokens(Tokens) -> fold_tokens(Tokens, []).

fold_tokens([], Abses) -> {ok, lists:reverse(Abses)};
fold_tokens(Tokens, Abses) ->
    {Form, Tokens1} = next_form(Tokens, []),
    {ok, Abs} = parse(Form),
    fold_tokens(Tokens1, [Abs | Abses]).


