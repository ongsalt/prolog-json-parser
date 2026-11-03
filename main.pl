% DCG
% set_prolog_flag(double_quotes, chars).

% example
ab --> [].
ab --> [a], ab, [b].

% MARK: Lexer

tokens([T|Ts]) --> blanks, token(T), !, tokens(Ts).
tokens([]) --> blanks.

% TODO: comment
blanks --> [C], { char_type(C, space) }, !, blanks.
blanks --> [].

token(null) --> "null".
token(bool(true)) --> "true".
token(bool(false)) --> "false".
token(left_brace) --> "{".
token(right_brace) --> "}".
token(left_bracket) --> "[".
token(right_bracket) --> "]".
token(comma) --> ",".
token(colon) --> ":".


% TODO: escaped string
token(string(S)) --> "\"", chars(Cs), "\"", { string_chars(S, Cs) } .
chars([C|Cs]) --> [C], { C \== '"' }, !, chars(Cs).
chars([]) --> [].

% MARK: Number

token(number(N)) -->
    sign(S), % optional
    integer(IntChars),
    fraction(FracChars), % optional
    % exp(ExpChars), % also optional
    {
        append([S, IntChars, FracChars], AllChars),
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

% TODO: exponent

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

test_entry :-
    Source = '{ "hihi": "Kroos", "idk": { "id": 1, "numbers": [1, 2, 3] } }',
    parse(Source, Out),
    format('~w', [Out]).
