{ open Parser }

let lowercase = ['a'-'z']
let uppercase = ['A'-'Z']
let letter = lowercase | uppercase
let digit = ['0'-'9']
let newline = ('\n' | '\r' | "\r\n")
let whitespace = [' ' '\t']
let separator = (newline | ';')

rule tokenize = parse
  [' ' '\t' '\r' '\n'] { tokenize lexbuf }
| ';' { SEP }
| eof { EOF }
(* SCOPING *)
| '(' { LPAREN }
| ')' { RPAREN }
| '[' { LBRACK }
| ']' { RBRACK }
| '{' { LBRACE }
| '}' { RBRACE }
(* OPERATORS *)
| '+' { PLUS }
| '-' { MINUS }
| '*' { TIMES }
| '/' { DIVIDE }
| '=' { ASSIGN }
| '==' { EQ }
| '!=' { NEQ }
| '<' { LT }
| '<=' { LTE }
| '>' { GT }
| ">=" { GTE }
| ',' {COMMA}
| '$' { CONCAT }
| '@' { BIND }
| '^' { DUP }
(* KEYWORDS *)
(* DATA TYPES *)
| 'note' { NOTE }
| 'tone' { TONE }
| 'rhythm' { RHYTHM }
| 'int' { INT }
| 'bool' { BOOL }
| 'string' { STRING }
| 'none' { NONE }
(* BOOLEAN LOGIC *)
| 'and' { AND }
| 'or' { OR }
| 'not' { NOT }
| 'true' { TRUE }
| 'false' { FALSE }
(* PROGRAM STRUCTURE *)
| 'main' { MAIN }
| 'func' { FUNC }
| 'in' { IN }
| 'if' { IF }
| 'else' { ELSE }
| 'for' { FOR }

(* COMMENTS *)
| '//' 