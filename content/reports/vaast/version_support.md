---
title: Version support
date: 2026-06-30
---
Explore projects' codebase and history to see how they use the typedtree and its changes

## Asak

[asak](https://github.com/nobrakal/asak) is described as
> Asak provides functions to parse, type-check and identify similar OCaml codes.
> These functions are then used to partition codes implementing the same function and help to detect code duplication.

It mostly uses the Lambda representation of the OCaml but still uses Typedtree
(and Parsetree). It supports OCaml versions from 4.10 to 5.2 included.

It uses the Typedtree through field accesses (e.g. `structure.str_items`,
`structure_item.str_desc`, `value_binding.vb_pat.pat_loc`), and pattern matching
constructors (e.g. `Tpat_var(id, _, _)`, `Tstr_value (_, xs)`,
`Tmod_structure structure`). It also uses some of the types in signatures
(e.g. `Typedtree.structure`, and `Typedtree.value_binding`).
I did not see any function use but may have missed them. A `Tast_mapper` is used
at some point, but does not care about the Typedtree constructs, only the env.

In order to adapt to changes in the Typedtree (and other components of
compiler-libs) and support multiple versions, the project relies on
[cppo](https://github.com/ocaml-community/cppo). It has the following instruction
in its dune files to setup an `OCAML_VERSION` cppo variable and preprocess the
code:
```dune
(preprocess (action (run %{bin:cppo} -V OCAML:%{ocaml_version} %{input-file})))
```
The `OCAML_VERSION` variable is then used to select some code depending on the
compiler's version, like in the following examples (found in
`src/parse_structure.ml`):
```OCaml
let get_name_of_pat pat =
  match pat.pat_desc with
#if OCAML_VERSION >= (5, 2, 0)
  | Tpat_var(id, _, _) -> Some id
  | Tpat_alias(_, id, _, _) -> Some id
#else
  | Tpat_var(id, _) -> Some id
  | Tpat_alias(_, id, _) -> Some id
#endif
  | _ -> None
```
```OCaml
let rec read_module_expr ~prefix m =
  match m.mod_desc with
  | Tmod_structure structure -> read_structure_with_loc ~prefix structure
#if OCAML_VERSION >= (4, 10, 0)
  | Tmod_functor (_,m) ->
#else
  | Tmod_functor (_,_,_,m) ->
#endif
      read_module_expr ~prefix m
  | _ -> []
```
```OCaml
    let mid =
#if OCAML_VERSION >= (4, 10, 0)
      Option.value ~default:"" (Option.map Ident.name m.mb_id)
#else
      Ident.name m.mb_id
#endif
    in
```

## Dead_code_analyzer

The [dead_code_analyzer](https://github.com/LexiFi/dead_code_analyzer) is
described as
> Dead-code analyzer for OCaml

It mostly depends on the Typedtree representation of OCaml. The latest version
only supports 5.3.

It uses the Typedtree through field accesses (e.g. `module_expr.mod_desc`,
`expression.exp_desc`, `'a pattern_data.pat_loc.Location.loc_start`), pattern
matching records (e.g. `{vb_pat = {pat_desc = Tpat_var (_, {loc = {Location.loc_start = loc; loc_ghost = false; _}; _}, _); _}; vb_expr = exp; _}`),
and pattern matching constructors (e.g.
`Texp_apply ({exp_desc = Texp_ident (_, _, val_desc); _}, _)`, `Tstr_include i`,
`Tpat_construct _`). It also uses some of the types in signatures
(e.g. `Typedtree.type_declaration`, `Typedtree.item_declaration`,
`Typedtree.structure`). It does not use functions.
A `Tast_mapper` is used intensively to traverse the Typedtree and analyze
selected components.

In order to adapt to changes in the Typedtree (and other components of
compiler-libs), the project updates the necessary parts, breaking compatibility
with previous versions of OCaml.

## Labltk

[labltk](https://github.com/garrigue/labltk) is described as
> LablTk is an interface to the Tcl/Tk GUI framework. It allows to develop GUI applications in a speedy and type safe way. A legacy Camltk interface is included. The OCamlBrowser library viewer is also part of this project.

It uses the Typedtree exclusively in OCamlBrowser. The project supports OCaml
versions from 4.08, but the OCamlBrowser requires 5.4.

It uses the Typedtree through field accesses (e.g. `'a pattern_data.patloc`,
`function_param.fp_kind`, `module_binding.mb_name.txt`), pattern matching
records (e.g. `{c_lhs; c_guard; c_rhs}`, `{vb_pat=pat;vb_expr=exp}`), and
pattern matching (e.g. `Tpat_var (id, _, _)`,
`Texp_record {fields=l; extended_expression=opt}`, `Tstr_module mb`).
It also uses some types in signatures (e.g. `Typedtree.structure_item`).
I did not see any function use but may have missed them. 2 `Tast_iterator` are
used to store type information found in Typedtrees.

In order to adapt to changes in the Typedtree (and other components of
compiler-libs), the OCamlBrowser updates the necessary parts, breaking
compatibility with previous versions of OCaml.

## Learn OCaml

[learn-ocaml](https://github.com/ocaml-sf/learn-ocaml) is described as
> This is Learn-OCaml, a platform for learning the OCaml language, featuring a Web toplevel, an exercise environment, and a directory of lessons and tutorials.

It uses the Typedtree only a few times and only to access `core_type`
information. It supports OCaml 5.1.

It uses the Typedtree through field access (e.g. `core_type.ctyp_type`,
`core_type.ctyp_desc`), pattern matching records (e.g.
`{ Typedtree.ctyp_type = ty; _ }`, and pattern matching constructors
(e.g. `Ttyp_package { pack_type; _ }`).

The project did not need to adapt to changes in the Typedtree for 10y (the
first commit available on gtihub).
In order to adapt to changes in other components of compiler-libs, the project
updates the necessary parts, breaking compatibility with previous versions of
OCaml.

## Merlin

[merlin](https://github.com/ocaml/merlin) is described as
> Merlin is an assistant for editing OCaml code. It aims to provide the features
> available in modern IDEs: error reporting, auto completion, source browsing and
> much more. It can be used as a standalone server or through an LSP server.

> Warning
> This project vendors the OCaml typer, including the Typedtree, with patches.
> Inspiration can be taken from it for Vaast but it is probably not in the user
> target for now.

The project states its version support technique in its
[README](https://github.com/ocaml/merlin/blob/main/README.md):
> Since version 4.0, Merlin's repository has a dedicated branch for each version of OCaml, and the branch name consists of the concatenation of OCaml major versions and minor versions. So, for instance, OCaml 4.11.* maps to branch 411. The main branch is usually synchronised with the branch compatible with the latest (almost-)released version of OCaml.

The process seems to be cumbersome ([wip wiki](https://github.com/ocaml/merlin/wiki/%5Bwip%5D-Upgrade-to-a-new-verison).
For each new version of the compiler,
they need to:
1. create a branch for the last supported version;
2. vendor the new version of the OCaml typer (without patches) in `upstream`;
2. update the vendored OCaml typer with patches to the new version in `src/ocaml`;
4. update all the impacted code.

I do not know why they need to keep each unpatched OCaml typer version in
`upstream`. As far as I can tell, there is a script
([`upstream/gen_patch.sh`](https://github.com/ocaml/merlin/blob/main/upstream/gen_patch.sh))
used to apply the upstream updates to the the patched version of the OCaml typer.
Once the update is applied, the previously supported upstream version is not
used and could be discarded.

> Note
> Maybe making Vaast "extensible" will help merlin in the future.

## Ocp-index

[ocp-index](https://github.com/OCamlPro/ocp-index) is described as
> ocp-index is a light-weight tool and library providing easy access to the information contained in your OCaml cmi/cmt/cmti files. It can be used to provide features like library interface browsing, auto-completion, show-type and goto-source.

It uses on the Typedtree representation of OCaml to retrieve include-related
information. The latest version supports version from 4.08 (incoming 5.5 included).

It uses the Typedtree through field accesses (e.g. `module_expr.mod_desc`,
`signature.sig_items`, `module_type.mty_desc`), pattern matching on records
(e.g. `{ Typedtree.mb_id; mb_expr = { Typedtree.mod_desc }`,
`{ Typedtree.md_id; md_type = { Typedtree.mty_desc }`), and pattern matching on
constructors (e.g. `Typedtree.Tmty_ident (incpath,_)`,
`Typedtree.Tmod_ident (incpath,{ Location.txt = _lid})`,
`Typedtree.Tstr_recmodule l`).
It did not find any function use of type used in signature.

In order to adapt to changes in the Typedtree (and other components of
compiler-libs), the OCamlBrowser updates the necessary parts, breaking
compatibility with previous versions of OCaml.

In order to adapt to changes in the Typedtree (and other components of
compiler-libs) and support multiple versions, the project relies on
[cppo](https://github.com/ocaml-community/cppo). It has the following instruction
in its dune files to setup an `OCAML_VERSION` cppo variable and preprocess the
code:
```dune
(preprocess
  (action
   (run %{bin:cppo} -V OCAML:%{ocaml_version} %{input-file})))
```
The `OCAML_VERSION` variable is then used to select some code depending on the
compiler's version, like in the following examples (found in
`libs/indexBuild.ml`):
```OCaml
#if OCAML_VERSION >= (4,10,0)
  | Typedtree.Tmod_apply ({ mod_desc = Typedtree.Tmod_functor(Typedtree.Named (Some id, _, _),f) },
#else
  | Typedtree.Tmod_apply ({ mod_desc = Typedtree.Tmod_functor(id,_,_,f) },
#endif
                          { mod_desc = Typedtree.Tmod_ident (arg,_)
                                     | Typedtree.Tmod_constraint ({mod_desc = Typedtree.Tmod_ident (arg,_)},_,_,_)  },_) ->
```
```OCaml
#if OCAML_VERSION >= (4,10,0)
  | Typedtree.Tmty_functor (_,e)
#else
  | Typedtree.Tmty_functor (_,_,_,e)
#endif
  | Typedtree.Tmty_with (e,_) ->
```

All the version-dependent typedtree code seems to be against 4.10.

## Odoc

[odoc](https://github.com/ocaml/odoc) is described as
> `odoc` is a powerful and flexible documentation generator for OCaml. It reads _doc comments_, demarcated by `(** ... *)`, and transforms them into a variety of output formats, including HTML, LaTeX, and man pages.

It supports OCaml versions from 4.08 to 5.6 (excluded).

It uses the Typedtree through field accesses, pattern matching on records,
and pattern matching on constructors. It also uses functions (e.g. `path_of_module`) and types in signatures.
Two `Tast_iterator`s are used to act on nodes of interest in the Typedtree.

In order to adapt to changes in the Typedtree (and other components of
compiler-libs) and support multiple versions, the project relies on
[cppo](https://github.com/ocaml-community/cppo). It also supports OxCaml.
It has the following instructions in its dune files to setup an `OCAML_VERSION`
and an `OXCAML` cppo variables and preprocess the code (the OXCAML part may be
ommitted):
```dune
(preprocess
  (action
   (run %{bin:cppo} -V OCAML:%{ocaml_version} -D "OXCAML" %{input-file})))
```
```dune
(action
  (chdir
   %{workspace_root}
   (run %{bin:cppo} -V OCAML:%{ocaml_version} -D OXCAML %{x} -o %{targets})))
```
The variables are then used to select some code depending on the compiler's
version, like in the following examples:
```OCaml
#if defined OXCAML
        | Ttype_record_unboxed_product _ -> []
#endif
        | Ttype_open -> []
#if OCAML_VERSION >= (5,5,0)
        | Ttype_external _ -> []
#endif
```
```OCaml
#if defined OXCAML
          | Tpat_alias (_, id, loc, _uid, _, _, _) -> (
#elif OCAML_VERSION >= (5, 4, 0)
          | Tpat_alias (_, id, loc, _uid, _ty) -> (
#elif OCAML_VERSION >= (5, 2, 0)
          | Tpat_alias (_, id, loc, _uid) -> (
#else
          | Tpat_alias (_, id, loc) -> (
#endif
```
```OCaml
#if OCAML_VERSION >= (5,5,0)
            match Typedtree.path_of_module incl_mod with
#else
            match Typemod.path_of_module incl_mod with
#endif
```

There are also multiple "global" guards around file content like in
`src/loader/typedtree_traverse.ml`, whose content only exist in OCaml >= 4.14.

## Reanalyze

[reanalyze](https://github.com/rescript-lang/reanalyze) is described as
> rogram analysis for ReScript and OCaml projects targeting JS (ReScript) as well as native code (dune):
> - Globally dead values, redundant optional arguments, dead modules, dead types (records and variants).
> - Exception analysis.
> - Termination.

Despite the following warning, there was recent activity to this project, s
 we can consider it active.
> This repository is only for keeping OCaml compatibility with an old version of reanalyze. It is further developed in the rescript monorepo.

It supports OCaml versions 4.08 (included) to 5.3 (excluded).

It was inspired by the `dead_code_analyzer` and uses the Typedtree the same way.
It uses mutliple `Tast_mapper`s to traverse the Typedtree.

In order to adapt to changes in the Typedtree (and other components of
compiler-libs) and support multiple versions, the project relies on
[cppo](https://github.com/ocaml-community/cppo). It has the following instruction
in its dune files to setup an `OCAML_VERSION` cppo variable and preprocess the
code:
```dune
(preprocess
  (action
   (run %{bin:cppo} -V OCAML:%{ocaml_version} %{input-file})))
```
The `OCAML_VERSION` variable is then used to select some code depending on the
compiler's version, like in the following examples:
```OCaml
#if OCAML_VERSION < (5, 2, 0)
    | Tpat_var (id, {loc = {loc_ghost}})
    #else
    | Tpat_var (id, {loc = {loc_ghost}}, _)
    #endif
      when (isFunction || isToplevel) && (not loc_ghost)
           && not vb.vb_loc.loc_ghost ->
```
```OCaml
| Texp_let
        ( Recursive,
          [{vb_pat = {pat_desc =
          #if OCAML_VERSION < (5, 2, 0)
            Tpat_var (id, _);
          #else
            Tpat_var (id, _, _);
          #endif
            pat_loc}; vb_expr}],
          inExpr ) ->
```
```OCaml
#if OCAML_VERSION < (5, 2, 0)
    | Texp_function {cases} ->
    #else
    | Texp_function (_, Tfunction_cases {cases; _}) ->
    #endif
       cases |> List.map (case ~ctx) |> Command.nondet
    #if OCAML_VERSION < (5, 2, 0)
    #else
    | Texp_function (_, Tfunction_body e) -> e |> expression ~ctx
    #endif
    | Texp_match _ when not (expr.exp_desc |> Compat.texpMatchHasExceptions)
      -> (
```

## Rocq-of-ocaml

[rocq-of-ocaml](https://github.com/formal-land/rocq-of-ocaml) is described as
> Formal verification for OCaml programs

It supports OCaml versions from 5.4 (included) to 5.7 (excluded).

It uses the Typedtree through field accesses, pattern matching on records,
and pattern matching on constructors. It also uses functions (e.g. `Typedtree.pat_bound_idents`) and types in signatures.

In order to adapt to changes in the Typedtree (and other components of
compiler-libs), the project updates the necessary parts, breaking compatibility
with previous versions of OCaml.

## Salto-il

[salto-il](https://gitlab.inria.fr/salto/salto-il) is described as
> The Salto Intermediate Language is a simplified version of the OCaml
TypedTree

It supports OCaml 4.14

It uses the Typedtree through field accesses, pattern matching on records,
and pattern matching on constructors. It also types in signatures. It does not
use functions.

It did not adapt to changes in the Typedtree yet. However, because it defines
an abstraction on the Typedtree, it can be an inspiration to Vaast.

## Utop

[utop](https://github.com/ocaml-community/utop) is described as
> utop is an improved toplevel (i.e., Read-Eval-Print Loop) for OCaml. It can run in a terminal or in Emacs. It supports line editing, history, real-time and context sensitive completion, colors, and more.

It uses the Typedtree only a few times. It supports OCaml versions from 4.11.

It uses the Typedtree through field access, pattern matching on records, and
pattern matching on constructors. It does not use functions or types in
signatures.

In order to adapt to changes in the Typedtree (and other components of
compiler-libs) and support multiple versions, the project relies on
[cppo](https://github.com/ocaml-community/cppo). It has the following instruction
in its dune file to setup an `OCAML_VERSION` cppo variable and preprocess the
code:
```dune
(preprocess
  (action
   (run %{bin:cppo} -V OCAML:%{ocaml_version} %{input-file})))
```
The `OCAML_VERSION` variable is then used to select some code depending on the
compiler's version, like in the following example:
```OCaml
#if OCAML_VERSION >= (5,4,0)
  module Data_types = Data_types
  let present_arg = function
  | Typedtree.Arg x -> Some x
  | Typedtree.Omitted () -> None
#else
  module Data_types = Types
  let present_arg x = x
#endif
```

## Zanuda

[zanuda](https://github.com/Kakadu/zanuda) is described as
> A linter for OCaml+dune projects

It heavily relies on the Typedtree. It supports OCaml versions 4.14 and 5.3.

It uses the Typedtree through field access, pattern matching on records,
and pattern matching on constructors. It also write build records
(e.g. `let vb = { vb with Typedtree.vb_attributes = [] } in`,
`Typedtree.{ str_items = [ si ]; str_type = Obj.magic 1; str_final_env = si.str_env }`),
and and construcors (e.g. `Texp_variant ("Dummy", None)`,
`Tstr_value (Nonrecursive, [ dummy_vb pat dummy_expr ])`).
It uses types in signatures. It does not use functions.

In order to adapt to changes in the Typedtree (and other components of
compiler-libs) and support multiple versions, the project relies on
[ppx_optcomp](https://github.com/janestreet/ppx_optcomp). It has the following
instruction in its dune files to preprocess the code (with other ppx listed):
```dune
(preprocess (pps ppx_optcomp))
```
The ppx is then used to select some code depending on the compiler's version,
like in the following examples:
```OCaml
[%%if ocaml_version < (5, 0, 0)]

let make_Tstr_module mb_name _presence ~loc me =
  Typedtree.Tstr_module
    { mb_id = None
    ; mb_name
    ; mb_expr = me
    ; mb_attributes = []
    ; mb_presence = Types.Mp_present
    ; mb_loc = loc
    }
;;

[%%else]

let make_Tstr_module mb_name presence ~loc me =
  Typedtree.Tstr_module
    { mb_id = None
    ; mb_uid = Shape.Uid.internal_not_actually_unique
    ; mb_name
    ; mb_expr = me
    ; mb_attributes = []
    ; mb_presence = presence
    ; mb_loc = loc
    }
;;

[%%endif]
```
```OCaml
[%%if ocaml_version < (4, 11, 0)]

type case_val = Typedtree.case
type case_comp = Typedtree.case
type value_pat = pattern
type comp_pat = pattern

[%%else]

type case_val = value case
type case_comp = computation case
type value_pat = value pattern_desc pattern_data
type comp_pat = computation pattern_desc pattern_data

[%%endif]
```
```OCaml
[%%if ocaml_version < (5, 0, 0)]

let texp_assert (T fexp) =
  T
    (fun ctx loc x k ->
      match x.exp_desc with
      | Texp_assert e ->
        ctx.matched <- ctx.matched + 1;
        fexp ctx loc e k
      | _ -> fail loc "texp_assert")
;;

[%%else]

let texp_assert (T fexp) =
  T
    (fun ctx loc x k ->
       match x.exp_desc with
       | Texp_assert (e, _) ->
         ctx.matched <- ctx.matched + 1;
         fexp ctx loc e k
       | _ -> fail loc "texp_assert"
     : context -> Warnings.loc -> expression -> 'a -> 'b)
;;

[%%endif]
```

The project defines matching combinators for the Typedtree in
`src/pattern/Tast_pattern.mli`, inspired by `Ppxlib.Ast_pattern`. This might
be an inspiration for Vaast.
