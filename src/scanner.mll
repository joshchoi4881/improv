(* Authors: Emily Li, Natalia Dorogi, Josh Choi *)

{ open Parser }

let lowercase = ['a'-'z']
let uppercase = ['A'-'Z']
let letter = lowercase | uppercase
let digit = ['0'-'9']
let keys = ("C" | "C#" | "D" | "D#" | "E" | "F" | "F#" | "G" | "G#" | "A" | "A#" | "B")

rule token = parse
  [' ' '\t' '\r' '\n'] { token lexbuf }
| ';' { SEP }
| eof { EOF }
(* SCOPING *)
| '(' { LPAREN }
| ')' { RPAREN }
| '[' { LBRACK }
| ']' { RBRACK }
| '{' { LCURLY }
| '}' { RCURLY }
(* OPERATORS *)
| '+' { PLUS }
| '-' { MINUS }
| '*' { TIMES }
| '/' { DIVIDE }
| '%' { MOD }
| '=' { ASSIGN }
| "==" { EQ }
| "!=" { NEQ }
| '<' { LT }
| "<=" { LTE }
| '>' { GT }
| ">=" { GTE }
| ',' { COMMA }
(* KEYWORDS *)
(* DATA TYPES *)
| "note" { NOTE }
| "int" { INT }
| "bool" { BOOL }
| "string" { STRING }
| "none" { NONE }
(* BOOLEAN LOGIC *)
| "and" { AND }
| "or" { OR }
| "not" { NOT }
(* PROGRAM STRUCTURE *)
| "func" { FUNC }
| "in" { IN }
| "if" { IF }
| "else" { ELSE }
| "for" { FOR }
| "while" { WHILE }
| "return" { RETURN }
(* LITERALS *)
| '"' (('\\' '"'| [^'"'])* as str) '"' { LIT_STRING(str) }
| ['0'-'9']+ as lit { LIT_INT(int_of_string lit) }
| "true"   { LIT_BOOL(true)  }
| "false"  { LIT_BOOL(false) }
(* IDENTIFIERS *)
| (lowercase | '_') (letter | digit | '_')* as lit { ID(lit) }
(* COMMENTS *)
| "//" { commentLine lexbuf }
| "/*" { commentBlock 0 lexbuf }

and commentLine = parse
| ('\n' | '\r' | "\r\n" | eof) { ENDLINE }
| _ { commentLine lexbuf }

and commentBlock level = parse
| "/*" { commentBlock (level + 1) lexbuf }
| "*/" { if level == 0 then token lexbuf 
        else commentBlock (level - 1) lexbuf }
| _ { commentBlock level lexbuf }