%{ open Ast %}

%token SEP EOF ENDLINE

%token ASSIGN
%token LPAREN RPAREN LBRACK RBRACK LCURLY RCURLY
%token COMMA COLON DECORATOR

%token PLUS MINUS TIMES DIVIDE
%token EQ NEQ LT LTE GT GTE 
%token AND OR NOT 
%token CONCAT BIND DUP

%token NOTE TONE RHYTHM
%token INT BOOL STRING MAP NONE 

%token MAIN FUNC IN IF ELSE FOR RETURN

%token <bool> LIT_BOOL
%token <int> LIT_INT
%token <string> LIT_STR 
%token <string> LIT_KEY 
%token <string> LIT_STYLE 
%token <string> LIT_RHYTHM
%token <string> ID

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
| EOF     { [] }
| FUNC MAIN LPAREN RPAREN LCURLY body RCURLY { }

func_def:
| FUNC type ID LPAREN args RPAREN LCURLY body RCURLY { FunctionDef($2, $3, $5, $8) }

// func_call:

type:
| BOOL    { Bool }
| INT     { Int }
| STRING  { String }
| NOTE    { Note }
| TONE    { Tone }
| RHYTHM  { Rhythm }
| type LBRACK RBRACK { Array($1) }
| MAP LT type COMMA type GT { Map($3, $5) }

args:
| type var             { [($1, $2)] }
| args COMMA type var  { [($3, $4)] :: $1 }

body:
| line SEP    { $1 } 
| control     { $1 }

line:
| assign      { $1 }
| func_call   { $1 }
| RETURN expr { Return($2) }

var:
| ID { Var($1) }

expr:
| arith     { $1 }
| bool      { $1 }
| val       { $1 }
| lit_array CONCAT lit_array { Binop($1, Concat, $3) }
| lit_array BIND lit_array { Binop($1, Bind, $3) } /* notes, tones, rhythms */
| val DUP LIT_INT { Binop($1, Dup, $3) }

// control statements

assign:
| type var ASSIGN expr { Assign($1, $2, $4) }

lit:
| LIT_BOOL         { LitBool($1) }
| LIT_INT          { LitInt($1) }
| LIT_STR          { LitStr($1) }
| LIT_RHYTHM       { LitRhythm($1) }
| lit_note         { $1 }
| lit_array        { $1 }

val:
| lit { $1 }
| var { $2 }

lit_note:
| LPAREN LIT_INT LIT_RHYTHM RPAREN  { LitNote($2, $3) }

lit_array:
| LBRACK items RBRACK { LitArray(List.rev $2) }

items:
|           { [] }
| val       { [$1] }
| items val { $2::$1 }

lit_map:
| LCURLY map_items RCURLY { LitMap($2) }

map_items:
|                               { [] }
| val COLON val                 { [($1, $3)] }
| map_items COMMA val COLON val { [($3, $5)]::$1 } 

dec:
| DEC LIT_KEY LIT_INT LIT_STYLE { Decorator($2, $3, $4) }

arith:
| expr PLUS   expr { Binop($1, Add, $3) }
| expr MINUS  expr { Binop($1, Sub, $3) }
| expr TIMES  expr { Binop($1, Mul, $3) }
| expr DIVIDE expr { Binop($1, Div, $3) }

bool:
| compare { $1 }
| logic { $1 }

compare:
| expr EQ  expr { Binop($1, Eq,  $3) }
| expr NEQ expr { Binop($1, Neq, $3) }
| expr LT  expr { Binop($1, Lt,  $3) }
| expr LTE expr { Binop($1, Lte, $3) }
| expr GT  expr { Binop($3, Lt,  $1) }
| expr GTE expr { Binop($3, Lte, $1) }

logic:
|      NOT expr { Uniop(Not, $2) }
| expr AND expr { Binop($1, And, $3) }
| expr OR  expr { Binop($1, Or,  $3) }

