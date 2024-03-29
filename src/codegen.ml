(* Authors: Alice Zhang, Emily Li *)

module L = Llvm
module A = Ast
open Sast

module StringMap = Map.Make(String)

(* translate : Sast.program -> Llvm.module *)
let translate (globals, functions) =
  let context    = L.global_context () in
  
  (* Create the LLVM compilation module into which
     we will generate code *)
  let the_module = L.create_module context "Improv" in

  (* Get types from the context *)
  let i32_t      = L.i32_type    context
  and i8_t       = L.i8_type     context
  and i1_t       = L.i1_type     context
  and string_t   = L.pointer_type (L.i8_type context)
  and void_t     = L.void_type   context in

  (* Return the LLVM type for an Improv type *)
  let rec ltype_of_typ = function
      A.Int  -> i32_t
    | A.String  -> string_t
    | A.Bool  -> i1_t
    | A.Tone  -> i32_t
    | A.Rhythm  -> string_t
    | A.Note  -> L.struct_type context [| i32_t ; string_t |]
    | A.Array(t)  -> L.struct_type context [| i32_t ; L.pointer_type (ltype_of_typ t) |] 
    | A.None  -> void_t
  in

  let rec int_range = function
      0 -> [ ]
    | 1 -> [ 0 ]
    | n -> int_range (n - 1) @ [ n - 1 ] in

  (* Create a map of global variables after creating each *)
  let global_vars : L.llvalue StringMap.t =
    let global_var m (t, n) = 
      let init = match t with
          A.String -> L.const_string context ""
        | _ -> L.const_int (ltype_of_typ t) 0
      in StringMap.add n (L.define_global n init the_module) m in
    List.fold_left global_var StringMap.empty globals in

  let printf_t : L.lltype = 
      L.var_arg_function_type i32_t [| L.pointer_type i8_t |] in
  let printf_func : L.llvalue = 
      L.declare_function "printf" printf_t the_module in
  
  let printbig_t : L.lltype =
      L.function_type i32_t [| i32_t |] in
  let printbig_func : L.llvalue =
      L.declare_function "printbig" printbig_t the_module in

  let printn_t : L.lltype =
    L.function_type i32_t [| ltype_of_typ(A.Note) |] in
  let printn_func : L.llvalue =
    L.declare_function "printn" printn_t the_module in

  let printa_t : L.lltype =
    L.function_type i32_t [| ltype_of_typ(A.Array(Int)) |] in
  let printa_func : L.llvalue =
    L.declare_function "printa" printa_t the_module in

  let render_t : L.lltype =
    L.function_type i32_t [| ltype_of_typ(A.Array(Note)) ; string_t ; i32_t ; i32_t |] in
  let render_func : L.llvalue =
    L.declare_function "render" render_t the_module in

  let printmidi_t : L.lltype =
    L.function_type i32_t [| string_t |] in
  let printmidi_func : L.llvalue =
    L.declare_function "printmidi" printmidi_t the_module in

  let append_t : L.lltype =
    L.function_type (ltype_of_typ(A.Array(Note))) [| ltype_of_typ(A.Array(Note)) ; ltype_of_typ(A.Array(Note)) |] in
  let append_func : L.llvalue =
    L.declare_function "append" append_t the_module in
  
  let printNoteArr_t : L.lltype =
    L.function_type i32_t [| ltype_of_typ(A.Array(Note)) |] in
  let printNoteArr_func : L.llvalue =
    L.declare_function "printNoteArr" printNoteArr_t the_module in

  (* Define each function (arguments and return type) so we can 
     call it even before we've created its body *)
  let function_decls : (L.llvalue * sfunc_decl) StringMap.t =
    let function_decl m fdecl =
      let name = fdecl.sfname
      and param_types = 
	      Array.of_list (List.map (fun (t,_) -> ltype_of_typ t) fdecl.sparams)
      in let ftype = L.function_type (ltype_of_typ fdecl.sftype) param_types in
      StringMap.add name (L.define_function name ftype the_module, fdecl) m in
    List.fold_left function_decl StringMap.empty functions in
  
  (* Fill in the body of the given function *)
  let build_function_body fdecl =
    let (the_function, _) = StringMap.find fdecl.sfname function_decls in
    let builder = L.builder_at_end context (L.entry_block the_function) in

    let int_format_str = L.build_global_stringptr "%d\n" "fmt" builder
    and string_format_str = L.build_global_stringptr "%s\n" "fmt" builder in

    (* Construct the function's "locals": param arguments and locally
       declared variables.  Allocate each on the stack, initialize their
       value, if appropriate, and remember their values in the "locals" map *)
    let local_vars =
      let add_param m (t, n) p = 
        L.set_value_name n p;
	  let local = L.build_alloca (ltype_of_typ t) n builder in
      ignore (L.build_store p local builder);
	  StringMap.add n local m 

      (* Allocate space for any locally declared variables and add the
       * resulting registers to our map *)
    and add_local m (t, n) =
	    let local_var = L.build_alloca (ltype_of_typ t) n builder
	    in StringMap.add n local_var m 
    in

    let params = List.fold_left2 add_param StringMap.empty fdecl.sparams
        (Array.to_list (L.params the_function)) in
      List.fold_left add_local params fdecl.svars 
    in

    (* Return the value for a variable or param argument.
       Check local names first, then global names *)
    let lookup n = try StringMap.find n local_vars
                   with Not_found -> StringMap.find n global_vars
    in

    let build_array len el = 
      let arr_mem = L.build_array_malloc (L.type_of (List.hd el)) len "tmp" builder in
        List.iter (fun idx ->
          let arr_ptr = (L.build_gep arr_mem [| L.const_int i32_t idx |] "tmp2" builder) in
          let e_val = List.nth el idx in
          ignore (L.build_store e_val arr_ptr builder)
        ) (int_range (List.length el));
        let len_arr_ptr = L.struct_type context [| i32_t ; L.pointer_type (L.type_of (List.hd el)) |] in
        let struc_ptr = L.build_malloc len_arr_ptr "arr_literal" builder in
        let first_store = L.build_struct_gep struc_ptr 0 "first" builder in
        let second_store = L.build_struct_gep struc_ptr 1 "second" builder in
        ignore (L.build_store len first_store builder);
        ignore (L.build_store arr_mem second_store builder);
        let result = L.build_load struc_ptr "actual_arr_literal" builder in
      result
    in 

    (* Construct code for an expression; return its value *)
    let rec expr builder ((_, e) : sexpr) = match e with
	      SLitInt i -> L.const_int i32_t i
      | SLitString s -> L.build_global_stringptr s "str" builder
      | SLitBool b  -> L.const_int i1_t (if b then 1 else 0)

      (* note struct type *)
      | SLitNote (i, s) -> 
        let i'= expr builder i in 
        let s' = L.build_global_stringptr s "str" builder in 
        let struc =  L.struct_type context [| i32_t ; string_t |] in 
        let struct_ptr = L.build_malloc struc "struct_mem" builder in 
        let first_store = L.build_struct_gep struct_ptr 0 "tone" builder in 
        let second_store = L.build_struct_gep struct_ptr 1 "rhythm" builder in 
        ignore (L.build_store i' first_store builder);
        ignore (L.build_store s' second_store builder); 
        let result = L.build_load struct_ptr "struct_literal" builder in result

      | SLitArray l  -> let len = L.const_int i32_t (List.length l) in
                        let el = List.map (fun e' -> expr builder e') (List.rev l) in
                        build_array len el
      | SArrayAccess(s, ind1) ->
        let i' = expr builder ind1 in 
        let v' = L.build_load (lookup s) s builder in 
        let extract_value = L.build_extractvalue v' 1 "extract_value" builder in
        let extract_array = L.build_gep extract_value [| i' |] "extract_array" builder in  
        let result = L.build_load extract_array s builder in result
        
      | SArrayAssign(v, i, e) -> let e' = expr builder e in 
        let i' = expr builder i in
        let v' = L.build_load (lookup v) v builder in 
        let extract_value = L.build_extractvalue v' 1 "extract_value" builder in
        let extract_array = L.build_gep extract_value [| i' |] "extract_array" builder in
        ignore (L.build_store e' extract_array builder); e'

      | SNoExpr     -> L.const_int i32_t 0
      | SId s       -> L.build_load (lookup s) s builder
      | SAssign (s, e) -> let e' = expr builder e in
                          ignore(L.build_store e' (lookup s) builder); e'
      | SBinop (e1, op, e2) ->
        let e1' = expr builder e1
        and e2' = expr builder e2 in
        (match op with
          A.Add     -> L.build_add
        | A.Sub     -> L.build_sub
        | A.Mul     -> L.build_mul
        | A.Div     -> L.build_sdiv
        | A.Mod     -> L.build_srem
        | A.And     -> L.build_and
        | A.Or      -> L.build_or
        | A.Eq      -> L.build_icmp L.Icmp.Eq
        | A.Neq     -> L.build_icmp L.Icmp.Ne
        | A.Lt      -> L.build_icmp L.Icmp.Slt
        | A.Lte     -> L.build_icmp L.Icmp.Sle
        ) e1' e2' "tmp" builder
      | SUniop(op, ((t, _) as e)) ->
        let e' = expr builder e in
        (match op with
        | A.Not                  -> L.build_not) e' "tmp" builder
      | SCall ("print", [e])
      | SCall ("printbig", [e]) ->
        L.build_call printbig_func [| (expr builder e) |] "printbig" builder
      | SCall ("printi", [e]) ->
        L.build_call printf_func [| int_format_str ; (expr builder e) |]
          "printf" builder
      | SCall ("prints", [e]) -> 
	      L.build_call printf_func [| string_format_str ; (expr builder e) |]
	        "printf" builder
      | SCall ("printn", [e]) -> 
        L.build_call printn_func [| (expr builder e) |]
          "printn" builder
      | SCall ("printa", [e]) -> 
        L.build_call printa_func [| (expr builder e) |]
          "printa" builder
      | SCall ("render", [arr ; file ; key ; tempo]) -> 
        L.build_call render_func [| (expr builder arr) ; (expr builder file) ; (expr builder key) ; (expr builder tempo) |]
          "render" builder
      | SCall ("printmidi", [e]) -> 
        L.build_call printmidi_func [| (expr builder e) |]
          "printmidi" builder
      | SCall ("append", [a1; a2]) -> 
        L.build_call append_func [| (expr builder a1) ; (expr builder a2) |]
          "append" builder
      | SCall ("printNoteArr", [a1]) -> 
        L.build_call printNoteArr_func [| (expr builder a1) |]
          "printNoteArr" builder
      | SCall (f, args) ->
        let (fdef, fdecl) = StringMap.find f function_decls in
        let llargs = List.rev (List.map (expr builder) (List.rev args)) in
        let result = (match fdecl.sftype with 
                          A.None -> ""
                        | _ -> f ^ "_result") in
            L.build_call fdef (Array.of_list llargs) result builder
      in
    
    (* LLVM insists each basic block end with exactly one "terminator" 
       instruction that transfers control.  This function runs "instr builder"
       if the current block does not already have a terminator.  Used,
       e.g., to handle the "fall off the end of the function" case. *)
    let add_terminal builder instr =
      match L.block_terminator (L.insertion_block builder) with
	      Some _ -> ()
      | None -> ignore (instr builder) in
	
    (* Build the code for the given statement; return the builder for
       the statement's successor (i.e., the next instruction will be built
       after the one generated by this call) *)

    let rec stmt builder = function
	      SBlock sl -> List.fold_left stmt builder sl
      | SExpr e -> ignore(expr builder e); builder 
      | SReturn e -> ignore(match fdecl.sftype with
                              (* Special "return nothing" instr *)
                              A.None -> L.build_ret_void builder 
                              (* Build return statement *)
                            | _ -> L.build_ret (expr builder e) builder );
                     builder
      | SIf (predicate, then_stmt, else_stmt) ->
        let bool_val = expr builder predicate in
	      let merge_bb = L.append_block context "merge" the_function in
        let build_br_merge = L.build_br merge_bb in (* partial function *)

        let then_bb = L.append_block context "then" the_function in
        add_terminal (stmt (L.builder_at_end context then_bb) then_stmt)
          build_br_merge;

        let else_bb = L.append_block context "else" the_function in
        add_terminal (stmt (L.builder_at_end context else_bb) else_stmt)
          build_br_merge;

        ignore(L.build_cond_br bool_val then_bb else_bb builder);
        L.builder_at_end context merge_bb

      | SWhile (predicate, body) ->
        let pred_bb = L.append_block context "while" the_function in
        ignore(L.build_br pred_bb builder);

        let body_bb = L.append_block context "while_body" the_function in
        add_terminal (stmt (L.builder_at_end context body_bb) body)
          (L.build_br pred_bb);

        let pred_builder = L.builder_at_end context pred_bb in
        let bool_val = expr pred_builder predicate in

        let merge_bb = L.append_block context "merge" the_function in
        ignore(L.build_cond_br bool_val body_bb merge_bb pred_builder);
        L.builder_at_end context merge_bb

      (* Implement for loops as while loops *)
      | SFor (e1, e2, e3, body) -> stmt builder
	      ( SBlock [SExpr e1 ; SWhile (e2, SBlock [body ; SExpr e3]) ] )
    in

    (* Build the code for each statement in the function *)
    let builder = stmt builder (SBlock fdecl.sbody) in

    (* Add a return if the last block falls off the end *)
    add_terminal builder (match fdecl.sftype with
        A.None -> L.build_ret_void
      | A.String -> L.build_ret (L.const_string context "")
      | t -> L.build_ret (L.const_int (ltype_of_typ t) 0))
  in

  List.iter build_function_body functions;
  the_module
