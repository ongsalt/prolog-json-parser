# วิธีรัน
0. โหลด `main.pl`
1. เปิด swi prolog [โหลดจากนี่](https://www.swi-prolog.org/download/stable)
2. ตั้งค่าการ parse string
```prolog
set_prolog_flag(double_quotes, chars)
```
3. กด File -> Consult
4. เลือก `main.pl` อาจมี Warning ขึ้น แต่ช่างมัน
5. ลอง 
```prolog
parse('{ "hihi": "Kroos", "id": 1 }', Out).
```

# ทำงานยังไง
ส่วนนี้เขียนสำหรับคนที่รู้จัก context-free grammar (CFG) แล้ว ไม่ต้องรู้จัก parser มาก่อน

## จาก CFG มาเป็น DCG
ลองดู grammar ของภาษา { aⁿbⁿ | n ≥ 0 } ซึ่งเป็นตัวอย่างคลาสสิกของภาษาที่เป็น context-free แต่ไม่ regular

```
AB → ε | a AB b
```

DCG (Definite Clause Grammar) คือการเขียน production แบบนี้ลงใน Prolog ตรง ๆ ตัวอย่างจาก `main.pl`

```prolog
ab --> [].
ab --> [a], ab, [b].
```

- nonterminal คือชื่อกฎ เช่น `ab`
- terminal คือของในวงเล็บเหลี่ยม เช่น `[a]`
- production หนึ่งตัวคือกฎหนึ่งข้อ ส่วน ε คือ `[]`

ลองถามได้เลยว่าสตริงนี้อยู่ในภาษาหรือเปล่า

```prolog
?- phrase(ab, [a, a, b, b]).   % true
?- phrase(ab, [a, b, b]).      % false
```

## DCG คือ Prolog ธรรมดา
ก่อนอื่นขอนิยามคำว่า **กิน** (consume) ที่จะใช้ตลอดทั้งส่วนนี้ มันคือการอ่าน symbol ที่อยู่หน้าสุดของ input แล้วขยับไปอ่านตัวถัดไป เหมือนหัวอ่านของ DFA ที่เลื่อนไปทางขวาทีละช่อง

แต่ list ใน Prolog แก้ไขไม่ได้ และไม่มีหัวอ่าน เราจึงแทนตำแหน่งปัจจุบันด้วย "ส่วนของ input ที่ยังไม่ได้อ่าน" แทน เช่น กิน `a` จาก `[a, b, c]` แปลว่าเช็คว่าตัวแรกคือ `a` แล้วเหลือ `[b, c]` ไว้ให้ขั้นถัดไป ถ้าตัวแรกไม่ใช่ `a` ก็ถือว่าไม่ผ่าน list เดิมไม่ได้ถูกเปลี่ยน

DCG ไม่ใช่กลไกพิเศษ กฎ `-->` เป็นแค่ syntax ย่อ ตอนโหลดไฟล์ Prolog จะแปลงมันเป็น predicate ธรรมดาที่มี argument เพิ่ม 2 ตัว

- `S0` : input ก่อนกิน
- `S` : input ที่เหลือหลังกิน

```prolog
% DCG
ab --> [].
ab --> [a], ab, [b].

% Prolog ธรรมดาที่ได้
ab(S, S).                % ε ไม่กินอะไร ก่อนกับหลังจึงเป็น list เดียวกัน
ab(S0, S) :-
    S0 = [a|S1],         % S0 ต้องขึ้นต้นด้วย a ที่เหลือคือ S1
    ab(S1, S2),          % ab กินต่อจาก S1 ที่เหลือคือ S2
    S2 = [b|S].          % S2 ต้องขึ้นต้นด้วย b ที่เหลือคือ S
```

ความหมายของ `ab(S0, S)` คือ "`S0` เขียนเป็น `w` ต่อด้วย `S` ได้ โดยที่ `AB ⇒* w`" พูดง่าย ๆ คือ nonterminal กิน prefix `w` ออกจาก `S0` แล้วคืนส่วนที่เหลือเป็น `S` ส่วนที่เหลือจะถูกส่งต่อเป็นทอด ๆ `S0 -> S1 -> S2 -> S` ตามลำดับสัญลักษณ์ใน production

ดังนั้น `phrase(ab, L)` ก็คือ `ab(L, [])` แปลว่า `L` ทั้งก้อนต้องถูก derive จาก `ab` โดยไม่เหลืออะไร ซึ่งตรงกับนิยาม `w ∈ L(G)` พอดี

กฎนี้จึงเป็น `ab/2` จริง ๆ ส่วน `ab//0` คือวิธีเรียกชื่อกฎ DCG ที่นับเฉพาะ argument ที่เราเขียนเอง ลองดูของจริงได้ด้วย `listing(ab).` (หน้าตาอาจต่างนิดหน่อยแต่ความหมายเดียวกัน)

ทุก syntax ของ DCG แปลงตรง ๆ ได้แบบนี้

```prolog
% ทำต่อกัน (concatenation) : ร้อยส่วนที่เหลือ
foo --> bar, baz.
foo(S0, S) :- bar(S0, S1), baz(S1, S).

% terminal
foo --> [a].
foo(S0, S) :- S0 = [a|S].

% | : หลาย production ทั้งสองทางเริ่มจาก S0 เดียวกัน
foo --> ( bar | baz ).
foo(S0, S) :- ( bar(S0, S) ; baz(S0, S) ).

% argument ของเราเอง : ต่อไว้ข้างหน้า S0, S ใช้ส่งผลลัพธ์ออกมา
foo(X) --> bar(X).
foo(X, S0, S) :- bar(X, S0, S).

% { } : โค้ด Prolog ธรรมดา ไม่แตะ list
foo --> bar, { G }.
foo(S0, S) :- bar(S0, S1), G, S1 = S.

% ! : cut ธรรมดา ไม่แตะ list
foo --> bar, !, baz.
foo(S0, S) :- bar(S0, S1), !, baz(S1, S).

% phrase : ต้องกินจนหมด
phrase(foo, L).          % เท่ากับ foo(L, [])
phrase(foo(X), L).       % เท่ากับ foo(X, L, [])
```

ส่วน `"abc"` ใน DCG ก็คือ terminal `[a, b, c]` เรียงกัน

สองอย่างสุดท้ายที่เพิ่มมาจาก CFG คือ argument กับ `{ }` argument ทำให้เราได้ผลลัพธ์ออกมา ไม่ใช่แค่ตอบว่าอยู่ในภาษาหรือไม่ และทำให้ DCG มีพลังมากกว่า CFG ด้วย เช่นเขียนภาษา aⁿbⁿcⁿ ได้

ตัวอย่างจริงจาก lexer

```prolog
% DCG
digit(D) --> [D], { char_type(D, digit) }.
digits([D|Ds]) --> digit(D), !, digits(Ds).
digits([]) --> [].

% Prolog ธรรมดา
digit(D, S0, S) :- S0 = [D|S1], char_type(D, digit), S1 = S.
digits([D|Ds], S0, S) :- digit(D, S0, S1), !, digits(Ds, S1, S).
digits([], S, S).

% ลองเรียกตรง ๆ ได้เลย ไม่ต้องผ่าน phrase
?- digits(Ds, ['1', '2', x], Rest).
Ds = ['1', '2'], Rest = [x].
```

## Recursive descent parser
CFG บอกแค่ว่าสตริงไหนอยู่ในภาษา แต่ไม่ได้บอกว่าจะเช็คยังไง parser คือโปรแกรมที่ทำส่วนนั้น และ recursive descent คือวิธีที่ตรงไปตรงมาที่สุด

- nonterminal หนึ่งตัวคือ procedure หนึ่งตัว
- procedure ลองแต่ละ production ทีละอัน
- เจอ terminal ก็เช็คกับ input แล้วเลื่อนไป เจอ nonterminal ก็เรียก procedure ของมัน

แบบนี้คือ top-down คือเริ่มจาก start symbol แล้วกระจายลงไปจนเจอ input และเรียกว่า recursive เพราะ grammar เรียกตัวเอง procedure จึงเรียกตัวเองด้วย

ถ้าดูรูป Prolog ด้านบนจะเห็นว่า DCG เป็นแบบนี้อยู่แล้ว แต่ละกฎคือ predicate ที่เรียกกฎอื่น Prolog รัน goal จากซ้ายไปขวาและลอง clause จากบนลงล่าง เราจึงได้ recursive descent parser โดยไม่ต้องเขียนอะไรเพิ่ม

ลองไล่ `ab([a, a, b, b], [])`

```
ab([a,a,b,b], [])
  ลอง AB → ε : ต้องได้ [a,a,b,b] = [] ไม่ผ่าน
  ลอง AB → a AB b :
    กิน a เหลือ [a,b,b]  (b ตัวปิดยังอยู่ในนี้)
    ab([a,b,b], R1)
      ลอง AB → ε : ได้ R1 = [a,b,b]
        คนเรียกต้องกิน b แต่ตัวแรกคือ a จึงย้อนกลับมาลองอันถัดไป
      ลอง AB → a AB b :
        กิน a เหลือ [b,b]
        ab([b,b], R2)
          ลอง AB → ε : ได้ R2 = [b,b]
        กิน b จาก R2 ได้ R1 = [b]
    กิน b จาก R1 เหลือ [] ตรงกับที่ต้องการ
```

เทียบกับสิ่งที่เรียนในวิชา automata

- **Leftmost derivation** : เส้นทางที่สำเร็จคือ `AB ⇒ aABb ⇒ aaABbb ⇒ aabb` พอดี เพราะ Prolog ขยายสัญลักษณ์ซ้ายสุดก่อนเสมอ
- **PDA** : call stack ทำหน้าที่เดียวกับ stack ของ PDA ที่แปลงมาจาก CFG แต่ละ call ที่ค้างอยู่จำไว้ว่ายังต้องกิน `b` อีกตัว นี่คือเหตุผลที่จับคู่ a กับ b ได้ ส่วน DFA ไม่มี stack จึงทำไม่ได้
- **Nondeterminism** : PDA เดาได้ว่าจะใช้ production ไหน แต่คอมพิวเตอร์เดาไม่ได้ Prolog เลยลองทีละทางแบบ depth-first ถ้าติดก็ backtrack กลับมาลองทางอื่น
- **`!` (cut)** : สั่งให้ทิ้งทางเลือกที่เหลือ ทำให้เร็วขึ้น แต่ถ้าใส่ผิดที่ก็เปลี่ยนภาษาที่ยอมรับได้ เช่น `digits` ที่มี cut จะกินตัวเลขให้มากที่สุดเสมอ

## Parser ของเรา
`parse/2` แบ่งงานเป็น 2 ชั้น

```
ข้อความ -> list ของตัวอักษร -> tokens//1 -> list ของ token -> json_value//1 -> ผลลัพธ์
```

ถ้าเขียนโดยไม่ใช้ `phrase` จะได้แบบนี้

```prolog
parse(Source, Output) :-
    string_chars(Source, Chars),
    tokens(Tokens, Chars, []),
    json_value(Output, Tokens, []).
```

การแบ่งชั้นนี้ตรงกับ hierarchy ของภาษา ระดับ token เป็นแค่ regular language ส่วนโครงสร้างที่ซ้อนกันได้ไม่ใช่

**1. Lexer** (`tokens//1`) กินตัวอักษรแล้วคืน list ของ token โดยวนข้าม whitespace และ comment (`// ...` กับ `/* ... */`) ด้วย `blanks` แล้วอ่าน 1 token ด้วย `token//1` เช่น `{"id": 1}` จะกลายเป็น

```prolog
[left_brace, string("id"), colon, number(1), right_brace]
```

token ทุกแบบเขียนเป็น regular expression ได้ เช่นตัวเลขคือ

```
-?(0|[1-9][0-9]*)(\.[0-9]+)?([eE][+-]?[0-9]+)?
```

ในโค้ดแต่ละส่วนคือ `sign`, `integer`, `fraction` และ `exponent` ซึ่งคืน list ของตัวอักษร แล้วเอามาต่อกันให้ `number_chars/2` แปลงเป็นตัวเลขตอนท้าย

**2. Parser** (`json_value//1`) ทำแบบเดียวกัน แต่ terminal คือ token ไม่ใช่ตัวอักษร grammar ที่โค้ดใช้คือ

```
Value    → string | number | bool | null | [ Elements ] | { Members }
Elements → Value ElemRest Trailing | ε
ElemRest → , Value ElemRest | ε
Members  → Pair MemRest Trailing | ε
MemRest  → , Pair MemRest | ε
Pair     → string : Value
Trailing → , | ε
```

ส่วนนี้ regular ไม่ได้ เพราะ `[[[ ... ]]]` มีรูปเดียวกับ aⁿbⁿ วงเล็บเปิดต้องจับคู่กับวงเล็บปิด และกฎ array ก็มีหน้าตาเหมือน `ab` ทุกอย่าง แค่ตรงกลางเป็น `Elements`

```prolog
% DCG
json_value(array(A)) --> [left_bracket], json_array_contents(A), [right_bracket], !.

% Prolog ธรรมดา
json_value(array(A), S0, S) :-
    S0 = [left_bracket|S1],
    json_array_contents(A, S1, S2),
    S2 = [right_bracket|S3],
    !,
    S3 = S.
```

parser นี้รับ JSON มาตรฐานทั้งหมด และเพิ่มจากมาตรฐาน 2 อย่างเท่านั้น คือ comment และ trailing comma `Trailing` ทำให้ใส่ comma ตัวสุดท้ายได้ และเป็นตัวอย่าง backtracking จริงในโค้ด เช่น `[1, 2,]` พอ `ElemRest` กิน comma ตัวสุดท้ายแล้วไปเจอ `]` ก็อ่าน `Value` ไม่ได้ จึงย้อนกลับไปเลือก ε แล้วให้ `Trailing` กิน comma นั้นแทน

argument ของแต่ละกฎใช้สร้าง parse tree ระหว่างทาง ผลลัพธ์จึงหน้าตาแบบนี้

```prolog
?- parse('{ "id": 1, "tags": ["a", null] }', Out).
Out = object(["id"-number(1), "tags"-array([string("a"), null])]).
```

# Todo
- หาวิธีที่ทำให้ไม่ต้อง `set_prolog_flag`
- ดู DCG
- query language?
- handle comment
