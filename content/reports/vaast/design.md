---
title: Design
date: 2026-06-30
---

There are 8 kinds of changes in the Typedtree shape :

- Updating an existing constructor or field.
    - It can add information the to component. E.g. in the change from 4.14 to
        5.0, `record_label_definition.Kept` stores one more value of type
        `mutable_flag`, and the constructor's content changed from a single
        value to a tuple.
    - It can change the type of the component. E.g. in the change from 5.4 to
        5.5, `package_type.tpt_type` changed from type `Types.module_type` to
        `Types.package`.
    - It can rename the component. E.g. in the change from 5.3 to 5.4, the
        fields of `package_type` were all renamed.

- Adding a new constructor or field. E.g. `module_expr_desc.Tmod_apply_unit` is
    introduced during the change from 5.0 to 5.1.

- Removing a constructor or field. E.g. `'a class_infos.ci_id_typehash` is
    removed during the change from 5.0 to 5.1.

- Replacing a constructor or field. E.g. in the change from 5.4 to 5.5,
    `expression_desc`'s constructors `Texp_letmodule`, `Texp_letexception`,
    and `Texp_open` are replaced by the single constructor `Texp_struct_item`.

- Adding a new type. E.g. `function_body` is added during the change from 5.1
    to 5.2.

- Adding a function. E.g. `map_apply_arg` is introduced during the change from
    5.3 to 5.4.

- Removing a function. E.g. `exp_is_nominal` is removed during the change from
    5.2 to 5.3.

- Updating a function. E.g. `pat_bound_idents_full`'s type changed from
    `'k general_pattern -> (Ident.t * string loc * Types.type_expr) list`
    to
    `'k general_pattern -> (Ident.t * string loc * Types.type_expr * Types.Uid.t) list`
    during the change from 5.1 to 5.2.

Among those changes, we will only worry about those that affect the shape of the
Typedtree (and its traversal). Thus, we will ignore the changes related to
functions, and focus only on the 5 first kinds, which affect types.

For the design of the library, we have multiple constraints:
1. it should be easy to adapt upstream changes;
2. it should be easy to learn and use;
3. it should be easy to adopt it in exisiting projects;
4. it should remain compatible with previous compiler versions;
5. it should not break its interface too often (assuming breakages may sometimes
    be unavoidable, or only avoidable at a non-negligible cost);
6. it should not incurr a heavy performance cost (that's very relative, and only
    experience will tell what's not tolerable, but we can reasonably estimate
    when the impact seems too important).

From the constraints and the focus on the changes in the shape of the Typedtree,
I will try and devise multiple designs and evaluate their benefits, and
disadvantages. In the end, at least one of them will be actually used in the
dead_code_analyzer (in an experimental branch) as a proof of concept. The
selected design and proposed alternatives will be the starting point for deeper
and more informed discussions with potential users (mainly the targeted
projets' maintainers).

## Design 1 (Superset)

In order to facilitate constraints 1 to 3, designing the new representation as
close as possible to the actual Typedtree seems like a good idea.
In my opinion, this should also encourage the development of new tools based on
the Typedtree without the worry of having to rewrite most of it to rely on the
library.
Staying as close as possible to the original shape means that traversal should
have similar performance to traversing the original Typedtree, so this would
satisfy constraint 6. This leaves constraints 4 and 5 to solve.

### Design 1.0

An "easy" design from the above description is a superset of the different
Typedtree versions. I.e. anything that exists in any version of the compiler's
Typedtree exists in Vaast's. This would mean that when a new type, field or
constructor is added, then it is part of the Vaast's Tytpedtree (made
optional if it is a field). When one is removed upstream, it is kept in Vaast
(made optional if it is a field). And when one is replaced, both the ancestor
and the successor are included in Vaast (both made optional if they are fields).\
Only the most complicated change remains : when a field or a constructor is
updated. If the update is a renaming, then one the ancestor can be kept or the
update can be translated into a replacement. However, in other kinds of updates,
the same entry point is used with different types. In this situation, if the
content is changed by adding or removing a component, then we can keep all the
components and update the types of the added/removed ones to be optional.
Otherwise, if there is a change in the type of a component (like in
`package_type.tpt_type` discussed above), then a sum type can be used, offering
both the old and the new types as alternatives.

