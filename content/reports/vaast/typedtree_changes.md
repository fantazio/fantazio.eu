---
title: Typedtree changes
date: 2026-06-30
---
Command is `git diff <version1> <version2> typing/typedtree`

There is no change in bugfix versions:
```bash
$ git diff 4.14.0 4.14.3 typing/typedtree.mli
$ git diff 5.1.0 5.1.1 typing/typedtree.mli
$ git diff 5.2.0 5.2.1 typing/typedtree.mli
$ git diff 5.4.0 5.4.1 typing/typedtree.mli
```

## 4.14 to 5.0

```diff
@@ -293,7 +293,7 @@ and 'k case =
     }

 and record_label_definition =
-  | Kept of Types.type_expr
+  | Kept of Types.type_expr * mutable_flag
   | Overridden of Longident.t loc * expression

 and binding_op =
```

Adding an extra info about field mutability in record label definitions.
The type `record_label_definition` is used in the `Texp_record` variant of
type `expression_desc`. This variant describes an record expression such as
`{x = 42}` or `{r with x = 42}`. Variant `Kept` indicates that the field is
kept from the source record (All the fields in `r` but `x` in the second
pattern). Varioant `Overriden` indicates that the field is defined in the
expression (`x` in the 2 patterns).

> Note: the mutability information of a field is also available in 2 different
> places within a `Texp_record`: always in the `label_description` and in the
> `record_label_definition` if it is `Kept`. Thus, we could retrieve the
> `mutable_flag` info in 4.14 via the `label_description`.

## 5.0 to 5.1

```diff
@@ -69,6 +69,8 @@ and pat_extra =
   | Tpat_unpack
         (** (module P)     { pat_desc  = Tpat_var "P"
                            ; pat_extra = (Tpat_unpack, _, _) :: ... }
+            (module _)     { pat_desc  = Tpat_any
+            ; pat_extra = (Tpat_unpack, _, _) :: ... }
          *)

 and 'k pattern_desc =
@@ -264,7 +266,7 @@ and expression_desc =
       Ident.t option * string option loc * Types.module_presence * module_expr *
         expression
   | Texp_letexception of extension_constructor * expression
-  | Texp_assert of expression
+  | Texp_assert of expression * Location.t
   | Texp_lazy of expression
   | Texp_object of class_structure * string list
   | Texp_pack of module_expr
@@ -390,6 +392,7 @@ and module_expr_desc =
   | Tmod_structure of structure
   | Tmod_functor of functor_parameter * module_expr
   | Tmod_apply of module_expr * module_expr * module_coercion
+  | Tmod_apply_unit of module_expr
   | Tmod_constraint of
       module_expr * Types.module_type * module_type_constraint * module_coercion
     (** ME          (constraint = Tmodtype_implicit)
@@ -754,7 +757,6 @@ and 'a class_infos =
     ci_id_class: Ident.t;
     ci_id_class_type : Ident.t;
     ci_id_object : Ident.t;
-    ci_id_typehash : Ident.t;
     ci_expr: 'a;
     ci_decl: Types.class_declaration;
     ci_type_decl : Types.class_type_declaration;
@@ -824,3 +826,7 @@ val pat_bound_idents_full:
 (** Splits an or pattern into its value (left) and exception (right) parts. *)
 val split_pattern:
   computation general_pattern -> pattern option * pattern option
+
+(** Whether an expression looks nice as the subject of a sentence in a error
+    message. *)
+val exp_is_nominal : expression -> bool
```

The first bit of change is extra documentation.

