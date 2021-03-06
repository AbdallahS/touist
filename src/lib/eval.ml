open Types.Ast
open Types
open Pprint
open Err
open Printf

(* Variables are stored in two data structures (global and local scopes). *)

(* [env] is for local variables (for bigand,bigor and let constructs).
   It is a simple list [(name,description),...] passed as recursive argument.
   The name is the variable name (e.g., '$var' or '$var(a,1,c)').
   The description is a couple (content, location) *)
type env = (string * (Ast.t * loc)) list

let ast_without_layout (ast : Ast.t) : Ast.t =
  match ast with
  (* AS: used to be without_loc*)
  | Layout (Loc _, ast) -> ast
  | ast -> ast

(* [raise_with_loc] takes an ast that may contains a Loc (Loc is added in
   parser.mly) and raise an exception with the given message.
   The only purpose of giving 'ast' is to get the Loc thing.
   [ast_without_layout] should not have been previously applied to [ast]
   because ast_without_layout will remove the Loc thing. *)
let raise_with_loc (ast : Ast.t) (message : string) =
  match ast with
  | Layout (Loc loc, _) -> fatal (Error, Eval, message, Some loc)
  | _ -> fatal (Error, Eval, message, None)

(* [raise_type_error] raises the errors that come from one-parameter functions.
   operator is the non-expanded (expand = eval_ast) operator.
   Example: in 'To_int x', 'operand' is the non-expanded parameter 'x',
   'expanded' iXs the expanded parameter 'x'.
   Expanded means that eval_ast has been applied to x.
   [expected_types] contain a string that explain what is expected, e.g.,
   'an integer or a float'. *)
let raise_type_error operator operand expanded (expected_types : string) =
  raise_with_loc operator
    (sprintf
       "'%s' expects %s. The operand:\n\
       \    %s\n\
        has been expanded to something of type '%s':\n\
       \    %s\n"
       (string_of_ast_type operator)
       expected_types (string_of_ast operand)
       (string_of_ast_type expanded)
       (string_of_ast expanded))

(* Same as above but for functions of two parameters. Example: with And (x,y),
   operator is And (x,y),
   op1 and op2 are the non-expanded parameters x and y,
   exp1 and exp2 are the expanded parameters x and y. *)
let raise_type_error2 operator _op1 exp1 _op2 exp2 (expected_types : string) =
  raise_with_loc operator
    (sprintf
       "incorrect types with '%s'; expects %s. In statement:\n\
       \    %s\n\
        Left-hand operand has type '%s':\n\
       \    %s\n\
        Right-hand operand has type '%s':\n\
       \    %s\n"
       (string_of_ast_type operator)
       expected_types (string_of_ast operator) (string_of_ast_type exp1)
       (string_of_ast exp1) (string_of_ast_type exp2) (string_of_ast exp2))

(* [raise_set_decl] is the same as [raise_type_error2] but between one element
   and the set this element is supposed to be added to. *)
let raise_set_decl ast elmt elmt_expanded set set_expanded
    (expected_types : string) =
  raise_with_loc ast
    (sprintf
       "Ill-formed set declaration. It expects %s. One of the elements is of \
        type '%s':\n\
       \    %s\n\
        This element has been expanded to\n\
       \    %s\n\
        Up to now, the set declaration\n\
       \    %s\n\
        has been expanded to:\n\
       \    %s\n"
       expected_types
       (string_of_ast_type elmt_expanded)
       (string_of_ast elmt)
       (string_of_ast elmt_expanded)
       (string_of_ast set)
       (string_of_ast set_expanded))

let check_nb_vars_same_as_nb_sets (ast : Ast.t) (vars : Ast.t list)
    (sets : Ast.t list) : unit =
  let loc =
    match (List.nth vars 0, List.nth sets (List.length sets - 1)) with
    | Layout (Loc (startpos, _), _), Layout (Loc (_, endpos), _) ->
        (startpos, endpos)
    | _ -> failwith "[shouldn't happen] missing locations in vars/sets"
  in
  match List.length vars = List.length sets with
  | true -> ()
  | false ->
      let message =
        sprintf
          "Ill-formed '%s'. The number of variables and sets must be the same. \
           You defined %d variables:\n\
          \    %s\n\
           but you gave %d sets:\n\
          \    %s\n"
          (string_of_ast_type ast) (List.length vars)
          (string_of_ast_list "," vars)
          (List.length sets)
          (string_of_ast_list "," sets)
      in
      fatal (Error, Eval, message, Some loc)

let extenv = ref (Hashtbl.create 0)

(* [check_only] allows to only 'check the types'. It prevents the bigand,
    bigor, exact, atmost, atleast and range to expand completely(as it
    may take a lot of time to do so). *)
let check_only = ref false

(* By default, we are in 'SAT' mode. When [smt] is true,
   some type checking (variable expansion mostly) is different
   (formulas can be 'int' or 'float' for example). *)