From the shape and update adaptation descriptions above, we would have the
following types in the Typedtree:

```OCaml
type record_label_definition =
  | Kept of Types.type_expr * mutable_flag option (* added mutable_flag -> make optional *)
  | Overridden of Longident.t loc * expression

type package_type =
  { (* renamed fields -> keep the old field names *)
    pack_path : Path.t;
    pack_fields : (Longident.t loc * core_type) list;
    pack_type : [`Module_type of Types.module_type; `Package of Types.package`] (* updated field type -> make alternative *)
    pack_txt : Longident.t loc;
  }

type module_expr_desc =
    Tmod_ident of Path.t * Longident.t loc
  | Tmod_structure of structure
  | Tmod_functor of functor_parameter * module_expr
  | Tmod_apply of module_expr * module_expr * module_coercion
  | Tmod_apply_unit of module_expr (* added constructor *)
  | Tmod_constraint of
      module_expr * Types.module_type * module_type_constraint * module_coercion
  | Tmod_unpack of expression * Types.module_type

type 'a class_infos =
  { ci_virt: virtual_flag;
    ci_params: (core_type * (variance * injectivity)) list;
    ci_id_name : string loc;
    ci_id_class: Ident.t;
    ci_id_class_type : Ident.t;
    ci_id_object : Ident.t;
    ci_id_typehash : Ident.t option; (* removed field -> make optional *)
    ci_expr: 'a;
    ci_decl: Types.class_declaration;
    ci_type_decl : Types.class_type_declaration;
    ci_loc: Location.t;
    ci_attributes: attributes;
  }

type expression_desc =
  (* ... *)
  | Texp_letmodule of Ident.t option * string option loc * Types.module_presence * module_expr * expression
  | Texp_letexception of extension_constructor * expression
  | Texp_open of open_declaration * expression
  | Texp_struct_item of structure_item * expression (* replaces the above 3 -> keep all *)
  (* ... *)

type function_body = (* added type -> keep it *)
  | Tfunction_body of expression
  | Tfunction_cases of
      { cases: value case list;
        partial: partial;
        param: Ident.t;
        loc: Location.t;
        exp_extra: exp_extra option;
        attributes: attributes;
      }
```

This example is incomplete but it illustrates what the Typedtree shape could
look like if it were to superset those from 4.14 to 5.5.
There are a few points that need to be discussed.

First, the example uses options to encode information that are only available
in some versions of compiler's Typedtree. This translates the "information may
be available" in a straightforward way but is undistinguishable from optional
information actually coming from the compiler (e.g.
`Texp_variant of label * expression option`). Thus, a user would lose some
information that could otherwise be encoded when using cppo (e.g.
`#if OCAML_VERSION >= (5, 2, 0)`). I like that code is documenting itself.

Second, the example uses polymorphic variants to keep alternative types of
`package_type.pack_type`. Defining regular sum types could improve the API, and
performance (see the [memory representation of polymorphic
variants](https://ocaml.org/docs/memory-representation#polymorphic-variants)).
I think using GADT risks to complicate constraints 2 and 3 for now.

Third, we only show a "static" view of the Typedtree, with a short description
of how it includes all the past changes. In order to satisfy constraints 4 and
5, we must look at the dynamics of the representation. I.e. we must simulate how
it actually adapts to upstream changes. The description of the design discusses
how a change affects the design. Thus, we can simulate and explore what such
affections would imply in the evolution of Vaast's Typedtree. Here is a diff of
the example that show how our Typedtree representation could evolve:
```diff
 type record_label_definition =
-   | Kept of Types.type_expr
+   | Kept of Types.type_expr * mutable_flag option (* added mutable_flag -> make optional *)
    | Overridden of Longident.t loc * expression

 type package_type =
   {
     pack_path : Path.t;
     pack_fields : (Longident.t loc * core_type) list;
-    pack_type : Types.module_type
+    pack_type : [`Module_type of Types.module_type; `Package of Types.package`] (* updated field type -> make alternative *)
     pack_txt : Longident.t loc;
   }

 type module_expr_desc =
     Tmod_ident of Path.t * Longident.t loc
   | Tmod_structure of structure
   | Tmod_functor of functor_parameter * module_expr
   | Tmod_apply of module_expr * module_expr * module_coercion