The next bit adds a Location information to `Texp_assert`. This is for more
precise assert failure reports (see https://github.com/ocaml/ocaml/issues/10852).

The third bit adds a new `Tmod_apply_unit` constructor for generative functors
(see https://github.com/ocaml/ocaml/pull/11984).

The fourth bit removes `ci_id_typehash`. This is due to simplificiation, making
the information available where it is necessary rather than storing it more
globally (see https://github.com/ocaml/ocaml/pull/11569).

The last bit adds a new function `exp_is_nominal`. This is related to error
messages (see https://github.com/ocaml/ocaml/pull/11679).

## 5.1 to 5.2

```diff
@@ -22,6 +22,7 @@
 *)

 open Asttypes
+module Uid = Shape.Uid

 (* Value expressions for the core language *)

@@ -77,10 +78,10 @@ and 'k pattern_desc =
   (* value patterns *)
   | Tpat_any : value pattern_desc
         (** _ *)
-  | Tpat_var : Ident.t * string loc -> value pattern_desc
+  | Tpat_var : Ident.t * string loc * Uid.t -> value pattern_desc
         (** x *)
   | Tpat_alias :
-      value general_pattern * Ident.t * string loc -> value pattern_desc
+      value general_pattern * Ident.t * string loc * Uid.t -> value pattern_desc
         (** P as a *)
   | Tpat_constant : constant -> value pattern_desc
         (** 1, 'a', "true", 1.0, 1l, 1L, 1n *)
@@ -183,18 +184,17 @@ and expression_desc =
         (** let P1 = E1 and ... and Pn = EN in E       (flag = Nonrecursive)
             let rec P1 = E1 and ... and Pn = EN in E   (flag = Recursive)
          *)
-  | Texp_function of { arg_label : arg_label; param : Ident.t;
-      cases : value case list; partial : partial; }
-        (** [Pexp_fun] and [Pexp_function] both translate to [Texp_function].
-            See {!Parsetree} for more details.
-
-            [param] is the identifier that is to be used to name the
-            parameter of the function.
-
-            partial =
-              [Partial] if the pattern match is partial
-              [Total] otherwise.
-         *)
+  | Texp_function of function_param list * function_body
+    (** fun P0 P1 -> function p1 -> e1 | p2 -> e2  (body = Tfunction_cases _)
+        fun P0 P1 -> E                             (body = Tfunction_body _)
+
+        This construct has the same arity as the originating
+        {{!Parsetree.expression_desc.Pexp_function}[Pexp_function]}.
+        Arity determines when side-effects for effectful parameters are run
+        (e.g. optional argument defaults, matching against lazy patterns).
+        Parameters' effects are run left-to-right when an n-ary function is
+        saturated with n arguments.
+    *)
   | Texp_apply of expression * (arg_label * expression option) list
         (** E0 ~l1:E1 ... ~ln:En

@@ -294,6 +294,54 @@ and 'k case =
      c_rhs: expression;
     }

+and function_param =
+  {
+    fp_arg_label: arg_label;
+    fp_param: Ident.t;
+    (** [fp_param] is the identifier that is to be used to name the
+        parameter of the function.
+    *)
+    fp_partial: partial;
+    (**
+       [fp_partial] =
+       [Partial] if the pattern match is partial
+       [Total] otherwise.
+    *)
+    fp_kind: function_param_kind;
+    fp_newtypes: string loc list;
+      (** [fp_newtypes] are the new type declarations that come *after* that
+          parameter. The newtypes that come before the first parameter are
+          placed as exp_extras on the Texp_function node. This is just used in
+          {!Untypeast}. *)
+    fp_loc: Location.t;
+      (** [fp_loc] is the location of the entire value parameter, not including
+          the [fp_newtypes].
+      *)
+  }
+
+and function_param_kind =
+  | Tparam_pat of pattern
+  (** [Tparam_pat p] is a non-optional argument with pattern [p]. *)
+  | Tparam_optional_default of pattern * expression
+  (** [Tparam_optional_default (p, e)] is an optional argument [p] with default
+      value [e], i.e. [?x:(p = e)]. If the parameter is of type [a option], the
+      pattern and expression are of type [a]. *)
+
+and function_body =
+  | Tfunction_body of expression
+  | Tfunction_cases of
+      { cases: value case list;
+        partial: partial;
+        param: Ident.t;
+        loc: Location.t;
+        exp_extra: exp_extra option;
+        attributes: attributes;
+        (** [attributes] is just used in untypeast. *)
+      }
+(** The function body binds a final argument in [Tfunction_cases],
+    and this argument is pattern-matched against the cases.
+*)
+
 and record_label_definition =
   | Kept of Types.type_expr * mutable_flag
   | Overridden of Longident.t loc * expression
@@ -430,8 +478,9 @@ and structure_item_desc =

 and module_binding =
     {
-     mb_id: Ident.t option;
+     mb_id: Ident.t option; (** [None] for [module _ = struct ... end] *)
      mb_name: string option loc;
+     mb_uid: Uid.t;
      mb_presence: Types.module_presence;
      mb_expr: module_expr;
      mb_attributes: attributes;
@@ -442,6 +491,7 @@ and value_binding =
   {
     vb_pat: pattern;
     vb_expr: expression;
+    vb_rec_kind: Value_rec_types.recursive_binding_kind;
     vb_attributes: attributes;
     vb_loc: Location.t;
   }
@@ -452,7 +502,19 @@ and module_coercion =
                          (Ident.t * int * module_coercion) list
   | Tcoerce_functor of module_coercion * module_coercion
   | Tcoerce_primitive of primitive_coercion
+  (** External declaration coerced to a regular value.
+      {[
+        module M : sig val ext : a -> b end =
+        struct external ext : a -> b = "my_c_function" end
+      ]}
+      Only occurs inside a [Tcoerce_structure] coercion. *)
   | Tcoerce_alias of Env.t * Path.t * module_coercion
+  (** Module alias coerced to a regular module.
+      {[
+        module M : sig module Sub : T end =
+        struct module Sub = Some_alias end
+      ]}
+      Only occurs inside a [Tcoerce_structure] coercion. *)

 and module_type =
   { mty_desc: module_type_desc;
@@ -510,6 +572,7 @@ and module_declaration =
     {
      md_id: Ident.t option;
      md_name: string option loc;
+     md_uid: Uid.t;
      md_presence: Types.module_presence;
      md_type: module_type;
      md_attributes: attributes;
@@ -520,6 +583,7 @@ and module_substitution =
     {
      ms_id: Ident.t;
      ms_name: string loc;
+     ms_uid: Uid.t;
      ms_manifest: Path.t;
      ms_txt: Longident.t loc;
      ms_attributes: attributes;
@@ -530,6 +594,7 @@ and module_type_declaration =
     {
      mtd_id: Ident.t;
      mtd_name: string loc;
+     mtd_uid: Uid.t;
      mtd_type: module_type option;
      mtd_attributes: attributes;
      mtd_loc: Location.t;
@@ -588,10 +653,11 @@ and core_type_desc =
   | Ttyp_constr of Path.t * Longident.t loc * core_type list
   | Ttyp_object of object_field list * closed_flag
   | Ttyp_class of Path.t * Longident.t loc * core_type list
-  | Ttyp_alias of core_type * string
+  | Ttyp_alias of core_type * string loc
   | Ttyp_variant of row_field list * closed_flag * label list option
   | Ttyp_poly of string list * core_type
   | Ttyp_package of package_type
+  | Ttyp_open of Path.t * Longident.t loc * core_type

 and package_type = {
   pack_path : Path.t;
@@ -654,6 +720,7 @@ and label_declaration =
     {
      ld_id: Ident.t;
      ld_name: string loc;
+     ld_uid: Uid.t;
      ld_mutable: mutable_flag;
      ld_type: core_type;
      ld_loc: Location.t;
@@ -664,6 +731,7 @@ and constructor_declaration =
     {
      cd_id: Ident.t;
      cd_name: string loc;
+     cd_uid: Uid.t;
      cd_vars: string loc list;
      cd_args: constructor_arguments;
      cd_res: core_type option;
@@ -780,6 +848,23 @@ type implementation = {
     structure.
 *)

+type item_declaration =
+  | Value of value_description
+  | Value_binding of value_binding
+  | Type of type_declaration
+  | Constructor of constructor_declaration
+  | Extension_constructor of extension_constructor
+  | Label of label_declaration
+  | Module of module_declaration
+  | Module_substitution of module_substitution
+  | Module_binding of module_binding
+  | Module_type of module_type_declaration
+  | Class of class_declaration
+  | Class_type of class_type_declaration
+(** [item_declaration] groups together items that correspond to the syntactic
+    category of "declarations" which include types, values, modules, etc.
+    declarations in signatures and their definitions in implementations. *)
+
 (* Auxiliary functions over the a.s.t. *)

 (** [as_computation_pattern p] is a computation pattern with description
@@ -810,7 +895,8 @@ val exists_pattern: (pattern -> bool) -> pattern -> bool

 val let_bound_idents: value_binding list -> Ident.t list
 val let_bound_idents_full:
-    value_binding list -> (Ident.t * string loc * Types.type_expr) list
+    value_binding list ->
+    (Ident.t * string loc * Types.type_expr * Types.Uid.t) list

 (** Alpha conversion of patterns *)
 val alpha_pat:
@@ -821,7 +907,8 @@ val mkloc: 'a -> Location.t -> 'a Asttypes.loc

 val pat_bound_idents: 'k general_pattern -> Ident.t list
 val pat_bound_idents_full:
-  'k general_pattern -> (Ident.t * string loc * Types.type_expr) list
+  'k general_pattern ->
+  (Ident.t * string loc * Types.type_expr * Types.Uid.t) list

 (** Splits an or pattern into its value (left) and exception (right) parts. *)
 val split_pattern:
```

Now it's getting hairy.

Many changes are related to the used of `Uid`. As explained
[here](https://github.com/ocaml/ocaml/pull/11782):
> A `Uid.t` is a unqiue identifier of a binding in the source code of the program.

A `Uid.t` element is added to the constructors `Tpat_var`, and `Tpat_alias`,
to records `module_binding`, `module_declaration`, `module_substitution`,
`module_type_declaration`, `label_declaration`, and `constructor_declaration`,
and to the returned values of `let_bound_idents_full`, and
`pat_bound_idents_full`.
(see https://github.com/ocaml/ocaml/pull/12508).

The addition of the type `item_declaration` is related to the same project-wide
occurences support as the use `Uid`
(see https://github.com/ocaml/ocaml/pull/12508).

Another big change is of the `Texp_function` constructor. It comes with
the definitiion of types `function_param`, `function_param_kind`, and
`function_body`. This completely redefines how function expressions are
represented. Previously, a function `fun x y z -> body` would be split per
argument, with a representation similar to
`function x -> function y -> function z -> body`, with `body` being any
expression.
Now, its representation is more compact (and its semantics closer to the
expected behavior): `fun [x;  y; z] -> body`, with `body` a `function_body`.
(see https://github.com/ocaml/ocaml/pull/12236).

There are a few documentation-related changes.

A new fields `vb_rec_kind` is added to `value_binding`. This is related to
recursive values (see https://github.com/ocaml/ocaml/pull/12551).

The constructor `Ttyp_alias` is updated to store the location of type aliases
(see https://github.com/ocaml/ocaml/pull/12639). It does not add any element
to the constructor but updates the type of the second field of the tuple.

A new `Ttyp_open` constructor is added for local opens in types
(see https://github.com/ocaml/ocaml/pull/12044).

## 5.2 to 5.3

```diff
@@ -211,17 +211,22 @@ and expression_desc =
                          (Labelled "y", Some (Texp_constant Const_int 3))
                         ])
          *)
-  | Texp_match of expression * computation case list * partial
+  | Texp_match of expression * computation case list * value case list * partial
         (** match E0 with
             | P1 -> E1
             | P2 | exception P3 -> E2
             | exception P4 -> E3
+            | effect P4 k -> E4

             [Texp_match (E0, [(P1, E1); (P2 | exception P3, E2);
-                              (exception P4, E3)], _)]
+                              (exception P4, E3)], [(P4, E4)],  _)]
          *)
-  | Texp_try of expression * value case list
-        (** try E with P1 -> E1 | ... | PN -> EN *)
+  | Texp_try of expression * value case list * value case list
+         (** try E with
+            | P1 -> E1
+            | effect P2 k -> E2
+            [Texp_try (E, [(P1, E1)], [(P2, E2)])]
+          *)
   | Texp_tuple of expression list
         (** (E1, ..., EN) *)
   | Texp_construct of
@@ -290,6 +295,7 @@ and meth =
 and 'k case =
     {
      c_lhs: 'k general_pattern;
+     c_cont: Ident.t option;
      c_guard: expression option;
      c_rhs: expression;
     }
@@ -913,7 +919,3 @@ val pat_bound_idents_full:
 (** Splits an or pattern into its value (left) and exception (right) parts. *)
 val split_pattern:
   computation general_pattern -> pattern option * pattern option
-
-(** Whether an expression looks nice as the subject of a sentence in a error
-    message. *)
-val exp_is_nominal : expression -> bool
```

The updates of `Texp_match` and `Texp_try` are related to a new syntax to match
on effects (see https://github.com/ocaml/ocaml/pull/12309).
As we can see, the change adds another list in the constructors' tuples,
specifically to hold the effects branches.

The new `c_cont` field in type `'k case` is also related to the new handler syntax.
It holds the name of the continuation in the pattern.

The `exp_is_nominal` function, that was added in 5.1 is now removed. It is
actually replaced by `Doc.nominal_exp` in `parsing/pprintast.mli`

## 5.3 to 5.4

```diff
@@ -81,17 +81,21 @@ and 'k pattern_desc =
   | Tpat_var : Ident.t * string loc * Uid.t -> value pattern_desc
         (** x *)
   | Tpat_alias :
-      value general_pattern * Ident.t * string loc * Uid.t -> value pattern_desc
+      value general_pattern * Ident.t * string loc * Uid.t * Types.type_expr ->
+      value pattern_desc
         (** P as a *)
   | Tpat_constant : constant -> value pattern_desc
         (** 1, 'a', "true", 1.0, 1l, 1L, 1n *)
-  | Tpat_tuple : value general_pattern list -> value pattern_desc
-        (** (P1, ..., Pn)
+  | Tpat_tuple :
+      (string option * value general_pattern) list -> value pattern_desc
+        (** (P1, ..., Pn)                  [(None,P1); ...; (None,Pn)])
+            (L1:P1, ... Ln:Pn)             [(Some L1,P1); ...; (Some Ln,Pn)])
+            Any mix, e.g. (L1:P1, P2)      [(Some L1,P1); ...; (None,P2)])

             Invariant: n >= 2
          *)
   | Tpat_construct :
-      Longident.t loc * Types.constructor_description *
+      Longident.t loc * Data_types.constructor_description *
         value general_pattern list * (Ident.t loc list * core_type) option ->
       value pattern_desc
         (** C                             ([], None)
@@ -111,15 +115,18 @@ and 'k pattern_desc =
             See {!Types.row_desc} for an explanation of the last parameter.
          *)
   | Tpat_record :
-      (Longident.t loc * Types.label_description * value general_pattern) list *
-        closed_flag ->
-      value pattern_desc
+      (Longident.t loc
+       * Data_types.label_description
+       * value general_pattern
+      ) list
+      * closed_flag
+      -> value pattern_desc
         (** { l1=P1; ...; ln=Pn }     (flag = Closed)
             { l1=P1; ...; ln=Pn; _}   (flag = Open)

             Invariant: n > 0
          *)
-  | Tpat_array : value general_pattern list -> value pattern_desc
+  | Tpat_array : mutable_flag * value general_pattern list -> value pattern_desc
         (** [| P1; ...; Pn |] *)
   | Tpat_lazy : value general_pattern -> value pattern_desc
         (** lazy P *)
@@ -195,10 +202,10 @@ and expression_desc =
         Parameters' effects are run left-to-right when an n-ary function is
         saturated with n arguments.
     *)
-  | Texp_apply of expression * (arg_label * expression option) list
+  | Texp_apply of expression * (arg_label * apply_arg) list
         (** E0 ~l1:E1 ... ~ln:En

-            The expression can be None if the expression is abstracted over
+            The expression can be Omitted if the expression is abstracted over
             this argument. It currently appears when a label is applied.

             For example:
@@ -207,8 +214,8 @@ and expression_desc =

             The resulting typedtree for the application is:
             Texp_apply (Texp_ident "f/1037",
-                        [(Nolabel, None);
-                         (Labelled "y", Some (Texp_constant Const_int 3))
+                        [(Nolabel, Omitted ());
+                         (Labelled "y", Arg (Texp_constant Const_int 3))
                         ])
          *)
   | Texp_match of expression * computation case list * value case list * partial
@@ -227,17 +234,24 @@ and expression_desc =
             | effect P2 k -> E2
             [Texp_try (E, [(P1, E1)], [(P2, E2)])]
           *)
-  | Texp_tuple of expression list
-        (** (E1, ..., EN) *)
+  | Texp_tuple of (string option * expression) list
+        (** [Texp_tuple(el)] represents
+            - [(E1, ..., En)]
+                 when [el] is [(None, E1);...;(None, En)],
+            - [(L1:E1, ..., Ln:En)]
+                 when [el] is [(Some L1, E1);...;(Some Ln, En)],
+            - Any mix, e.g. [(L1: E1, E2)]
+                 when [el] is [(Some L1, E1); (None, E2)]
+          *)
   | Texp_construct of
-      Longident.t loc * Types.constructor_description * expression list
+      Longident.t loc * Data_types.constructor_description * expression list
         (** C                []
             C E              [E]
             C (E1, ..., En)  [E1;...;En]
          *)
   | Texp_variant of label * expression option
   | Texp_record of {
-      fields : ( Types.label_description * record_label_definition ) array;
+      fields : ( Data_types.label_description * record_label_definition ) array;
       representation : Types.record_representation;
       extended_expression : expression option;
     }
@@ -252,10 +266,13 @@ and expression_desc =
               { fields = [| l1, Kept t1; l2 Override P2 |]; representation;
                 extended_expression = Some E0 }
         *)
-  | Texp_field of expression * Longident.t loc * Types.label_description
+  | Texp_atomic_loc of
+      expression * Longident.t loc * Data_types.label_description
+  | Texp_field of
+      expression * Longident.t loc * Data_types.label_description
   | Texp_setfield of
-      expression * Longident.t loc * Types.label_description * expression
-  | Texp_array of expression list
+      expression * Longident.t loc * Data_types.label_description * expression
+  | Texp_array of mutable_flag * expression list
   | Texp_ifthenelse of expression * expression * expression option
   | Texp_sequence of expression * expression
   | Texp_while of expression * expression
@@ -364,6 +381,12 @@ and binding_op =
     bop_loc : Location.t;
   }

+and ('a, 'b) arg_or_omitted =
+  | Arg of 'a
+  | Omitted of 'b
+
+and apply_arg = (expression, unit) arg_or_omitted
+
 (* Value expressions for the class language *)

 and class_expr =
@@ -381,7 +404,7 @@ and class_expr_desc =
   | Tcl_fun of
       arg_label * pattern * (Ident.t * expression) list
       * class_expr * partial
-  | Tcl_apply of class_expr * (arg_label * expression option) list
+  | Tcl_apply of class_expr * (arg_label * apply_arg) list
   | Tcl_let of rec_flag * value_binding list *
                   (Ident.t * expression) list * class_expr
   | Tcl_constraint of
@@ -655,7 +678,7 @@ and core_type_desc =
     Ttyp_any
   | Ttyp_var of string
   | Ttyp_arrow of arg_label * core_type * core_type
-  | Ttyp_tuple of core_type list
+  | Ttyp_tuple of (string option * core_type) list
   | Ttyp_constr of Path.t * Longident.t loc * core_type list
   | Ttyp_object of object_field list * closed_flag
   | Ttyp_class of Path.t * Longident.t loc * core_type list
@@ -666,10 +689,10 @@ and core_type_desc =
   | Ttyp_open of Path.t * Longident.t loc * core_type

 and package_type = {
-  pack_path : Path.t;
-  pack_fields : (Longident.t loc * core_type) list;
-  pack_type : Types.module_type;
-  pack_txt : Longident.t loc;
+  tpt_path : Path.t;
+  tpt_cstrs : (Longident.t loc * core_type) list;
+  tpt_type : Types.module_type;
+  tpt_txt : Longident.t loc;
 }
 and row_field = {
@@ -728,6 +751,7 @@ and label_declaration =
      ld_name: string loc;
      ld_uid: Uid.t;
      ld_mutable: mutable_flag;
+     ld_atomic: atomic_flag;
      ld_type: core_type;
      ld_loc: Location.t;
      ld_attributes: attributes;
@@ -919,3 +943,6 @@ val pat_bound_idents_full:
 (** Splits an or pattern into its value (left) and exception (right) parts. *)
 val split_pattern:
   computation general_pattern -> pattern option * pattern option
+
+val map_apply_arg:
+  ('a -> ' b) -> ('a, 'omitted) arg_or_omitted ->  ('b, 'omitted) arg_or_omitted
```

This is a failry big diff.

First, the change in `Tpat_alias` is related to a bug fix and adds a
type-related component to the constructor's tuple
(se https://github.com/ocaml/ocaml/pull/13763).

The change in `Tpat_tuple` is related to the new labeled tuples feature.
This changes the type of the elements in the list held by the constructor.
A tuple component is now represented by an optional string (the label) and
its pattern.
The same change is applied to `Texp_tuple`, with expressions instead of
patterns, and `Ttyp_tuple`, with types instead of patterns.
(see https://github.com/ocaml/ocaml/pull/13498).

The changes in `Tpat_construct`, `Tpat_record`, `Texp_construct`, `Texp_record`,
`Texp_field`, and `Texp_setfield` are related to a refactor which moved some of
their components types (`constructor_description`, and `label_description`) from
`Types` (`typing/types.mli`) to `Data_types` (`typing/data_types.mli`).
(see https://github.com/ocaml/ocaml/pull/13466).

The change in `Tpat_array` and `Texp_array` is related to the introduction of
immutable arrays in the language.
It simply adds `mutable_flag` as first component of the construcotrs' tuples.
(see https://github.com/ocaml/ocaml/pull/13097).

The change in `Texp_apply`, `Tcl_apply`, and the introduction of types
`('a, 'b) arg_or_omitted` and `apply_arg` are related to a refactor in how
optional arguments are represented and typed.
Instead of using an optional expression for the value of an optional argument,
it is now represented via an `apply_arg = (expression, unit) arg_or_ommited`.
This does not make any real semantic difference in the Typedtree but does in
previous steps of the compiler.
The new function `map_apply_arg` is related to that change.
(see https://github.com/ocaml/ocaml/pull/13612).

The new constructor `Texp_atomic_loc`, and field `ld_atomic` in type
`label_declaration` are related to the introduction of atomic locations
(see https://github.com/ocaml/ocaml/pull/13404).

Finally the changes of field names in `package_type` is for disambiguation
with the new type `Types.package`.
(see https://github.com/ocaml/ocaml/pull/13856).

## 5.4 to 5.5

OCaml 5.5 is not officially released yet. The diff is made with its current
release candidate: 5.50-rc1.

```diff
@@ -67,9 +67,9 @@ and pat_extra =
                            branches of [tconst].
          *)
   | Tpat_open of Path.t * Longident.t loc * Env.t
-  | Tpat_unpack
-        (** (module P)     { pat_desc  = Tpat_var "P"
-                           ; pat_extra = (Tpat_unpack, _, _) :: ... }
+  | Tpat_unpack of package_type option
+        (** (module P : ?S)     { pat_desc  = Tpat_var "P"
+                           ; pat_extra = (Tpat_unpack ?S, _, _) :: ... }
             (module _)     { pat_desc  = Tpat_any
             ; pat_extra = (Tpat_unpack, _, _) :: ... }
          *)
@@ -284,10 +284,6 @@ and expression_desc =
   | Texp_instvar of Path.t * Path.t * string loc
   | Texp_setinstvar of Path.t * Path.t * string loc * expression
   | Texp_override of Path.t * (Ident.t * string loc * expression) list
-  | Texp_letmodule of
-      Ident.t option * string option loc * Types.module_presence * module_expr *
-        expression
-  | Texp_letexception of extension_constructor * expression
   | Texp_assert of expression * Location.t
   | Texp_lazy of expression
   | Texp_object of class_structure * string list
@@ -301,8 +297,7 @@ and expression_desc =
     }
   | Texp_unreachable
   | Texp_extension_constructor of Longident.t loc * Path.t
-  | Texp_open of open_declaration * expression
-        (** let open[!] M in e *)
+  | Texp_struct_item of structure_item * expression
 
 and meth =
     Tmeth_name of string
@@ -687,11 +682,12 @@ and core_type_desc =
   | Ttyp_poly of string list * core_type
   | Ttyp_package of package_type
   | Ttyp_open of Path.t * Longident.t loc * core_type
+  | Ttyp_functor of arg_label * Ident.t loc * package_type * core_type
 
 and package_type = {
   tpt_path : Path.t;
-  tpt_cstrs : (Longident.t loc * core_type) list;
-  tpt_type : Types.module_type;
+  tpt_constraints : (Longident.t loc * core_type) list;
+  tpt_type : Types.package;
   tpt_txt : Longident.t loc;
 }
 
@@ -731,7 +727,7 @@ and type_declaration =
     typ_name: string loc;
     typ_params: (core_type * (variance * injectivity)) list;
     typ_type: Types.type_declaration;
-    typ_cstrs: (core_type * core_type * Location.t) list;
+    typ_constraints: (core_type * core_type * Location.t) list;
     typ_kind: type_kind;
     typ_private: private_flag;
     typ_manifest: core_type option;
@@ -744,6 +740,7 @@ and type_kind =
   | Ttype_variant of constructor_declaration list
   | Ttype_record of label_declaration list
   | Ttype_open
+  | Ttype_external of string
 
 and label_declaration =
     {
@@ -946,3 +943,7 @@ val split_pattern:
 
 val map_apply_arg:
   ('a -> ' b) -> ('a, 'omitted) arg_or_omitted ->  ('b, 'omitted) arg_or_omitted
+
+val path_of_module : module_expr -> Path.t option
+
+val remove_module_constraint : module_expr -> module_expr
```

The update on `Tpat_unpack` is related to the introduction of modular explicits.
(see https://github.com/ocaml/ocaml/pull/14149).

Constructors `Texp_letmodule`, `Texp_letexception`, and `Texp_open` are
replaced by the single construct `Texp_struct_item`.
This is a refactoring that enables sharing more code between this constructs.
(see https://github.com/ocaml/ocaml/pull/13839).

The new constructor `Ttyp_functor`, and functions `path_of_module`,
and `remove_module_constraint` are added for modular explicits.
Function `path_of_module` was actually moved from `typing/typemod.mli`.
(see https://github.com/ocaml/ocaml/pull/13275).

The field `tpt_cstrs` is replaced with `tpt_constraints` in type `package_type`.
This is due to a refactor to disambiguate constraints and constructors.
The same refactor changes `typ_cstrs` in `typ_constraints` in type
`type_declaration`.
(see https://github.com/ocaml/ocaml/pull/14141).

The field `tpt_type` in `package_type` was updated in 2 times:
1st removed as part of a cleanup (see https://github.com/ocaml/ocaml/pull/14148),
then reinstated with modular explicits
(see https://github.com/ocaml/ocaml/pull/14149).

The new `Ttype_external` constructor is related to external types.
They introduce the possibility to uniquely identify an abstract type, and, thus,
enable the type checker to distinguish it from (or equate it to) another.
(see https://github.com/ocaml/ocaml/pull/13712).
