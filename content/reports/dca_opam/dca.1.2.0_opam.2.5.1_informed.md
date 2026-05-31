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


#### State

This section focuses on reports in `/tmp/proj/opam/src/state`.

I did not find any external use of `OpamStateTypes.switch_state.invalidated`.
According to the project's history, this field existed for a single purpose and made obsolete during a refactor.
Thus, I'll consider it is indeed unused and can be kept removed.