+  | Tmod_apply_unit of module_expr (* added constructor *)
   | Tmod_constraint of
       module_expr * Types.module_type * module_type_constraint * module_coercion
   | Tmod_unpack of expression * Types.module_type

 type 'a class_infos =
   { ci_virt: virtual_flag;
     ci_params: (core_type * (variance * injectivity)) list;
     ci_id_name : string loc;
     ci_id_class: Ident.t;
     ci_id_class_type : Ident.t;
     ci_id_object : Ident.t;
-    ci_id_typehash : Ident.t;
+    ci_id_typehash : Ident.t option; (* removed field -> make optional *)
     ci_expr: 'a;
     ci_decl: Types.class_declaration;
     ci_type_decl : Types.class_type_declaration;
     ci_loc: Location.t;
     ci_attributes: attributes;
   }

 type expression_desc =
   (* ... *)
   | Texp_letmodule of Ident.t option * string option loc * Types.module_presence * module_expr * expression
   | Texp_letexception of extension_constructor * expression
   | Texp_open of open_declaration * expression
+  | Texp_struct_item of structure_item * expression (* replaces the above 3 -> keep all *)
   (* ... *)

+type function_body = (* added type -> keep it *)
+  | Tfunction_body of expression
+  | Tfunction_cases of
+      { cases: value case list;
+        partial: partial;
+        param: Ident.t;
+        loc: Location.t;
+        exp_extra: exp_extra option;
+        attributes: attributes;
+      }
```
Constraint 4 is statisfied: anything that existed before continues existing
(possibly under a different shape) in the new version. I.e. the Typedtree is
only growing to continue to include all the past version of the Typedtree.

We can see that updating, adding or removing information in an upstream
constructor or field, results in a breakage in the API. Similarly when adding or
removing a field. Thus, the effort that is necessary to adapt to the new
upstream Typedtree is propagated to Vaast's users.\
Adding, removing or replacing a constructor, or adding a type is absorbed by
Vaast and a user may ignore those changes e.g. with a catch-all branch. This is
not necessarily a good thing. Indeed, as a user, if a constructor my tool relies
on is replaced (like in `expression_desc`), I would appreciate more that my code
stops compiling with a clear error, or at least get a warning, than seeing
failures (e.g. invalid results) in tests and having to debug, or worse, that
all the tests pass and the tool fails in production.\
Therefore, I do not see the current dynamics as satisfying with regards to
constraint 5.

### Design 1.1

Let's iterate on the previous design and try to fix its identified pitflass.

First, version-dependently available data.
Alternatively to using an option type, dedicated sum types could be used.
Using our example, we could define `Kept` as :
```OCaml
| Kept of Types.type_expr * [`Until_500 | `Since_500 of mutable_flag]
```
This way, code that cares about it could match on both patterns as follows,
and specify a dependency on OCaml >= 5.0.0 in their package description, or
documentation.
```OCaml
| Kept (_, `Until_500) -> (* assert false or something *)
| Kept (_, `Since_500 mutable_flag) -> (* do something *)
```
The equivalent code (ignoring the package and build configuration) with cppo
would look like:
```OCaml
#if OCAML_VERSION < (5, 0, 0)
| Kept _ -> (* assert false or something *)
#else
| Kept (_, mutable_flag) -> (* do something *)
#endif
```
In the meantime, code that does not care about the mutable_flag data could
simply match on `Kept (type_expr, _)` and remain compatbile with all the
compiler's versions, while using cppo, the code would be similar to the one
above.\
As a result, the proposed design is more lightweight than using cppo, and only
pushes relevant information into the code.

Second, the version-alternative types. Instead of dedicated constructors, the
interface could be unified with the above representation using `` `Until_XXX`` and
`` `Since_XXX``.

Third, regarding breakage and constraint 5, I would argue that there is some
subnjectivity in what a "cost" is, and, in my opinion, an invisible cost is
downstream maintenance. As explained, as a user, I would rather have my code not
compile and pay the small update to remain compatible with all versions than see
my tool fail in production. Especially when a failure could mean that the
results become entirely unreliable. On the other hand, I would not want to pay
the cost of updating code to account for changes irrelevant to my needs. Those
needs will vary from one user to another so anticipating them cannot always fit
all.\
A balanced proposition is to represent all the constructor's (tuple or single
value) content as inline records, replaced constructors by a new one that embeds
alternatives (using the above polymorphic variant representation), and updated
types with alternatives. All this applied on a case by case basis to limit
negatively breaking code that should not be and best represent what the version
change actually impacts.
<div class="alert-note">

> Using inline records should not increase the memory footprint or add
> indirections (see [Alain Frisch's post on LexiFi's
blog](https://www.lexifi.com/blog/ocaml/inlined-records-constructors/)).
</div>

From the above description, we can re-write our example Typedtree content as:
```OCaml
type record_label_definition =
  | Kept of
      {
        type_expr: Types.type_expr;
        mut_flag: [ `Until_500; `Since_500 of mutable_flag ]; (* added mutable_flag -> make alternative *)
      }
  | Overridden of { longid: Longident.t loc; expr: expression }

