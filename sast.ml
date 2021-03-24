(* Semantically-checked Abstract Syntax Tree and functions for printing it *)

open Ast

type sdec = SDecorator of string * int * string

type sexpr = typ * sx
and sx =
    SLitBool of bool 
  | SLitInt of int 
  | SLitString of string
  | SLitRhythm of string 
  | SLitNote of int * string
  | SLitArray of sexpr list 
  | SLitMap of (sexpr * sexpr) list
  | SId of string
  | SBinop of sexpr * op * sexpr
  | SUniop of uop * sexpr
  | SAssign of string * sexpr
  | SCall of string * sexpr list
  | SNoexpr

type sstmt =
    SBlock of sstmt list
  | SExpr of sexpr
  | SReturn of sexpr
  | SIf of sexpr * sstmt * sstmt
  | SFor of sexpr * sexpr * sstmt
  | SWhile of sexpr * sstmt

type sfunc_decl = {
    sfdec : sdec;
    sftype : typ;
    sfname : string;
    sparams : bind list;
    svars : bind list;
    sbody : stmt list;
  }

type sprogram = bind list * sfunc_decl list

(* Pretty-printing functions *)

let rec string_of_sexpr (t, e) =
  "(" ^ string_of_typ t ^ " : " ^ (match e with
    SLitBool(true) -> "true"
  | SLitBool(false) -> "false"
  | SLitInt(i) -> string_of_int i
  | SLitString(s) -> s
  | SLitRhythm(r) -> r
  | SLitNote(i, r) -> "<" ^ string_of_int i ^ " " ^ r ^ ">"
  | SLitArray(el) -> "[" ^ String.concat ", " (List.map string_of_sexpr el) ^ "]"
  | SLitMap(ml) -> "{" ^ String.concat ", " (List.map (fun (e1, e2) -> string_of_sexpr e1 ^ ": " ^ string_of_sexpr e2) ml) ^ "}"
  | SId(s) -> s
  | SBinop(e1, o, e2) ->
      string_of_sexpr e1 ^ " " ^ string_of_op o ^ " " ^ string_of_sexpr e2
  | SUniop(o, e) -> string_of_uop o ^ string_of_sexpr e
  | SAssign(v, e) -> v ^ " = " ^ string_of_sexpr e
  | SCall(f, el) ->
      f ^ "(" ^ String.concat ", " (List.map string_of_sexpr el) ^ ")"
  | SNoexpr -> ""
				  ) ^ ")"				     

let rec string_of_sstmt = function
    SBlock(stmts) ->
      "{\n" ^ String.concat "" (List.map string_of_sstmt stmts) ^ "}\n"
  | SExpr(expr) -> string_of_sexpr expr ^ ";\n";
  | SReturn(expr) -> "return " ^ string_of_sexpr expr ^ ";\n";
  | SIf(e, s, Block([])) -> "if " ^ string_of_sexpr e ^ "\n" ^ string_of_sstmt s
  | SIf(e, s1, s2) ->  "if " ^ string_of_sexpr e ^ "\n" ^
      string_of_sstmt s1 ^ "else\n" ^ string_of_sstmt s2
  | SFor(e1, e2, s) ->
      "for " ^ string_of_sexpr e1  ^ " in " ^ string_of_sexpr e2 ^ string_of_sstmt s
  | SWhile(e, s) -> "while " ^ string_of_sexpr e ^ string_of_sstmt s

let string_of_sfdecl fdecl =
  string_of_typ fdecl.sftype ^ " " ^
  fdecl.sfname ^ "(" ^ String.concat ", " (List.map snd fdecl.sparams) ^
  ")\n{\n" ^
  String.concat "" (List.map string_of_vdecl fdecl.svars) ^
  String.concat "" (List.map string_of_sstmt fdecl.sbody) ^
  "}\n"

let string_of_sprogram (vars, funcs) =
  String.concat "" (List.map string_of_vdecl vars) ^ "\n" ^
  String.concat "\n" (List.map string_of_sfdecl funcs)