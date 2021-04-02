%{ open Ast %}

%token SEP EOF ENDLINE

%token ASSIGN
%token LPAREN RPAREN LBRACK RBRACK LCURLY RCURLY
%token COMMA COLON DECORATOR

%token PLUS MINUS TIMES DIVIDE
%token CONCAT BIND DUP
%token EQ NEQ LT LTE GT GTE 
%token AND OR NOT 

%token NOTE TONE RHYTHM
%token INT BOOL STRING MAP NONE 

%token FUNC IN IF ELSE FOR WHILE RETURN

%token <bool> LIT_BOOL
%token <int> LIT_INT
%token <string> LIT_STRING
%token <string> LIT_KEY 
%token <string> LIT_STYLE 
%token <string> LIT_RHYTHM
%token <string> ID

%nonassoc NOELSE
%nonassoc ELSE 
%left SEP 
%nonassoc ASSIGN 
%nonassoc COLON

%left OR 
%left AND 
%left EQ NEQ
%nonassoc LT LTE GT GTE
%left CONCAT
%nonassoc BIND 
%nonassoc DUP
%left COMMA 
%left PLUS MINUS
%left TIMES DIVIDE 

%nonassoc NOT

%start program
%type <Ast.program> program

%%

program:
  decls EOF { $1 }
  
decls: 
  | /* nothing */ { ([], []) }
 | decls vdecl { (($2 :: fst $1), snd $1) }
 | decls fdecl { (fst $1, ($2 :: snd $1)) }

fdecl:
  | dec FUNC typ ID LPAREN params_opt RPAREN LCURLY vdecl_list stmt_list RCURLY 
    { { fdec = $1;
        ftype = $3;
        fname = $4;
        params = List.rev $6;
        vars = List.rev $9;
        body = List.rev $10 } }

dec:
  | /* nothing */ { NoDecorator }
  | DECORATOR LPAREN LIT_KEY COMMA LIT_INT COMMA LIT_STYLE RPAREN { Decorator($3, $5, $7) }

params_opt:
  | /* nothing */ { [] }
  | params_list { $1 }

params_list:
  | typ ID                  { [($1, $2)] }
  | params_list COMMA typ ID  { ($3, $4) :: $1 }

typ:
  | BOOL    { Bool }
  | INT     { Int }
  | STRING  { String }
  | NOTE    { Note }
  | TONE    { Tone }
  | RHYTHM  { Rhythm }
  | NONE    { None }
  | typ LBRACK RBRACK { Array($1) }
  | MAP LT typ COMMA typ GT { Map($3, $5) }

vdecl_list:
  | /* nothing */ { [] }
  | vdecl_list vdecl { $2 :: $1 }

vdecl:
  | typ ID SEP { ($1, $2) }

stmt_list:
  | stmt { [$1] }
  | stmt_list stmt { $2 :: $1 }

stmt:
  | expr SEP                              { Expr $1               }
  | RETURN expr_opt SEP                   { Return $2             }
  | LCURLY stmt_list RCURLY               { Block(List.rev $2)    }
  | IF expr stmt %prec NOELSE             { If($2, $3, Block([])) }
  | IF expr stmt ELSE stmt                { If($2, $3, $5)        }
  | FOR expr IN expr stmt                 { For($2, $4, $5)       }
  | WHILE expr stmt                       { While($2, $3)         }

expr_opt:
  | /* nothing */ { NoExpr }
  | expr        { $1 }

expr:
  /* literals */
  | literals { $1 }
  | lit_map { $1 }
  | ID { Id($1) }

  /* arithmetic operations */
  | expr PLUS   expr { Binop($1, Add, $3) }
  | expr MINUS  expr { Binop($1, Sub, $3) }
  | expr TIMES  expr { Binop($1, Mul, $3) }
  | expr DIVIDE expr { Binop($1, Div, $3) }

  /* boolean operations */
  | expr EQ  expr { Binop($1, Eq,  $3) }
  | expr NEQ expr { Binop($1, Neq, $3) }
  | expr LT  expr { Binop($1, Lt,  $3) }
  | expr LTE expr { Binop($1, Lte, $3) }
  | expr GT  expr { Binop($3, Lt,  $1) }
  | expr GTE expr { Binop($3, Lte, $1) }
  |      NOT expr { Uniop(Not, $2) }
  | expr AND expr { Binop($1, And, $3) }
  | expr OR  expr { Binop($1, Or,  $3) }

  /* music list operations */
  | lit_array CONCAT lit_array { Binop($1, Concat, $3) }
  | lit_array BIND lit_array { Binop($1, Bind, $3) } /* notes, tones, rhythms */
  | expr DUP expr { Binop($1, Dup, $3) } /* LIT_INT */

  /* variable assignment */ 
  | ID ASSIGN expr { Assign($1, $3) }

  /* function call */
  | ID LPAREN args_opt RPAREN { Call($1, $3) }

args_opt:
  | /* nothing */ { [] }
  | args_list  { List.rev $1 }

args_list:
  | expr                    { [$1] }
  | args_list COMMA expr { $3 :: $1 }

literals: 
  | LIT_BOOL         { LitBool($1) }
  | LIT_INT          { LitInt($1) }
  | LIT_STRING       { LitString($1) }
  | LIT_RHYTHM       { LitRhythm($1) }
  | lit_note         { $1 }
  | lit_array        { $1 }

lit_note:
  | LT LIT_INT COMMA LIT_RHYTHM GT  { LitNote($2, $4) }

lit_array:
  | LBRACK items_list RBRACK { LitArray($2) }

items_list:
  |                  { [] }
  | expr             { [$1] }
  | items_list COMMA expr { $3 :: $1 }

lit_map:
  | LCURLY map_list RCURLY { LitMap($2) }

map_list:
  |                                 { [] }
  | expr COLON expr                 { [($1, $3)] }
  | map_list COMMA expr COLON expr  { ($3, $5) :: $1 } 