type package_type =
  { (* renamed fields -> keep the old field names *)
    pack_path : Path.t;
    pack_fields : (Longident.t loc * core_type) list;
    pack_type : (* updated field type -> make alternative *)
      [
        `Until_550 of Types.module_type;
        `Since_550 of Types.package;
      ]
    pack_txt : Longident.t loc;
  }

type module_expr_desc =
    Tmod_ident of { path: Path.t; longid: Longident.t loc }
  | Tmod_structure of { str: structure }
  | Tmod_functor of { param: functor_parameter; mod_expr: module_expr }
  | Tmod_apply of { ftor: module_expr; arg: module_expr; coercion: module_coercion }
  | Tmod_apply_unit of { ftor: module_expr } (* added constructor *)
  | Tmod_constraint of
      {
        mod_expr: module_expr;
        mod_type: Types.module_type;
        constraint: module_type_constraint;
        coercion: module_coercion;
      }
  | Tmod_unpack of { expr: expression; mod_type: Types.module_type }

type 'a class_infos =
  { ci_virt: virtual_flag;
    ci_params: (core_type * (variance * injectivity)) list;
    ci_id_name : string loc;
    ci_id_class: Ident.t;
    ci_id_class_type : Ident.t;
    ci_id_object : Ident.t;
    ci_id_typehash : [ `Until_510 of Ident.t; `Since_510 ]; (* removed field -> make alternative *)
    ci_expr: 'a;
    ci_decl: Types.class_declaration;
    ci_type_decl : Types.class_type_declaration;
    ci_loc: Location.t;
    ci_attributes: attributes;
  }

type texp_struct_item = (* new type to represent replaced constructors *)
  | Texp_letmodule of
      {
        ident: Ident.t option;
        name: string option loc;
        presence: Types.module_presence;
        mod_expr: module_expr;
      }
  | Texp_letexception of { ext_ctor: extension_constructor }
  | Texp_open of { open_decl: open_declaration }

type expression_desc =
  (* ... *)
  | Texp_struct_item of (* replaces 3 constructors -> available as texp_struct_item *)
      {
        struct_item:
          [
            `Until_550 of texp_struct_item;
            `Since_550 of structure_item;
          ];
        expr: expression;
      }
  (* ... *)

