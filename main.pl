% DCG
% set_prolog_flag(double_quotes, chars).

% example
ab --> [].
ab --> [a], ab, [b].

% MARK: Lexer

tokens([T|Ts]) --> blanks, token(T), !, tokens(Ts).
tokens([]) --> blanks.

blanks --> blank_char, !, blanks.
blanks --> comment, !, blanks.
blanks --> [].

blank_char --> [C], { memberchk(C, [' ', '\t', '\n', '\r']) }.

% MARK: Comment

comment --> "//", !, line_comment_rest.
comment --> "/*", !, block_comment_rest.

% the newline itself is left for blanks. end of input also ends a line comment
line_comment_rest --> [C], { C \== '\n' }, !, line_comment_rest.
line_comment_rest --> [].

% no clause for end of input, so an unterminated comment fails
block_comment_rest --> "*/", !.
block_comment_rest --> [_], block_comment_rest.

token(null) --> "null".
token(bool(true)) --> "true".
token(bool(false)) --> "false".
token(left_brace) --> "{".
token(right_brace) --> "}".
token(left_bracket) --> "[".
token(right_bracket) --> "]".
token(comma) --> ",".
token(colon) --> ":".


% MARK: String

token(string(S)) --> "\"", chars(Cs), "\"", { string_chars(S, Cs) } .
chars([C|Cs]) --> string_char(C), !, chars(Cs).
chars([]) --> [].

string_char(C) --> "\\", !, escape(C).
string_char(C) --> [C], { C \== '"', char_code(C, Code), Code >= 0x20 }.

escape('"') --> "\"".
escape('\\') --> "\\".
escape('/') --> "/".
escape('\b') --> "b".
escape('\f') --> "f".
escape('\n') --> "n".
escape('\r') --> "r".
escape('\t') --> "t".
escape(C) --> "u", hex4(First), surrogate_pair(First, Code), { char_code(C, Code) }.

% characters above U+FFFF are written as two \u escapes
surrogate_pair(High, Code) -->
    "\\u", hex4(Low),
    {
        High >= 0xD800, High =< 0xDBFF,
        Low >= 0xDC00, Low =< 0xDFFF
    }, !,
    { Code is 0x10000 + (High - 0xD800) * 0x400 + (Low - 0xDC00) }.
surrogate_pair(Code, Code) --> [].

hex4(N) -->
    hex(A), hex(B), hex(C), hex(D),
    { N is A * 0x1000 + B * 0x100 + C * 0x10 + D }.

hex(Weight) --> [C], { char_type(C, xdigit(Weight)) }.

% MARK: Number

token(number(N)) -->
    sign(S), % optional
    integer(IntChars),
    fraction(FracChars), % optional
    exponent(ExpChars), % also optional
    {
        append([S, IntChars, FracChars, ExpChars], AllChars),
        number_chars(N, AllChars)
    }.

sign("-") --> ['-'], !.
sign("") --> [].

integer("0") --> "0", !.
integer([D|Ds]) -->
    digit1_9(D),
    digits(Ds).

fraction(['.'|Ds]) --> ".", !, digits_plus(Ds).
fraction([]) --> [].

exponent([e|Cs]) -->
    ("e" | "E"), !,
    exponent_sign(S),
    digits_plus(Ds),
    { append(S, Ds, Cs) }.
exponent([]) --> [].

exponent_sign(['+']) --> "+", !.
exponent_sign(['-']) --> "-", !.
exponent_sign([]) --> [].

digit(D) --> [D], { char_type(D, digit) }.
digit1_9(D) --> [D], { char_type(D, digit), D \== '0' }.
% one or more
digits_plus([D|Ds]) --> digit(D), digits(Ds).

digits([D|Ds]) --> digit(D), !, digits(Ds).
digits([]) --> [].

% MARK: Parser
json_value(string(S)) --> [string(S)], !.
json_value(number(N)) --> [number(N)], !.
json_value(bool(B)) --> [bool(B)], !.
json_value(null) --> [null], !.

% array
json_value(array(A)) --> [left_bracket], json_array_contents(A), [right_bracket], !.

json_array_contents([V|Vs]) --> json_value(V), json_array_rest(Vs), json_trailing_comma.
json_array_contents([]) --> [].

json_array_rest([V|Vs]) --> [comma], json_value(V), json_array_rest(Vs).
json_array_rest([]) --> [].

% object
json_value(object(O)) --> [left_brace], json_object_contents(O), [right_brace], !.

json_object_contents([P|Ps]) --> json_pair(P), json_object_rest(Ps), json_trailing_comma.
json_object_contents([]) --> [].

json_object_rest([P|Ps]) --> [comma], json_pair(P), json_object_rest(Ps).
json_object_rest([]) --> [].

json_pair(Key-Value) --> [string(Key), colon], json_value(Value).
json_trailing_comma --> ([comma] | []).

parse(Source, Output) :-
    string_chars(Source, Codes),
    phrase(tokens(Tokens), Codes),
    % format('Tokens=~w\n', [Tokens]),
    phrase(json_value(Output), Tokens).

% MARK: Main

test_entry :-
    Source = '{ "hihi": "Kroos", "idk": { "id": 1, "numbers": [1, 2, 3] } }',
    parse(Source, Out),
    format('~w', [Out]).
