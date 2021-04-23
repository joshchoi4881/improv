(* Abstract Syntax Tree and functions for printing it *)

type op = Add | Sub | Mul | Div | Mod |
          Eq | Neq | Lt | Lte | And | Or
          (* | Concat | Bind | Dup *)

type uop = Not

type typ = Bool | Int | String | Note | Tone | Rhythm | None |
           Array of typ 

type bind = typ * string

type expr =
    LitBool of bool 
  | LitInt of int 
  | LitString of string
  | LitTone of int
  | LitRhythm of string 
  | LitNote of int * string (* LitTone, LitRhythm *)
  | LitArray of expr list 
  | Id of string
  | Binop of expr * op * expr
  | Uniop of uop * expr
  | Assign of string * expr
  | Call of string * expr list
  | ArrayAccess of string * expr
  (* | ArrayAssign of string * expr * expr *)
  | NoExpr

type stmt =
    Block of stmt list
  | Expr of expr
  | Return of expr
  | If of expr * stmt * stmt
  | For of expr * expr * expr * stmt
  | While of expr * stmt 

type func_decl = {
    ftype : typ;
    fname : string;
    params : bind list;
    vars : bind list;
    body : stmt list;
}

type program = bind list * func_decl list

(* Pretty-printing functions *)

let string_of_op = function
    Add -> "+"
  | Sub -> "-"
  | Mul -> "*"
  | Div -> "/"
  | Mod -> "%"
  | Eq -> "=="
  | Neq -> "!="
  | Lt -> "<"
  | Lte -> "<="
  | And -> "&&"
  | Or -> "||"
  (* | Concat -> "$"
  | Bind -> "@"
  | Dup -> "^" *)

let string_of_uop = function
    Not -> "!"

let rec string_of_expr = function
  (* Insert literal and boolean logic *)
    LitBool(true) -> "true"
  | LitBool(false) -> "false"
  | LitInt(i) -> string_of_int i
  | LitString(s) -> s
  | LitTone(t) -> string_of_int t
  | LitRhythm(r) -> r
  | LitNote(t, r) -> "<" ^ string_of_int t ^ " " ^ r ^ ">"
  | LitArray(el) -> "[" ^ String.concat ", " (List.map string_of_expr el) ^ "]"
  | Id(s) -> s
  | Binop(e1, o, e2) ->
      string_of_expr e1 ^ " " ^ string_of_op o ^ " " ^ string_of_expr e2
  | Uniop(o, e) -> string_of_uop o ^ string_of_expr e
  | Assign(v, e) -> v ^ " = " ^ string_of_expr e
  | Call(f, el) ->
      f ^ "(" ^ String.concat ", " (List.map string_of_expr el) ^ ")"
  | ArrayAccess(s, e) -> s ^ "[" ^ string_of_expr e ^ "]"
  (* | ArrayAssign(v, l, e) -> v ^ "[" ^ string_of_expr l ^ "]" ^ " = " ^ string_of_expr e *)
  | NoExpr -> ""

let rec string_of_stmt = function
    Block(stmts) ->
      "{\n" ^ String.concat "" (List.map string_of_stmt stmts) ^ "}\n"
  | Expr(expr) -> string_of_expr expr ^ ";\n"
  | Return(expr) -> "return " ^ string_of_expr expr ^ ";\n"
  | If(e, s, Block([])) -> "if " ^ string_of_expr e ^ "\n" ^ string_of_stmt s
  | If(e, s1, s2) ->  "if " ^ string_of_expr e ^ "\n" ^
      string_of_stmt s1 ^ "else\n" ^ string_of_stmt s2
  | For(e1, e2, e3, s) ->
<<<<<<< HEAD
    "for (" ^ string_of_expr e1  ^ " ; " ^ string_of_expr e2 ^ " ; " ^
    string_of_expr e3  ^ ") " ^ string_of_stmt s
=======
      "for " ^ string_of_expr e1  ^ " ; " ^ string_of_expr e2 ^ " ; " ^ string_of_expr e3 ^ string_of_stmt s 
>>>>>>> c74635bee72c16744249edde9313e875c20c5dbe
  | While(e, s) -> "while " ^ string_of_expr e ^ string_of_stmt s 

let rec string_of_typ = function
    Int -> "int"
  | Bool -> "bool"
  | String -> "string"
  | Note -> "note"
  | Tone -> "tone"
  | Rhythm -> "rhythm"
  | None -> "none"
  | Array(t) -> string_of_typ t ^ "[]"

let string_of_vdecl (t, id) = string_of_typ t ^ " " ^ id ^ ";\n"

let string_of_fdecl fdecl =
  string_of_typ fdecl.ftype ^ " " ^
  fdecl.fname ^ "(" ^ String.concat ", " (List.map snd fdecl.params) ^
  ")\n{\n" ^
  String.concat "" (List.map string_of_vdecl fdecl.vars) ^
  String.concat "" (List.map string_of_stmt fdecl.body) ^
  "}\n"

let string_of_program (vars, funcs) =
  String.concat "" (List.map string_of_vdecl vars) ^ "\n" ^
  String.concat "\n" (List.map string_of_fdecl funcs)