type function_body = (* added type -> keep it *)
  | Tfunction_body of { expr: expression }
  | Tfunction_cases of
      { cases: value case list;
        partial: partial;
        param: Ident.t;
        loc: Location.t;
        exp_extra: exp_extra option;
        attributes: attributes;
      }
```

This definition is heavier than the previous but also stronger. Constructors'
content is labeled, changes are granularly identified (and understandable)
and more uniformly represented. Constraint 4 is still satisfied.\
Like we did with the previous design, let's simulate the dynamics of this
representation.
```diff
 type record_label_definition =
-  | Kept of { type_expr: Types.type_expr }
+  | Kept of
+      {
+        type_expr: Types.type_expr;
+        mut_flag: [ `Until_500; `Since_500 of mutable_flag ]; (* added mutable_flag -> make alternative *)
+      }
   | Overridden of { longid: Longident.t loc; expr: expression }

 type package_type =
   { (* renamed fields -> keep the old field names *)
     pack_path : Path.t;
     pack_fields : (Longident.t loc * core_type) list;
-    pack_type : Types.module_type;
+    pack_type : (* updated field type -> make alternative *)
+      [
+        `Until_550 of Types.module_type;
+        `Since_550 of Types.package;
+      ]
     pack_txt : Longident.t loc;
   }

 type module_expr_desc =
     Tmod_ident of { path: Path.t; longid: Longident.t loc }
   | Tmod_structure of { str: structure }
   | Tmod_functor of { param: functor_parameter; mod_expr: module_expr }
   | Tmod_apply of { ftor: module_expr; arg: module_expr; coercion: module_coercion }
+  | Tmod_apply_unit of { ftor: module_expr } (* added constructor *)
   | Tmod_constraint of
       {
         mod_expr: module_expr;
         mod_type: Types.module_type;
         constraint: module_type_constraint;
         coercion: module_coercion;
       }
   | Tmod_unpack of { expr: expression; mod_type: Types.module_type }

 type 'a class_infos =
   { ci_virt: virtual_flag;
     ci_params: (core_type * (variance * injectivity)) list;
     ci_id_name : string loc;
     ci_id_class: Ident.t;
     ci_id_class_type : Ident.t;
     ci_id_object : Ident.t;
-    ci_id_typehash : Ident.t; (* removed field -> make alternative *)
+    ci_id_typehash : [ `Until_510 of Ident.t; `Since_510 ]; (* removed field -> make alternative *)
     ci_expr: 'a;
     ci_decl: Types.class_declaration;
     ci_type_decl : Types.class_type_declaration;
     ci_loc: Location.t;
     ci_attributes: attributes;
   }

+type texp_struct_item = (* new type to represent replaced constructors *)
+  | Texp_letmodule of
+      {
+        ident: Ident.t option;
+        name: string option loc;
+        presence: Types.module_presence;
+        mod_expr: module_expr;
+      }
+  | Texp_letexception of { ext_ctor: extension_constructor }
+  | Texp_open of { open_decl: open_declaration }
+
 type expression_desc =
   (* ... *)
-  | Texp_letmodule of
-      {
-        ident: Ident.t option;
-        name: string option loc;
-        presence: Types.module_presence;
-        mod_expr: module_expr;
-        expr: expression;
-      }
-  | Texp_letexception of { ext_ctor: extension_constructor; expr: expression }
-  | Texp_open of { open_decl: open_declaration; expr: expression }
+  | Texp_struct_item of (* replaces 3 constructors -> available as texp_struct_item *)
+      {
+        struct_item:
+          [
+            `Until_550 of texp_struct_item;
+            `Since_550 of structure_item;
+          ];
+        expr: expression;
+      }
   (* ... *)

