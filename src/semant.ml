(* Semantic checking *)

open Ast
open Sast

module StringMap = Map.Make(String)

(* Semantic checking of the AST. Returns an SAST if successful,
   throws an exception if something is wrong.

   Check each global variable, then check each function *)

let check (globals, functions) =

  (* Verify a list of bindings has no void types or duplicate names *)
  let check_binds (kind : string) (binds : bind list) =
    List.iter (function (None, b) -> raise (Failure ("illegal void " ^ kind ^ " " ^ b))
      | _ -> ()) binds;
    let rec dups = function
        [] -> ()
      |	((_,n1) :: (_,n2) :: _) when n1 = n2 ->
	  raise (Failure ("duplicate " ^ kind ^ " " ^ n1))
      | _ :: t -> dups t
    in dups (List.sort (fun (_,a) (_,b) -> compare a b) binds)
  in

  (**** Check global variables ****)
  check_binds "global" globals;

  (**** Check functions ****)

  (* Collect function declarations for built-in functions: no bodies *)
  let built_in_decls = 
    let add_bind map (name, ty) = StringMap.add name {
      ftype = None;
      fname = name; 
      params = [(ty, "x")];
      vars = []; 
      body = [] } map
    in List.fold_left add_bind StringMap.empty [ ("print", Int); ("printi", Int); ("prints", String); ("printn", Note); ("printbig", Int); ("printmidi", String); ("printa", Array(Int)); ("printNoteArr", Array(Note))]; 
  in

  (* TODO: add render function, printarray *)
  let built_in_decls =
    StringMap.add "render" {
      ftype = None;
      fname = "render";
      params = [(Array(Note), "noteArr"); (String, "filename"); (Int, "key"); (Int, "tempo")]; (* formals *)
      vars = []; (* locals *)
      body = [] } built_in_decls 
  in

  let built_in_decls =
    StringMap.add "append" {
      ftype = Array(Note);
      fname = "append";
      params = [(Array(Note), "a1"); (Array(Note), "a2")]; (* formals *)
      vars = []; (* locals *)
      body = [] } built_in_decls 
  in

  (* Add function name to symbol table *)
  let add_func map fd = 
    let built_in_err = "function " ^ fd.fname ^ " may not be defined"
    and dup_err = "duplicate function " ^ fd.fname
    and make_err er = raise (Failure er)
    and n = fd.fname (* Name of the function *)
    in match fd with (* No duplicate functions or redefinitions of built-ins *)
         _ when StringMap.mem n built_in_decls -> make_err built_in_err
       | _ when StringMap.mem n map -> make_err dup_err  
       | _ ->  StringMap.add n fd map (*adds function to map*)
  in

  (* Collect all function names into one symbol table *)
  let function_decls = List.fold_left add_func built_in_decls functions
  in
  
  (* Return a function from our symbol table *)
  let find_func s = 
    try StringMap.find s function_decls
    with Not_found -> raise (Failure ("unrecognized function " ^ s))
  in

  let _ = find_func "main" in (* Ensure "main" is defined *)

  let check_function func =
    (* Make sure no params or vars are void or duplicates *)
    check_binds "params" func.params;
    check_binds "vars" func.vars;

    (* Raise an exception if the given rvalue type cannot be assigned to
       the given lvalue type *)
    let check_assign lvaluet rvaluet err =
       if lvaluet = rvaluet then lvaluet else raise (Failure err)
    in   

    (* Build var symbol table of variables for this function *)
    let symbols = List.fold_left (fun m (ty, name) -> StringMap.add name ty m)
	                StringMap.empty (globals @ func.params @ func.vars )
    in

    (* Return a variable from our var symbol table *)
    let type_of_identifier s =
      try StringMap.find s symbols
      with Not_found -> raise (Failure ("undeclared identifier " ^ s))
    in

    (* Raise exception if given tone is not valid (only 1-6) *)
    let check_tone = function
      (Int, t) -> (Int, t)

      (* how to check if t is in between values ?? *)
         
        (* if t >= 0 && t <= 5 then (Int, t *)
      | _ -> raise (Failure ("invalid tone assignment, must be int expression")) 
(*       
      if t >= 0 && t <= 5 then t
      else raise (Failure ("invalid tone assignment, must be within 0-5"))  *)
    in 

    (* Raise exception if given rhythm is not valid *)
    let check_rhythm r = 
      match r with
        | "wh" -> "0" 
        | "hf" -> "1"
        | "qr" -> "2" 
        | "ei" -> "3" 
        | "sx" -> "4"
        | _ -> raise (Failure ("invalid rhythm assignment " ^ r))
      in 

    (* let check_type lvaluet rvaluet err =
      if (String.compare (string_of_typ lvaluet) (string_of_typ rvaluet)) == 0 then lvaluet else raise err
   in

    let var_symbols = List.fold_left (fun m (t, n) -> StringMap.add n t m) 
       StringMap.empty func.params in *)

    (* let array_access_type = function
      Array(t) -> t
      | _ -> raise(Failure("Can only access a[x] from an array a")) 
    in *)

    let match_array = function
        Array(_) -> true
      | _ -> false
    in

    let get_array_type = function
        Array(t) -> t
      | _ -> raise (Failure "invalid array type")
    in

    (* Return a semantically-checked expression, i.e., with a type *)
    let rec expr = function
        LitInt  l -> (Int, SLitInt l)
      | LitString l -> (String, SLitString l)
      | LitBool l  -> (Bool, SLitBool l)
      (* | LitTone t -> (Tone, SLitTone (check_tone t)) *)
      | LitRhythm r -> (Rhythm, SLitRhythm (check_rhythm r))
      | LitNote (t, r) -> 
        let (typ, t') = expr t in 
        (* let rec check_int typ = 
          match typ with 
          | Int -> Int
          | _ -> raise (Failure ("invalid tone assignment, must be int expression")) *)
        (Note, SLitNote(check_tone(typ, t'), check_rhythm r)) 
      | LitArray l -> let array = List.map expr l in
          let rec type_check = function
            (t1, _) :: [] -> (Array(t1), SLitArray(array))
            | ((t1,_) :: (t2,_) :: _) when t1 != t2 ->
              raise (Failure ("inconsistent array types, expected " ^ string_of_typ t1 ^ " but found " ^ string_of_typ t2))
            | _ :: t -> type_check t
            | [] -> raise (Failure ("empty array")) 
            in type_check array
      | ArrayAccess (a, i) -> 
        let (t, i') = expr i in
        let ty = (type_of_identifier a) in
        (* let ty' = match t with
            Array(ty) -> ty
          | _ -> raise (Failure ("invalid array type")) in *)
        (get_array_type ty, SArrayAccess (a, (t, i')))
        
        (* (Int, SLitInt 10) *)

      (* ArrayAccess 
      Return string & semantically checked sexpr
      (string, sexpr)

      Check s is an array
      e is an integer

      Type of array access = type of elements of array *)
                    
      | ArrayAssign(v, i, e) -> 
        let (t, i') = expr i in
        let (te, e') = expr e in
        let ty = (type_of_identifier v) in
        (* let ty' = match t with
            Array(ty) -> ty
          | _ -> raise (Failure ("invalid array type")) in *)
        (get_array_type ty, SArrayAssign (v, (t, i'), (te, e')))
        
        (* (Int, SLitInt 11) *)

      | ArrayAppend(a1, a2) -> 
          let (t1, a1') = expr a1 in
          let (t2, a2') = expr a2 in
          (* let ty1 = (type_of_identifier a1') in *)
          (* let ty' = match t with
              Array(ty) -> ty
            | _ -> raise (Failure ("invalid array type")) in *)
          (t1, SArrayAppend ((t1, a1'), (t2, a2')))
          
          (* (Int, SLitInt 11) *)

      | NoExpr     -> (None, SNoExpr)
      | Id s       -> (type_of_identifier s, SId s)
      | Assign(var, e) as ex -> 
          let lt = type_of_identifier var
          and (rt, e') = expr e in
          let err = "illegal assignment " ^ string_of_typ lt ^ " = " ^ 
            string_of_typ rt ^ " in " ^ string_of_expr ex
          in (check_assign lt rt err, SAssign(var, (rt, e')))
      | Uniop(op, e) as ex -> 
          let (t, e') = expr e in
          let ty = match op with
            (* Neg when t = Int || t = Float -> t *)
          | Not when t = Bool -> Bool
          | _ -> raise (Failure ("illegal unary operator " ^ 
                                 string_of_uop op ^ string_of_typ t ^
                                 " in " ^ string_of_expr ex))
          in (ty, SUniop(op, (t, e')))
      | Binop(e1, op, e2) as e -> 
          let (t1, e1') = expr e1 
          and (t2, e2') = expr e2 in
          (* All binary operators require operands of the same type *)
          let same = t1 = t2 in
          (* Determine expression type based on operator and operand types *)
          let ty = match op with
            Add | Sub | Mul | Div | Mod when same && t1 = Int  -> Int
          | Eq | Neq            when same               -> Bool
          (* | Concat | Dup when same && t1 = Array(t1) -> Array(t1) *)
          (* | Bind when same && t1 = Array(Note) -> Array(Note) *)
          | Lt | Lte
                     when same && (t1 = Int) -> Bool
          | And | Or when same && t1 = Bool -> Bool
          | _ -> raise (
	      Failure ("illegal binary operator " ^
                       string_of_typ t1 ^ " " ^ string_of_op op ^ " " ^
                       string_of_typ t2 ^ " in " ^ string_of_expr e))
          in (ty, SBinop((t1, e1'), op, (t2, e2')))	
      | Call(fname, args) as call -> 
          let fd = find_func fname in
          let param_length = List.length fd.params in
          if List.length args != param_length then
            raise (Failure ("expecting " ^ string_of_int param_length ^ 
                            " arguments in " ^ string_of_expr call))
          else let check_call (ft, _) e = 
            let (et, e') = expr e in 
            let err = "illegal argument found " ^ string_of_typ et ^
              " expected " ^ string_of_typ ft ^ " in " ^ string_of_expr e
            in (check_assign ft et err, e')
          in 
          let args' = List.map2 check_call fd.params args
          in (fd.ftype, SCall(fname, args'))
      (* | _ -> (None, SNoExpr) *)
    in

    let check_bool_expr e = 
      let (t', e') = expr e
      and err = "expected Boolean expression in " ^ string_of_expr e
      in if t' != Bool then raise (Failure err) else (t', e') 
    in

    (* Return a semantically-checked statement i.e. containing sexprs *)
    let rec check_stmt = function
        Expr e -> SExpr (expr e) (*check the expr semantically woo*)
      | If(p, b1, b2) -> SIf(check_bool_expr p, check_stmt b1, check_stmt b2)
      | For(e1, e2, e3, st) ->
          SFor(expr e1, check_bool_expr e2, expr e3, check_stmt st)
      | While(p, s) -> SWhile(check_bool_expr p, check_stmt s)
      | Return e -> let (t, e') = expr e in
        if t = func.ftype then SReturn (t, e') 
        else raise (
	  Failure ("return gives " ^ string_of_typ t ^ " expected " ^
		   string_of_typ func.ftype ^ " in " ^ string_of_expr e))
	    
	    (* A block is correct if each statement is correct and nothing
	       follows any Return statement.  Nested blocks are flattened. *)
      | Block sl -> 
          let rec check_stmt_list = function
              [Return _ as s] -> [check_stmt s]
            | Return _ :: _   -> raise (Failure "nothing may follow a return")
            | Block sl :: ss  -> check_stmt_list (sl @ ss) (* Flatten blocks *)
            | s :: ss         -> check_stmt s :: check_stmt_list ss
            | []              -> []
          in SBlock(check_stmt_list sl)
      (* |  _  -> raise (Failure "this statement is undefined") *)

    in (* body of check_function *)
    { sftype = func.ftype;
      sfname = func.fname;
      sparams = func.params;
      svars  = func.vars;
      sbody = match check_stmt (Block func.body) with
	SBlock(sl) -> sl
      | _ -> raise (Failure ("internal error: block didn't become a block?"))
    }
  in (globals, List.map check_function functions)
