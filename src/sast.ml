open Ast

type sexpr = typ * sx
and sx =
    SLitBool of bool 
  | SLitInt of int 
  | SLitString of string
  | SLitNote of sexpr * string
  | SLitArray of sexpr list 
  | SId of string
  | SBinop of sexpr * op * sexpr
  | SUniop of uop * sexpr
  | SAssign of string * sexpr
  | SCall of string * sexpr list
  | SArrayAccess of string * sexpr
  | SArrayAssign of string * sexpr * sexpr
  | SNoExpr

type sstmt =
    SBlock of sstmt list
  | SExpr of sexpr
  | SReturn of sexpr
  | SIf of sexpr * sstmt * sstmt
  | SFor of sexpr * sexpr * sexpr * sstmt
  | SWhile of sexpr * sstmt 

type sfunc_decl = {
    sftype : typ;
    sfname : string;
    sparams : bind list;
    svars : bind list;
    sbody : sstmt list;
  }

type sprogram = bind list * sfunc_decl list

(* Pretty-printing functions *)

let rec string_of_sexpr (t, e) =
  "(" ^ string_of_typ t ^ " : " ^ (match e with
    SLitBool(true) -> "true"
  | SLitBool(false) -> "false"
  | SLitInt(i) -> string_of_int i
  | SLitString(s) -> s
  | SLitNote(t, r) -> "<" ^ string_of_sexpr t ^ ", " ^ r ^ ">"
  | SLitArray(el) -> "[" ^ String.concat ", " (List.map string_of_sexpr el) ^ "]"
  | SId(s) -> s
  | SBinop(e1, o, e2) ->
      string_of_sexpr e1 ^ " " ^ string_of_op o ^ " " ^ string_of_sexpr e2
  | SUniop(o, e) -> string_of_uop o ^ string_of_sexpr e
  | SAssign(v, e) -> v ^ " = " ^ string_of_sexpr e
  | SCall(f, el) ->
      f ^ "(" ^ String.concat ", " (List.map string_of_sexpr el) ^ ")"
  | SArrayAccess(s, e) -> s ^ "[" ^ string_of_sexpr e ^ "]"
  | SArrayAssign(v, l, e) -> v ^ "[" ^ string_of_sexpr l ^ "]" ^ " = " ^ string_of_sexpr e
  | SNoExpr -> ""
				  ) ^ ")"				     

let rec string_of_sstmt = function
    SBlock(stmts) ->
      "{\n" ^ String.concat "" (List.map string_of_sstmt stmts) ^ "}\n"
  | SExpr(expr) -> string_of_sexpr expr ^ ";\n";
  | SReturn(expr) -> "return " ^ string_of_sexpr expr ^ ";\n";
  | SIf(e, s, SBlock([])) -> "if " ^ string_of_sexpr e ^ "\n" ^ string_of_sstmt s
  | SIf(e, s1, s2) ->  "if " ^ string_of_sexpr e ^ "\n" ^
      string_of_sstmt s1 ^ "else\n" ^ string_of_sstmt s2
  | SFor(e1, e2, e3, s) ->
      "for (" ^ string_of_sexpr e1  ^ " ; " ^ string_of_sexpr e2 ^ " ; " ^
      string_of_sexpr e3  ^ ") " ^ string_of_sstmt s
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