+type function_body = (* added type -> keep it *)
+  | Tfunction_body of { expr: expression }
+  | Tfunction_cases of
+      { cases: value case list;
+        partial: partial;
+        param: Ident.t;
+        loc: Location.t;
+        exp_extra: exp_extra option;
+        attributes: attributes;
+      }
```

The diff is a little bit more involved than in the previous iteration but mostly
because the representation is more complete.\
The result is that if some code matchied on `Kept {type_expr}` before OCaml 5.0,
then it would still compile in OCaml 5.0, and the compiler would issue a
warning 9 (`[missing-record-field-pattern] Missing fields in a record pattern`)
if enabled, so it is up to the user to decide if the new field matters to them;
whereas code matching on `Texp_letmodule _` would not compile anymore and the
user would need to take into account its new representation to be compatible
with OCaml 5.5.

I think this iteration offers a better compromise on constraint 5 than the
previous one: the interface is broken only if the upstream representation
removes information (replacements can be seen as a deletion and an addition),
and the breakage only impacts code that relied on the impacted information. As a
comparison, when using the compiler's Typedtree, one's code would also break if
they matched on `Kept type_expr` before OCaml 5.5.

We fixed most of the pitfalls of the previous iteration but one: the use of
polymorphic variants. Using them gives a lot of flexibility, especially when an
update both deletes information somewhere and add information somewhere else,
like in OCaml 5.1, where `Texp_assert` gets an additional parameter while field
`class_infos.ci_id_typehash` is removed. For the former, Vaast can use
``[`Until_510 | `Since_510 of Location.t]`` for its new parameter's type, while
for the latter it would use ``[`Until_510 Ident.t | `Since_510]``. Notice the
parameter-less constructors that exactly reflect the absence of value
until/since the specified version. If we were not using polymorphic variants,
then the constructors would need to always have the same arity, forcing them
to hold a value (e.g. unit or a dedicated one) when there is none in the
corresponding Typedtree. On the other hand, using regular variants would have
the benefit of simlplifying the type description, strengthening the API, improve
the performance of non-empty constructors and unify the performance in-between
compiler versions.\
This lead us to the next iteration.

### Design 1.2

As explained above, the flexibility of polymorphic variants is beneficial but
using regular variants would provide more uniform and better performances
accross OCaml versions, in addition to improving the type discipline of the API.

I suggest that for each version update a new type is devised:
```OCaml
(* with XXX the version number *)
type ('until, 'since) ocaml_XXX =
  | Until_XXX of 'until (* type until XXX excluded *)
  | Since_XXX of 'since (* type since XXX included *)
```
and that a specific type is defined to represent the non-existence:
```OCaml
type not_available = NA
```

The rest of the design is the same as the previous iteration. Thus, this
iteration fits the constraints in the same way, with a slight improvement
regarding contraint 2.\
Here is what our example now looks like:
```OCaml
type not_available = NA

type ('until, 'since) ocaml_500 =
  | Until_500 of 'until (* type until 500 excluded *)
  | Since_500 of 'since (* type since 500 included *)

type ('until, 'since) ocaml_510 =
  | Until_510 of 'until (* type until 510 excluded *)
  | Since_510 of 'since (* type since 510 included *)

type ('until, 'since) ocaml_550 =
  | Until_550 of 'until (* type until 550 excluded *)
  | Since_550 of 'since (* type since 550 included *)

type record_label_definition =
  | Kept of
      {
        type_expr: Types.type_expr;
        mut_flag: (not_available, mutable_flag) ocaml_500; (* added mutable_flag -> make alternative *)
      }
  | Overridden of { longid: Longident.t loc; expr: expression }

type package_type =
  { (* renamed fields -> keep the old field names *)
    pack_path : Path.t;
    pack_fields : (Longident.t loc * core_type) list;
    pack_type : (Types.module_type, Types.package) ocaml_550; (* updated field type -> make alternative *)
    pack_txt : Longident.t loc;
  }

