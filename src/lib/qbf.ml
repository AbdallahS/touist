open Types
open Types.Ast

let add_suffix name =
  let open Re.Str in
  try
    let _ =
      Re.Str.search_backward (Re.Str.regexp "_[0-9]+$") name
        (String.length name)
    in
    ();
    name
    |> Re.Str.substitute_first (Re.Str.regexp "[0-9]+$") (fun str ->
           (str |> matched_string |> int_of_string) + 1 |> string_of_int)
  with Not_found -> name ^ "_1"

let rec remove_dups = function
  | [] -> []
  | h :: t -> h :: remove_dups (List.filter (fun x -> x <> h) t)

let dual = function Forall -> Exists | Exists -> Forall

(** [to_prenex] is used over and over by {!prenex} as long as the formula
    is not in prenex form.

    [quant_l] is the list of previously quantified propositions. We need this
    to rename any overlapping quantor scope when transforming to prenex form.
    [conflict_t] is the list of must-currenlty-be-renamed list of props (as
    strings).
    [only_rename] allows us to skip the subsequent transformations if one
    of the 14 transformations has been performed in the recursion. We
    only want one exists/forall transformation per to_prenex full recursion
    because of the variable renaming.
*)
let rec to_prenex debug quant_l conflict_l only_rename ast : Ast.t =
  let string_of_prop prop =
    match prop with
    | Prop name -> name
    | e ->
        failwith
          ("[shouldnt happen] a quantor must be a proposition, not a '"
          ^ Pprint.string_of_ast_type e
          ^ "' in " ^ Pprint.string_of_ast e)
  in
  (* [to_prenew_new] is just going to add a newly quantified variable to the
     list. But if the newly quantified variable is already in quant_l, then
     an error is raised. *)
  let to_prenex_new prop ast_inner =
    if List.exists (fun y -> y = string_of_prop prop) quant_l then
      Err.fatal
        ( Err.Error,
          Err.Prenex,
          "the prop '" ^ Pprint.string_of_ast prop
          ^ "' has been quantified twice. For all the quantifiers quantifying \
             on '" ^ Pprint.string_of_ast prop
          ^ "' in the following code, you should rename their variables:\n    "
          ^ Pprint.string_of_ast ast ^ "\n",
          None )
    else
      ast_inner
      |> to_prenex debug (string_of_prop prop :: quant_l) conflict_l only_rename
  in
  (* [to_prenex_rn] will recursively launch a prenex where all propositions that
     have the same name as 'prop' will be renamed by adding a suffix
     (x1,x2...). *)
  let to_prenex_rn prop ast =
    ast |> to_prenex debug quant_l (string_of_prop prop :: conflict_l) true
  in
  (* [to_prenex] is the same as the outer 'to_prenex' except that the
     non-changing arguments are already given. *)
  let to_prenex ast = ast |> to_prenex debug quant_l conflict_l only_rename in
  if debug then
    Printf.printf "to_prenex_in  (%s): %s\n"
      (if only_rename then "traversing  " else "transforming")
      (Pprint.string_of_ast ~utf8:true ast);

  (* To transform into prenex, I want to traverse recursively the AST so that
     in every traversal of each branch, only ONE transformation can happen.
     Do do that, we use the variable [only_rename] which is true if one
     transformation has already happened previously in the recursion.
     We call recursively [process] -> [transform] (if not only_rename) -> [traverse].
     As soon as a [transform] has been completed, all inner recursions of
     [to_prenex_rn] will disable any subsequent transformation to avoid any
     colision between renaming and transforming (the subsequent calls
     of [to_prenex_new] or [to_prenex] will still be able to run [transform]).
  *)
  let transform = function
    | Not (Quantifier (q, x, f)) ->
        Quantifier (dual q, to_prenex x, Not (to_prenex_new x f)) (* 1,8 *)
    | LogicBinop (f, (And as b), Quantifier (q, x, g))
    | LogicBinop (Quantifier (q, x, g), (And as b), f)
    | LogicBinop (f, (Or as b), Quantifier (q, x, g))
    | LogicBinop (Quantifier (q, x, g), (Or as b), f) ->
        Quantifier
          (q, to_prenex x, LogicBinop (to_prenex_rn x f, b, to_prenex_new x g))
        (* 2,5,9,12,3,6,10,13 *)
    | LogicBinop (Quantifier (q, x, f), Implies, g) ->
        Quantifier
          ( dual q,
            to_prenex x,
            LogicBinop (to_prenex_new x f, Implies, to_prenex_rn x g) )
        (* 4,11 *)
    | LogicBinop (f, Implies, Quantifier (q, x, g)) ->
        Quantifier
          ( q,
            to_prenex x,
            LogicBinop (to_prenex_rn x f, Implies, to_prenex_new x g) )
        (* 7,14 *)
    | _ -> raise Not_found
  in
  let traverse = function
    | Top -> Top
    | Bottom -> Bottom
    | Not x -> Not (to_prenex x)
    | LogicBinop (x, Xor, y) ->
        to_prenex
          (LogicBinop (LogicBinop (x, Or, y), And, LogicBinop (Not x, Or, Not y)))
    (* ∃x ⇔ y   ≡   (∃x ⇒ y)⋀(y ⇒ ∃x)  ≡  ∀x.(x ⇒ y) ⋀ ∃x1.(y ⇒ x1), and thus
       we cannot translate to prenex and keep the equivalence notation: x is used
       twice. *)
    | LogicBinop (x, Equiv, y) ->
        to_prenex
          (LogicBinop
             (LogicBinop (x, Implies, y), And, LogicBinop (y, Implies, x)))
    | LogicBinop (x, b, y) -> LogicBinop (to_prenex x, b, to_prenex y)
    | Prop x ->
        if List.exists (fun y -> y = x) conflict_l then Prop (add_suffix x)
        else Prop x
    | e ->
        failwith
          ("[shouldnt happen] a qbf formula shouldn't contain '"
          ^ Pprint.string_of_ast_type e
          ^ "' in "
          ^ Pprint.string_of_ast ~debug:true e)
  in
  let process = function
    | Quantifier (q, x, f) -> Quantifier (q, to_prenex x, to_prenex_new x f)
    | v -> (
        if only_rename then traverse v
        else try transform v with Not_found -> traverse v)
  in
  let new_ast = process ast in
  if debug then
    Printf.printf "to_prenex_out (%s): %s\n"
      (if only_rename then "traversing  " else "transforming")
      (Pprint.string_of_ast ~utf8:true ast);
  new_ast

