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

test_entry :-
    % Source = '{ "hihi": "Kroos" }',
    Source2 = "12 \"yomama\" null",
    % Source2 = "   \"hh\" ",
    string_chars(Source2, Codes),
    phrase(tokens(Out), Codes),
    format('~w', [Out]).