type module_expr_desc =
    Tmod_ident of { path: Path.t; longid: Longident.t loc }
  | Tmod_structure of { str: structure }
  | Tmod_functor of { param: functor_parameter; mod_expr: module_expr }
  | Tmod_apply of { ftor: module_expr; arg: module_expr; coercion: module_coercion }
  | Tmod_apply_unit of { ftor: module_expr } (* added constructor *)
  | Tmod_constraint of
      {
        mod_expr: module_expr;
        mod_type: Types.module_type;
        constraint: module_type_constraint;
        coercion: module_coercion;
      }
  | Tmod_unpack of { expr: expression; mod_type: Types.module_type }

type 'a class_infos =
  { ci_virt: virtual_flag;
    ci_params: (core_type * (variance * injectivity)) list;
    ci_id_name : string loc;
    ci_id_class: Ident.t;
    ci_id_class_type : Ident.t;
    ci_id_object : Ident.t;
    ci_id_typehash : (Ident.t, not_available) ocaml_510; (* removed field -> make alternative *)
    ci_expr: 'a;
    ci_decl: Types.class_declaration;
    ci_type_decl : Types.class_type_declaration;
    ci_loc: Location.t;
    ci_attributes: attributes;
  }

type texp_struct_item = (* new type to represent replaced constructors *)
  | Texp_letmodule of
      {
        ident: Ident.t option;
        name: string option loc;
        presence: Types.module_presence;
        mod_expr: module_expr;
      }
  | Texp_letexception of { ext_ctor: extension_constructor }
  | Texp_open of { open_decl: open_declaration }

type expression_desc =
  (* ... *)
  | Texp_struct_item of (* replaces 3 constructors -> available as texp_struct_item *)
      {
        struct_item: (texp_struct_item, structure_item) ocaml_550;
        expr: expression;
      }
  (* ... *)

type function_body = (* added type -> keep it *)
  | Tfunction_body of { expr: expression }
  | Tfunction_cases of
      { cases: value case list;
        partial: partial;
        param: Ident.t;
        loc: Location.t;
        exp_extra: exp_extra option;
        attributes: attributes;
      }
```

Although there are more type definitions, the overall example is a bit lighter
than in the previous iteration.\
We can also simulate how the representation would have evolved in time:
```diff
 type not_available = NA

+type ('until, 'since) ocaml_500 =
+  | Until_500 of 'until (* type until 500 excluded *)
+  | Since_500 of 'since (* type since 500 included *)
+
+type ('until, 'since) ocaml_510 =
+  | Until_510 of 'until (* type until 510 excluded *)
+  | Since_510 of 'since (* type since 510 included *)
+
+type ('until, 'since) ocaml_550 =
+  | Until_550 of 'until (* type until 550 excluded *)
+  | Since_550 of 'since (* type since 550 included *)
+
 type record_label_definition =
-  | Kept of { type_expr: Types.type_expr }
+  | Kept of
+      {
+        type_expr: Types.type_expr;
+        mut_flag: (not_available, mutable_flag) ocaml_500; (* added mutable_flag -> make alternative *)
+      }
   | Overridden of { longid: Longident.t loc; expr: expression }

 type package_type =
   { (* renamed fields -> keep the old field names *)
     pack_path : Path.t;
     pack_fields : (Longident.t loc * core_type) list;
-    pack_type : Types.module_type;
+    pack_type : (Types.module_type, Types.package) ocaml_550; (* updated field type -> make alternative *)
     pack_txt : Longident.t loc;
   }

 type module_expr_desc =
     Tmod_ident of { path: Path.t; longid: Longident.t loc }
   | Tmod_structure of { str: structure }
   | Tmod_functor of { param: functor_parameter; mod_expr: module_expr }
   | Tmod_apply of { ftor: module_expr; arg: module_expr; coercion: module_coercion }