let rec is_unquant = function
  | Quantifier _ -> false
  | Prop _ | Top | Bottom -> true
  | Not x -> is_unquant x
  | LogicBinop (x, _, y) -> is_unquant x && is_unquant y
  | e ->
      failwith
        ("[shouldnt happen] a qbf formula shouldn't contain '"
        ^ Pprint.string_of_ast_type e
        ^ "' in "
        ^ Pprint.string_of_ast ~debug:true e)

let rec is_prenex = function
  | Quantifier (_, _, f) -> is_prenex f
  | f -> is_unquant f

(* [quantify_free_variables] takes a prenex form and quantifies existentially
   any free variable in the innermost way possible.
   It is mainly used by {!cnf}. *)
let rec quantify_free_variables env ast =
  let rec search_free env ast =
    match ast with
    | Prop x -> if List.exists (fun y -> y = x) env then [] else [ x ]
    | Top | Bottom -> []
    | Not x -> search_free env x
    | LogicBinop (x, _, y) -> search_free env x @ search_free env y
    | e ->
        failwith
          ("quantify_free_variables(): a qbf formula shouldn't contain '"
          ^ Pprint.string_of_ast_type e
          ^ "' in "
          ^ Pprint.string_of_ast ~debug:true e)
  in
  match ast with
  | Quantifier (q, Prop x, f) ->
      Quantifier (q, Prop x, quantify_free_variables (x :: env) f)
  | other ->
      let free = search_free env other in
      free |> remove_dups
      |> List.fold_left (fun acc x -> Quantifier (Exists, Prop x, acc)) other