let smt = ref false

let eval_arith_unop ast u x x' =
  match (u, x') with
  | Neg, Int i -> Int (-i)
  | Neg, Float f -> Float (-.f)
  | Neg, _ -> raise_type_error ast x x' "'float' or 'int'"
  | Sqrt, Float f -> Float (sqrt f)
  | Sqrt, _ -> raise_type_error ast x x' "a float"
  | To_int, Float f -> Int (int_of_float f)
  | To_int, Int i -> Int i
  | To_int, _ -> raise_type_error ast x x' "a 'float' or 'int'"
  | To_float, Int i -> Float (float_of_int i)
  | To_float, Float f -> Float f
  | To_float, _ -> raise_type_error ast x x' "a 'float' or 'int'"
  | Abs, Int i -> Int (abs i)
  | Abs, Float f -> Float (abs_float f)
  | Abs, _ -> raise_type_error ast x x' "a 'float' or 'int'"

let int_binop = function
  | Add -> ( + )
  | Sub -> ( - )
  | Mul -> ( * )
  | Div -> ( / )
  | Mod -> ( mod )

let float_binop = function
  | Add -> Some ( +. )
  | Sub -> Some ( -. )
  | Mul -> Some ( *. )
  | Div -> Some ( /. )
  | Mod -> None

let eval_arith_binop x b y =
  match (x, y) with
  | Int x, Int y -> Some (Int (int_binop b x y))
  | Float x, Float y -> (
      match float_binop b with None -> None | Some o -> Some (Float (o x y)))
  | _, _ -> None

let bool_binop = function
  | And -> ( && )
  | Or -> ( || )
  | Xor -> fun x y -> (x || y) && not (x && y)
  | Implies -> fun x y -> (not x) || y
  | Equiv -> fun x y -> ((not x) || y) && ((not x) || y)

let bool_binrel = function
  | Equal -> ( = )
  | Not_equal -> ( <> )
  | Lesser_than -> ( < )
  | Lesser_or_equal -> ( <= )
  | Greater_than -> ( > )
  | Greater_or_equal -> ( >= )

let eval_logic_binop_formula f x b y =
  match (x, b, y) with
  | Top, Or, _ | _, Or, Top -> Top
  | Bottom, And, _ | _, And, Bottom -> Bottom
  | _, Implies, Top | Bottom, Implies, _ -> Top
  | Top, And, z
  | z, And, Top
  | Bottom, Or, z
  | z, Or, Bottom
  | z, Equiv, Top
  | Top, Equiv, z
  (* x ⇔ ⊤  ≡  (¬x ⋁ ⊤) ⋀ (¬⊤ ⋁ x)  ≡  ⊤ ⋀ x  ≡  x *)
  | Top, Implies, z ->
      z
  | z, Implies, Bottom
  | z, Equiv, Bottom
  (* x ⇔ ⊥  ≡  (¬x ⋁ ⊥) ⋀ (¬⊥ ⋁ x)  ≡  ¬x ⋀ ⊤  ≡  ¬x *)
  | Bottom, Equiv, z ->
      f (Not z)
  | _, _, _ -> LogicBinop (x, b, y)

(* AS: We could simplify the XOR as well: xor(Top, x) = x*)

let set_binop = function
  | Union -> AstSet.union
  | Inter -> AstSet.inter
  | Diff -> AstSet.diff

let rec process_formulas ast = function
  | [] -> raise_with_loc ast "no formulas" (* AS: return Top instead? *)
  | [ x ] -> x
  | x :: xs -> LogicBinop (x, And, process_formulas ast xs)

let quantifier = function Exists -> "exists" | Forall -> "forall"

let rec exact_str lst =
  let rec go = function
    | [], [] -> Top
    | t :: ts, [] -> LogicBinop (t, And, go (ts, []))
    | [], f :: fs -> LogicBinop (Not f, And, go ([], fs))
    | t :: ts, f :: fs ->
        LogicBinop (LogicBinop (t, And, Not f), And, go (ts, fs))
  in
  match lst with [] -> Bottom | x :: xs -> LogicBinop (go x, Or, exact_str xs)

and atleast_str lst =
  List.fold_left
    (fun acc str -> LogicBinop (acc, Or, formula_of_string_list str))
    Bottom lst

and atmost_str lst =
  List.fold_left
    (fun acc str ->
      LogicBinop
        ( acc,
          Or,
          List.fold_left
            (fun acc' str' -> LogicBinop (acc', And, Not str'))
            Top str ))
    Bottom lst

and formula_of_string_list =
  List.fold_left (fun acc str -> LogicBinop (acc, And, str)) Top

let eval_cardinality_formula i s = function
  (* !check_only simplifies by returning a dummy proposition *)
  | Exact ->
      if i = 0 && AstSet.is_empty s then Top
      else if AstSet.is_empty s then Bottom
      else if !check_only then Prop "dummy"
      else exact_str (AstSet.exact i s)
  | Atleast ->
      if i = 0 && AstSet.is_empty s then Top
      else if i > 0 && AstSet.is_empty s then Bottom
      else if !check_only then Prop "dummy"
      else atleast_str (AstSet.atleast i s)
  | Atmost ->
      if AstSet.is_empty s then Top
      else if i = 0 then Bottom
      else if !check_only then Prop "dummy"
      else atmost_str (AstSet.atmost i s)

let rec eval ?smt:(smt_mode = false) ?(onlychecktypes = false) ast : Ast.t =
  check_only := onlychecktypes;
  smt := smt_mode;
  extenv := Hashtbl.create 50;
  (* extenv must be re-init between two calls to [eval] *)
  eval_touist_code [] ast

and eval_touist_code (env : env) ast : Ast.t =
  let rec affect_vars = function
    | [] -> []
    | Layout (Loc _, Affect (Layout (Loc var_loc, Var (p, i)), y)) :: xs ->
        Hashtbl.replace !extenv
          (expand_var_name env (p, i))
          (eval_ast env y, var_loc);
        affect_vars xs
    | x :: xs -> x :: affect_vars xs
  in
  match ast_without_layout ast with
  | Touist_code formulas ->
      eval_ast_formula env (process_formulas ast (affect_vars formulas))
  | e ->
      raise_with_loc ast
        ("this does not seem to be a touist code structure: "
        ^ string_of_ast ~debug:true e
        ^ "\n")

(* [eval_ast] evaluates (= expands) numerical, boolean and set expresions that
   are not directly in formulas. For example, in 'when $a!=a' or 'if 3>4',
   the boolean values must be computed: eval_ast will do exactly that.*)
and eval_ast (env : env) (ast : Ast.t) : Ast.t =
  let eval_ast_env = eval_ast in
  let eval_ast = eval_ast env in
  match ast_without_layout ast with
  | Int x -> Int x
  | Float x -> Float x
  | Bool x -> Bool x
  | Var (p, i) -> (
      (* p,i = prefix, indices *)
      let name = expand_var_name env (p, i) in
      try
        let content, _loc = List.assoc name env in
        content
      with Not_found -> (
        try
          let content, _ = Hashtbl.find !extenv name in
          content
        with Not_found ->
          raise_with_loc ast
            ("variable '" ^ name
           ^ "' does not seem to be known. Either you forgot "
           ^ "to declare it globally or it has been previously declared \
              locally "
           ^ "(with bigand, bigor or let) and you are out of its scope." ^ "\n"
            )))
  | Set x -> Set x
  | Set_decl _ -> eval_set_decl env ast
  | ArithUnop (u, x) -> eval_arith_unop ast u x (eval_ast x)
  | ArithBinop (x, b, y) -> (
      let x', y' = (eval_ast x, eval_ast y) in
      match eval_arith_binop x' b y' with
      | Some t -> t
      | None -> raise_type_error2 ast x x' y y' "'float' or 'int'")
  | Not x -> (
      match eval_ast x with
      | Bool x -> Bool (not x)
      | x' -> raise_type_error ast x x' "a 'bool'")
  | LogicBinop (x, b, y) -> (
      let x', y' = (eval_ast x, eval_ast y) in
      match (x', y') with
      | Bool x, Bool y -> Bool (bool_binop b x y)
      | _, _ -> raise_type_error2 ast x x' y y' "a 'bool'")
  | If (x, y, z) ->
      let test =
        match eval_ast x with
        | Bool true -> true
        | Bool false -> false
        | x' -> raise_type_error ast x x' "a 'bool'"
      in
      if test then eval_ast y else eval_ast z
  | SetBinop (x, o, y) -> (
      match (eval_ast x, eval_ast y) with
      | Set a, Set b -> Set (set_binop o a b)
      | x', y' ->
          raise_type_error2 ast x x' y y'
            "a 'float-set', 'int-set' or 'prop-set'")
  | Range (x, y) -> (
      (* !check_only will simplify [min..max] to [min..min] *)
      (* [irange] generates a list of int between min and max with an increment of step. *)
      let irange min max step =
        let rec loop acc = function
          | i when i = max + 1 -> acc
          | i -> loop (Int i :: acc) (i + step)
        in
        loop [] min |> List.rev
      and frange min max step =
        let rec loop acc = function
          | i when i = max +. 1. -> acc
          | i -> loop (Float i :: acc) (i +. step)
        in
        loop [] min |> List.rev
      in
      match (eval_ast x, eval_ast y) with
      | Int x, Int y ->
          Set (AstSet.of_list (irange x (if !check_only then x else y) 1))
      | Float x, Float y ->
          Set (AstSet.of_list (frange x (if !check_only then x else y) 1.))
      | x', y' -> raise_type_error2 ast x x' y y' "two integers or two floats")
  | IsEmpty x -> (
      match eval_ast x with
      | Set x -> Bool (AstSet.is_empty x)
      | x' -> raise_type_error ast x x' "a 'float-set', 'int-set' or 'prop-set'"
      )
  | Card x -> (
      match eval_ast x with
      | Set x -> Int (AstSet.cardinal x)
      | x' -> raise_type_error ast x x' "a 'float-set', 'int-set' or 'prop-set'"
      )
  | Subset (x, y) -> (
      match (eval_ast x, eval_ast y) with
      | Set a, Set b -> Bool (AstSet.subset a b)
      | x', y' -> raise_type_error2 ast x x' y y' "a 'float-set', int or prop")
  | Powerset x -> (
      let combination_to_set k set =
        List.fold_left
          (fun acc x -> AstSet.add (Set (AstSet.of_list x)) acc)
          AstSet.empty
          (AstSet.combinations k set)
      in
      let rec all_combinations_to_set k set =
        match k with
        (* 0 -> because AstSet.combinations does not produce the empty set
                in the set of combinations, we must add the empty set here. *)
        | 0 -> AstSet.of_list [ Set AstSet.empty ]
        | _ ->
            AstSet.union (combination_to_set k set)
              (all_combinations_to_set (pred k) set)
      in
      match eval_ast x with
      (* !check_only is here to skip the full expansion of powerset(). This
         is useful for linting (=checking types). *)
      | Set s ->
          if !check_only then Set (AstSet.of_list [ AstSet.choose s ])
          else Set (all_combinations_to_set (AstSet.cardinal s) s)
      | x' -> raise_type_error ast x x' "a 'set'")
  | In (x, y) -> (
      match (eval_ast x, eval_ast y) with
      | x', Set y' -> Bool (AstSet.mem x' y')
      | x', y' ->
          raise_type_error2 ast x x' y y'
            "an 'int', 'float' or 'prop' on the left-hand and a 'set' on the \
             right-hand")
  | ArithBinrel (x, Equal, y) -> (
      match (eval_ast x, eval_ast y) with
      | Int x, Int y -> Bool (x = y)
      | Float x, Float y -> Bool (x = y)
      | Prop x, Prop y -> Bool (x = y)
      | Set a, Set b -> Bool (AstSet.equal a b)
      | x', y' ->
          raise_type_error2 ast x x' y y' "an 'int', 'float', 'prop' or 'set'")
  | ArithBinrel (x, Not_equal, y) -> eval_ast (Not (ArithBinrel (x, Equal, y)))
  | ArithBinrel (x, b, y) -> (
      let x', y' = (eval_ast x, eval_ast y) in
      match (x', y') with
      | Int x, Int y -> Bool (bool_binrel b x y)
      | Float x, Float y -> Bool (bool_binrel b x y)
      | x', y' -> raise_type_error2 ast x x' y y' "a 'float' or 'int'")
  | UnexpProp (p, i) -> expand_prop_with_set env p i
  | Prop x -> Prop x
  | Layout (_, x) -> eval_ast x
  | Formula x -> Formula (eval_ast_formula env x)
  | SetBuilder (expr, vars, sets, cond) ->
      let rec treat env vars sets : Ast.t list =
        match (vars, sets) with
        | [], [] ->
            if match cond with Some c -> ast_to_bool env c | None -> true then
              [ eval_ast_env env expr ] (* bottom of the recursion: expand f *)
            else []
        | ( Layout (Loc loc, Var (p, i)) :: next_vars,
            Layout (Loc _, set) :: next_sets ) ->
            let set =
              match eval_ast_env env set with
              | Set set -> set
              | _ -> failwith ""
            in
            AstSet.fold
              (fun value acc ->
                let name = expand_var_name env (p, i) and desc = (value, loc) in
                treat ((name, desc) :: env) next_vars next_sets @ acc)
              set []
        | e1, e2 ->
            raise_with_loc ast
              ("[shouldnt happen] set builder error: "
              ^ string_of_ast_list ~debug:true "," e1
              ^ "; "
              ^ string_of_ast_list ~debug:true "," e2
              ^ "\n")
      in
      Set (treat env vars sets |> AstSet.of_list)
  | e ->
      raise_with_loc ast
        ("[shouldnt happen] this expression cannot be expanded: "
       ^ string_of_ast e ^ "\n")

and eval_set_decl (env : env) (set_decl : Ast.t) =
  let sets =
    match ast_without_layout set_decl with
    | Set_decl sets -> sets
    | _ -> failwith "shoulnt happen: non-Set_decl in eval_set_decl"
  in
  let sets_expanded = List.map (fun x -> eval_ast env x) sets in
  let unwrap_set first_elmt elmt elmt_expanded =
    match (first_elmt, elmt_expanded) with
    | Int _, Int x -> Int x
    | Float _, Float x -> Float x
    | Prop _, Prop x -> Prop x
    | Formula _, Formula x -> Formula x
    | Set _, Set x -> Set x
    | _ ->
        raise_set_decl set_decl elmt elmt_expanded (Set_decl sets)
          (Set_decl sets_expanded)
          (sprintf
             "at this point a comma-separated list of '%s', because previous \
              elements of the list had this type"
             (string_of_ast_type first_elmt))
  in
  (* We take the first elmnt of 'sets' and 'sets_expanded' in order to enforce
     what the following elmnts should be. 'x' is only useful for raising the
     error as we need the unexpanded faulty elmt in the error message. *)
  match (sets, sets_expanded) with
  | [], [] -> Set AstSet.empty
  | x :: _, first :: _ -> (
      match first with
      | Int _ | Float _ | Prop _ | Formula _ | Set _ ->
          Set (AstSet.of_list (List.map2 (unwrap_set first) sets sets_expanded))
      | _ ->
          raise_set_decl set_decl x first (Set_decl sets)
            (Set_decl sets_expanded)
            "elements of type 'int', 'float', 'prop', 'set' or 'formula'")
  | [], _ :: _ | _ :: _, [] ->
      failwith "[shouldn't happen] len(sets)!=len(sets_expanded)"

(* [eval_ast_formula] evaluates formulas; nothing in formulas should be
   expanded, except for variables, bigand, bigor, let, exact, atleast,atmost. *)
and eval_ast_formula (env : env) (ast : Ast.t) : Ast.t =
  let eval_ast_formula = eval_ast_formula env
  and eval_ast_formula_env = eval_ast_formula
  and eval_ast = eval_ast env in
  match ast_without_layout ast with
  | Int _ when not !smt -> failwith "Integer allowed only with SMT solver"
  | Int x when !smt -> Int x
  | Float _ when not !smt -> failwith "Float allowed only with SMT solver"
  | Float x when !smt -> Float x
  | ArithUnop (Neg, x) -> (
      match eval_ast_formula x with
      | Int x' -> Int (-x')
      | Float x' -> Float (-.x')
      | x' -> ArithUnop (Neg, x') (*| _ -> raise (Error (string_of_ast ast))*))
  | ArithBinop (x, Add, y) -> (
      match (eval_ast_formula x, eval_ast_formula y) with
      | Int x', Int y' -> Int (x' + y')
      | Float x', Float y' -> Float (x' +. y')
      | Int _, Prop _ | Prop _, Int _ -> ArithBinop (x, Add, y)
      | x', y' ->
          ArithBinop (x', Add, y')
          (*| _,_ -> raise (Error (string_of_ast ast))*))
  | ArithBinop (x, b, y) -> (
      let x', y' = (eval_ast_formula x, eval_ast_formula y) in
      match eval_arith_binop x' b y' with
      | Some t -> t
      | None -> ArithBinop (x', b, y'))
  | ArithBinrel (x, b, y) ->
      ArithBinrel (eval_ast_formula x, b, eval_ast_formula y)
  | Top -> Top
  | Bottom -> Bottom
  | UnexpProp (p, i) -> Prop (expand_var_name env (p, i))
  | Prop x -> Prop x
  | Var (p, i) -> (
      (* p,i = prefix,indices *)
      (* name = prefix + indices.
         Example with $v(a,b,c):
         name is '$v(a,b,c)', prefix is '$v' and indices are '(a,b,c)' *)
      let name = expand_var_name env (p, i) in
      (* Case 1. Check if this variable name has been affected locally
         (recursive-wise) in bigand, bigor or let.
         To be accepted, this variable must contain a proposition. *)
      try
        let content, _ = List.assoc name env in
        match content with
        | Prop x -> Prop x
        | Int x when !smt -> Int x
        | Float x when !smt -> Float x
        | Formula x -> x
        | _ ->
            raise_with_loc ast
              (sprintf
                 "local variable '%s' (defined in bigand, bigor, let or list \
                  comprehension) cannot be expanded into a 'prop' or 'formula' \
                  because its content is of type '%s' instead of %s'prop' or \
                  'formula'. Why? Because this variable is part of a formula, \
                  and thus is expected to be a proposition. Here is the \
                  content of '%s':\n\
                 \    %s\n"
                 name
                 (string_of_ast_type content)
                 (if !smt then "'int', 'float', " else "")
                 name (string_of_ast content))
      with Not_found -> (
        (* Case 2. Check if this variable name has been affected globally, i.e.,
           in the 'data' section. To be accepted, this variable must contain
           a proposition. *)
        try
          let content, _ = Hashtbl.find !extenv name in
          match content with
          | Prop x -> Prop x
          | Int x when !smt -> Int x
          | Float x when !smt -> Float x
          | Formula x -> x
          | _ ->
              raise_with_loc ast
                (sprintf
                   "global variable '%s' cannot be expanded into a 'prop' or \
                    'formula' because its content is of type '%s' instead of \
                    %s'prop' or 'formula'. Why? Because this variable is part \
                    of a formula, and thus is expected to be a proposition. \
                    Here is the content of '%s':\n\
                   \    %s\n"
                   name
                   (string_of_ast_type content)
                   (if !smt then "'int', 'float', " else "")
                   name (string_of_ast content))
        with Not_found -> (
          try
            match (p, i) with
            (* Case 3. The variable is a non-tuple of the form '$v' => name=prefix only.
               As it has not been found in the Case 1 or 2, this means that this variable
               has not been declared. *)
            | _, None -> raise Not_found (* trick to go to the Case 5. error *)
            (* Case 4. The var is a tuple-variable of the form '$v(1,2,3)' and has not
               been declared.
               But maybe we are in the following special case where the parenthesis
               in $v(a,b,c) that should let think it is a tuple-variable is actually
               a 'reconstructed' term, e.g. the content of $v should be expanded.
               Example of use:
                $F = [a,b,c]
                bigand $i in [1..3]:
                  bigand $f in $F:     <- $f is defined as non-tuple variable (= no indices)
                    $f($i)             <- here, $f looks like a tuple-variable but NO!
                  end                     It is simply used to form the proposition
                end                       a(1), a(2)..., b(1)... *)
            | prefix, Some indices ->
                let content, loc_affect = List.assoc prefix env in
                let term =
                  match content with
                  | Prop x -> Prop x
                  | wrong ->
                      let message =
                        sprintf
                          "the proposition '%s' cannot be expanded because \
                           '%s' is of type '%s'. In order to produce an \
                           expanded proposition of this kind, '%s' must be a \
                           proposition. Why? Because this variable is part of \
                           a formula, and thus is expected to be a \
                           proposition. Here is the content of '%s':\n\
                          \    %s\n"
                          name prefix (string_of_ast_type wrong) prefix prefix
                          (string_of_ast content)
                      in
                      fatal (Error, Eval, message, Some loc_affect)
                in
                eval_ast_formula (UnexpProp (string_of_ast term, Some indices))
            (* Case 5. the variable was of the form '$v(1,2,3)' and was not declared
               and '$v' is not either declared, so we can safely guess that this var has not been declared. *)
          with Not_found ->
            raise_with_loc ast ("'" ^ name ^ "' has not been declared" ^ "\n")))
      )
  | Not Top -> Bottom
  | Not Bottom -> Top
  | Not x -> Not (eval_ast_formula x)
  | LogicBinop (x, b, y) ->
      let x', y' = (eval_ast_formula x, eval_ast_formula y) in
      eval_logic_binop_formula eval_ast_formula x' b y'
  | Cardinality (c, x, y) ->
      let x', y' = (eval_ast x, eval_ast y) in
      let i, s =
        match (x', y') with
        | Int i, Set s -> (i, s)
        | _, _ ->
            raise_type_error2 ast x x' y y'
              "'int' (left-hand) and a 'prop-set' (right-hand)"
      in
      rm_top_bot (eval_cardinality_formula i s c)
  (* We consider 'bigand' as the universal quantification; it could be translated as
         for all elements i of E, p(i) is true
     As such, whenever 'bigand' returns nothing (when condition always false or empty
     sets), we return Top. This means that an empty bigand satisfies all the p($i) *)
  | Bigand (vars, sets, when_optional, body) -> (
      let when_cond =
        match when_optional with Some x -> x | None -> Bool true
      in
      check_nb_vars_same_as_nb_sets ast vars sets;
      match (vars, sets) with
      | [], [] | _, [] | [], _ ->
          failwith "shouln't happen: non-variable in big construct"
      | [ Layout (Loc loc, Var (name, _)) ], [ set ] ->
          (* we don't need the indices because bigand's vars are 'simple' *)
          let rec process_list_set env (set_list : Ast.t list) =
            match set_list with
            | [] ->
                Top (*  what if bigand in a or? We give a warning (see below) *)
            | x :: xs -> (
                let env = (name, (x, loc)) :: env in
                match ast_to_bool env when_cond with
                | true when xs != [] ->
                    LogicBinop
                      ( eval_ast_formula_env env body,
                        And,
                        process_list_set env xs )
                | true -> eval_ast_formula_env env body
                | false -> process_list_set env xs)
          in
          let list_ast_set = set_to_ast_list env set in
          let evaluated_ast = process_list_set env list_ast_set in
          rm_top_bot evaluated_ast
      | x :: xs, y :: ys ->
          eval_ast_formula
            (Bigand ([ x ], [ y ], None, Bigand (xs, ys, when_optional, body))))
  (* bigor returns 'Bot' when it returns nothing. It can be interpreted as the
     existential quantificator
         there exists some i of E so that p(i) is true
     When it is applied an empty E, it means that there exists no elements that
     satisfy p(i), so we return Bot. *)
  | Bigor (vars, sets, when_optional, body) -> (
      let when_cond =
        match when_optional with Some x -> x | None -> Bool true
      in
      check_nb_vars_same_as_nb_sets ast vars sets;
      match (vars, sets) with
      | [], [] | _, [] | [], _ ->
          failwith "shouln't happen: non-variable in big construct"
      | [ Layout (Loc loc, Var (name, _)) ], [ set ] ->
          let rec process_list_set env (set_list : Ast.t list) =
            match set_list with
            | [] -> Bottom
            | x :: xs -> (
                let env = (name, (x, loc)) :: env in
                match ast_to_bool env when_cond with
                | true when xs != [] ->
                    LogicBinop
                      ( eval_ast_formula_env env body,
                        Or,
                        process_list_set env xs )
                | true -> eval_ast_formula_env env body
                | false -> process_list_set env xs)
          in
          let list_ast_set = set_to_ast_list env set in
          let evaluated_ast = process_list_set env list_ast_set in
          rm_top_bot evaluated_ast
      | x :: xs, y :: ys ->
          eval_ast_formula
            (Bigor ([ x ], [ y ], None, Bigor (xs, ys, when_optional, body))))
  | If (c, y, z) ->
      let test =
        match eval_ast c with
        | Bool c -> c
        | c' -> raise_type_error ast c c' "boolean"
      in
      if test then eval_ast_formula y else eval_ast_formula z
  | Let (Layout (Loc loc, Var (p, i)), content, formula) ->
      let name = expand_var_name env (p, i)
      and desc = (eval_ast content, loc) in
      eval_ast_formula_env ((name, desc) :: env) formula
  | Layout (Paren, x) | Layout (NewlineBefore, x) | Layout (NewlineAfter, x) ->
      eval_ast_formula x
  | Quantifier (q, p, f) ->
      let p =
        match eval_ast_formula p with
        | Prop p -> Prop p
        | wrong ->
            raise_with_loc p
              (sprintf "'%s' only works on propositions. Instead, got a '%s'.\n"
                 (quantifier q) (string_of_ast_type wrong))
      in
      Quantifier (q, p, eval_ast_formula f)
  | For (Layout (Loc loc, Var (p, i)), content, Layout (Loc _, formula)) -> (
      let name = expand_var_name env (p, i) in
      match (formula, eval_ast content) with
      | Quantifier (q, x, f), Set s ->
          AstSet.fold
            (fun content acc ->
              Quantifier
                (q, eval_ast_formula_env ((name, (content, loc)) :: env) x, acc))
            s (eval_ast_formula f)
      | _, content' -> raise_type_error ast content content' " 'prop-set'")
  | Formula f -> eval_ast_formula f
  | e ->
      raise_with_loc ast
        ("this expression is not a formula: " ^ string_of_ast e ^ "\n")

