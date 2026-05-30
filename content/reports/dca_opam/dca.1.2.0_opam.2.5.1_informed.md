---
title: Dead code analyzing Opam
description: Running the dead_code_analyzer on opam
date: 2026-05-05
tags: [dead_code_analyzer, opam, ocaml, static analysis, ocaml software foundation]
---

This experiment uses the `dead_code_analyzer 1.2.0` on `opam 2.5.1`.
It is funded by the [OCaml Software Fundation](https://ocaml-sf.org/).

This is a follow up on the naive cleanup. We will re-examine the results with a more context-aware eye.

In order to achive that goal, we will reuse the cleanup done with the naive approach, check if it makes sense and undo it when not.

Let's re-explore the `dead_code_analyzer` results on `Opam` in the same order as for the naive cleanup.

### Unused exported values

The [report](/assets/reports/dca/opam/dca.out)'s unused exported values section initial content is 433 lines long after discarding the header, footer, and blank lines.

#### Client

This section focuses on reports in `/tmp/proj/opam/src/client`.

This component builds into the library [`opam-client`](https://opam.ocaml.org/packages/opam-client/). Thus, we must be very careful when choosing to remove a value.

#### Format

This section focuses on reports in `/tmp/proj/opam/src/format`.

Investigating the unused `OpamFile.*.with_*` functions, I found a mistake in opam :
`OpamFile.Wrappers.with_pre_remove` is used in [`src/client/opamConfigCommand.ml`](https://github.com/ocaml/opam/blob/2.5.1/src/client/opamConfigCommand.ml#L665),
where `OpamFile.Wrappers.with_wrap_remove` is expected. Thus, it should not be removed but used.

The `OpamFile.Config.with_*` and `Opam.InitConfig.with_*` exist to update valeus of the abstract `t`. Keeping them, even if unused, would make sense.
However, because the 2 APIs already show some inconsistencies, I think it would make sense to reduce them to what is actually used for easier maintenance. Thus, I'll consider them actually unused and they can be kept remoived.

Although I found a use of `OpamFile.Descr.full` in [an external package](with_jobs), its last update was 8 years ago. Thus, I'll consider the reported values in `OpamFile.Descr` as unused and keep them removed.

By the same reasoning as with `OpamFile.Config.with_*`, I'll consider the reported `OpamFile.URL.with_*` values as unused and keep them removed.

Some of the reported values in `OpamFile.OPAM` are simple accessors, that existed for a long time and were sensical when `OpamFile.OPAM.t` was abstract.
Now that the type is private, the fields can be accessed directly and the getters do not provide any additional value.
The same argument as before can be applied to the setters (`with_*` values).
However, multiple reported values are used by external packages:
- `extended` in [`opam-monorepo`](https://github.com/tarides/opam-monorepo/blob/main/lib/opam.ml#L313)
- `homepage`, `author`, `license`, and more in [dune-release](https://github.com/tarides/dune-release/blob/main/lib/opam.ml#L181)

Thus, it will be safer to consider the values in `OpamFile.OPAM` as used and not remove them.

`OpamFile.Environment` does not seem to be used outside of opam and its reported values' history show that they are indeed unused. I'll keep them removed.

`src/format/opamFile.mli` contains the following comment on its `Comp` module:
```
(** Compiler version [$opam/compilers/]. Deprecated, only used to upgrade old
```
Thus, I'll consider its values are indeed unused and can be kept removed.

By the same reasoning as with `OpamFile.Config.with_*`, I'll consider the reported `OpamFile.Dot_install.with_*` values as unused and keep them removed.
This corresponds to all the `with_*` setters. Because `OpamFile.Dot_install.t` is abstract, this means that those fields are never updated externally.
Additionally, the module is never used outside of opam, so I'll also consider that the reported `Dot_install.variablesè can be kept removed.

I have not found any use of `OpamFile.Repo.browse` outside of opam but found one of `OpamFile.Repo.upstream` in [Opam2Web](https://github.com/ocaml-opam/opam2web/blob/master/src/o2wPackage.ml#L472).
Thus, I'll consider the first one is indeed unused and can be kept removed, but the second one should ne be removed.
Regarding the reported `OpamFile.Repo.with_*` values, by the same reasoning as with `OpamFile.Config.with_*`, I'll consider them as unused and keep them removed.

I did not find any external use of the values reported in `OpamFile.Syntax`. I have not found any historical use outside their compilation units as well.
Thus, I'll consider they are indeed unused and can be kept removed.

Among all the values reported in `src/format/opamFilter.mli`, I could only find the use of one: `OpamFilter.eval` in [opam-0install](https://github.com/ocaml-opam/opam-0install-solver/blob/master/lib/dir_context.ml#L104).
Thus, I'll consider this values should not be removed while all the other are indeed unused and can be kept removed.

There is a comment in [`src/format/opamFormat.mli` at line 287](https://github.com/ocaml/opam/blob/2.5.1/src/format/opamFormat.mli#L287)
indicating a wor in progress:
```OCaml
  (** Signature handling (wip) *)
```
Thus, I'll consider everything related to this comment should not be removed.

I did not find any use outside of opam of the other values reported in `src/format/opamFormat.mli`.
Thus, I'll consider they are indeed unused and keep them removed.

Among the values reported in `src/format/opamFormula.mli`, `iter` is actually used by `admin-scripts/depopts_to_conflicts.ml`.
This was missed by the analyzer because the files in `admin-scripts` are not part of the build.
The other values do not appear used outside of opam. Thus, I'll consider the first one as actually being used and the other as indeed unused.

I have not found any external use of the values reported in `src/format/opamPath.mli`. Thus, I'll consider they are indeed unused and can be kept removed.

I have not found any external use of the value reported in `src/format/opamPp.mli`. Thus, I'll consider it is indeed unused and can be kept removed.

I have not found any external use of the values reported in `src/format/opamSysPkg.mli`. Thus, I'll consider they are indeed unused and can be kept removed.

I have not found any external use of the values reported in `src/format/opamTypesBase.mli`. Thus, I'll consider they are indeed unused and can be kept removed.

#### Repository

This section focuses on reports in `/tmp/proj/opam/src/repository`.

The value `find_backend` reported in `src/repository/opamRepository.mli` seems to be replaced by `find_backend_by_kind`.
I cannot find any external use of it and all its historical uses have been removed. Thus, I'll consider it is indeed unused and can be kept removed.

I have not found any external use of the values reported in `src/repository/opamRepositoryBackend.mli`. Thus, I'll consider they are indeed unused and can be kept removed.

The values `E.fetch` and `E.curl` reported in `src/repository/opamRepositoryConfig.mli` are replaced by their eager equivalent `E.fetch_t` and `E.curl_t`.
I did not find any use outside of opam. Thus, I'll consider they are indeed unused and can be kept removed.

The values reported in `src/repository/opamRepositoryPath.mli` were historically used but not anymore.
I did not find any use outside of opam. Thus, I'll consider they are indeed unused and can be kept removed.

#### Solver

This section focuses on reports in `/tmp/proj/opam/src/solver`.

I have found only one use of `OpamCudf` outside of opam and it does not concern any of its reported values.
Thus, I'll consider they are indeed unused and can be kept removed.

I have not found any external use of the values reported in `src/solver/opamSolver.mli`.
Thus, I'll consider they are indeed unused and can be kept removed.

#### State

This section focuses on reports in `/tmp/proj/opam/src/state`.

I have not found any external use of the values reported in `src/state/opamEnv.mli`.
Thus, I'll consider they are indeed unused and can be kept removed.

I have not found any external use of `OpamFileTools.lint_string`.
Thus, I'll consider it is indeed unused and can be kept removed.

I have not found any external use of `OpamFormatUpgrade.latest_version`.
Thus, I'll consider it is indeed unused and can be kept removed.

I have not found any external use of the values reported in `src/state/opamGlobalState.mli`.
Thus, I'll consider they are indeed unused and can be kept removed.

I have not found any external use of the values reported in `src/state/opamRepositoryState.mli`.
Thus, I'll consider they are indeed unused and can be kept removed.

I have not found any use of `OpamScript` outside of opam.
Thus, I'll consider its reported value is indeed unused and can be kept removed, along with all the code generation cleanup.

I have not found any external use of the values reported in `src/state/opamStateConfig.mli`.
Thus, I'll consider they are indeed unused and can be kept removed.

I have not found any external use of the values reported in `src/state/opamSwitchState.mli`.
Thus, I'll consider they are indeed unused and can be kept removed.

I have not found any external use of `OpamSysPoll.os_version`.
Thus, I'll consider it is indeed unused and can be kept removed.

I have not found any use of `OpamUpdate` outside of opam.
Thus, I'll consider its reported value is indeed unused and can be kept removed.

#### Tools

This section focuses on reports in `/tmp/proj/opam/src/tools`.

`Opam_admin_top` is actaully used in `admin-scripts`.
This was missed by the analyzer because the files in `admin-scripts` are not part of the build.
Thus, I'll consider its values are used and should not be removed

### Unused constructors/record fields

The [report](../assets/reports/dca/opam/dca.out)'s unused constructors/record fields section initial content is 75 lines long after discarding the header, footer, and blank lines.

#### Core

This section focuses on reports in `/tmp/proj/opam/src/core`.

It is, however, more complicated to verify
if a type component is used than a value component. The Serlocode search requires looking for places where the module is used, and then for the use of the component near those places.

#### Format

This section focuses on reports in `/tmp/proj/opam/src/format`.

I did not find any external use of `OpamTypes.universe.u_action`.
I also did not find external use of any of the constructors of `OpamTypes.lock`.
Thus, I'll consider the field and constructors reported in `src/format/opamTypes.mli` are indeed unused and keep their cleanup.

#### State

This section focuses on reports in `/tmp/proj/opam/src/state`.

I did not find any external use of `OpamStateTypes.switch_state.invalidated`.
According to the project's history, this field existed for a single purpose and made obsolete during a refactor.
Thus, I'll consider it is indeed unused and can be kept removed.