let prenex ?(debug = false) ast : Ast.t =
  let rec to_prenex_loop ast =
    if debug then
      Printf.printf "step: %s\n" (Pprint.string_of_ast ~utf8:true ast);
    if is_prenex ast then ast
    else ast |> to_prenex debug [] [] false |> to_prenex_loop
  in
  let intermediate = to_prenex_loop ast in
  if debug then
    Printf.printf "before bounding free vars: %s\n"
      (Pprint.string_of_ast ~utf8:true intermediate);
  let final = intermediate |> quantify_free_variables [] in
  final

let cnf ?(debug_cnf = false) ast =
  let rec process = function
    | Quantifier (q, x, f) -> Quantifier (q, x, process f)
    | inner -> Cnf.ast_to_cnf ~debug_cnf inner
  in
  ast |> process |> quantify_free_variables []

type 'a quantlist = A of 'a list | E of 'a list

(* NOTE: I had to reverse the lists each time because the lists were
   constructed the wrong way around. *)
let rec regroup_quantors ast quantlist =
  match ast with
  | Quantifier (q, Prop x, f) -> (
      match q with
      | Forall ->
          let rec process_forall ast l =
            match ast with
            | Quantifier (Forall, Prop x', f') -> process_forall f' (x' :: l)
            | f' -> (l, f')
          in
          let foralls, inner = process_forall f [ x ] in
          regroup_quantors inner (A (List.rev foralls) :: quantlist)
      | Exists ->
          let rec process_exists ast l =
            match ast with
            | Quantifier (Exists, Prop x', f') -> process_exists f' (x' :: l)
            | f' -> (l, f')
          in
          let exists, inner = process_exists f [ x ] in
          regroup_quantors inner (E (List.rev exists) :: quantlist))
  | inner -> (List.rev quantlist, inner)

(* NOTE: I use [fold_right] (which is non-tail recursive, thus less
    performant) to avoid the mess yielded by the reversing of the lists with
    [fold_left]. *)
let qbfclauses_of_cnf ast =
  let quants, inner = regroup_quantors ast [] in
  let num_lit = ref 1 in
  let fresh_lit () =
    let lit = !num_lit in
    incr num_lit;
    lit
  in
  let clauses_int, int_to_str, str_to_int =
    Cnf.clauses_of_cnf (fun v -> -v) fresh_lit inner
  in
  let quantlist_int =
    quants
    |> List.fold_left
         (fun acc lst ->
           let res =
             match lst with
             | A l ->
                 A
                   (List.fold_right
                      (fun p acc -> Hashtbl.find str_to_int p :: acc)
                      l [])
             | E l ->
                 E
                   (List.fold_right
                      (fun p acc -> Hashtbl.find str_to_int p :: acc)
                      l [])
           in
           res :: acc)
         []
  in
  (List.rev quantlist_int, clauses_int, int_to_str)

let print_qdimacs ?(line_begin = "") ?(debug_dimacs = false)
    (quantlist_int, clauses_int, int_to_str) ?out_table (out : out_channel) =
  let print_lit =
    if debug_dimacs then fun v ->
      (if v < 0 then "-" else "") ^ (abs v |> Hashtbl.find int_to_str)
    else string_of_int
  in
  (* Display the mapping table (propositional names -> int)
     1) if out = out_table, append 'c' (dimacs comments)
     2) if out != out_table, print it as-is into out_table *)
  let _ =
    match out_table with
    | Some out_tbl ->
        int_to_str
        |> Cnf.print_table
             (fun x -> x)
             out_tbl
             ~prefix:(if out = out_tbl then line_begin ^ "c " else line_begin)
    | None -> ()
  in
  (* Display the dimacs' preamble line. *)
  Printf.fprintf out "%sp cnf %d %d\n" line_begin
    (Hashtbl.length int_to_str)
    (List.length clauses_int);
  (* Display the quantifiers lines *)
  quantlist_int
  |> List.iter (fun quantlist ->
         let open List in
         let open Printf in
         match quantlist with
         | A l ->
             fprintf out "%sa%s 0\n" line_begin
               (l |> fold_left (fun acc s -> acc ^ " " ^ print_lit s) "")
         | E l ->
             fprintf out "%se%s 0\n" line_begin
               (l |> fold_left (fun acc s -> acc ^ " " ^ print_lit s) ""));
  (* Display the clauses in dimacs way *)
  clauses_int |> Cnf.print_clauses ~prefix:line_begin out print_lit