(* [expand_prop_with_set] takes care of expanding all expressions. Two cases:
   (a) all indices are propositions, meaning that it retuns a simple proposition.
   (b) some indices are sets (= set builder), we expand it using a cartesian
       product, e.g.:     time([1,2],[a,b])
       becomes            [time(1,a),time(1,b)...time(b,2)].
   Here, [name] is 'time' and [indices_optional] is the list '[1,2],[a,b]'.
   This is useful when generating sets. *)
and expand_prop_with_set env name indices_optional =
  let rec eval_indices env (l : Ast.t list) : Ast.t list =
    match l with [] -> [] | x :: xs -> eval_ast env x :: eval_indices env xs
  in
  let rec has_nonempty_set = function
    | [] -> false
    | Set s :: _ when AstSet.is_empty s -> false
    | Set _ :: _ -> true
    | _ :: next -> has_nonempty_set next
  in
  let indices, generated_props =
    match indices_optional with
    | None ->
        (* case (1): proposition without indices (e.g.: it_rains) *)
        ([], [ UnexpProp (name, None) ])
    | Some x ->
        (* case (2): proposition with indices (e.g.: it_rains(day)) *)
        let indices = eval_indices env x in
        (indices, expand_prop_with_set' env [ UnexpProp (name, None) ] indices)
  in
  let eval_unexpprop acc cur =
    match cur with
    | UnexpProp (p, i) -> Prop (expand_var_name env (p, i)) :: acc
    | _ -> failwith "shouldnt happen"
  in
  let props_evaluated = List.fold_left eval_unexpprop [] generated_props in
  if has_nonempty_set indices then Set (AstSet.of_list props_evaluated)
  else List.nth props_evaluated 0

(* This function handles the case (2) of [expand_prop_with_set]. This is
   where we do the actual hard work.
   [acc_props] is an accumulator of the generated propositions when sets are
   expanded. For example, with the above example (the 'env' param is skipped),
   here is the evolution of the acc_props when iterating i over [indices]:
         <- i ->       <--------------- acc_props ------------->
                       [time]
         [1,2]     ->  [time(1), time(2)]
         [a,b]     ->  [time(1,a), time(1,b), time(2,a), time(2,b)]       *)
and expand_prop_with_set' env acc_props indices =
  match indices with
  (* at this point, indices contain either Props or Sets *)
  | [] -> acc_props
  | i :: next ->
      let acc_next =
        match i with
        (* Case (b): the index [x] is a set *)
        | Set s when AstSet.is_empty s -> acc_props
        | Set s -> expand_props acc_props (Set s |> set_to_ast_list env)
        (* Case (a): the index [x] is a simple proposition *)
        | x -> expand_props acc_props [ x ]
      in
      expand_prop_with_set' env acc_next next

(* [expand_props] does the cartesian product between a set of propositions and
   a set of indices and combines each tuple into a proposition. Example:
       expand_props([a,b], [1,2])   ->   [a(1), a(2), b(1), b(2)]. *)
and expand_props props ind =
  match props with
  | [] -> []
  | x :: xs -> expand_prop x ind @ expand_props xs ind

(* [expand_prop] creates a list of same lenght as [ind] in which [prop] is
   concatenated with each value in [ind]. Example:
       expand_prop([1,2], a)   ->   [a(1), a(2)] *)
and expand_prop prop ind =
  match prop with
  | UnexpProp (name, None) ->
      List.fold_left (fun acc i -> UnexpProp (name, Some [ i ]) :: acc) [] ind
  | UnexpProp (name, Some cur) ->
      List.fold_left
        (fun acc i -> UnexpProp (name, Some (cur @ [ i ])) :: acc)
        [] ind
  | x ->
      failwith
        ("[shouldnt happen] proplist contains smth that is not UnexpProp: "
       ^ string_of_ast_type x)

(* [expand_var_name] turns a variable into a string. *)
and expand_var_name (env : env) ((prefix, indices) : string * Ast.t list option)
    =
  match (prefix, indices) with
  | x, None -> x
  | x, Some y ->
      x ^ "("
      ^ string_of_ast_list "," (List.map (fun e -> eval_ast env e) y)
      ^ ")"

(* [set_to_ast_list] evaluates one element  of the list of things after
   the 'in' of bigand/bigor.
   If this element is a set, it turns this Set (_) into a list of Int,
   Float or Prop.

   WARNING: this function reverses the order of the elements of the set;
   we could use fold_right in order to keep the original order, but
   it would mean that it is not tail recursion anymore (= uses much more heap)

   If [!check_only] is true, then the lists *)
and set_to_ast_list (env : env) (ast : Ast.t) : Ast.t list =
  let lst =
    match ast_without_layout (eval_ast env ast) with
    | Set s -> AstSet.elements s
    | ast' ->
        raise_with_loc ast
          (sprintf
             "after 'in', only sets are allowed, but got '%s':\n\
             \    %s\n\
              This element has been expanded to\n\
             \    %s\n"
             (string_of_ast_type ast') (string_of_ast ast') (string_of_ast ast'))
  in
  match (!check_only, lst) with
  (* useful when you only want to check types *)
  | false, _ -> lst
  | true, [] -> []
  | true, x :: _ -> [ x ]

(* [ast_to_bool] evaluates the 'when' condition when returns 'true' or 'false'
   depending on the result.
   This function is used in Bigand and Bigor statements. *)
and ast_to_bool env (ast : Ast.t) : bool =
  match eval_ast env ast with
  | Bool b -> b
  | ast' ->
      raise_with_loc ast
        (sprintf
           "'when' expects a 'bool' but got '%s':\n\
           \    %s\n\
            This element has been expanded to\n\
           \    %s\n"
           (string_of_ast_type ast') (string_of_ast ast') (string_of_ast ast'))

(* To_int, To_float, Var, Int... all these cannot contain ToRemove because
   ToRemove can only be generated by exact, atleast, atmost, bigand and bigor.
   I only need to match the items that can potentially be produced by the
   above mentionned. And because "produced" means that everything has already
   been evaluated, all If, Var... have already disapeared. *)
and has_top_or_bot = function
  | Top | Bottom -> true
  | Not x -> has_top_or_bot x
  | LogicBinop (x, _, y) -> has_top_or_bot x || has_top_or_bot y
  (* the following items are just here because of SMT that
     allows ==, <, >, +, -, *... in formulas. *)
  | ArithUnop (Neg, x) ->
      has_top_or_bot x (* AS: What about other unary operators? *)
  | ArithBinop (x, _, y) -> has_top_or_bot x || has_top_or_bot y
  | ArithBinrel (x, _, y) -> has_top_or_bot x || has_top_or_bot y
  | Quantifier (_, _, y) -> has_top_or_bot y
  | _ -> false

(* Simplify an AST by removing Bot and Top that can be absorbed
   by And or Or. *)
and rm_top_bot ast =
  if ast != Top && ast != Bottom && has_top_or_bot ast then
    rm_top_bot (eval_ast_formula [] ast)
  else ast
