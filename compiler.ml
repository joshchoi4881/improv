(* Top-level of the MicroC compiler: scan & parse the input,
   check the resulting AST and generate an SAST from it, generate LLVM IR,
   and dump the module *)

   open Ast
   open Scanner
   open Parser
   open Semant
   open Pretty_type_print
   open Codegen
   open Printf

   let () =
     let lexbuf = Lexing.from_channel stdin in
     let ast = Parser.program Scanner.token lexbuf in 
     let sast = Semant.check ast in
     let m = Codegen.translate sast in 
     Llvm_analysis.assert_valid_module m;
     let ls = Llvm.string_of_llmodule m in
     let file = "hello.impv" in
     let oc = open_out file in
     fprintf oc "%s\n" ls; 
     close_out oc;
     Sys.command ("cat " ^ file ^ " | lli")
        