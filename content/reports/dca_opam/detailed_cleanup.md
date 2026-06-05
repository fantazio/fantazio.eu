---
title: Dead code analyzing opam - Detailed cleanup
description: This report describes the cleanup of opam using the dead_code_analyzer.
date: 2026-06-04
tags: [dead_code_analyzer, opam, ocaml, static analysis, dead code, ocaml software foundation]
---
This is part of [the study report of using the analyzer on opam](./).

## Table of content
- [src/client](#srcclient)
- [src/core](#srccore)
- [src/format](#srcformat)
- [src/solver](#srcsolver)
- [src/state](#srcstate)
- [src/tools](#srctools)

For each component, we will first give a quick description of the component and
its findings, then we will describe the aggressive cleanup phase, followed by
the informed cleanup. Finally, we will conclude on the results of the cleanups.

To avoid redundancy, the first phase will be focused on the actual cleanup
actions, while the second will discuss contextualization and indicate which
findings are actually considered for cleanup and which are discarded.\
If you are interested in the audit of opam, you might want to skip the
aggressive cleanup sections.

<div class="alert-caution" style='--alert-title: "Important"'>

> During the informed cleanup, some projects have been discarded from the
> research for uses outside opam. This is because they are archived or have not
> been active for years.\
> One such project escaped the filter because a user recently interacted with it:
> [opam-bundle](https://github.com/AltGr/opam-bundle).
>
> The following projects have been discarded:
> [marracheck](https://github.com/Armael/marracheck/),
> [opamfu](https://github.com/ocamllabs/opamfu),
> [opam-build-revdeps](https://github.com/gildor478/opam-build-revdeps),
> [opam-lock](https://github.com/AltGr/opam-lock),
> [opam-package-upgrade](https://github.com/AltGr/opam-package-upgrade).
</div>

<div class="alert-tip">

> During the aggressive cleanup, some compiler warnings will be reported as errors.
> More specifically, we will encounter warnings 16, 27, 32, 33, 34, 37, and 60.\
> The obtain a list and short description of available compiler warnings, use
> `ocamlopt -warn-help`.
>
> The warnings appear as errors because of dune's default configuration.
> They can be kept as warnings by using the `--profile=release` flag.
</div>

<div class="alert-note">

> The warning 70 below, triggered when building, will be ignored for the
> remaining of this report:
>   ```bash
>   $ dune build @check
>   File "src/tools/opam_admin_topstart.ml", line 1:
>   Warning 70 [missing-mli]: Cannot find interface file.
>   ```
</div>

## <li>src/client</li>

### Description

This component is distributed as the package
[`opam-client`](https://ocaml.org/p/opam-client/2.5.1), and has
[7 reverse package dependencies](https://ocaml.org/p/opam-client/2.5.1#used-by).\
It is described in
[opam/CONTRIBUTING.md#layout](https://github.com/ocaml/opam/blob/2.5.1/CONTRIBUTING.md#layout)
as:
<div class="alert-cite">

> where the entry point for the opam binary and all the code handling all the opam subcommands is.
</div>


There are 34 unused values, 1 unused constructor and 1 unused field
reported by the `dead_code_analyzer`for this component.

### Aggressive cleanup

#### Unused exported values

Applying steps 1 and 2 of the cleanup methodology for
[unused exported values](./#cleaning-up-unused-exported-values) is trivial.\
Applying step 3 triggered 10 warnings 32 (reported as errors).
<details><summary>build output</summary>

```bash
$ dune build @check
File "src/client/opamClientConfig.ml", line 207, characters 4-16:
207 | let search_files = ["findlib"]
          ^^^^^^^^^^^^
Error (warning 32 [unused-value-declaration]): unused value search_files.

File "src/client/opamListCommand.ml", line 32, characters 4-30:
32 | let default_dependency_toggles = {
         ^^^^^^^^^^^^^^^^^^^^^^^^^^
Error (warning 32 [unused-value-declaration]): unused value default_dependency_toggles.

File "src/client/opamArg.ml", line 1208, characters 4-13:
1208 | let name_list =
           ^^^^^^^^^
Error (warning 32 [unused-value-declaration]): unused value name_list.

File "src/client/opamArg.ml", line 1211, characters 4-13:
1211 | let atom_list =
           ^^^^^^^^^
Error (warning 32 [unused-value-declaration]): unused value atom_list.

File "src/client/opamArg.ml", line 1233, characters 4-22:
1233 | let nonempty_atom_list =
           ^^^^^^^^^^^^^^^^^^
Error (warning 32 [unused-value-declaration]): unused value nonempty_atom_list.

File "src/client/opamArg.ml", line 1239, characters 4-14:
1239 | let param_list =
           ^^^^^^^^^^
Error (warning 32 [unused-value-declaration]): unused value param_list.

File "src/client/opamConfigCommand.ml", line 526, characters 4-15:
526 | let parse_whole fv =
          ^^^^^^^^^^^
Error (warning 32 [unused-value-declaration]): unused value parse_whole.

File "src/client/opamSolution.ml", line 117, characters 4-7:
117 | let sum stats =
          ^^^
Error (warning 32 [unused-value-declaration]): unused value sum.
```
</details>

<a id="anchor_warning_fix_methodology"></a>
Fixing a warning 32 is the same as cleaning up a an unused value:
1. go to the reported location,
2. remove the element (along with its associated attributes and comments)

After cleaning up the warnings 32, the build works without error.

We are done with the unused exported values.

#### Unused constructors and fields

Applying steps 1 and 2 of the general cleanup methodology for
[unused constructors and fields](./#cleaning-up-unused-constructors-and-fields)
is trivial.\
Applying the steps 3 and 4 leads to:
-  2 build and fix iterations to finish the cleanup of the field `pattern_selector.ext_fields`.
    <details><summary>build output</summary>

    ```bash
    $ dune build @check
    File "src/client/opamListCommand.ml", line 1:
    Error: The implementation src/client/opamListCommand.ml
           does not match the interface src/client/opamListCommand.mli:
           Type declarations do not match:
             type pattern_selector = {
               case_sensitive : bool;
               exact : bool;
               glob : bool;
               fields : string list;
               ext_fields : bool;
             }
           is not included in
             type pattern_selector = {
               case_sensitive : bool;
               exact : bool;
               glob : bool;
               fields : string list;
             }
           An extra field, ext_fields, is provided in the first declaration.
           File "src/client/opamListCommand.mli", lines 31-36, characters 0-1:
             Expected declaration
           File "src/client/opamListCommand.ml", lines 32-38, characters 0-1:
             Actual declaration

    $ dune build @check
    File "src/client/opamListCommand.ml", line 44, characters 2-12:
    44 |   ext_fields = false;
           ^^^^^^^^^^
    Error: Unbound record field ext_fields
    ```
    </details>

- 4 build and fix iterations for the cleanup of the constructor `selector.Atoms`.
    <details><summary>build output</summary>

    ```bash
    $ dune build @check
    File "src/client/opamListCommand.ml", line 1:
    Error: The implementation src/client/opamListCommand.ml
           does not match the interface src/client/opamListCommand.mli:
           Type declarations do not match:
             type selector =
                 Any
               | Installed
               | Root
               | Compiler
               | Available
               | Installable
               | Pinned
               | Latests_only
               | Depends_on of dependency_toggles * OpamFormula.atom list
               | Required_by of dependency_toggles * OpamFormula.atom list
               | Conflicts_with of OpamPackage.t list
               | Coinstallable_with of dependency_toggles * OpamPackage.t list
               | Solution of dependency_toggles * OpamFormula.atom list
               | Pattern of pattern_selector * string
               | Atoms of OpamFormula.atom list
               | Flag of OpamTypes.package_flag
               | NotFlag of OpamTypes.package_flag
               | Tag of string
               | From_repository of OpamRepositoryName.t list
               | Owns_file of OpamFilename.t
           is not included in
             type selector =
                 Any
               | Installed
               | Root
               | Compiler
               | Available
               | Installable
               | Pinned
               | Latests_only
               | Depends_on of dependency_toggles * OpamFormula.atom list
               | Required_by of dependency_toggles * OpamFormula.atom list
               | Conflicts_with of OpamPackage.t list
               | Coinstallable_with of dependency_toggles * OpamPackage.t list
               | Solution of dependency_toggles * OpamFormula.atom list
               | Pattern of pattern_selector * string
               | Flag of OpamTypes.package_flag
               | NotFlag of OpamTypes.package_flag
               | Tag of string
               | From_repository of OpamRepositoryName.t list
               | Owns_file of OpamFilename.t
           An extra constructor, Atoms, is provided in the first declaration.
           File "src/client/opamListCommand.mli", lines 41-60, characters 0-25:
             Expected declaration
           File "src/client/opamListCommand.ml", lines 46-66, characters 0-25:
             Actual declaration

    $ dune build @check
    File "src/client/opamListCommand.ml", line 111, characters 4-9:
    111 |   | Atoms atoms ->
              ^^^^^
    Error: This variant pattern is expected to have type selector
           There is no constructor Atoms within type selector

    $ dune build @check
    File "src/client/opamListCommand.ml", line 211, characters 4-9:
    211 |   | Atoms _
              ^^^^^
    Error: This variant pattern is expected to have type selector
           There is no constructor Atoms within type selector

    $ dune build @check
    File "src/client/opamListCommand.ml", line 321, characters 4-9:
    321 |   | Atoms atoms ->
              ^^^^^
    Error: This variant pattern is expected to have type selector
           There is no constructor Atoms within type selector

    ```

The errors can be fixed quite easily:
- for a type mismatch, remove the extra field/constructor;
- for an unbound record field, remove it from the structure;
- for an invalid constructor, remove its branch from the pattern matching.

This simple cleanup took 6 builds in total. This is not ideal but easy to follow
and the builds are fast so it does not incur a big overhead.

We are done with the aggressive cleanup and can move on to the informed cleanup.

### Informed cleanup

This section takes the findings in lexicographical order (often at once in a
single file) and indicates if their cleanup is reasonable or if it should be
undone, along with a short explanation.

- `src/client/opamAction.mli:42: prepare_package_build`: <span class="alert-danger">**undo**</span>\
    I was able to find a use in
    [opam2nix](https://github.com/timbertson/opam2nix/blob/v1/src/invoke.ml#L258),
    thanks to the file's history ([PR #4147](https://github.com/ocaml/opam/pull/4147)).

- `src/client/opamAdminCheck.mli`: <span class="alert-safe">**clean**</span>\
    The reported values were added in the same
    [PR #3253](https://github.com/ocaml/opam/pull/3253) and never used outside
    their compilation units.\
    I did not find any use outside opam of `OpamAdminCheck`.

- `src/client/opamArg.mli`: <span class="alert-safe">**clean**</span>\
    The documentation of the module below leads me to believe the module is
    intended for internal use.\
    Additionally, I did not find any use of the findings outside opam.\
    Finally, I tried to follow the history of `OpamArg.name_list` and it appears
    to have been made redundant by the unexported `OpamCommands.name_list`.
    ```OCaml
    (** Command-line argument parsers and helpers *)
    ```

- `src/client/opamAuxCommands.mli`: <span class="alert-safe">**clean**</span>\
    Based on its documentation and its naming, I assume this module is not
    intended for use outside opam.\
    Additionally, I did not find any use outside opam of `OpamAuxCommands`.

- `src/client/opamCliMain.mli`: <span class="alert-safe">**clean**</span>\
    My understanding of the module `OpamCliMain` is that it is meant for use
    by the binary entry point, not as a library.\
    I did not find any use outside opam, and only 1 use inside opam in
    [`src/client/opamMain.ml`](https://github.com/ocaml/opam/blob/2.5.1/src/client/opamMain.ml#L12).

- `src/client/opamClient.mli`: <span class="alert-safe">**clean**</span>\
    The reported findings' histories show that they have not been used outside
    their compilation units for many years.

- `src/client/opamClientConfig.mli:93: search_files`: <span class="alert-safe">**clean**</span>\
    Although `OpamClientConfig` is used outside opam, I could not find any
    use of `search_files`.\
    Additionally, it has not been used inside opam for a decade.

- `src/client/opamConfigCommand.mli`: <span class="alert-safe">**clean**</span>\
    The documentation of the module below leads me to believe the module is
    intended for internal use.\
    Additionally, I did not find any use of `OpamConfigCommand` outside opam.
    ```OCaml
    (** Functions handling the `opam config` subcommand and configuration actions *)
    ```

- `src/client/opamInitDefaults.mli`: <span class="alert-safe">**clean**</span>\
    The documentation of the module below leads me to believe the module is
    intended for internal use.\
    Additionally, I only found 1 use of `OpamInitDefaults` outside opam, in
    [opam-bundle](https://github.com/AltGr/opam-bundle/blob/master/src/opamBundleMain.ml#L875),
    and it does not concern the findings.
    ```OCaml
    (** This module defines a few defaults, used at 'opam init', that bind opam to
        its default OCaml repository at https://opam.ocaml.org. All can be overridden
        through the init command flags or an init config file. *)
    ```

- `src/client/opamListCommand.mli:31: default_dependency_toggles`: <span class="alert-danger">**undo**</span>\
    I found a use in [opam-bundle](https://github.com/AltGr/opam-bundle/blob/master/src/opamBundleMain.ml#L175).

- `src/client/opamListCommand.mli:38: pattern_selector.ext_fields`:  <span class="alert-safe">**clean**</span>\
  `src/client/opamListCommand.mli:59: selector.Atoms`:  <span class="alert-safe">**clean**</span>\
    The documentation of the module below leads me to believe the module is
    intended for internal use (although there is a use outside opam documented
    above).\
    Additionally, I did not find any use outside opam of these findings.
    ```OCaml
    (** Functions handling the "opam list" subcommand *)
    ```

- `src/client/opamRepositoryCommand.mli`: <span class="alert-safe">**clean**</span>\
    The documentation of the module below leads me to believe the module is
    intended for internal use.\
    Additionally, I only found 1 use of `OpamRepositoryCommand` outside opam,
    in [opam-bundle](https://github.com/AltGr/opam-bundle/blob/master/src/opamBundleMain.ml#L191),
    and it does not concern the finding.
    ```OCaml
    (** Functions handling the "opam repository" subcommand *)
    ```

- `src/client/opamSolution.mli:102: eq_atom`: <span class="alert-safe">**clean**</span>\
    When exploring the finding's history, I was under the impression that its
    package specific version `OpamSolution.eq_atom_of_package` was meant to
    replace it.\
    Additionally, I did not find any use of this value outside opam, but I
    found a use of `eq_atom_of_package` in [opam-bundle](https://github.com/AltGr/opam-bundle/blob/master/src/opamBundleMain.ml#L34).

- `src/client/opamSolution.mli:136: sum`: <span class="alert-safe">**clean**</span>\
    I did not find any use outside opam.\
    According to its history, it exists almost since the origins of opam in
    [2012](https://github.com/ocaml/opam/commit/dd0c0ca284aeb520394acb91d15e01f919ed8b7e).
    I assume it was moved around and forgotten since then.

### Results

The analyzer reported 36 findings in this component:
34 unused values, 1 unused constructor and 1 unused field.\
The aggressive cleanup did not reveal any false positive or limitation.\
The informed cleanup indicates that only 2 findings should not be removed.
They are exported values used outside opam.

From these results, we can compute the precision of the analyzer shown in the
table below. The estimated precision after the informed cleanup can be
extrapolated as the potential fix rate.

| section                 | aggressive | + informed |
|:-----------------------:|:----------:|:----------:|
| exported values         | 100%       | 94.1%      |
| constructors and fields | 100%       | 100%       |
| total                   | 100%       | 94.4%      |

## <li>src/core</li>

### Description

This component is distributed as the package
[`opam-core`](https://ocaml.org/p/opam-core/2.5.1), and has
[7 reverse package dependencies](https://ocaml.org/p/opam-core/2.5.1#used-by).\
It is described in
[opam/CONTRIBUTING.md#layout](https://github.com/ocaml/opam/blob/2.5.1/CONTRIBUTING.md#layout)
as:
<div class="alert-cite">

> where all the lowest level common code used everywhere else is (opam stdlib, IOs, retrocompatibility with older versions of OCaml, code for version handling, …)
</div>

It has 1 subcomponent : `src/core/cmdliner` which defines the sub-library
`opam-core.cmdliner`. According to the [release notes of 2.5.0-beta1](https://github.com/ocaml/opam/releases/tag/2.5.0-beta1):
<div class="alert-cite">

> it is meant for internal use only.
</div>

In total, there are 153 unused values, and 56 unused constructors and fields
reported by the `dead_code_analyzer`for this component.\
Among the findings, 75 values are reported for the subcomponent.\
This is the component with the most findings, and the most unused conconstructors
and fields reported. It is the component with the most unused values reported
if
 we include its subcomponent.
### Aggressive cleanup

#### Unused exported values

Because almost half (75 out of 153, i.e. 49.0%) of the reported values are within the
`src/core/cmdliner` subcomponent, we will clean it first. The intent is to
reduce the workload during step 3 of the cleanup, although it may lead to more
iterations.

Applying steps 1 and 2 of the cleanup methodology for
[unused exported values](./#cleaning-up-unused-exported-values) on the findings in
`src/core/cmdliner` is trivial.\
Applying step 3 did not trigger any new warning or error.
<details><summary>build output</summary>

```bash
$ dune build @check
File "src/tools/opam_admin_topstart.ml", line 1:
Warning 70 [missing-mli]: Cannot find interface file.
```
</details>

The analyzer does not report unused types and modules yet. However, a more thorough cleanup
can be applied as some types (e.g. `Manpage.t`) are only used by unused values
and a module (`Term.Syntax`) is only composed of unused values.

Moving on to the rest of the `src/core` component,  applying steps 1 and 2 is
trivial again.\
However, applying step 3 triggers 1 warning 60, 36 warnings 32 (reported as
errors), and 1 actual error.
<details><summary>build output</summary>

```bash
$ dune build @check
File "src/core/opamVersionCompare.ml", line 142, characters 4-9:
142 | let equal (x : string) (y : string) =
          ^^^^^
Error (warning 32 [unused-value-declaration]): unused value equal.

File "src/core/opamStubs.unix.ml", line 15, characters 4-23:
Error (warning 32 [unused-value-declaration]): unused value getCurrentProcessID.

File "src/core/opamStubs.unix.ml", line 41, characters 4-19:
Error (warning 32 [unused-value-declaration]): unused value getConsoleAlias.

File "src/core/opamCoreConfig.ml", line 166, characters 4-7:
166 | let set t = setk (fun x () -> x) t
          ^^^
Error (warning 32 [unused-value-declaration]): unused value set.

File "src/core/opamVersion.ml", line 43, characters 4-9:
43 | let major v =
         ^^^^^
Error (warning 32 [unused-value-declaration]): unused value major.

File "src/core/opamVersion.ml", line 65, characters 4-11:
65 | let message () =
         ^^^^^^^
Error (warning 32 [unused-value-declaration]): unused value message.

File "src/core/opamHash.ml", line 72, characters 4-10:
72 | let sha256 = make `SHA256
         ^^^^^^
Error (warning 32 [unused-value-declaration]): unused value sha256.

File "src/core/opamDirTrack.ml", line 45, characters 4-13:
45 | let to_string t =
         ^^^^^^^^^
Error (warning 32 [unused-value-declaration]): unused value to_string.

File "src/core/opamProcess.ml", line 972, characters 6-13:
972 |   let seq_map f l =
            ^^^^^^^
Error (warning 32 [unused-value-declaration]): unused value seq_map.

File "src/core/opamSystem.ml", line 633, characters 4-29:
633 | let verbose_for_base_commands () =
          ^^^^^^^^^^^^^^^^^^^^^^^^^
Error (warning 32 [unused-value-declaration]): unused value verbose_for_base_commands.

File "src/core/opamFilename.ml", line 138, characters 4-15:
138 | let to_list_dir dir =
          ^^^^^^^^^^^
Error (warning 32 [unused-value-declaration]): unused value to_list_dir.

File "src/core/opamFilename.ml", line 249, characters 4-21:
249 | let with_open_out_bin [@deprecated] =
          ^^^^^^^^^^^^^^^^^
Error (warning 32 [unused-value-declaration]): unused value with_open_out_bin.

File "src/core/opamFilename.ml", line 273, characters 4-17:
273 | let with_tmp_file fn =
          ^^^^^^^^^^^^^
Error (warning 32 [unused-value-declaration]): unused value with_tmp_file.

File "src/core/opamFilename.ml", line 276, characters 4-21:
276 | let with_tmp_file_job fjob =
          ^^^^^^^^^^^^^^^^^
Error (warning 32 [unused-value-declaration]): unused value with_tmp_file_job.

File "src/core/opamFilename.ml", line 279, characters 4-17:
279 | let with_contents fn filename =
          ^^^^^^^^^^^^^
Error (warning 32 [unused-value-declaration]): unused value with_contents.

File "src/core/opamFilename.ml", line 378, characters 4-11:
378 | let copy_in ?root = process_in ?root copy
          ^^^^^^^
Error (warning 32 [unused-value-declaration]): unused value copy_in.

File "src/core/opamFilename.ml", line 402, characters 4-24:
402 | let extract_generic_file filename dirname =
          ^^^^^^^^^^^^^^^^^^^^
Error (warning 32 [unused-value-declaration]): unused value extract_generic_file.

File "src/core/opamFilename.ml", line 423, characters 4-17:
423 | let remove_suffix suffix filename =
          ^^^^^^^^^^^^^
Error (warning 32 [unused-value-declaration]): unused value remove_suffix.

File "src/core/opamFilename.ml", line 517, characters 4-30:
517 | let with_flock_write_then_read ?dontblock file write read =
          ^^^^^^^^^^^^^^^^^^^^^^^^^^
Error (warning 32 [unused-value-declaration]): unused value with_flock_write_then_read.

File "src/core/opamSystem.ml", line 858, characters 32-47:
858 |   let nproc = Nativeint.to_int (OpamStubs.nproc ()) in
                                      ^^^^^^^^^^^^^^^
Error: Unbound value OpamStubs.nproc

File "src/core/opamParallel.ml", line 488, characters 4-8:
488 | let iter ~jobs ~command ?dry_run l =
          ^^^^
Error (warning 32 [unused-value-declaration]): unused value iter.

File "src/core/opamConsole.ml", line 100, characters 6-40:
100 |   let latin_capital_letter_o_with_stroke = Uchar.of_int 0x00d8
            ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^
Error (warning 32 [unused-value-declaration]): unused value latin_capital_letter_o_with_stroke.

File "src/core/opamStd.ml", line 68, characters 2-49:
68 |   external compare : 't -> 't -> int = "%compare"
       ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^
Error (warning 32 [unused-value-declaration]): unused value compare.

File "src/core/opamStd.ml", line 70, characters 2-44:
70 |   external (=) : 't -> 't -> bool = "%equal"
       ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^
Error (warning 32 [unused-value-declaration]): unused value =.

File "src/core/opamStd.ml", line 71, characters 2-48:
71 |   external (<>) : 't -> 't -> bool = "%notequal"
       ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^
Error (warning 32 [unused-value-declaration]): unused value <>.

File "src/core/opamStd.ml", line 72, characters 2-47:
72 |   external (<) : 't -> 't -> bool = "%lessthan"
       ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^
Error (warning 32 [unused-value-declaration]): unused value <.

File "src/core/opamStd.ml", line 73, characters 2-50:
73 |   external (>) : 't -> 't -> bool = "%greaterthan"
       ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^
Error (warning 32 [unused-value-declaration]): unused value >.

File "src/core/opamStd.ml", line 74, characters 2-49:
74 |   external (<=) : 't -> 't -> bool = "%lessequal"
       ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^
Error (warning 32 [unused-value-declaration]): unused value <=.

File "src/core/opamStd.ml", line 75, characters 2-52:
75 |   external (>=) : 't -> 't -> bool = "%greaterequal"
       ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^
Error (warning 32 [unused-value-declaration]): unused value >=.

File "src/core/opamStd.ml", line 139, characters 6-12:
139 |   let insert comp x l =
            ^^^^^^
Error (warning 32 [unused-value-declaration]): unused value insert.

File "src/core/opamStd.ml", line 185, characters 6-18:
185 |   let update_assoc eq k v l =
            ^^^^^^^^^^^^
Error (warning 32 [unused-value-declaration]): unused value update_assoc.

File "src/core/opamStd.ml", line 424, characters 6-17:
424 |   let default_map dft = function
            ^^^^^^^^^^^
Error (warning 32 [unused-value-declaration]): unused value default_map.

File "src/core/opamStd.ml", line 1337, characters 8-17:
1337 |     let to_string = function
               ^^^^^^^^^
Error (warning 32 [unused-value-declaration]): unused value to_string.

File "src/core/opamStd.ml", line 1344, characters 8-17:
1344 |     let of_string = function
               ^^^^^^^^^
Error (warning 32 [unused-value-declaration]): unused value of_string.

File "src/core/opamStd.ml", lines 1336-1356, characters 2-5:
1336 | ..module RegistryHive = struct
1337 |     let to_string = function
1338 |     | OpamStubs.HKEY_CLASSES_ROOT   -> "HKEY_CLASSES_ROOT"
1339 |     | OpamStubs.HKEY_CURRENT_CONFIG -> "HKEY_CURRENT_CONFIG"
1340 |     | OpamStubs.HKEY_CURRENT_USER   -> "HKEY_CURRENT_USER"
...
1353 |     | "HKU"
1354 |     | "HKEY_USERS"          -> OpamStubs.HKEY_USERS
1355 |     | _                     -> failwith "RegistryHive.of_string"
1356 |   end
Warning 60 [unused-module]: unused module RegistryHive.

File "src/core/opamStd.ml", line 1358, characters 7-21:
1358 |   let (set_parent_pid, parent_putenv) =
              ^^^^^^^^^^^^^^
Error (warning 32 [unused-value-declaration]): unused value set_parent_pid.

File "src/core/opamStd.ml", line 1745, characters 6-18:
1745 |   let resolve_when ~auto = function
             ^^^^^^^^^^^^
Error (warning 32 [unused-value-declaration]): unused value resolve_when.

File "src/core/opamStd.ml", line 1780, characters 8-14:
1780 |     let update v = r := v :: !r
               ^^^^^^
Error (warning 32 [unused-value-declaration]): unused value update.
```
</details>

The error is:
```OCaml-error
File "src/core/opamSystem.ml", line 858, characters 32-47:
858 |   let nproc = Nativeint.to_int (OpamStubs.nproc ()) in
                                      ^^^^^^^^^^^^^^^
Error: Unbound value OpamStubs.nproc
```
The value is actually exported by `OpamStubsType` and included `OpamStubs`.
The latter re-exports the interface of the former, as its own via the following
construct:
```OCaml
include module type of struct include OpamStubsTypes end
```
This is close enough to a
[known limitation](https://github.com/LexiFi/dead_code_analyzer/blob/master/docs/exported_values/EXPORTED_VALUES.md#include-module-type-with-substitution)
so we do not need to document it further.
The following finding is a <span class="alert-danger">false positive</span>:
```dca
/tmp/proj/opam/_build/default/src/core/opamStubsTypes.ml:128: nproc
```

The warning 60 on module `RegistryHive` below appears because I removed it from
`src/core/opamStd.mli`. It was only exporting unused values.
```OCaml-error
File "src/core/opamStd.ml", lines 1336-1356, characters 2-5:
1336 | ..module RegistryHive = struct
1337 |     let to_string = function
1338 |     | OpamStubs.HKEY_CLASSES_ROOT   -> "HKEY_CLASSES_ROOT"
1339 |     | OpamStubs.HKEY_CURRENT_CONFIG -> "HKEY_CURRENT_CONFIG"
1340 |     | OpamStubs.HKEY_CURRENT_USER   -> "HKEY_CURRENT_USER"
...
1353 |     | "HKU"
1354 |     | "HKEY_USERS"          -> OpamStubs.HKEY_USERS
1355 |     | _                     -> failwith "RegistryHive.of_string"
1356 |   end
Warning 60 [unused-module]: unused module RegistryHive.
```

The warnings 60 and 32 can be fixed by following the technique described in [section src/client](#anchor_warning_fix_methodology).

We are done with the unused exported values.

#### Unused constructors and fields

More than half (35 out of 56, i.e. 62.5%) of the findings are located in
`src/core/opamStubsTypes.ml`. However, unlike with unused exported values,
we will try to minimize the amount of re-builds necessary to clean them.
Thus, we will not focus on this file specifically but clean up all the findings
in the directory at once, hoping to get multiple compiler errors reported at
once.

Some of the findings accumulate to whole type definitions (e.g. `Either.t.Left`
and `Either.t.Right` in `src/core/opamCompat.mli`), so we will follow the more
specific cleanup methodology of
[unused constructors and fields](./#cleaning-up-unused-constructors-and-fields)
for those cases.

Applying steps 1 and 2 is trivial.\
Applying step 3 a first time triggers 2 warnings 37 (reported as errors) and
6 errors.
<details><summary>build output</summary>

```bash
$ dune build @check
File "src/core/opamCompat.ml", line 75, characters 4-16:
75 |     | Left of 'a
         ^^^^^^^^^^^^
Error (warning 37 [unused-constructor]): constructor Left is never used to build values.
Its type is exported as a private type.

File "src/core/opamCompat.ml", line 76, characters 4-17:
76 |     | Right of 'b
         ^^^^^^^^^^^^^
Error (warning 37 [unused-constructor]): constructor Right is never used to build values.
Its type is exported as a private type.

File "src/core/opamStubs.ml", line 1:
Error: The implementation src/core/opamStubs.ml
       does not match the interface src/core/opamStubs.mli:
       Type declarations do not match:
         type uname =
           OpamStubsTypes.uname = private {
           sysname : string;
           release : string;
           machine : string;
         }
       is not included in
         type uname = {
           sysname : string;
           release : string;
           machine : string;
         }
       A private record constructor would be revealed.
       File "src/core/opamStubs.mli", lines 166-170, characters 0-1:
         Expected declaration
       File "src/core/opamStubsTypes.ml", lines 85-89, characters 0-1:
         Actual declaration

File "src/core/opamConsole.ml", line 43, characters 6-12:
43 |     | Darwin -> true
           ^^^^^^
Error: This variant pattern is expected to have type OpamStd.Sys.os
       There is no constructor Darwin within type OpamStd.Sys.os

File "src/core/opamProcess.ml", line 470, characters 4-10:
470 |     p_info   = info_file;
          ^^^^^^
Error: Unbound record field p_info

File "src/core/opamStd.ml", line 1:
Error: The implementation src/core/opamStd.ml
       does not match the interface src/core/opamStd.mli:  ... In module Sys:
       Type declarations do not match:
         type os =
           Sys.os =
             Darwin
           | Linux
           | FreeBSD
           | OpenBSD
           | NetBSD
           | DragonFly
           | Cygwin
           | Win32
           | Unix
           | Other of string
       is not included in
         type os = Cygwin | Win32
       1. An extra constructor, Darwin, is provided in the first declaration.
       2. An extra constructor, Linux, is provided in the first declaration.
       3. An extra constructor, FreeBSD, is provided in the first declaration.
       4. An extra constructor, OpenBSD, is provided in the first declaration.
       5. An extra constructor, NetBSD, is provided in the first declaration.
       6. An extra constructor, DragonFly, is provided in the first declaration.
       9. An extra constructor, Unix, is provided in the first declaration.
       10. An extra constructor, Other, is provided in the first declaration.
       File "src/core/opamStd.mli", lines 454-455, characters 2-17:
         Expected declaration
       File "src/core/opamStd.ml", lines 880-890, characters 2-21:
         Actual declaration

File "src/core/opamSystem.ml", line 934, characters 6-25:
934 |     | OpamStd.Sys.OpenBSD -> "gtar"
            ^^^^^^^^^^^^^^^^^^^
Error: Unbound constructor OpamStd.Sys.OpenBSD

File "src/format/opamTypes.mli", lines 22-24, characters 0-15:
22 | type ('a, 'b) either = ('a, 'b) OpamCompat.Either.t =
23 |   | Left of 'a
24 |   | Right of 'b
Error: This variant or record definition does not match that of type
         ('a, 'b) OpamCompat.Either.t
       Private variant constructor(s) would be revealed.
```
</details>

There are different kinds of errors reported.
1.  The first one is the warning 37.\
    It indicates the constructor is never constructed. This is expected to happen.
    Because we exported the type as `private`, its constructors can only be
    used to build values inside its compilation unit. Thus, the compiler can
    check if they are used in their compilation unit and report them if not.\
    This is solved by removing the unused constructor.

2.  The second kind is a type definition mismatch between the interface
    and the implementation.\
    This is also expected to happen and is solved by updating the `.ml` to match
    the `.mli`.

3.  The third kind is an unbound constructor or record field.\
    Again, this is expected to happen and is solved by removing the
    corresponding code.

4.  The fourth and last kind of error we can observe is a type mismatch, like the second kind.\
    However, this one is due to broken type equations. We will explore them in
    more details.

After only a couple iterations of step 3 we get stuck on the complicated cases.
<details><summary>build output</summary>

```bash
$ dune build @check
File "src/format/opamTypes.mli", lines 22-24, characters 0-15:
22 | type ('a, 'b) either = ('a, 'b) OpamCompat.Either.t =
23 |   | Left of 'a
24 |   | Right of 'b
Error: This variant or record definition does not match that of type
         ('a, 'b) OpamCompat.Either.t
       Private variant constructor(s) would be revealed.
File "src/core/opamCompat.ml", line 75, characters 4-16:
75 |     | Left of 'a
         ^^^^^^^^^^^^
Error (warning 37 [unused-constructor]): constructor Left is never used to build values.
Its type is exported as a private type.

File "src/core/opamCompat.ml", line 76, characters 4-17:
76 |     | Right of 'b
         ^^^^^^^^^^^^^
Error (warning 37 [unused-constructor]): constructor Right is never used to build values.
Its type is exported as a private type.
File "src/core/opamConsole.ml", line 1106, characters 35-44:
1106 |   OpamStd.Sys.(set_warning_printer {warning})
                                          ^^^^^^^^^
Error: Cannot create values of the private type warning_printer

File "src/core/opamStd.ml", line 1:
Error: The implementation src/core/opamStd.ml
       does not match the interface src/core/opamStd.mli:  ... In module Sys:
       Type declarations do not match:
         type os =
           Sys.os =
             Darwin
           | Linux
           | FreeBSD
           | OpenBSD
           | NetBSD
           | DragonFly
           | Cygwin
           | Win32
           | Unix
           | Other of string
       is not included in
         type os = Cygwin | Win32
       1. An extra constructor, Darwin, is provided in the first declaration.
       2. An extra constructor, Linux, is provided in the first declaration.
       3. An extra constructor, FreeBSD, is provided in the first declaration.
       4. An extra constructor, OpenBSD, is provided in the first declaration.
       5. An extra constructor, NetBSD, is provided in the first declaration.
       6. An extra constructor, DragonFly, is provided in the first declaration.
       9. An extra constructor, Unix, is provided in the first declaration.
       10. An extra constructor, Other, is provided in the first declaration.
       File "src/core/opamStd.mli", lines 454-455, characters 2-17:
         Expected declaration
       File "src/core/opamStd.ml", lines 880-890, characters 2-21:
         Actual declaration
```
</details>

Let's look at the invalid type equation at the top first:
```OCaml-error
File "src/format/opamTypes.mli", lines 22-24, characters 0-15:
22 | type ('a, 'b) either = ('a, 'b) OpamCompat.Either.t =
23 |   | Left of 'a
24 |   | Right of 'b
Error: This variant or record definition does not match that of type
         ('a, 'b) OpamCompat.Either.t
       Private variant constructor(s) would be revealed.
File "src/core/opamCompat.ml", line 75, characters 4-16:
75 |     | Left of 'a
         ^^^^^^^^^^^^
Error (warning 37 [unused-constructor]): constructor Left is never used to build values.
Its type is exported as a private type.

File "src/core/opamCompat.ml", line 76, characters 4-17:
76 |     | Right of 'b
         ^^^^^^^^^^^^^
Error (warning 37 [unused-constructor]): constructor Right is never used to build values.
Its type is exported as a private type.
```
Here we have 2 kinds of errors: an invalid type equation and warnings 37.\
I did not clean these warnings because they are directly connected to the error.

To fix the invalid type equation we could make `OpamTypes.either` private, like
`OpamCompat.Either.t`. This would leave us with unfixable warnings. This dead-end
might be a sign that we hit a limitation of the analyzer and found false
positives.
<div class="alert-note">

> The warnings could actually be fixed by making the type private within
> `src/core/opamCompat.ml`, which would make it impossible to build any value of
> this type. There may be situations were this makes sense but the current one
> is not.
</div>

Alternatively, we could choose to fix the warnings first by making the type
abstract in `src/core/opamCompat.ml`.
Because we updated the type in the `.ml`, the compiler will complain about a
type mismatch, and we need to update the `.mli` to reflect the change.\
With the type abstract in both the interface and the implementation,
the warnings are gone, and the invalid type equation changed to:
```OCaml-error
File "src/format/opamTypes.mli", lines 22-24, characters 0-15:
22 | type ('a, 'b) either = ('a, 'b) OpamCompat.Either.t =
23 |   | Left of 'a
24 |   | Right of 'b
Error: This variant or record definition does not match that of type
         ('a, 'b) OpamCompat.Either.t
       The original is abstract, but this is a variant.
```
We can fix it by making `OpamTypes.either` abstract as well. This unveils a new
invalid type equation:
```OCaml-error
File "src/format/opamTypes.mli", line 320, characters 0-81:
320 | type powershell_host = OpamStd.Sys.powershell_host = Powershell_pwsh | Powershell
      ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^
Error: This variant or record definition does not match that of type
         OpamStd.Sys.powershell_host
       Private variant constructor(s) would be revealed.
```
The situation is similar to our original case but there is no warning 37 to
indicate that the constructors are not used within their compilation units.
This time, we can simply make `OpamTypes.powershell_host` private to satisfy the
equation.\
This unveils yet another invalid equation which can be solved by making the new
type private as well:
```OCaml-error
File "src/format/opamTypes.mli", lines 321-323, characters 0-10:
321 | type shell = OpamStd.Sys.shell =
322 |   | SH_sh | SH_bash | SH_zsh | SH_csh | SH_fish | SH_pwsh of powershell_host
323 |   | SH_cmd
Error: This variant or record definition does not match that of type
         OpamStd.Sys.shell
       Private variant constructor(s) would be revealed.
```

With all the invalid type equations resolved, the compiler is now able to report
more errors. In particular, the 2 following errors tell use that constructors
`Left` and `Right` are actually used to build values:
```OCaml-error
File "src/client/opamAction.ml", line 1062, characters 32-37:
1062 |     | Some (_, result) -> Done (Right (OpamSystem.Process_error result))
                                       ^^^^^
Error: Unbound constructor Right

File "src/client/opamCommands.ml", line 439, characters 31-35:
439 |       | Some d, false -> Some (Left d)
                                     ^^^^
Error: Unbound constructor Left
```
As we suspected in our initial attempt to fix the invalid type equation on
`OpamTypes.either`, we hit a limitation of the analyzer. Even better, we hit an
[undocumented limitation](https://github.com/fantazio/dead_code_analyzer/blob/master/docs/fields_and_constructors/FIELDS_AND_CONSTRUCTORS.md#limitations)
so we can open an [issue](https://github.com/LexiFi/dead_code_analyzer/issues/79)
to report it.\
We can conclude that the following findings are <span class="alert-danger">false positives</span>:
```dca
/tmp/proj/opam/src/core/opamCompat.mli:36: Either.t.Left
/tmp/proj/opam/src/core/opamCompat.mli:37: Either.t.Right
```

Among the new compilation errors there is also an error telling us that the
constructor `SH_bash` is used:
```OCaml-error
File "src/client/opamArg.ml", line 1149, characters 16-23:
1149 |     None,"bash",SH_bash;
                       ^^^^^^^
Error: Cannot create values of the private type shell
```
We are hitting the same limitation as with `OpamTypes.either`, and can conclude
that the following findings are also <span class="alert-danger">false positives</span>:
```dca
/tmp/proj/opam/src/core/opamStd.mli:506: Sys.shell.SH_sh
/tmp/proj/opam/src/core/opamStd.mli:506: Sys.shell.SH_bash
/tmp/proj/opam/src/core/opamStd.mli:506: Sys.shell.SH_zsh
/tmp/proj/opam/src/core/opamStd.mli:506: Sys.shell.SH_csh
/tmp/proj/opam/src/core/opamStd.mli:506: Sys.shell.SH_fish
/tmp/proj/opam/src/core/opamStd.mli:507: Sys.shell.SH_pwsh
/tmp/proj/opam/src/core/opamStd.mli:507: Sys.shell.SH_cmd
```

Finally, after re-building the project, an new error tells us that the constructor `Powershell_pwsh` is used:
```OCaml-error
File "src/client/opamArg.ml", line 1154, characters 31-46:
1154 |     Some cli2_2,"pwsh",SH_pwsh Powershell_pwsh;
                                      ^^^^^^^^^^^^^^^
Error: Cannot create values of the private type powershell_host
```
Once again, we are hitting the same limitation, and can conclude the following
findings are <span class="alert-danger">false positives</span>:
```dca
/tmp/proj/opam/src/core/opamStd.mli:505: Sys.powershell_host.Powershell_pwsh
/tmp/proj/opam/src/core/opamStd.mli:505: Sys.powershell_host.Powershell
```

Now that we explored the 1st error and identified false positives, we can come
back to our original build errors and move on to the next one:
```OCaml-error
File "src/core/opamConsole.ml", line 1106, characters 35-44:
1106 |   OpamStd.Sys.(set_warning_printer {warning})
                                          ^^^^^^^^^
Error: Cannot create values of the private type warning_printer
```
The analyzer reported `Sys.warning_printer.warning` as unused. This means that
it is never read. Because this is the only field in its type, we made the type
private. Hence the error when creating a value of that type from outside its
compilation unit.\
Although the error is not surprising, the associated function is telling us
something. `OpamStd.Sys.set_warning_printer` has type `warning_printer -> unit`.
This indicates that it must be storing the argument somewhere as a side effect.
By looking at its definition, it does store it in a variable named `console`:
```OCaml
  let set_warning_printer =
    let called = ref false in
    fun printer ->
      if !called then invalid_arg "Just what do you think you're doing, Dave?";
      called := true;
      console := printer
```
`console` is an unexported value of type `warning_printer` and if we look at its
uses, its `warning` field is actually read a couple times.

The issue here is that the type `warning_printer` is defined twice in
`src/core/opamStd.ml`: once before the definition of `console` and another
before the definition of `set_warning_printer` with a type equation indicating
that the 2 are equal.\
Thus, we are facing a situation similar to the previous type equation where the
analyzer did not associate uses to its type. We can open another
[issue](https://github.com/LexiFi/dead_code_analyzer/issues/80) to report this
limitation, and conclude that the following finding is a
<span class="alert-danger">false positive</span>:
```dca
/tmp/proj/opam/src/core/opamStd.mli:613: Sys.warning_printer.warning
```

Finally, the last of our errors in the build output is:
```OCaml-error
File "src/core/opamStd.ml", line 1:
Error: The implementation src/core/opamStd.ml
       does not match the interface src/core/opamStd.mli:  ... In module Sys:
       Type declarations do not match:
         type os =
           Sys.os =
             Darwin
           | Linux
           | FreeBSD
           | OpenBSD
           | NetBSD
           | DragonFly
           | Cygwin
           | Win32
           | Unix
           | Other of string
       is not included in
         type os = Cygwin | Win32
       1. An extra constructor, Darwin, is provided in the first declaration.
       2. An extra constructor, Linux, is provided in the first declaration.
       3. An extra constructor, FreeBSD, is provided in the first declaration.
       4. An extra constructor, OpenBSD, is provided in the first declaration.
       5. An extra constructor, NetBSD, is provided in the first declaration.
       6. An extra constructor, DragonFly, is provided in the first declaration.
       9. An extra constructor, Unix, is provided in the first declaration.
       10. An extra constructor, Other, is provided in the first declaration.
       File "src/core/opamStd.mli", lines 454-455, characters 2-17:
         Expected declaration
       File "src/core/opamStd.ml", lines 880-890, characters 2-21:
         Actual declaration
```
This type mismatch could fit our 2nd kind of errors: the expected type mismatch
between the interface and the implementation. However, the reported code contains
the type equation `type os = Sys.os`, so it will fit our 4th kind. This is why
we did not fix it earlier.\
If we try to fix it like a regular type mismatch by updating the type in the
`.ml` to match the `.mli`, we get this new compilation error:
```OCaml-error
File "src/core/opamStd.ml", line 889, characters 27-33:
889 |           | "Darwin"    -> Darwin
                                 ^^^^^^
Error: Unbound constructor Darwin
```
This indicates that the constructor is used to build a value. Thus, it should
not be reported as unused. We hit a new undocumented limitation of the analyzer
so we can open an [issue](https://github.com/LexiFi/dead_code_analyzer/issues/81)
to report it.\
We can conclude that the following findings are
<span class="alert-danger">false positives</span>:
```dca
/tmp/proj/opam/src/core/opamStd.mli:474: Sys.os.Darwin
/tmp/proj/opam/src/core/opamStd.mli:475: Sys.os.Linux
/tmp/proj/opam/src/core/opamStd.mli:476: Sys.os.FreeBSD
/tmp/proj/opam/src/core/opamStd.mli:477: Sys.os.OpenBSD
/tmp/proj/opam/src/core/opamStd.mli:478: Sys.os.NetBSD
/tmp/proj/opam/src/core/opamStd.mli:479: Sys.os.DragonFly
/tmp/proj/opam/src/core/opamStd.mli:482: Sys.os.Unix
/tmp/proj/opam/src/core/opamStd.mli:483: Sys.os.Other
```

With all those errors fixed, we are now done with the naive cleaning, using
private type when their content is entirely unused.

The only remaining private type is `uname` in `src/core/opamStubsTypes.ml`
and `src/core/opamStubs.mli`.
We can try to clean it further by making it abstract. Building produces the following output:
```bash
$ dune build @check
File "src/core/opamStd.ml", line 896, characters 27-34:
896 |           match (uname ()).sysname with
                                 ^^^^^^^
Error: Unbound record field sysname

File "src/state/opamSysPoll.ml", line 40, characters 55-62:
40 |     | "Unix" | "Cygwin" -> Some (OpamStd.Sys.uname ()).machine
                                                            ^^^^^^^
Error: Unbound record field machine
```
This indicates that the fields `sysname` and `machine` are read. If we search a
bit further, the field `release` is also read. Thus, they should not be reported
as unused.\
Actually, I made a mistake earlier: I assumed that the following error was a
2nd kind error (mismatch between interface and implementation) when it is more
subtle than that. The type `uname` is defined in 2 separate compilation units
(`OpamStubsTypes` and `OpamStubs`), and one is included in the other (the former
into the latter).
```OCaml-error
File "src/core/opamStubs.ml", line 1:
Error: The implementation src/core/opamStubs.ml
       does not match the interface src/core/opamStubs.mli:
       Type declarations do not match:
         type uname =
           OpamStubsTypes.uname = private {
           sysname : string;
           release : string;
           machine : string;
         }
       is not included in
         type uname = {
           sysname : string;
           release : string;
           machine : string;
         }
       A private record constructor would be revealed.
       File "src/core/opamStubs.mli", lines 166-170, characters 0-1:
         Expected declaration
       File "src/core/opamStubsTypes.ml", lines 85-89, characters 0-1:
         Actual declaration
```
We hit a new undocumented limitation of the analyzer so we can open an
[issue](https://github.com/LexiFi/dead_code_analyzer/issues/82) to report it.\
We can conclude that the following findings are
<span class="alert-danger">false positives</span>:
```dca
/tmp/proj/opam/src/core/opamStubsTypes.ml:118: uname.sysname
/tmp/proj/opam/src/core/opamStubsTypes.ml:119: uname.release
/tmp/proj/opam/src/core/opamStubsTypes.ml:120: uname.machine
```

We are done with the aggressive cleanup and can move on to the informed cleanup.

### Informed cleanup

This section takes the findings in lexicographical order (often at once in a
single file) and indicates if their cleanup is reasonable or if it should be
undone, along with a short explanation.

- `src/core/cmdliner`: <span class="alert-safe">**clean**</span>\
    I'll assume all the findings in this subcomponent to be valid, because it
    is meant for internal use.

- `src/core/opamCompat.mli:45: Lazy.map_val`: <span class="alert-danger">**undo**</span>\
    Based on the intent of `OpamCompat`, the value `Lazy.map_val` should not be
    be removed, although it has never been used according to its history.

- `src/core/opamConsole.mli`: <span class="alert-safe">**clean**</span>\
    The reported values were either never used or their uses have been
    internalized during refactors.\
    Additionally, I did not find any use of the findings outside opam.

- `src/core/opamCoreConfig.mli`: <span class="alert-safe">**clean**</span>\
    The reported values uses have been internalized during refactors.\
    Additionally, I did not find any use of the findings outside opam.

- `src/core/opamDirTrack.mli`: <span class="alert-safe">**clean**</span>\
    The reported findings were never used outside their compilation unit.\
    Additionally, I did not find any use of the findings outside opam.

- `src/core/opamFilename.mli`: <span class="alert-safe">**clean**</span>\
    The reported values uses have been removed or internalized during refactors.\
    Additionally, I did not find any use of the findings outside opam.

- `src/core/opamHash.mli`: <span class="alert-safe">**clean**</span>\
    The reported findings were never used outside their compilation unit.\
    Additionally, I did not find any use of the findings outside opam.\
    Finally, `OpamHash.compute` (12 occurences) and
    `OpamHash.compute_from_string` (6 occurences) seem to be the entry points to
    compute hashes, instead of calling the direct hash functions (`OpamHash.md5`
    and `OpamHash.sha256`: 0 occurence, `OpamHash.sha512`: 1 occurence).\
    Thus, I'll go even further in the cleanup by unexporting `OpamHash.sha512`
    and replace its use with ``OpamHash.compute ~kind:`SHA512``.

- `src/core/opamParallel.mli:42: iter`: <span class="alert-danger">**undo**</span>\
    I found a use outside opam in [opam-bundle](https://github.com/AltGr/opam-bundle/blob/master/src/opamBundleMain.ml#L732).

- `src/core/opamProcess.mli:54: is_verbose_command`: <span class="alert-safe">**clean**</span>\
  `src/core/opamProcess.mli:73: t.p_info`: <span class="alert-safe">**clean**</span>\
  `src/core/opamProcess.mli:217: Job.seq_map`: <span class="alert-danger">**undo**</span>\
    I could not find any use outside opam of the 1st and 2nd findings but I did
    find one of the 3rd in [opam-bundle](https://github.com/AltGr/opam-bundle/blob/master/src/opamBundleMain.ml#L685).

- `src/core/opamSHA.mli`: <span class="alert-safe">**clean**</span>\
    Similar observations as for `OpamHash` can be made for `OpamSHA`, with the
    `hash_file` and `hash_string` functions as entry points and not the
    `sha*_file` and `sha*_string` ones.\
    Thus, I'll go even further in the cleanup by unexporting `OpamSHA.sha1_string`
    and replace its use with ``OpamSHA.hash_string `SHA1``.

- `src/core/opamStd.mli`: <span class="alert-danger">**undo**</span>\
    Based on the intent of `OpamStd`, its findings should not be removed.

- `src/core/opamStubs.mli`: <span class="alert-danger">**undo**</span>\
    According to the module documentation below, most of its functions are
    windows-specific.
    ```OCaml
    (** OS-specific functions requiring C code on at least one platform.

        Most functions are Windows-specific and raise an exception on other
        platforms. *)
    ```
    I am using Linux, and the compilation of opam is dependent on os-type, as shown in `src/core/dune`:
    ```dune
    (rule
      (enabled_if (<> %{os_type} "Win32"))
      (action (copy# opamStubs.unix.ml opamStubs.ml)))

    (rule
     (enabled_if (= %{os_type} "Win32"))
     (action (copy# opamWin32Stubs.win32.ml opamWin32Stubs.ml)))
    ```

- `src/core/opamStubsTypes.ml`: <span class="alert-danger">**undo**</span>\
    The documentation of the module below indicates that it exposes types for
    C stubs. If we look deeper, the mentioned stubs can be found in
    `src/core/opamWindows.c`, and the exported OCaml types are based on their
    C equivalents. Although the reported OCaml fields seem to only be written to
    in those stubs, keeping both types structurally equivalent will be easier to
    maintain.\
    Additionally, handling FFI is out of scope for the `dead_code_analyzer`, although undocumented.
    ```OCaml
    (** Types for C stubs modules and common C stubs. *)
    ```


- `src/core/opamSystem.mli`: <span class="alert-safe">**clean**</span>\
    The file contains the following comment line 216, so I'll consider
    everything reported below that line can be safely removed.
    ```OCaml
    (** OLD COMMAND API, DEPRECATED *)
    ```
    Regarding the 4 values reported above that comment, opam's history shows
    that they became unused through consecutive improvements.

- `src/core/opamVersion.mli`: <span class="alert-safe">**clean**</span>\
    The findings are not used anymore and I did not find any use outside opam.

- `src/core/opamVersionCompare.mli:35: equal`: <span class="alert-safe">**clean**</span>\
    According to the value's history, it has never been used inside opam.\
    Additionally, I did not find any use outside opam.

### Results

The analyzer reported 209 findings in this component:
153 unused values, 56 unused constructors and fields.\
The aggressive cleanup revealed 24 false positives (1 value and 23 constructors
and fields), and 4 new limitations.\
The informed cleanup indicates that 65 additional findings (33 values and
32 fields) should not be removed.

From these results, we can compute the precision of the analyzer shown in the
table below. The estimated precision after the informed cleanup can be
extrapolated as the potential fix rate.

| section                 | aggressive | + informed |
|:-----------------------:|:----------:|:----------:|
| exported values         | 99.3%      | 77.8%      |
| constructors and fields | 58.9%      |  1.8%      |
| total                   | 88.5%      | 57.4%      |

During the informed cleanup, we discovered that the `OpamHash` and
`OpamSha` modules were exporting more entry-points for hash and sha computations
than they should, and simplified their API.

The estimated precision on the constructors and fields after the 2 phases is
disappointing. It is entirely due to the analyzer's limitations.
Either limitations that will be adressed (for 23 of the findings) or the use of
FFI (for 32 of them). In the best-case scenario, with the actual false positives
fixed, the estimated precision would not improve much (3%) because of the FFI
limitation.

## <li>src/format</li>

### Description

This component is distributed as the package
[`opam-format`](https://ocaml.org/p/opam-format/2.5.1), and has
[18 reverse package dependencies](https://ocaml.org/p/opam-format/2.5.1#used-by).\
It is described in
[opam/CONTRIBUTING.md#layout](https://github.com/ocaml/opam/blob/2.5.1/CONTRIBUTING.md#layout)
as:
<div class="alert-cite">

>  entirely dedicated to parsing opam files (higher level, but still using opam-file-format) and other internal config files
</div>

In total, there are 147 unused values, and 16 unused constructors and fields
reported by the `dead_code_analyzer`for this component.\
This is the component with the most unused values reported.

### Aggressive cleanup

#### Unused exported values

Because more than half (82 out of 147, i.e. 55.8%) of the reported values are
lcoated in `src/format/opamFile.mli`, we will clean it first. The intent is to
reduce the workload during step 3 of the cleanup, although it may lead to more
iterations.

Applying steps 1 and 2 of the cleanup methodology for
[unused exported values](./#cleaning-up-unused-exported-values) on the findings in
`src/format/opamFile.mli` is trivial.\
Applying step 3 triggers 9 warnings 32 (reported as errors).
<details><summary>build output</summary>

```bash
$ dune build @check
File "src/format/opamFile.ml", line 1741, characters 6-26:
1741 |   let with_solver_criteria solver_criteria t = {t with solver_criteria}
             ^^^^^^^^^^^^^^^^^^^^
Error (warning 32 [unused-value-declaration]): unused value with_solver_criteria.

File "src/format/opamFile.ml", line 2299, characters 6-15:
2299 |   let variables t = List.rev_map fst t.vars
             ^^^^^^^^^
Error (warning 32 [unused-value-declaration]): unused value variables.

File "src/format/opamFile.ml", line 2368, characters 6-20:
2368 |   let with_stamp_opt stamp t = { t with stamp }
             ^^^^^^^^^^^^^^
Error (warning 32 [unused-value-declaration]): unused value with_stamp_opt.

File "src/format/opamFile.ml", line 2452, characters 6-16:
2452 |   let with_swhid swhid t = { t with swhid = Some swhid }
             ^^^^^^^^^^
Error (warning 32 [unused-value-declaration]): unused value with_swhid.

File "src/format/opamFile.ml", line 2746, characters 6-14:
2746 |   let extended t fld parse =
             ^^^^^^^^
Error (warning 32 [unused-value-declaration]): unused value extended.

File "src/format/opamFile.ml", line 2776, characters 6-22:
2776 |   let with_version_opt version (t:t) = { t with version }
             ^^^^^^^^^^^^^^^^
Error (warning 32 [unused-value-declaration]): unused value with_version_opt.

File "src/format/opamFile.ml", line 2851, characters 6-20:
2851 |   let with_descr_opt descr t = { t with descr }
             ^^^^^^^^^^^^^^
Error (warning 32 [unused-value-declaration]): unused value with_descr_opt.

File "src/format/opamFile.ml", line 3431, characters 6-14:
3431 |   let contents = Syntax.contents pp
             ^^^^^^^^
Error (warning 32 [unused-value-declaration]): unused value contents.

File "src/format/opamFile.ml", line 3968, characters 6-25:
3968 |   let create_preinstalled name version packages env =
             ^^^^^^^^^^^^^^^^^^^
Error (warning 32 [unused-value-declaration]): unused value create_preinstalled.
```
</details>

The warnings 32 can be fixed by following the technique described in [section src/client](#anchor_warning_fix_methodology)

Moving on to the rest of the `src/format` component,  applying steps 1 and 2 is
trivial again.\
However, applying step 3 triggers 25 warnings 32 (reported as errors).
<details><summary>build output</summary>

```bash
$ dune build @check
File "src/format/opamSysPkg.ml", line 65, characters 4-20:
65 | let string_of_status sp =
         ^^^^^^^^^^^^^^^^
Error (warning 32 [unused-value-declaration]): unused value string_of_status.

File "src/format/opamSysPkg.ml", line 85, characters 4-24:
85 | let string_of_to_install ti =
         ^^^^^^^^^^^^^^^^^^^^
Error (warning 32 [unused-value-declaration]): unused value string_of_to_install.

File "src/format/opamFormula.ml", line 100, characters 4-25:
100 | let string_of_disjunction string_of_atom c =
          ^^^^^^^^^^^^^^^^^^^^^
Error (warning 32 [unused-value-declaration]): unused value string_of_disjunction.

File "src/format/opamFormula.ml", line 105, characters 4-17:
105 | let string_of_cnf string_of_atom cnf =
          ^^^^^^^^^^^^^
Error (warning 32 [unused-value-declaration]): unused value string_of_cnf.

File "src/format/opamFormula.ml", line 114, characters 4-17:
114 | let string_of_dnf string_of_atom cnf =
          ^^^^^^^^^^^^^
Error (warning 32 [unused-value-declaration]): unused value string_of_dnf.

File "src/format/opamFormula.ml", line 194, characters 8-12:
194 | let rec iter f = function
              ^^^^
Error (warning 32 [unused-value-declaration]): unused value iter.

File "src/format/opamFormula.ml", line 462, characters 4-18:
462 | let of_conjunction c =
          ^^^^^^^^^^^^^^
Error (warning 32 [unused-value-declaration]): unused value of_conjunction.

File "src/format/opamFormula.ml", line 536, characters 4-18:
536 | let to_conjunction t =
          ^^^^^^^^^^^^^^
Error (warning 32 [unused-value-declaration]): unused value to_conjunction.

File "src/format/opamFormula.ml", line 540, characters 4-18:
540 | let to_disjunction t =
          ^^^^^^^^^^^^^^
Error (warning 32 [unused-value-declaration]): unused value to_disjunction.

File "src/format/opamFormula.ml", line 544, characters 4-18:
544 | let of_disjunction d =
          ^^^^^^^^^^^^^^
Error (warning 32 [unused-value-declaration]): unused value of_disjunction.

File "src/format/opamPp.ml", line 133, characters 4-10:
133 | let ignore = {
          ^^^^^^
Error (warning 32 [unused-value-declaration]): unused value ignore.

File "src/format/opamTypesBase.ml", line 117, characters 4-12:
117 | let pos_best pos1 pos2 =
          ^^^^^^^^
Error (warning 32 [unused-value-declaration]): unused value pos_best.

File "src/format/opamTypesBase.ml", line 329, characters 4-16:
329 | let iter_success f = function
          ^^^^^^^^^^^^
Error (warning 32 [unused-value-declaration]): unused value iter_success.

File "src/format/opamTypesBase.ml", line 334, characters 4-14:
334 | let env_update ?comment:envu_comment ~rewrite:envu_rewrite
          ^^^^^^^^^^
Error (warning 32 [unused-value-declaration]): unused value env_update.

File "src/format/opamFilter.ml", line 395, characters 4-8:
395 | let eval ?default env e = value ?default (reduce env e)
          ^^^^
Error (warning 32 [unused-value-declaration]): unused value eval.

File "src/format/opamFilter.ml", line 421, characters 4-15:
421 | let ident_value ?default env id = value ?default (resolve_ident env id)
          ^^^^^^^^^^^
Error (warning 32 [unused-value-declaration]): unused value ident_value.

File "src/format/opamFilter.ml", line 425, characters 4-14:
425 | let ident_bool ?default env id = value_bool ?default (resolve_ident env id)
          ^^^^^^^^^^
Error (warning 32 [unused-value-declaration]): unused value ident_bool.

File "src/format/opamFormat.ml", line 165, characters 6-15:
165 |   let map_group pp1 = group -| map_list ~posf:value_pos pp1
            ^^^^^^^^^
Error (warning 32 [unused-value-declaration]): unused value map_group.

File "src/format/opamFormat.ml", line 480, characters 6-18:
480 |   let package_atom constraints =
            ^^^^^^^^^^^^
Error (warning 32 [unused-value-declaration]): unused value package_atom.

File "src/format/opamFormat.ml", line 959, characters 6-12:
959 |   let signed ~check =
            ^^^^^^
Error (warning 32 [unused-value-declaration]): unused value signed.

File "src/format/opamPath.ml", line 63, characters 4-10:
63 | let backup t = backup_dir t /- backup_file ()
         ^^^^^^
Error (warning 32 [unused-value-declaration]): unused value backup.

File "src/format/opamPath.ml", line 79, characters 4-10:
79 | let plugin t name =
         ^^^^^^
Error (warning 32 [unused-value-declaration]): unused value plugin.

File "src/format/opamPath.ml", line 137, characters 6-16:
137 |   let extra_file t a h = extra_files_dir t a // OpamHash.contents h
            ^^^^^^^^^^
Error (warning 32 [unused-value-declaration]): unused value extra_file.

File "src/format/opamPath.ml", line 182, characters 8-16:
182 |     let man_dirs t a = List.map (fun num -> man_dir ~num t a) mans
              ^^^^^^^^
Error (warning 32 [unused-value-declaration]): unused value man_dirs.
```
</details>

We can clean up the warnings using the same methodology and re-iterate step 3
until there is no more warning or error to fix.\
This cleanup requires multiple iterations because some values were not exported
and only used by unused values that appear in the above build output. Now that
we removed these unused values, new unused values are uncovered.

Going ever further, there are a type and an exception that are exported by
`OpamFormat` but unused: `signature` and `Invalid_signature`.
They can be removed both from the `.mli` and the `.ml` without breaking the compilation.

We are done with the unused exported values.

#### Unused constructors and fields

Some of the findings accumulate to the whole type definition of `OpamTypes.lock`,
so we will follow the more specific cleanup methodology of
[unused constructors and fields](./#cleaning-up-unused-constructors-and-fields)
for this case.

Applying steps 1 and 2 is trivial.\
Applying step 3 a first time triggers 2 errors.
<details><summary>build output</summary>

```bash
$ dune build @check
File "src/format/opamTypes.mli", lines 102-105, characters 0-20:
102 | type variable_contents = OpamVariable.variable_contents =
103 |   | B of bool
104 |   | S of string
105 |   | L of string list
Error: This variant or record definition does not match that of type
         OpamVariable.variable_contents
       A constructor, L, is missing in the original definition.

File "src/format/opamVariable.ml", line 1:
Error: The implementation src/format/opamVariable.ml
       does not match the interface src/format/opamVariable.mli:
       Type declarations do not match:
         type variable_contents =
             B of bool
           | S of variable
           | L of variable list
       is not included in
         type variable_contents = B of bool | S of variable
       An extra constructor, L, is provided in the first declaration.
       File "src/format/opamVariable.mli", lines 23-25, characters 0-15:
         Expected declaration
       File "src/format/opamVariable.ml", lines 16-19, characters 0-20:
         Actual declaration
```
</details>

The first error is related to a type equation:
`type variable_contents = OpamVariable.variable_contents`,
and we already hit a limitation on this in [section src/core](#srccore)
(documented in [issue #79](https://github.com/LexiFi/dead_code_analyzer/issues/79)).\
We will still explore it because one of the goals of this study is to properly
qualify the results of the `dead_code_analyzer`.

<div class="alert-tip">

> In a given codebase, the same patterns will probably repeat, so the same limitations will probably be encountered.
> For a more efficient cleanup, it is recommended to skip reports on patterns already associated with false positives.
</div>

We can quickly verify if we hit the same type-equation-related limitation by
removing the constructor `L` in the type alias `variable_contents`.
Re-building triggers new errors among which a couple indicate that `L` is
actually used to build values:
```OCaml-error
File "src/client/opamAction.ml", line 1101, characters 15-16:
1101 |         (Some (L added))
                      ^
Error: Unbound constructor L

File "src/client/opamSolution.ml", line 1478, characters 42-43:
1478 |         OpamVariable.Full.of_string name, L l
                                                 ^
Error: Unbound constructor L
```
Thus, we can conclude the the following finding is a
<span class="alert-danger">false positive</span>:
```dca
/tmp/proj/opam/src/format/opamVariable.mli:26: variable_contents.L
```

Now that we identified a false positive, we can re-apply step 3 and explore the
new errors.
<details><summary>build output</summary>

```bash
$ dune build @check
File "src/state/opamSwitchAction.ml", line 35, characters 4-9:
35 |     paths = [];
         ^^^^^
Error: Unbound record field OpamFile.Switch_config.paths

File "src/state/opamFormatUpgrade.ml", line 946, characters 23-28:
946 |             opam_root; paths; variables; wrappers = OpamFile.Wrappers.empty;
                             ^^^^^
Error: Unbound record field OpamFile.Switch_config.paths

File "src/client/opamAdminCheck.ml", line 38, characters 4-12:
38 |     u_action = Query;
         ^^^^^^^^
Error: Unbound record field u_action

File "src/state/opamSwitchState.ml", line 1042, characters 2-10:
1042 |   u_action = user_action;
         ^^^^^^^^
Error: Unbound record field u_action

File "src/format/opamFile.ml", line 1:
Error: The implementation src/format/opamFile.ml
       does not match the interface src/format/opamFile.mli:  ...
       In module OPAM:
       Type declarations do not match:
         type t =
           OPAM.t = {
           opam_version : OpamVersion.t;
           name : StateTable.M.key option;
           version : OpamPackage.Version.t option;
           depends : OpamTypes.filtered_formula;
           depopts : OpamTypes.filtered_formula;
           conflicts : OpamTypes.filtered_formula;
           conflict_class : StateTable.M.key list;
           available : OpamTypes.filter;
           flags : OpamTypes.package_flag list;
           env :
             (OpamTypes.spf_unresolved, OpamTypes.euok_writeable)
             OpamTypes.env_update list;
           build : OpamTypes.command list;
           run_test : OpamTypes.command list;
           install : OpamTypes.command list;
           remove : OpamTypes.command list;
           substs : OpamFilename.Base.t list;
           patches : (OpamFilename.Base.t * OpamTypes.filter option) list;
           build_env :
             (OpamTypes.spf_unresolved, OpamTypes.euok_writeable)
             OpamTypes.env_update list;
           features :
             (OpamVariable.t * OpamTypes.filtered_formula * string) list;
           extra_sources : (OpamFilename.Base.t * URL.t) list;
           messages : (string * OpamTypes.filter option) list;
           post_messages : (string * OpamTypes.filter option) list;
           depexts : (OpamSysPkg.Set.t * OpamTypes.filter) list;
           libraries : (string * OpamTypes.filter option) list;
           syntax : (string * OpamTypes.filter option) list;
           dev_repo : OpamUrl.t option;
           pin_depends : (OpamPackage.t * OpamUrl.t) list;
           maintainer : string list;
           author : string list;
           license : string list;
           tags : string list;
           homepage : string list;
           doc : string list;
           bug_reports : string list;
           extensions : OpamParserTypes.FullPos.value ChangesSyntax.SM.t;
           url : URL.t option;
           descr : Descr.t option;
           metadata_dir : (OpamRepositoryName.t option * string) option;
           extra_files : (OpamFilename.Base.t * OpamHash.t) list option;
           locked : string option;
           format_errors : (string * Pp.bad_format) list;
           ocaml_version :
             (OpamParserTypes.relop * string) OpamFormula.formula option;
           os : (bool * string) OpamFormula.formula;
           deprecated_build_test : OpamTypes.command list;
           deprecated_build_doc : OpamTypes.command list;
         }
       is not included in
         type t = private {
           opam_version : OpamVersion.t;
           name : StateTable.M.key option;
           version : OpamPackage.Version.t option;
           depends : OpamTypes.filtered_formula;
           depopts : OpamTypes.filtered_formula;
           conflicts : OpamTypes.filtered_formula;
           available : OpamTypes.filter;
           flags : OpamTypes.package_flag list;
           build : OpamTypes.command list;
           run_test : OpamTypes.command list;
           install : OpamTypes.command list;
           remove : OpamTypes.command list;
           patches : (OpamFilename.Base.t * OpamTypes.filter option) list;
           features :
             (OpamVariable.t * OpamTypes.filtered_formula * string) list;
           extra_sources : (OpamFilename.Base.t * URL.t) list;
           messages : (string * OpamTypes.filter option) list;
           post_messages : (string * OpamTypes.filter option) list;
           depexts : (OpamSysPkg.Set.t * OpamTypes.filter) list;
           libraries : (string * OpamTypes.filter option) list;
           syntax : (string * OpamTypes.filter option) list;
           dev_repo : OpamUrl.t option;
           pin_depends : (OpamPackage.t * OpamUrl.t) list;
           maintainer : string list;
           author : string list;
           license : string list;
           tags : string list;
           homepage : string list;
           doc : string list;
           bug_reports : string list;
           url : URL.t option;
           descr : Descr.t option;
           extra_files : (OpamFilename.Base.t * OpamHash.t) list option;
           format_errors : (string * OpamPp.bad_format) list;
           ocaml_version :
             (OpamParserTypes.relop * string) OpamFormula.formula option;
           os : (bool * string) OpamFormula.formula;
           deprecated_build_test : OpamTypes.command list;
           deprecated_build_doc : OpamTypes.command list;
         }
       7. An extra field, conflict_class, is provided in the first declaration.
       10. An extra field, env, is provided in the first declaration.
       15. An extra field, substs, is provided in the first declaration.
       17. An extra field, build_env, is provided in the first declaration.
       34. An extra field, extensions, is provided in the first declaration.
       37. An extra field, metadata_dir, is provided in the first declaration.
       39. An extra field, locked, is provided in the first declaration.
       File "src/format/opamFile.mli", lines 333-390, characters 2-3:
         Expected declaration
       File "src/format/opamFile.ml", lines 2528-2603, characters 2-3:
         Actual declaration
```
</details>

The last error reminds a lot the one that lead to opening
[issue #81](https://github.com/LexiFi/dead_code_analyzer/issues/81)
in [section src/core](#srccore).\
We can verify if we hit the same limitation by looking for the actual definition
of `t` and the definition of `OPAM` in the `.ml`. It turns out that `t` is
defined in `OPAMSyntax` which is included in `OPAM`. Thus, the situation is
closer to [issue #82](https://github.com/LexiFi/dead_code_analyzer/issues/82).\
Now to see if we actually hit the limitation, we can update the type in
`OPAMSyntax` to match the definition in `OPAM`.
Quickly we can reach a compilation error synonymous of a false positive:
```OCaml-error
File "src/format/opamFile.ml", line 2649, characters 34-46:
2649 |         OpamStd.Option.Op.(>>|) t.metadata_dir @@ function
                                         ^^^^^^^^^^^^
Error: Unbound record field metadata_dir
```
We can conclude that the following findings are
<span class="alert-danger">false positives</span>:
```dca
/tmp/proj/opam/src/format/opamFile.mli:366: OPAM.t.conflict_class
/tmp/proj/opam/src/format/opamFile.mli:369: OPAM.t.env
/tmp/proj/opam/src/format/opamFile.mli:378: OPAM.t.substs
/tmp/proj/opam/src/format/opamFile.mli:380: OPAM.t.build_env
/tmp/proj/opam/src/format/opamFile.mli:403: OPAM.t.extensions
/tmp/proj/opam/src/format/opamFile.mli:413: OPAM.t.metadata_dir
/tmp/proj/opam/src/format/opamFile.mli:419: OPAM.t.locked
```

If we re-apply step 3, the following error is triggered:
```OCaml-error
File "src/format/opamFile.ml", line 1:
Error: The implementation src/format/opamFile.ml
       does not match the interface src/format/opamFile.mli:  ...
       In module Repo_config_legacy:
       Type declarations do not match:
         type t =
           Repo_config_legacy.t = {
           repo_name : OpamRepositoryName.t;
           repo_root : OpamFilename.Dir.t;
           repo_url : OpamUrl.t;
           repo_priority : int;
         }
       is not included in
         type t = { repo_url : OpamUrl.t; repo_priority : int; }
       1. An extra field, repo_name, is provided in the first declaration.
       2. An extra field, repo_root, is provided in the first declaration.
       File "src/format/opamFile.mli", lines 854-857, characters 2-3:
         Expected declaration
       File "src/format/opamFile.ml", lines 2174-2179, characters 2-3:
         Actual declaration
```
We are facing the the same pattern as with the type `t` in modules `OPAM` and
`OPAMSyntax`. This time it is the module `Repo_config_legacySyntax` that is
included in `Repo_config_legacy`.
Both fields `repo_name` and `repo_root` are used in `src/format/opamFile.ml` in
the definition of the value `Repo_config_legacySyntax.fields`.\
We can move on with the same conclusion that the following findings are
<span class="alert-danger">false positives</span>:
```dca
/tmp/proj/opam/src/format/opamFile.mli:1019: Repo_config_legacy.t.repo_name
/tmp/proj/opam/src/format/opamFile.mli:1020: Repo_config_legacy.t.repo_root
```

Once again we can re-apply step 3, and once again it triggers a similar error:
```OCaml-error
File "src/format/opamFile.ml", line 1:
Error: The implementation src/format/opamFile.ml
       does not match the interface src/format/opamFile.mli:  ...
       In module Switch_config:
       Type declarations do not match:
         type t =
           Switch_config.t = {
           opam_version : OpamVersion.t;
           synopsis : string;
           repos : OpamRepositoryName.t list option;
           paths : (OpamTypes.std_path * string) list;
           variables : (OpamVariable.t * OpamVariable.variable_contents) list;
           opam_root : OpamFilename.Dir.t option;
           wrappers : Wrappers.t;
           env :
             (OpamTypes.spf_resolved, OpamTypes.euok_writeable)
             OpamTypes.env_update list;
           invariant : OpamFormula.t option;
           depext_bypass : OpamSysPkg.Set.t;
         }
       is not included in
         type t = {
           opam_version : OpamVersion.t;
           synopsis : string;
           repos : OpamRepositoryName.t list option;
           variables : (OpamVariable.t * OpamVariable.variable_contents) list;
           opam_root : OpamFilename.Dir.t option;
           wrappers : Wrappers.t;
           env :
             (OpamTypes.spf_resolved, OpamTypes.euok_writeable)
             OpamTypes.env_update list;
           invariant : OpamFormula.t option;
           depext_bypass : OpamSysPkg.Set.t;
         }
       An extra field, paths, is provided in the first declaration.
       File "src/format/opamFile.mli", lines 870-880, characters 2-3:
         Expected declaration
       File "src/format/opamFile.ml", lines 1990-2001, characters 2-3:
         Actual declaration
```
We are facing the same pattern, with module `Switch_configSyntax` included in
`Switch_config`. The field `paths` is actually used in `src/format/opamFile.ml`
in the definition of the value `Switch_configSyntax.sections`.\
Once again, we can conclude that the following finding is a
<span class="alert-danger">false positive</span>:
```dca
/tmp/proj/opam/src/format/opamFile.mli:1038: Switch_config.t.paths
```

Now that we are done with the false positives in `src/format/opamFile.ml`,
iterating on step 3 only triggers "safe" errors.\
During the iterations, we wil encounter the following warning 26 (reported as error):
```OCaml-error
File "src/state/opamSwitchState.ml", line 959, characters 4-15:
959 |     user_action =
          ^^^^^^^^^^^
Error (warning 27 [unused-var-strict]): unused variable user_action.
```
This error points to an unused parameter. Removing it would trigger a warning 16
(reported as error) that is more problematic :
```OCaml-error
File "src/state/opamSwitchState.ml", line 957, characters 5-14:
957 |     ?reinstall
           ^^^^^^^^^
Error (warning 16 [unerasable-optional-argument]): this optional argument cannot be erased.
```
In order to keep this exploration simple enough, I will silence the parameter
reported by the warning 27 by prefixing its name with an underscore: `_user_action`.
<div class="alert-note">

> In practice, fixing such situation can lead to a replacement of the parameter with unit and updating all the callers accordingly,
> or more heavy-handed refactors.
</div>

All the errors can be fixed without encountering any more limitation of the analyzer.

We are done with the aggressive cleanup and can move on to the informed cleanup

### Informed cleanup

This section takes the findings in lexicographical order (often at once in a
single file or module) and indicates if their cleanup is reasonable or if it
should be undone, along with a short explanation.

- `src/format/opamFile.mli:112: Wrappers.with_wrap_remove`: <span class="alert-danger">**undo**</span>\
    While investigating the unused `OpamFile.*.with_*` functions, I found a
    mistake in opam : `OpamFile.Wrappers.with_pre_remove` is used in
    [`src/client/opamConfigCommand.ml`](https://github.com/ocaml/opam/blob/2.5.1/src/client/opamConfigCommand.ml#L665),
    where `OpamFile.Wrappers.with_wrap_remove` is expected.

- `src/format/opamFile.mli:*: Config.*`: <span class="alert-safe">**clean**</span>\
  `src/format/opamFile.mli:*: InitConfig.*`: <span class="alert-safe">**clean**</span>\
    These functions are meant to update values of abstract types `t`.
    Keeping them, even if unused, would be reasonable.\
    However, because the 2 APIs already show some inconsistencies, I think it
    would also be reasonable to reduce them to what is actually used in order to
    reduce maintenance cost.

- `src/format/opamFile.mli:*: Descr.*`: <span class="alert-safe">**clean**</span>\
    I only found a use of `OpamFile.Descr.full` outside opam in
    [opamfu](https://github.com/ocamllabs/opamfu/blob/master/lib/opamfUniverse.ml#L123).\
    However the project has not seen activity for the past 8 years so I will
    consider it dead.

- `src/format/opamFile.mli:*: URL.*`: <span class="alert-safe">**clean**</span>\
    Same reasoning as with `OpamFile.Config.*`.

- `src/format/opamFile.mli:*: OPAM.*`: <span class="alert-danger">**undo**</span>\
    Some of the reported values in `OpamFile.OPAM` are simple accessors that
    existed for a long time and were sensical when `OpamFile.OPAM.t` was abstract.\
    Now that the type is private, the fields can be accessed directly and the getters do not provide any additional value.\
    Additionally, the same argument as before could be applied to the setters
    (`with_*` values).\
    However, multiple reported values are used by external packages:
    - `extended` in [opam-monorepo](https://github.com/tarides/opam-monorepo/blob/main/lib/opam.ml#L313)
    - `homepage`, `author`, `license`, and more in [dune-release](https://github.com/tarides/dune-release/blob/main/lib/opam.ml#L181)

    Thus, it will be safer to consider the findings in `OpamFile.OPAM` as used
    and not remove them.


- `src/format/opamFile.mli:*: Environment.*`: <span class="alert-safe">**clean**</span>\
    I did not find an use of `OpamFile.Environment` outside opam.

- `src/format/opamFile.mli:*: Comp.*`: <span class="alert-safe">**clean**</span>\
    The `Comp` module is documented as deprecated:
    ```OCaml
    (** Compiler version [$opam/compilers/]. Deprecated, only used to upgrade old
        data *)
    ```

- `src/format/opamFile.mli:*: Dot_install.*`: <span class="alert-safe">**clean**</span>\
    Same reasoning as with `OpamFile.Config.*`.

- `src/format/opamFile.mli:998: Dot_config.variables`: <span class="alert-safe">**clean**</span>\
    I did not find any use of `Dot_config` outside opam.

- `src/format/opamFile.mli:1087: Repo.browse`: <span class="alert-safe">**clean**</span>\
  `src/format/opamFile.mli:1090: Repo.upstream`: <span class="alert-danger">**undo**</span>\
    I have not found any use of `OpamFile.Repo.browse` outside opam but found
    one of `OpamFile.Repo.upstream` in [opam2Web](https://github.com/ocaml-opam/opam2web/blob/master/src/o2wPackage.ml#L472).

- `src/format/opamFile.mli:*: Repo.with_*`: <span class="alert-safe">**clean**</span>\
    Same reasoning as with `OpamFile.Config.with_*`.

- `src/format/opamFile.mli:*: Syntax.*`: <span class="alert-safe">**clean**</span>\
    I did not find any use outside opam.\
    Additionally, I have not found any historical use outside their compilation unit.


- `src/format/opamFilter.mli:109: eval`: <span class="alert-danger">**undo**</span>\
  `src/format/opamFilter.mli:121: eval_to_string`: <span class="alert-safe">**clean**</span>\
  `src/format/opamFilter.mli:134: ident_value`: <span class="alert-safe">**clean**</span>\
  `src/format/opamFilter.mli:140: ident_bool`: <span class="alert-safe">**clean**</span>\
  `src/format/opamFilter.mli:142: expand_interpolations_in_file_full`: <span class="alert-safe">**clean**</span>\
  `src/format/opamFilter.mli:188: gen_filter_formula`: <span class="alert-safe">**clean**</span>\
    Among all the values reported in `src/format/opamFilter.mli`, I could only
    find the use of one outside opam: `OpamFilter.eval` in
    [opam-0install](https://github.com/ocaml-opam/opam-0install-solver/blob/master/lib/dir_context.ml#L104).

- `src/format/opamFormat.mli:19: value_pos`: <span class="alert-safe">**clean**</span>\
  `src/format/opamFormat.mli:*: V.*`: <span class="alert-safe">**clean**</span>\
  `src/format/opamFormat.mli:196: I.file`: <span class="alert-safe">**clean**</span>\
  `src/format/opamFormat.mli:200: I.item`: <span class="alert-safe">**clean**</span>\
  `src/format/opamFormat.mli:271: I.extract_field`: <span class="alert-safe">**clean**</span>\
  `src/format/opamFormat.mli:292: I.signature`: <span class="alert-danger">**undo**</span>\
  `src/format/opamFormat.mli:299: I.signed`: <span class="alert-danger">**undo**</span>\
    I did not find any use outside opam of the findings in
    `src/format/opamFormat.mli`.\
    However, the file contains the following comment line 287 indicating a work
    in progress, so I'll consider everything reported below that line must not
    be removed.
    ```OCaml
      (** Signature handling (wip) *)
    ```

- `src/format/opamFormula.mli:144: iter`: <span class="alert-danger">**undo**</span>\
  `src/format/opamFormula.mli:172: compare`: <span class="alert-safe">**clean**</span>\
  `src/format/opamFormula.mli:190: compare_nc`: <span class="alert-safe">**clean**</span>\
  `src/format/opamFormula.mli:199: formula_to_cnf`: <span class="alert-safe">**clean**</span>\
  `src/format/opamFormula.mli:202: dnf_of_formula`: <span class="alert-safe">**clean**</span>\
  `src/format/opamFormula.mli:218: simplify_ineq_formula`: <span class="alert-safe">**clean**</span>\
  `src/format/opamFormula.mli:245: to_conjunction`: <span class="alert-safe">**clean**</span>\
  `src/format/opamFormula.mli:248: of_conjunction`: <span class="alert-safe">**clean**</span>\
  `src/format/opamFormula.mli:252: to_disjunction`: <span class="alert-safe">**clean**</span>\
  `src/format/opamFormula.mli:260: of_disjunction`: <span class="alert-safe">**clean**</span>\
    I did not find any use outside opam of the findings.\
    However,`OpamFormula.iter` is actually used inside opam by
    `admin-scripts/depopts_to_conflicts.ml`.
    This was missed by the analyzer because the files in `admin-scripts` are not
    part of the build.

- `src/format/opamPath.mli`: <span class="alert-safe">**clean**</span>\
    I did not find any use of the findings outside opam.

- `src/format/opamPp.mli:96: ignore`: <span class="alert-safe">**clean**</span>\
    I did not find any use of the finding outside opam.

- `src/format/opamSysPkg.mli`: <span class="alert-safe">**clean**</span>\
    I did not find any use of the findings outside opam.

- `src/format/opamTypesBase.mli`: <span class="alert-safe">**clean**</span>\
    I did not find any use of the findings outside opam.

- `src/format/opamTypes.mli`: <span class="alert-safe">**clean**</span>\
    I did not find any use of the findings outside opam.

### Results

The analyzer reported 163 findings in this component:
147 unused values, 16 unused constructors and fields.\
The aggressive cleanup revealed 11 false positives (constructors and fields
only), all caused by patterns already encountered in [section src/core](#srccore).\
The informed cleanup indicates that 27 additional findings (values only) should
not be removed.

From these results, we can compute the precision of the analyzer shown in the
table below. The estimated precision after the informed cleanup can be
extrapolated as the potential fix rate.

| section                 | aggressive | + informed |
|:-----------------------:|:----------:|:----------:|
| exported values         | 100%       | 81.6%      |
| constructors and fields | 31.3%      | 31.3%      |
| total                   | 93.3%      | 76.7%      |

The precision on the constructors and fields after the aggressive cleanup could
largely be improved. Especially, knowing that 10 out of 11 (i.e. 90.9%) of the
false positives are caused by the same
[issue](https://github.com/LexiFi/dead_code_analyzer/issues/82). Fixing this
issue would increase the precision for this section after both phases to 83.3%.

## <li>src/repository</li>

### Description

This component is distributed as the package
[`opam-repository`](https://ocaml.org/p/opam-repository/2.5.1), and has
[3 reverse package dependencies](https://ocaml.org/p/opam-repository/2.5.1#used-by).\
It is described in
[opam/CONTRIBUTING.md#layout](https://github.com/ocaml/opam/blob/2.5.1/CONTRIBUTING.md#layout)
as:
<div class="alert-cite">

> gathers code handling everything related to how to download and store repositories. The same code path is also reused when downloading a package for example.
</div>

In total, there are 8 unused values, and no unused field or constructor
reported by the `dead_code_analyzer` for this component.

### Aggressive cleanup

#### Unused exported values

Applying steps 1 and 2 of the cleanup methodology for
[unused exported values](./#cleaning-up-unused-exported-values) on the findings in
is trivial.\
Applying step 3 triggers 10 warnings 32 (reported as errors).
<details><summary>build output</summary>

```bash
$ dune build @check
File "src/state/opamScript.ml", line 23, characters 4-10:
23 | let prompt =
         ^^^^^^
Error (warning 32 [unused-value-declaration]): unused value prompt.

File "src/state/opamGlobalState.ml", line 165, characters 4-17:
165 | let all_installed gt =
          ^^^^^^^^^^^^^
Error (warning 32 [unused-value-declaration]): unused value all_installed.

File "src/state/opamFileTools.ml", line 1236, characters 4-15:
1236 | let lint_string ?check_extra_files ?check_upstream ?handle_dirname
           ^^^^^^^^^^^
Error (warning 32 [unused-value-declaration]): unused value lint_string.

File "src/state/opamUpdate.ml", line 475, characters 4-19:
475 | let pinned_packages st ?autolock ?(working_dir=OpamPackage.Name.Set.empty) names =
          ^^^^^^^^^^^^^^^
Error (warning 32 [unused-value-declaration]): unused value pinned_packages.

File "src/state/opamSwitchState.ml", line 705, characters 4-9:
705 | let descr st nv =
          ^^^^^
Error (warning 32 [unused-value-declaration]): unused value descr.

File "src/state/opamSwitchState.ml", line 793, characters 4-16:
793 | let dev_packages st =
          ^^^^^^^^^^^^
Error (warning 32 [unused-value-declaration]): unused value dev_packages.

File "src/state/opamEnv.ml", line 701, characters 4-12:
701 | let get_opam ~set_opamroot ~set_opamswitch ~force_path st =
          ^^^^^^^^
Error (warning 32 [unused-value-declaration]): unused value get_opam.

File "src/state/opamEnv.ml", line 722, characters 4-16:
722 | let get_opam_raw ~set_opamroot ~set_opamswitch ?(base=[]) ~force_path
          ^^^^^^^^^^^^
Error (warning 32 [unused-value-declaration]): unused value get_opam_raw.

File "src/state/opamEnv.ml", line 811, characters 4-8:
811 | let path ~force_path root switch =
          ^^^^
Error (warning 32 [unused-value-declaration]): unused value path.

File "src/state/opamEnv.ml", line 1251, characters 4-30:
1251 | let clear_dynamic_init_scripts gt =
           ^^^^^^^^^^^^^^^^^^^^^^^^^^
Error (warning 32 [unused-value-declaration]): unused value clear_dynamic_init_scripts.
```
</details>

The warnings 32 can be fixed by following the technique described in [section src/client](#anchor_warning_fix_methodology)

We are done with the unused exported values.

#### Unused constructors and fields

There is no finding in this section.

We are done with the aggressive cleanup and can move on to the informed cleanup

### Informed cleanup

This section takes the findings in lexicographical order (often at once in a
single file) and indicates if their cleanup is reasonable or if it should be
undone, along with a short explanation.

- `src/repository/opamRepository.mli:87: find_backend`: <span class="alert-safe">**clean**</span>\
    I did not find any use outisde opam and all its historical uses have been
    removed.\
    The value seems to be replaced with `find_backend_by_kind`.

- `src/repository/opamRepositoryBackend.mli`: <span class="alert-safe">**clean**</span>\
    I did not find any use of the findings outside opam.

- `src/repository/opamRepositoryConfig.mli`: <span class="alert-safe">**clean**</span>\
    The values `E.fetch` and `E.curl` reported in `src/repository/opamRepositoryConfig.mli` are replaced with their eager equivalent `E.fetch_t` and `E.curl_t`.\
    I did not find any use of the findings outside opam.

- `src/repository/opamRepositoryPath.mli`: <span class="alert-safe">**clean**</span>\
    I did not find any use of the findings outside opam.

### Results

The analyzer reported 8 findings in this component:
8 unused values, 0 unused field or constructor.\
The aggressive cleanup did not reveal any false positive or limitation.\
The informed cleanup did not reveal any false positive or limitation.

From these results, we can compute the precision of the analyzer shown in the
table below. The estimated precision after the informed cleanup can be
extrapolated as the potential fix rate.

| section                 | aggressive | + informed |
|:-----------------------:|:----------:|:----------:|
| exported values         | 100%       | 100%       |
| constructors and fields | NA         | NA         |
| total                   | 100%       | 100%       |

## <li>src/solver</li>

### Description

This component is distributed as the package
[`opam-solver`](https://ocaml.org/p/opam-solver/2.5.1), and has
[4 reverse package dependencies](https://ocaml.org/p/opam-solver/2.5.1#used-by).\
It is described in
[opam/CONTRIBUTING.md#layout](https://github.com/ocaml/opam/blob/2.5.1/CONTRIBUTING.md#layout)
as:
<div class="alert-cite">

> gathers everything related to the various options for constraint solving that opam can use (custom search, dose, mccs, z3, 0install, …)
</div>

In total, there are 58 unused values, and 4 unused fields
reported by the `dead_code_analyzer` for this component.

### Aggressive cleanup

#### Unused exported values

Because the vast majority of the findings are located in `src/solver/opamCudf.mli`
(51 out of 58, i.e. 87.9%), we will clean it first.

Applying steps 1 and 2 of the cleanup methodology for
[unused exported values](./#cleaning-up-unused-exported-values) on the findings in
`src/solver/opamCudf.mli` is trivial.\
All the values exported by `OpamCudf.Json` are unused. This leaves the module's
signature defined as below. The module does not export anything anymore, so it
can be removed entirely.
```OCaml
module Json: sig
  open Cudf_types
end
```
Applying step 3 triggers 8 warnings 32 (reported as errors).
<details><summary>build output</summary>

```bash
$ dune build @check
File "src/solver/opamCudf.ml", line 51, characters 4-23:
51 | let unavailable_package = unavailable_package_name, unavailable_package_version
         ^^^^^^^^^^^^^^^^^^^
Error (warning 32 [unused-value-declaration]): unused value unavailable_package.

File "src/solver/opamCudf.ml", line 52, characters 4-26:
52 | let is_unavailable_package p = p.Cudf.package = unavailable_package_name
         ^^^^^^^^^^^^^^^^^^^^^^
Error (warning 32 [unused-value-declaration]): unused value is_unavailable_package.

File "src/solver/opamCudf.ml", line 624, characters 4-22:
624 | let string_of_universe u =
          ^^^^^^^^^^^^^^^^^^
Error (warning 32 [unused-value-declaration]): unused value string_of_universe.

File "src/solver/opamCudf.ml", line 1226, characters 4-19:
1226 | let conflict_cycles = function
           ^^^^^^^^^^^^^^^
Error (warning 32 [unused-value-declaration]): unused value conflict_cycles.

File "src/solver/opamCudf.ml", line 1288, characters 4-17:
1288 | let uninstall_all universe =
           ^^^^^^^^^^^^^
Error (warning 32 [unused-value-declaration]): unused value uninstall_all.

File "src/solver/opamCudf.ml", line 1293, characters 4-11:
1293 | let install universe package =
           ^^^^^^^
Error (warning 32 [unused-value-declaration]): unused value install.

File "src/solver/opamCudf.ml", line 1303, characters 4-39:
1303 | let remove_all_uninstalled_versions_but universe name constr =
           ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^
Error (warning 32 [unused-value-declaration]): unused value remove_all_uninstalled_versions_but.

File "src/solver/opamCudf.ml", line 2057, characters 4-12:
2057 | let packages u = Cudf.get_packages u
           ^^^^^^^^
Error (warning 32 [unused-value-declaration]): unused value packages.
```
</details>

The warnings 32 can be fixed by following the technique described in [section src/client](#anchor_warning_fix_methodology).\
After 2 more iterations on step 3, building does not trigger any new error or
warning.

Moving on to the rest of the `src/solver` component, all the remaining findings
are in `src/solver/opamSolver.mli`.\
Applying steps 1 and 2 is trivial again.\
Applying step 3 triggers 4 warnings 32 (reported as errors) which can be
cleaned up using the same methodology.
<details><summary>build output</summary>

```bash
dune build @check
File "src/solver/opamSolver.ml", line 23, characters 4-18:
23 | let empty_universe =
         ^^^^^^^^^^^^^^
Error (warning 32 [unused-value-declaration]): unused value empty_universe.

File "src/solver/opamSolver.ml", line 39, characters 4-20:
39 | let solution_to_json solution =
         ^^^^^^^^^^^^^^^^
Error (warning 32 [unused-value-declaration]): unused value solution_to_json.

File "src/solver/opamSolver.ml", line 41, characters 4-20:
41 | let solution_of_json json =
         ^^^^^^^^^^^^^^^^
Error (warning 32 [unused-value-declaration]): unused value solution_of_json.

File "src/solver/opamSolver.ml", line 617, characters 4-23:
617 | let check_for_conflicts universe =
          ^^^^^^^^^^^^^^^^^^^
Error (warning 32 [unused-value-declaration]): unused value check_for_conflicts.
```
</details>

We are done with the unused exported values.

#### Unused constructors and fields

All the findings are located in `src/solver/opamCudfSolverSig.ml`.
In particular, they are all fields of the same type `criteria_def` and amount to
all the fields of that type.
We will follow the more specific cleanup methodology of
[unused constructors and fields](./#cleaning-up-unused-constructors-and-fields)
for this case.

Applying steps 1 and 2 is trivial.\
Applying step 3 triggers 4 errors.
<details><summary>build output</summary>

```bash
$ dune build @check
File "src/solver/opamBuiltinZ3.dummy.ml", lines 23-28, characters 23-1:
Error: Cannot create values of the private type criteria_def

File "src/solver/opamBuiltinMccs.real.ml", lines 15-32, characters 23-1:
Error: Cannot create values of the private type criteria_def

File "src/solver/opamBuiltin0install.ml", lines 25-31, characters 23-1:
25 | .......................{
26 |   crit_default = "-changed,\
27 |                   -count[avoid-version,solution]";
28 |   crit_upgrade = "-count[avoid-version,solution]";
29 |   crit_fixup = "-count[avoid-version,solution]";
30 |   crit_best_effort_prefix = None;
31 | }
Error: Cannot create values of the private type criteria_def

File "src/solver/opamCudfSolver.ml", lines 15-20, characters 30-1:
15 | ..............................{
16 |   crit_default = "-removed,-notuptodate,-changed";
17 |   crit_upgrade = "-removed,-notuptodate,-changed";
18 |   crit_fixup = "-changed,-notuptodate";
19 |   crit_best_effort_prefix = None;
20 | }
Error: Cannot create values of the private type criteria_def
```
</details>

As expected we have errors about the impossibility to write into the fields.
Remember, a field is considered used if it is read. If none of its fields is ever
used, then the values created of type `criteria_def` become useless. We can fix
our errors by removing them and their use, guided by the compilation errors.

After a couple of iterations of step 3, we get the following error:
```OCaml-error
File "src/solver/opamSolverConfig.ml", line 161, characters 4-22:
161 |     S.default_criteria
          ^^^^^^^^^^^^^^^^^^
Error: Unbound value S.default_criteria
```
This is not surprising because we removed the value because it was of type
`criteria_def`.\
However, the referenced code is part of the following larger piece of code in which
the removed value `S.default_criteria` is stored in `criteria`, and its fields
(`crit_default`, `crit_upgrade`, `crit_fixup`, and `crit_best_effort_prefix`) are all visibly read.
```OCaml
  let criteria = lazy (
    let module S = (val Lazy.force config.solver) in
    S.default_criteria
  ) in
  set config
    ~solver_preferences_default:
      (lazy (match config.solver_preferences_default with
           | lazy None -> Some (Lazy.force criteria).OpamCudfSolver.crit_default
           | lazy some -> some))
    ~solver_preferences_upgrade:
      (lazy (match config.solver_preferences_upgrade with
           | lazy None -> Some (Lazy.force criteria).OpamCudfSolver.crit_upgrade
           | lazy some -> some))
    ~solver_preferences_fixup:
      (lazy (match config.solver_preferences_fixup with
           | lazy None -> Some (Lazy.force criteria).OpamCudfSolver.crit_fixup
           | lazy some -> some))
    ~solver_preferences_best_effort_prefix:
      (lazy (match config.solver_preferences_best_effort_prefix with
           | lazy None ->
             (Lazy.force criteria).OpamCudfSolver.crit_best_effort_prefix
           | lazy some -> some))
    ()
```
We hit a new limitation of the analyzer and can open an
[issue](https://github.com/LexiFi/dead_code_analyzer/issues/83) to report it.\
We can conclude that the following reports are
<span class="alert-danger">false positives</span>:
```dca
/tmp/proj/opam/src/solver/opamCudfSolverSig.ml:12: criteria_def.crit_default
/tmp/proj/opam/src/solver/opamCudfSolverSig.ml:13: criteria_def.crit_upgrade
/tmp/proj/opam/src/solver/opamCudfSolverSig.ml:14: criteria_def.crit_fixup
/tmp/proj/opam/src/solver/opamCudfSolverSig.ml:15: criteria_def.crit_best_effort_prefix
```

We are done with the aggressive cleanup and can move on to the informed cleanup

### Informed cleanup

This section takes the findings in lexicographical order (at once in a
single file) and indicates if their cleanup is reasonable or if it should be
undone, along with a short explanation.

- `src/solver/opamCudf.mli`: <span class="alert-safe">**clean**</span>\
    I have found only one use of `OpamCudf` outside of opam, in
    [opam-0install](https://github.com/ocaml-opam/opam-0install-solver/blob/master/test/test.ml#L34),
    and it does not concern any of its findings.

- `src/solver/opamSolver.mli`: <span class="alert-safe">**clean**</span>\
    I did not find any use of the findings outside opam.

### Results

The analyzer reported 62 findings in this component:
58 unused values, 4 unused fields.\
The aggressive cleanup revealed 4 false positives (all the fields),
and 1 new limitation.\
The informed cleanup did not reveal any false positive or limitation.

From these results, we can compute the precision of the analyzer shown in the
table below. The estimated precision after the informed cleanup can be
extrapolated as the potential fix rate.

| section                 | aggressive | + informed |
|:-----------------------:|:----------:|:----------:|
| exported values         | 100%       | 100%       |
| constructors and fields |   0%       |   0%       |
| total                   | 93.5%      | 93.5%      |

The null precision on constructors and fields is not suprising. Because all the
findings amount to all the fields of a type, their truthfulness is strongly
correlated. We are facing an "all or nothing" precision situtation.

## <li>src/state</li>

### Description

This component is distributed as the package
[`opam-state`](https://ocaml.org/p/opam-state/2.5.1), and has
[12 reverse package dependencies](https://ocaml.org/p/opam-state/2.5.1#used-by).\
It is described in
[opam/CONTRIBUTING.md#layout](https://github.com/ocaml/opam/blob/2.5.1/CONTRIBUTING.md#layout)
as:
<div class="alert-cite">

> gathers code dealing with the diverse states of opam (environments, depexts, internal state files handling, pinning, …)
</div>

In total, there are 25 unused values, and 1 unused field
reported by the `dead_code_analyzer` for this component.

### Aggressive cleanup

#### Unused exported values

Applying steps 1 and 2 of the cleanup methodology for
[unused exported values](./#cleaning-up-unused-exported-values) on the findings in
is trivial.\
Applying step 3 triggers 10 warnings 32 (reported as errors).
<details><summary>build output</summary>

```bash
$ dune build @check
File "src/state/opamScript.ml", line 23, characters 4-10:
23 | let prompt =
         ^^^^^^
Error (warning 32 [unused-value-declaration]): unused value prompt.

File "src/state/opamGlobalState.ml", line 165, characters 4-17:
165 | let all_installed gt =
          ^^^^^^^^^^^^^
Error (warning 32 [unused-value-declaration]): unused value all_installed.

File "src/state/opamFileTools.ml", line 1236, characters 4-15:
1236 | let lint_string ?check_extra_files ?check_upstream ?handle_dirname
           ^^^^^^^^^^^
Error (warning 32 [unused-value-declaration]): unused value lint_string.

File "src/state/opamUpdate.ml", line 475, characters 4-19:
475 | let pinned_packages st ?autolock ?(working_dir=OpamPackage.Name.Set.empty) names =
          ^^^^^^^^^^^^^^^
Error (warning 32 [unused-value-declaration]): unused value pinned_packages.

File "src/state/opamSwitchState.ml", line 705, characters 4-9:
705 | let descr st nv =
          ^^^^^
Error (warning 32 [unused-value-declaration]): unused value descr.

File "src/state/opamSwitchState.ml", line 793, characters 4-16:
793 | let dev_packages st =
          ^^^^^^^^^^^^
Error (warning 32 [unused-value-declaration]): unused value dev_packages.

File "src/state/opamEnv.ml", line 701, characters 4-12:
701 | let get_opam ~set_opamroot ~set_opamswitch ~force_path st =
          ^^^^^^^^
Error (warning 32 [unused-value-declaration]): unused value get_opam.

File "src/state/opamEnv.ml", line 722, characters 4-16:
722 | let get_opam_raw ~set_opamroot ~set_opamswitch ?(base=[]) ~force_path
          ^^^^^^^^^^^^
Error (warning 32 [unused-value-declaration]): unused value get_opam_raw.

File "src/state/opamEnv.ml", line 811, characters 4-8:
811 | let path ~force_path root switch =
          ^^^^
Error (warning 32 [unused-value-declaration]): unused value path.

File "src/state/opamEnv.ml", line 1251, characters 4-30:
1251 | let clear_dynamic_init_scripts gt =
           ^^^^^^^^^^^^^^^^^^^^^^^^^^
Error (warning 32 [unused-value-declaration]): unused value clear_dynamic_init_scripts.
```
</details>

The warnings 32 can all be fixed but one, following the technique described in
[section src/client](#anchor_warning_fix_methodology).\
The following warning cannot be fixed trivially because the file
`src/state/opamScript.ml` does not exist. I will come back to this in no time.
```OCaml-error
File "src/state/opamScript.ml", line 23, characters 4-10:
23 | let prompt =
         ^^^^^^
Error (warning 32 [unused-value-declaration]): unused value prompt.
```

After one more iteration of step 3, building does not trigger any new error
warning.\
Let's come back to our unused `prompt` value in `src/state/opamScript.ml`.

The file is actually generated by the following rule in `src/state/dune`:
```dune
(rule
  (targets opamScript.ml)
  (deps    ../../shell/crunch.ml (glob_files shellscripts/*.*sh))
  (action  (with-stdout-to %{targets} (run ocaml %{deps}))))
```
The `crunch.ml` script simply prints out the name of the script and its content in following format for each script provided as argument:
```OCaml
let name =
"content"

```
As a result, this rule creates the `src/state/opamScript.ml` file and fills it
with variables named after the shell scripts found in `src/state/shellscripts`.\
If we continue applying a naive cleanup, we hit a wall here. 2 choices can be made:
- go as far as possible in the cleanup and remove the unused script
    (`src/state/shellscripts/prompt.sh`);
- or tolerate to leave the unused `prompt` variable in `src/state/opamScript.mli`
    because it is generated code.

Because we are doing an _aggressive_ cleanup, I chose to remove the script.
After this, the compiler does not report any unused value.

We are done with the unused exported values.

#### Unused constructors and fields

There is only one report in this section: field `switch_state.invalidated`
in `src/state/opamStateTypes.mli`.\
As usual, applying steps 1 and 2 of the general cleanup methodology for
[unused constructors and fields](./#cleaning-up-unused-constructors-and-fields)
is trivial.\
After 3 iterations of step 3, building does not trigger any new error or warning.

We are done with the aggressive cleanup and can move on to the informed cleanup

### Informed cleanup

This section takes the findings in lexicographical order (often at once in a
single file) and indicates if their cleanup is reasonable or if it should be
undone, along with a short explanation.

- `src/state/opamEnv.mli`: <span class="alert-safe">**clean**</span>\
    I did not find any use of the findings outside opam.

- `src/state/opamFileTools.mli:54: lint_string`: <span class="alert-safe">**clean**</span>\
    I did not find any use of the finding outside opam.

- `src/state/opamFormatUpgrade.mli:26: latest_version`: <span class="alert-safe">**clean**</span>\
    I did not find any use of the finding outside opam.

- `src/state/opamGlobalState.mli`: <span class="alert-safe">**clean**</span>\
    I did not find any use of the findings outside opam.

- `src/state/opamRepositoryState.mli`: <span class="alert-safe">**clean**</span>\
    I did not find any use of the findings outside opam.

- `src/state/opamScript.mli:16: prompt`: <span class="alert-safe">**clean**</span>\
    I did not find any use of the finding outside opam.\
    I'll consider removing the associated script is safe.

- `src/state/opamStateConfig.mli`: <span class="alert-safe">**clean**</span>\
    I did not find any use of the findings outside opam.

- `src/state/opamStateTypes.mli:164: switch_state.invalidated`: <span class="alert-safe">**clean**</span>\
    I did not find any use of the finding outside opam.

- `src/state/opamSwitchState.mli`: <span class="alert-safe">**clean**</span>\
    I did not find any use of the findings outside opam.\
    According to the project's history, this field existed for a single purpose
    and made obsolete during a refactor.

- `src/state/opamSysPoll.mli:21: os_version`: <span class="alert-safe">**clean**</span>\
    I did not find any use of the finding outside opam.

- `src/state/opamUpdate.mli`: <span class="alert-safe">**clean**</span>\
    I did not find any use of the findings outside opam.

### Results

The analyzer reported 26 findings in this component:
25 unused values, 1 unused field.\
The aggressive cleanup did not reveal any false positive or limitation.\
The informed cleanup did not reveal any false positive or limitation.

From these results, we can compute the precision of the analyzer shown in the
table below. The estimated precision after the informed cleanup can be
extrapolated as the potential fix rate.

| section                 | aggressive | + informed |
|:-----------------------:|:----------:|:----------:|
| exported values         | 100%       | 100%       |
| constructors and fields | 100%       | 100%       |
| total                   | 100%       | 100%       |

## <li>src/tools</li>

### Description

This component is not distributed.

In total, there are 5 unused values, and no unused field or constructor
reported by the `dead_code_analyzer` for this component.

### Aggressive cleanup

#### Unused exported values

All the findings are located in `src/tools/opam_admin_top.mli` and they amount
to all the values exported by this module.

Applying steps 1 and 2 of the cleanup methodology for
[unused exported values](./#cleaning-up-unused-exported-values) is trivial.\
There is a type exported that only seems to be used by the exported values,
and an open that becomes unused without the values. Consequently, we can go even
further than a naive cleanup and remove all the content of the file (except for
the copyright and module description).\
Applying step 3 triggers 3 warnings 32 (reported as errors) and 1 warning 34
(reported as error).
<details><summary>build output</summary>

```bash
$ dune build @check
File "src/tools/opam_admin_top.ml", line 18, characters 4-12:
18 | let packages = OpamRepository.packages repo
         ^^^^^^^^
Error (warning 32 [unused-value-declaration]): unused value packages.

File "src/tools/opam_admin_top.ml", line 29, characters 0-51:
29 | type 'a action = [`Update of 'a | `Remove  | `Keep]
     ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^
Error (warning 34 [unused-type-declaration]): unused type action.

File "src/tools/opam_admin_top.ml", line 93, characters 4-17:
93 | let iter_packages ?quiet
         ^^^^^^^^^^^^^
Error (warning 32 [unused-value-declaration]): unused value iter_packages.

File "src/tools/opam_admin_top.ml", line 129, characters 4-19:
129 | let filter_packages = filter OpamPackage.to_string
          ^^^^^^^^^^^^^^^
Error (warning 32 [unused-value-declaration]): unused value filter_packages.
```
</details>

The warnings 34 and 32 can be fixed by following the technique described in [section src/client](#anchor_warning_fix_methodology).\
After 2 more iterations on step 3, building does not trigger any new error or
warning.
Now both the `.mli` and the `.ml` only contain the copyright notice and
a documentation comment.\
Therefore, we can go further in the cleanup and remove this module entirely.
Doing so requires a few extra steps.

First we need to remove the whole `library` stanza from `src/tools/dune`:
```dune
(library
  (name         opam_admin_top)
  (public_name  opam-admin.top)
  (synopsis     "OCaml Package Manager admin toplevel")
  (modules      opam_admin_top)
  ; TODO: Remove (re_export ...) when CI uses the OCaml version that includes https://github.com/ocaml/ocaml/pull/11989
  (libraries    opam-client opam-file-format (re_export compiler-libs.toplevel) re)
  (wrapped      false))
```

Then, we also need to edit the `executable` stanza in the same file, to replace
the dependecy on the removed lib to a dependency on the ocaml toplevel:
```diff
 (executable
   (name         opam_admin_topstart)
   (public_name  opam-admin.top)
   (package      opam-admin)
   (modes        byte)
   (modules      opam_admin_topstart)
-  (libraries    opam-admin.top)
+  (libraries    compiler-libs.toplevel)
   (ocamlc_flags (:standard
                 (:include ../ocaml-flags-standard.sexp)
                 (:include ../ocaml-flags-configure.sexp)
                 (:include ../ocaml-context-flags.sexp)
                 -linkall)))
```

Finally, in the same `dune` file we must update the rule that generates
`src/tools/opam_admin_topstart.ml` to remove its dependency on `Opam_admin_top`:
```diff
-(rule (with-stdout-to opam_admin_topstart.ml (echo "include Opam_admin_top\n\nlet _ = Topmain.main ()")))
+(rule (with-stdout-to opam_admin_topstart.ml (echo "let _ = Topmain.main ()")))
```

We are done with the unused exported values.

#### Unused constructors and fields

There is no finding in this section.

We are done with the aggressive cleanup and can move on to the informed cleanup

### Informed cleanup

This section takes all the findings at once in a single file and indicates if
their cleanup is reasonable or if it should be undone, along with a short
explanation.

- `src/tools/opam_admin_top.mli`: <span class="alert-danger">**undo**</span>\
    The module is actually used inside opam in `admin-scripts`.
    This was missed by the analyzer because the files in `admin-scripts` are not
    part of the build.\
    The only value I could not find using `grep` is `filter_packages`.
    I would not dismiss it, because the component should have been considered
    out of scope based on its documentation:
    ```OCaml
    (** Small lib for writing opam-repo admin scripts *)
    ```

### Results

The analyzer reported 5 findings in this component:
5 unused values, 0 unused field or constructor.\
The aggressive cleanup did not reveal any false positive or limitation.\
The informed cleanup indicates no finding should be removed. This is due to a
methodology mistake.

From these results, we can compute the precision of the analyzer shown in the
table below. The estimated precision after the informed cleanup can be
extrapolated as the potential fix rate.

| section                 | aggressive | + informed |
|:-----------------------:|:----------:|:----------:|
| exported values         | 100%       |   0%       |
| constructors and fields | NA         | NA         |
| total                   | 100%       |   0%       |

\
\
\
We are done with the detailed cleanup.\
[Back to the study report of using the analyzer on opam](./).
