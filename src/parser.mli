type token =
  | SEP
  | EOF
  | ENDLINE
  | ASSIGN
  | LPAREN
  | RPAREN
  | LBRACK
  | RBRACK
  | LCURLY
  | RCURLY
  | COMMA
  | PLUS
  | MINUS
  | TIMES
  | DIVIDE
  | MOD
  | CONCAT
  | BIND
  | DUP
  | EQ
  | NEQ
  | LT
  | LTE
  | GT
  | GTE
  | AND
  | OR
  | NOT
  | NOTE
  | TONE
  | RHYTHM
  | INT
  | BOOL
  | STRING
  | NONE
  | FUNC
  | IN
  | IF
  | ELSE
  | FOR
  | WHILE
  | RETURN
  | LIT_BOOL of (bool)
  | LIT_INT of (int)
  | LIT_STRING of (string)
  | LIT_KEY of (string)
  | LIT_STYLE of (string)
  | LIT_RHYTHM of (string)
  | ID of (string)

val program :
  (Lexing.lexbuf  -> token) -> Lexing.lexbuf -> Ast.program
