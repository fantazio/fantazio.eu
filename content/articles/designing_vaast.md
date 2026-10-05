---
title: Designing Vaast
description: A library to support multiple versions of OCaml's AST at once
date: 2026-10-03
---

## Table of content
- [Context](#context)
- [Parsetree](#parsetree)
    - [OMP](#omp)
    - [ppxlib](#ppxlib)
- [Vaast](#vaast)
    - [Inspiration and Differences](#inspiration-and-differences)
    - [Design](#design)
        - [Example](#example)
        - [Typedtree proximity](#typedtree-proximity)
        - [Inline records](#inline-records)
        - [A Shallow Replacement](#a-shallow-replacement)
        - [ocaml_XYY](#ocaml_xyy)
        - [Vaast_OCaml](#vaast_ocaml)
        - [Guidelines](#guidelines)
        - [Organization](#organization)
    - [Observations](#observations)
        - [Not a 1-to-1 correspondence](#not-a-1-to-1-correspondence)
        - [option, list, and ocaml_XYY](#option-list-and-ocaml_xyy)
        - [Texp_function](#texp_function)
    - [Future](#future)
- [Conclusion](#conclusion)

## Context

The development of static analysis tools requires access to program information.

Most of this information is available via the [compiler-libs](
https://ocaml.github.io/odoc/ocaml-base-compiler/compiler-libs.common/)
which provides access to the compiler's internal representations.
Among them we find :
- [`Parsetree`](https://ocaml.github.io/odoc/ocaml-base-compiler/compiler-libs.common/Parsetree/index.html),
    which is mainly used for PPXs and linters;
- [`Typedtree`](https://ocaml.github.io/odoc/ocaml-base-compiler/compiler-libs.common/Typedtree/index.html),
    which is used by various projects mainly for code navigation and analysis;
- [`Lambda`](https://ocaml.github.io/odoc/ocaml-base-compiler/compiler-libs.common/Lambda/index.html).

Because I maintain the [dead_code_analyzer](https://github.com/LexiFi/dead_code_analyzer),
which heavily relies on the `Typedtree`, this is the representation this
article will focus on. However, observations made on this representation are
still relevant for other parts of the `compiler-libs`.

The `compiler-libs` is part of the internal OCaml compiler API. Thus, there
are no compatibility guarantees between releases.
Consequently, code relying on it may break with each new release.
In the case of `Typedtree`, it does not break more often than on minor
releases, which is scheduled to happen every 6 months, and in practice
happens every 8-9 months on average since OCaml 4.14.

Although the pace of new minor releases is bearable, not every OCaml user
moves on to the latest version at the same time or even at all. This leads
to a growing galaxy of OCaml versions that code analysis tools must support
to reach the widest audience, or accept to drop support for.

As a result, projects relying on the `Typedtree` may apply different techniques:
- drop the support for previous releases when updating to a more recent one:
    the `dead_code_analyzer` applied this strategy until 1.3.0;
- maintain different versions of the codebase:
    [merlin](https://github.com/ocaml/merlin) does this via dedicated git
    branches;
- maintain preprocessed-based compiler-dependent code: most use
    [cppo](https://github.com/ocaml-community/cppo), but [zanuda](
    https://github.com/Kakadu/zanuda) uses [ppx_optcomp](
    https://github.com/janestreet/ppx_optcomp).

The 1st technique is unsatisfying because it simply cuts out support for
users that have not moved on to the same OCaml version as the tool's.\
The 2nd technique can be cumbersome and error-prone because one must maintain
multiple "copies" of the project.\
Finally, the 3rd and last technique is the most widespread but also has strong
pitfalls:
- it hinders maintenance by leading to unclear errors. E.g.
    ```
    File "_none_", lines 1-71:
    Error: Attributes not allowed here
    ```
- it hinders maintenance by adding mental overhead;
- it is unsafe because it does not guarantee that you actually wrote code
    for the different versions you want to support, and only compiling
    for each of these versions will ensure it;
- `ppx_optcomp`'s guards can only be applied to a few constructs (mainly
    toplevel);
- `cppo` is not navigation-friendly nor format-friendly because it uses a
    non-OCaml syntax.

As you have understood by now, I am not satisfied by the current techniques
to handle compiler-version-dependent code. In addition, the use of `cppo` to
solve this is the most widespread, so different projects end up reimplementing
the same "fix" for the same compatibility breakage. I see that as a maintenace
cost multiplier.

This observation leads to the introduction of [Vaast](
https://github.com/fantazio/vaast): a library that offers a single uniform
representation of the `Typedtree` accross multiple versions of OCaml.

<div class="alert-note">

> This work is mostly focused on the `Typedtree` representation for now.
> The long-term goal is to support more information available in the
> `compiler-libs` (`Parsetree`, `Types`, `Cmt_format`, ...), associated
> functions, and additional utility functions for usual manipulations.

</div>

## Parsetree

The incompatibility issue exposed for the `Typedtree` exists for the
`Parsetree`. Because the two are closely related, it is worth looking at
exisiting solutions for the latter.

The `Parsetree` is more widely used than the `Typedtree` because it is
the representation used by PPXs. Thus, the version-compatibility issue is
more important in this context, and lead to the development of libraries
dedicated to its resolution (among other things).

### OMP

Historically, there used to be [ocaml-migrate-parsetree](
https://github.com/ocaml-ppx/ocaml-migrate-parsetree) (aka OMP).
Its goal was to ensure PPXs written against a specific version of the
compiler could be used on code built with a different version.
It did so by converting `Parsetree`s in between versions. More specifically,
it converted the unpreprocessed code's Parsetree to the PPX's version,
applied the PPX, and converted the result back to the original version.
Because each PPX may be written against a different version, it even provided
a driver to limit the amount of conversions required to apply multiple PPXs.

<div class="alert-note">

> OMP originated in [ppx_tools](https://github.com/ocaml-ppx/ppx_tools).
> I believe [this is its genesis](https://github.com/ocaml-ppx/ppx_tools/pull/54).

</div>

Internally, it contained copies of the `Parsetree` (and `Asttypes`) for different
OCaml versions, and migration functions between each version and its supported
adjacents (i.e. for version `n`, migration from/to `n-1` and `n+1`).
This adjacent-only conversion avoids a combinatorial explosion. Thus, going
from one version to another simply requires multiple adjacent conversions.
Backward conversion (from `n` to `n-1`) could break when a feature was not
available in the previous version. OMP handled that situation by raising
an dedicated exception.

OMP was maintained from 2017 to 2022, supported OCaml versions 4.02 to 4.13,
and was eventually replaced by `ppxlib` in [2023](
https://discuss.ocaml.org/t/deprecating-ocaml-migrate-parsetree-in-favor-of-ppxlib-also-as-a-platform-tool/13240).

### ppxlib

[ppxlib](https://github.com/ocaml-ppx/ppxlib) is the current standard library
for ppx rewriters, and listed on the [OCaml Platform](https://ocaml.org/platform).
Although, as the name suggests, it is targetting PPXs, its Readme indicates it
is suited for
> other programs that manipulate the in-memory representation of
OCaml programs, a.k.a. the "Parsetree".

Unlike OMP, ppxlib provides one version of the `Parsetree` that PPXs must agree
on. Like OMP, ppxlib handles the migration to/from other versions (but with
fundamental differences in the driving of the PPXs). An important consequence
is a more uniform ecosystem, and reduced maintenance (compared to OMP).

Internally it uses a "frozen" version of the `Parsetree`, which is a copy of
the corresponding compiler version's, and provides stable APIs to manipulate
it.\
Every so often, ppxlib's Parsetree is bumped to a more recent version. This
does not happen on all releases: the latest was last year to 5.2, the previous
was 3 years before to 4.14/5.0.
The stable APIs help limiting breakages in reverse-dependenices when such
a bump happens, and the ppxlib maintainers provided help to update to the
latest version.\
Because ppxlib's version is not the compiler's latest, it offers a mean to
interact with newer nodes by encoding them as extension points [as discussed in
this thread](https://discuss.ocaml.org/t/ann-ppxlib-support-for-future-compilers/17430).
The benefit of that design is that it makes PPXs forward-compatible with new
features, while the frozen version and migration scheme takes care of a more
general compatbility with features existing in the selected version.

A more thorough description of the compatibility design is available in
[ppxlib's documentation](https://ocaml-ppx.github.io/ppxlib/ppxlib/compatibility.html).

`ppxlib` was initially released in 2018, is still maintained, and supports OCaml 4.08 to 5.5.

## Vaast

### Inspiration and Differences

OMP and ppxlib are 2 great examples of libraries that solve the
compiler-version-compatiblity issue. The 1st by exposing all the versions
and converting between them. The 2nd by choosing a specific a version and
converting to/from it.

The use of a single version and the ability to convert from/to it is the
basis of Vaast's design. This means that from their current compiler version,
one can translate the AST to/from Vaast's. However, it does not provide
the ability to convert in between OCaml versions.

The ppx libraries are both targetting a different ecosystem than Vaast : PPXs.
Thus, they focus on the `Parsetree` and the ability to preform local rewrites.
Vaast's main target is static analysis tools with a more "global" view of a
program. I would argue that for such tools, staying up to date with the
latest features is a lot more important than for PPX rewriters, because
discarding them can quickly lead to invalid results.
Consequently, Vaast's AST should adapt upstream's new AST in a user-friendly
way and may break with every minor OCaml release.

Finally, the goal of Vaast is not to provide compatibility by conversion but
to replace the current version compatibility techniques with a safer and
less cumbersome alternative. I.e. it does not intend to relieve maintainers
of Typedtree-dependent tools from updating to the latest version of the compiler,
or make old tools magically work, but to provide a more convenient interface
to the Typedtree whithout losing the compatibility with previous versions of
the compiler.

### Design

I have kept you waiting long enough. Let's dive into the actual design of Vaast

<div class="alert-caution" style='--alert-title: "Important"'>

> This is an initial design propostion. The goal of this article is to open
> a discussion with the community about this library and correct its design
> to a more generally satisfying solution.
> Vaast can only be considered experimental until then and should not be relied
> on for production development.

</div>

A picture is worth a thousand words so we'll start with a small piece of
`Vaast.Typeedtree`'s interface and then go into the details of the design
of Vaast.

#### Example

Here is an excerpt from `Vaast.Typedtree`'s interface :

```OCaml
(* ... *)

and pat_extra =
  | Tpat_constraint of { type_ : OCaml.core_type }
  | Tpat_type of { path : Path.t; longid : Longident.t Asttypes.loc }
  | Tpat_open of { path : Path.t; longid : Longident.t Asttypes.loc; env : Env.t }
  | Tpat_unpack of { pack_type : (not_available, OCaml.package_type option) ocaml_505; }

(* ... *)

and package_type = {
  pack_path : Path.t;
  pack_fields : (Longident.t Asttypes.loc * OCaml.core_type) list;
  pack_type : (Types.module_type, Vaast_OCaml.Types.package) ocaml_505;
  pack_txt : Longident.t Asttypes.loc;
}

(* ... *)
```

It is very close to OCaml 5.5's Typedtree interface:
```OCaml
(* ... *)

and pat_extra =
  | Tpat_constraint of core_type
  | Tpat_type of Path.t * Longident.t loc
  | Tpat_open of Path.t * Longident.t loc * Env.t
  | Tpat_unpack of package_type option

(* ... *)

and package_type = {
  tpt_path : Path.t;
  tpt_constraints : (Longident.t loc * core_type) list;
  tpt_type : Types.package;
  tpt_txt : Longident.t loc;
}


(* ... *)
```

#### Typedtree proximity

Similarly to OMP and ppxlib for the `Parsetree`, Vaast's `Typedtree` remains
close to the compiler's.

This has 3 main benefits:
1. it is easy to adapt upstream changes;
2. it is easy to adopt in exitsting projects;
3. it is easy to learn and use.

Regarding the 1st benefit, very similar representations implies that when the
upstream changes, it is easy to pinpoint which part of Vaast's are affected.
Thus, the maintenance cost should not be far greater than it is for any
Typedtree-dependent tool when updating to the latest version.

Regarding the 2nd benefit, this is a corollary of the 1st one: very similar
representations oùplies that it is easy to translate the compiler's constructs
into Vaast's. This could mostly be automatized.

Regarding the 3rd benefit, this is a corollary of the 2nd one: very similar
representations implies that knowledge of one can be easily derived into
knowledge of the other, and using the other should not be much more
complicated.

In order to complete the 2nd benefit, a simple conversion API from/to each
representation is provided.


If you squint a little, Vaast's Typedtree representation can be seen as a
super-representation of the different compiler versions.
That is, it contains the types, constructors, and fields that exist in the
different versions.

#### Inline records

The first noticeable difference from OCaml's representation is the use of
inline records instead of inline tuples. Even for single-element constructors.

It often happens that some constructors are provided an additional field in
a new minor release. It actually happened in all minor releases from 4.14 to
5.4. It also happened in 5.5 to `Tpat_unpack` which did not have any field to
begin with. This kind of change leads to breakages in user code.
It also often happens that user-code matching on such constructors do not
care about all the fields but only a few selected ones. Thus, the breakage
leads to version-dependent code only to discard the extra field.

An example of such version-dependent selection can be observed in
[odoc](https://github.com/ocaml/odoc/blob/6dc58262b276af7e24b92ac5343b9f26d621122b/src/loader/typedtree_traverse.ml#L43):
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
              match maybe_localvalue id loc.loc with
              | Some x -> poses := x :: !poses
              | None -> ())
```

Using records instead of tuples reduces the chances of breakage in user-code,
and reduces the "noise" introduced by the version-dependent selection.

Using Vaast and ignoring the OxCaml case, the above code could be rewritten
as a single pattern:
```OCaml
          | Tpat_alias {id; name; _} -> (
              match maybe_localvalue id name.loc with
              | Some x -> poses := x :: !poses
              | None -> ())
```

It does not remove the possibility of breakages because in cases user-code
was actually matching all the fields, then it may not use the discarding
pattern `; _`, so the compiler would complain about the record pattern
missing some fields when new ones are introduced.\
Similarly in the case of `Tpat_unpack`, the addition of an inline record
would break code matchig this constructor.\
However, in both cases, the fix is trivial and only one pattern needs to
subsist to remain compatible with all the supported OCaml versions.

#### A Shallow Replacement

A second noticeable difference is the mention of `OCaml` whithin
`Typedtree`'s types as in
```OCaml
Tpat_constraint of { type_ : OCaml.core_type }
```
This module is pointing to OCaml's Typedtree (this is actually an extended
version as explained in [Vaast_OCaml](#vaast_ocaml) below).

`Vaast.Typedtree` is not meant to be used as a deep replacement of OCaml's.
Rather, it is meant to be used at points of interest and only when necessary.
Using a shallow representation is an important part of the design.

To achieve this, the types in Vaast only convert a component's type if it
is an unwrapped sum type. E.g. `Vaast.Typedtree.expression.exp_desc` is a
`Vaast.Typedtree.expression_desc` because the `expression_desc` type is
not wrapped (i.e. not a type parameter), and is a sum type,
whereas `core_type` is a record type so it references OCaml's.

Along with this shallow representation come conversion functions. They are
simply prefixed by `of_` for conversion from OCaml to Vaast and `to_` the
other way around. They are defined for each OCaml Typedtree type.
E.g.
```OCaml
val of_pat_extra : OCaml.pat_extra -> pat_extra
val to_pat_extra : pat_extra -> OCaml.pat_extra
```

The result is that one does not need to convert a whole tree to work in
Vaast's universe but rather convert the specific nodes when desired.
This allows an incremental integration of Vaast with existing
Typedtree-related code and infrastructure. It also reduces the cost of
conversion by only paying for what's useful.

If one would like to emulate a deep replacement of OCaml's Typedtree, they
can still convert each node on the fly during a Typedtree traversal.

#### ocaml_XYY

The next thing one may notice in the example is the type of
`pat_extra.Tpat_unpack`:
```OCaml
  | Tpat_unpack of {
        pack_type : (not_available, OCaml.package_type option) ocaml_505;
      }
```

This type relies on Vaast's core compatibility mechanism: the `ocaml_XYY`
types.
Those types have the following shape:
```OCaml
type ('until, 'since) ocaml_XYY =
  | Until_XYY of 'until (** type until X.YY excluded *)
  | Since_XYY of 'since (** type since X.YY included *)
```

As you may have guessed, their purpose is to diffentiate the type of a
component prior to and after a given version.\
In the example we have
`(not_available, Typedtree.package_type option) ocaml_505`:
- the `ocaml_505` type splits the representation between OCaml < 5.5 and
OCaml >= 5.5.
- the field was `not_available` until 5.5
- the field is a `Typedtree.package_type option` since 5.5.
- this translates the difference between `Tpat_unpack` in OCaml < 5.5 and
    `Tpat_unpack of package_type option` in OCaml >= 5.5.

The `not_available` type is defined by Vaast with a single constructor.
Its meaning is straightforward: the component is not available for the
specified versions.
```OCaml
type not_available = NA
```

As a result, matching on `Tpat_unpack` using Vaast may look like:
```OCaml
| Tpat_unpack { package_type = Since_505 (Some ptype) } -> do_smth_with ptype
| Tpat_unpack _ -> do_smth_else
```

Those types are exposed via the module `Vaast_Core`.

#### Vaast_OCaml

Another noticeable type change is the use of `Vaast_OCaml` as in
`package_type.pack_type`'s type:
```OCaml
  pack_type : (Types.module_type, Vaast_OCaml.Types.package) ocaml_505;
```

This module refers to extended versions of OCaml's modules as necessary.
This is part of the compatibility mechanism, not for users particularly
but for Vaast itself.

Here `Vaast_OCaml.Types` is an extended version of `Types`. This is necessary
because `Types.package` was only introduced in OCaml 5.4. Thus, without
this extension, the library would not compile in prior versions of OCaml
(defeating its purpose).

You may also encounter an extension of `Typedtree` (the one actually
referenced by `OCaml` in [A Shallow Replacement](#a-shallow-replacement)
above), `Asttypes`, `Value_rec_types`, and `Data_types`.
They each extend the corresponding compiler's modules with the missing types.

#### Guidelines

The example gave use a look at the most important pieces of the design of
Vaast.

Here is a short description of the design guidelines that can be devised to
adapt the Typedtree to upstream changes.

1. The inline tuples are replaced by inline records

2. The field names used in the new inline records are chosen based on the
    surrounding constructor and their type. This encourages an overall
    coherence while providing local meaning. E.g. a field of type `expression`
    will be named `expr` by default (as in `Texp_match {expr; _}`) unless
    a more meaningful name can be provided (as in `Texp_let {in_; _}`).

3. The field names do not change. This is to limit breakage in user code.
    It happened twice that field names are changed in the compiler (once
    in 5.4 and once in 5.5). Vaast's did not change. We can actually see
    that difference in the example with `package_type`'s fields being
    prefixed with `pack` in Vaast and `tpt` in OCaml.

4. A change in the type of a field leads to the use of an `ocaml_XYY` type
    to identify the types until and since OCaml X.YY.

5. The introduction of a new constructor (e.g. `Ttype_external` in 5.5)
    does not lead to using an `ocaml_XYY` type. This is because we cannot
    place it on the constructor, and putting it on its fields would be
    indiscernable from a previously existing constructor without such
    fields (e.g. `Tpat_unpack` in the example).
    I.e. the fields are inseparable from the constructor and using the
    version type would indicate otherwise.

6. New fields introduced (e.g. `label_declaration.ld_atomic` in 5.4) have
    type `(not_available, 'since) ocaml_XYY`.
    Unlike constructors, we can attach the version type to fields.

7. Conversely to the point above, fields removed (e.g.
    `class_infos.ci_id_typehash` in 5.1) have type
    `('until, not_available) ocaml_XYY`.

8. `ocaml_XYY` should appear as deep as possible in a type to clearly identify
    the actual changes and avoid unnecessary breakages and complexity in
    user-code.
    This can lead to rewriting some definitions to better represent the
    semantic changes that happened (e.g. `Texp_function` in 5.2).

9. Do not replace a field's type by the `Vaast.Typedtree` equivalent unless
    it is a sum type and is not used as a type parameter.

10. If the Typedtree relies on a type defined in another module, explicitly
    state that module. If the type is not available in all versions, then
    extend the module in `Vaast_OCaml`.

#### Organization

Vaast is organized into 4 libraries.\
The main library is `vaast`, whose entry point is the module `Vaast`.\
It contains 3 submodules: `Vaast.Core`, `Vaast.OCaml` and `Vaast.Typedtree`.
These 3 modules are aliases to the entry points of the libraries
`vaast.core`, `vaast.ocaml` and `vaast.typedtree` respectively.

The core library, exposing the `ocaml_XYY` and `not_available` types, is
`vaast.core`. Its main entry point is the module `Vaast_Core`.

The main entry point of `vaast.ocaml` is `Vaast_OCaml`.\
This is the module containing the extended versions of some of the compiler
modules (e.g. `Asttypes`).

The main entry point of `vaast.typedtree` is `Vaast_Typedtree`.\
It is the shallow replacement to OCaml's which exposes the types and
conversion functions mentionned. It also exposes a module `OCaml` which is
an alias for `Vaast_OCaml.Typedtree`.\
This library depends on the previous two.

As a result, a user can depend on `vaast`, locally open `Vaast` to work in
Vaast's universe and come back to the OCaml (extended) universe by using
`OCaml`.

Similarily, they can locally open `Vaast.Typedtree` and comeback to the OCaml
(extended) universe by using `OCaml`.

### Observations

#### Not a 1-to-1 correspondence

In some cases, Vaast introduces intermediate types as a result of the
guideline n°8.

This is, for example, the case with the replacement of `Texp_letmodule`,
`Texp_letexception`, and `Texp_open` by the single constructor
`Texp_struct_item` in OCaml 5.5.
The old constructors were each dedicated to a specific `let ... in` syntax.
The new constructor is a generalization to all `structure_item`s.

In order to represent this change in Vaast, the old constructors are moved
to their own type `texp_struct_item` (non-existant in OCaml), and the new
constructor is translated as:
```OCaml
    | Texp_struct_item of {
            struct_item : (texp_struct_item, OCaml.structure_item) ocaml_505;
            in_ : OCaml.expression;
        }

(* ... *)

and texp_struct_item =
    | Texp_letmodule of {
            id : Ident.t option;
            name : string option Asttypes.loc;
            presence : Types.module_presence;
            mod_expr : OCaml.module_expr;
        }
    | Texp_letexception of { extension_ctor : OCaml.extension_constructor; }
    | Texp_open of { open_decl : OCaml.open_declaration; }
```

Because the `in_` field is shared by all the constructors, it is removed
from the old ones and not versionned. The `struct_item` field is versionned
and can be either one of the old constructors (without `in_`) or a
`structure_item`.

This is also the case for `T*_tuple` constructors, which hold tuple fields.
Since 5.4, tuple fields can be labeled. In order to simplify the type
expressions of those constructors, 2 types `tuple_field` and `tuple_fields`
are defined.

```OCaml
and 'a tuple_field = {
    label : (not_available, string option) ocaml_504;
    content : 'a;
}

and 'a tuple_fields = 'a tuple_field list
```

#### option, list, and ocaml_XYY

Following guideline n°4, some fields that are newly introduced with an
`option` or `list` type are versionned.

This is, for example, the case for with the introduction of effect cases
in `Texp_match` and `Texp_try` in OCaml 5.3.
Those cases are represented in a new field:
```OCaml
effect_cases : (not_available, OCaml.value OCaml.case list) ocaml_503;
```

Because the corresponding syntax is `not_available` in OCaml < 5.3,
it is equivalent to having no effect cases, i.e. an empty list.

This is also the case for the `c_cont` field introduced in 5.3 for the effect
cases as well. This field is introduced with an `Ident.t option` type and is
versionned in Vaast. Instead of `Until_503 NA`, the absence of continuation
could equivalently be represented by `None` in OCaml < 5.3.

This is actually the case in multiple places.
Flattening those could improve usability, to the cost of losing the
version information. The documentation can still take care of making this
information explicit. I believe keeping those types as-is does not provide
any additional safety and those should systematically be flattened (but
documented).

A similar situation can be observed with `apply_arg`, a type introduced in
5.4 and used in place of `expression option` in `Texp_apply` and `Tcl_apply`.
Its definition (`Arg of expression | Omitted of unit`) is semantically
equivalent to the previous type. Versionning the fields that changed only adds
an extra layer of indirection. The versionned types could be flattened to
either the `option` or `arg_or_omitted`. I prefer the latter for its
expressiveness.


#### Texp_function

This particular constructor is cumbersome. Its definition changed in OCaml 5.2.\
Here is what it looked like:
```OCaml
    | Texp_function of {
            arg_label : arg_label;
            param : Ident.t;
            cases : value case list;
            partial : partial;
        }
```
And here is what it looks like now:
```OCaml
    | Texp_function of function_param list * function_body

(* ... *)

and function_param = {
    fp_arg_label : arg_label;
    fp_param : Ident.t;
    fp_partial : partial;
    fp_kind : function_param_kind;
    fp_newtypes : string loc list;
    fp_loc : Location.t;
}

and function_param_kind =
  | Tparam_pat of pattern
  | Tparam_optional_default of pattern * expression

and function_body =
  | Tfunction_body of expression
  | Tfunction_cases of {
            cases : value case list;
            partial : partial;
            param : Ident.t;
            loc : Location.t;
            exp_extra : exp_extra option;
            attributes : attributes;
        }
```

For more details on the motivation of this change, see [PR #12236](
https://github.com/ocaml/ocaml/pull/12236).

In order to unify and reflect the actual semantic change, Vaast's representation is:
```OCaml
    | Texp_function of {
            params : (Asttypes.arg_label, OCaml.function_param list) ocaml_502;
            body : function_body;
        }

(* ... *)

and function_param = {
    fp_arg_label : Asttypes.arg_label;
    fp_param : Ident.t;
    fp_partial : partial;
    fp_kind : function_param_kind;
    fp_newtypes : string Asttypes.loc list;
    fp_loc : Location.t;
}

and function_param_kind =
    | Tparam_pat of { pat : OCaml.pattern; }
    | Tparam_optional_default of {
            pat : OCaml.pattern;
            default : OCaml.expression;
        }

and function_body =
    | Tfunction_body of { expr : OCaml.expression; }
    | Tfunction_cases of {
            cases : OCaml.value OCaml.case list;
            partial : partial;
            param : Ident.t;
            loc : (not_available, Location.t) ocaml_502;
            exp_extra : (not_available, OCaml.exp_extra option) ocaml_502;
            attributes : (not_available, OCaml.attributes) ocaml_502;
        }
```

This ressembles the representation in OCaml >= 5.2. The types `function_param`
and `function_param_kind` are even left unversionned.
What it actually does is translate the pre 5.2 representation in the new one.
Because the old representation is similar to the `Tfunction_cases`, the
unchanged information is stored there (fields `cases`, `partial`, and `param`),
and the other fields are versionned as `not_available` in OCaml < 5.2.
An important part of the change is the arity. Thus `Texp_function`'s `params`
is versioned.

As a result, translating the `Texp_function` in OCaml >= 5.2 is
straightforward, and in OCaml < 5.2 looks like:
```OCaml
Texp_function { arg_label; param; cases; partial } ->
    let params = Until_502 arg_label in
    let body =
        Tfunction_cases {
            cases;
            partial;
            param;
            loc = Until_502 NA;
            exp_extra = Until_502 NA;
            attributes = Until_502 NA;
        }
    in
    Texp_function {params; body}
```

This is not too convoluted, and one may identify where the info is moved.
However, this is not very convenient to use. Indeed, the `Tfunction_body` case
must still be accounted for when `params = Until_502 arg_label`,
and the `params` cannot be uniformly processed.

Maybe the `function_param` type could be used to hold the `arg_label` in
`fp_arg_label`, making all its other fields versionned, and `params`' type
be flattened (using a singleton list in OCaml < 5.2).\
Maybe a resolution similar to that of `Texp_struct_item` could be applied,
with `Texp_function` holding a single versionned field.\
Maybe using a GADT could be used to enforce a connection between `params`
and `body`.

### Future

So far, Vaast is compatible with OCaml 4.14 to 5.5. It can be extended forward
as explained, but also backward. The current plan is to keep up with the
compiler.

Handling the `Typedtree` is only the first step. My immediate use case is
the `dead_code_analyzer`.\
It also depends on the `Parsetree`, `Cmt_format`, and `Types`.
`Parsetree` also breaks on minor releases. The goal is not to replace ppxlib
on that front, as explained in [Inspiration and Differences](
#inspiration-and-differences) the two libraries have different goals, but to
provide a compatibility similar to the `Typedtree's`.\
There is a change in `Cmt_format.cmt_infos` in OCaml 5.3 that leads to
a big chunk of version-dependent code.\
`Types`, is a natural candidate after `Typedtree` and `Parsetree`, and the
analyzer is slightly impacted by the introduction of labeled tuples.

The short-term goal is to discuss and correct the current design with the
community in order to provide a 1st official interface to Vaast.\
The mid-term goal is to add utility functions for common operations,
support a few mainstream modules of compiler-libs, and make Vaast a basic
building block for static analyzers.\
The long-term goal is to support as many modules of compiler-libs as are used
in the wild.

## Conclusion

Vaast provides an alternative to the current techniques to handle
version-dependent Typedtree uses which is:
- safer than the preprocessing-based alternative, because it embeds the version
    in the type system;
- more resilient to upstream changes, thanks to the inline records and a more
    precise identification of the changes;
- cleaner, because it reduces the volume of user-code and flourishes required
    to handle mutliple versions.

Under the hood, it is actually relying on `cppo`. So it can be seen as moving
the version-dependency information from the preprocessor to the type checker.

There is still work to do on its documentation and testing but the current
prototype is already usable as a replacement for ad-hoc compatibility
([experimented on the dead_code_analyzer](
https://github.com/LexiFi/dead_code_analyzer/compare/master...fantazio:dead_code_analyzer:vaast)
).

If you are interested in its development or use, feel free to join the
[discussion on its design](https://github.com/fantazio/vaast/issues/8).

<span class="thanks">for reading</span>