+  | Tmod_apply_unit of { ftor: module_expr } (* added constructor *)
   | Tmod_constraint of
       {
         mod_expr: module_expr;
         mod_type: Types.module_type;
         constraint: module_type_constraint;
         coercion: module_coercion;
       }
   | Tmod_unpack of { expr: expression; mod_type: Types.module_type }

 type 'a class_infos =
   { ci_virt: virtual_flag;
     ci_params: (core_type * (variance * injectivity)) list;
     ci_id_name : string loc;
     ci_id_class: Ident.t;
     ci_id_class_type : Ident.t;
     ci_id_object : Ident.t;
-    ci_id_typehash : Ident.t; (* removed field -> make alternative *)
+    ci_id_typehash : (Ident.t, not_available) ocaml_510; (* removed field -> make alternative *)
     ci_expr: 'a;
     ci_decl: Types.class_declaration;
     ci_type_decl : Types.class_type_declaration;
     ci_loc: Location.t;
     ci_attributes: attributes;
   }

+type texp_struct_item = (* new type to represent replaced constructors *)
+  | Texp_letmodule of
+      {
+        ident: Ident.t option;
+        name: string option loc;
+        presence: Types.module_presence;
+        mod_expr: module_expr;
+      }
+  | Texp_letexception of { ext_ctor: extension_constructor }
+  | Texp_open of { open_decl: open_declaration }
+
 type expression_desc =
   (* ... *)
-  | Texp_letmodule of
-      {
-        ident: Ident.t option;
-        name: string option loc;
-        presence: Types.module_presence;
-        mod_expr: module_expr;
-        expr: expression;
-      }
-  | Texp_letexception of { ext_ctor: extension_constructor; expr: expression }
-  | Texp_open of { open_decl: open_declaration; expr: expression }
+  | Texp_struct_item of (* replaces 3 constructors -> available as texp_struct_item *)
+      {
+        struct_item: (texp_struct_item, structure_item) ocaml_550;
+        expr: expression;
+      }
   (* ... *)

+type function_body = (* added type -> keep it *)
+  | Tfunction_body of { expr: expression }
+  | Tfunction_cases of
+      { cases: value case list;
+        partial: partial;
+        param: Ident.t;
+        loc: Location.t;
+        exp_extra: exp_extra option;
+        attributes: attributes;
+      }
```

Again, the diff is lighter than in the previous iteration.
I like this design but it can still be improved in 2 ways: first we could try
and use a single GADT instead of the `ocaml_XXX` types, second we only looked
at the shape of the Typedtree and did not look into providing a functional API
to absorb more breakage when possible. I'll leave the GADT for later because I
don't really see any immediate benefit in using it in the context.\
Regarding the functional interface, I see it make sense in contexts where the
type representation would break but a user might not actually care about the
change. An example of this is the evolution of the tuples representation in
OCaml 5.4. With the new labeled tuple feature, the `Texp_tuple`'s list
parameter's content changed. It now contains `(string option * expression)`
tuples instead of only `expression`s. Given our design, this constructor would
be represented as:
```OCaml
| Texp_tuple of (expression, (string opt * expression)) ocaml_540 list
```
<div class="alert-note">

> An alternative representation could be:
>   ```OCaml
>   | Texp_tuple of (expression list, (string opt * expression) list) ocaml_540
>   ```
> The chosen one is closer to the actual semantic change, more fine
> grained and would be easier to adapt to in user code (e.g. no breakage if it
> does not manipulate the content of the list).
> The alternative would result in less wrapping (only the list vs each element),
> thus have less impact on performance and user code. Because tuples are usually
> small, the impact might be negligible.
</div>

With this representation, code that used to match on `Texp_tuple`, iterate on
its list and do not care about the labels would stop compiling after the update.
This is a negative impact. To compensate, the functional API could provide two
functions to convert to a specific representation of the list:
```OCaml
val without_labels:
  (expression, (string opt * expression)) ocaml_540 list -> expression list

val with_labels:
  (expression, (string opt * expression)) ocaml_540 list -> (string opt * expression) list
```
These functions would make the fix in user code more lightweight than by hand.\
To generalize from this example, I don't think we want to pre-emptively provide
accessor functions for constructors, but that functions would appear on a
by-need basis (like here), and faicilitate maintenance on the user side without
trying to eliminate it. I'd argue that as user, it is important to be aware of
changes in manipulated data, and compiler warnings and errors are excellent
to point them out.
