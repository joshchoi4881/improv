{ open Parser }

let lowercase = ['a'-'z']
let uppercase = ['A'-'Z']
let letter = lowercase | uppercase
let digit = ['0'-'9']
let keys = ("C" | "C#" | "D" | "D#" | "E" | "F" | "F#" | "G" | "G#" | "A" | "A#" | "B")

rule tokenize = parse
  [' ' '\t' '\r' '\n'] { tokenize lexbuf }
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
| '=' { ASSIGN }
| "==" { EQ }
| "!=" { NEQ }
| '<' { LT }
| "<=" { LTE }
| '>' { GT }
| ">=" { GTE }
| ',' { COMMA }
| '$' { CONCAT }
| '@' { BIND }
| '^' { DUP }
| ':' { COLON }
| '%' { DECORATOR }
(* KEYWORDS *)
(* DATA TYPES *)
| "note" { NOTE }
| "tone" { TONE }
| "rhythm" { RHYTHM }
| "int" { INT }
| "bool" { BOOL }
| "string" { STRING }
| "map" { MAP }
| "none" { NONE }
(* BOOLEAN LOGIC *)
| "and" { AND }
| "or" { OR }
| "not" { NOT }
(* PROGRAM STRUCTURE *)
| "main" { MAIN }
| "func" { FUNC }
| "in" { IN }
| "if" { IF }
| "else" { ELSE }
| "for" { FOR }
| "while" { WHILE }
| "return" { RETURN }
(* LITERALS *)
| ("wh" | "hf" | "qr" | "ei" | "sx") as lit { LIT_RHYTHM(lit) }
| ("DEFAULT" | "BLUES" | "JAZZ") as lit { LIT_STYLE(lit) }
| keys ("MAJ" | "MIN") as lit { LIT_KEY(lit) }
| '"' (('\\' '"'| [^'"'])* as str) '"' { LIT_STR(str) }
| ['0'-'9']+ as lit { LIT_INT(int_of_string lit) }
| ("true" | "false") as lit { LIT_BOOL(lit) }
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
| "*/" { if level == 0 then tokenize lexbuf 
        else commentBlock (level - 1) lexbuf }
| _ { commentBlock level lexbuf }