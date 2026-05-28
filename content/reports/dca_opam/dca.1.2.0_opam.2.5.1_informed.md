---
title: Dead code analyzing Opam
description: Running the dead_code_analyzer on opam
date: 2026-05-05
tags: [dead_code_analyzer, opam, ocaml, static analysis, ocaml software foundation]
---

This experiment uses the `dead_code_analyzer 1.2.0` on `opam 2.5.1`.
It is funded by the [OCaml Software Fundation](https://ocaml-sf.org/).

This is a follow up on the naive cleanup. We will re-examine the results with a more context-aware eye.

The naive cleanup removed all that it could among the reports. This time, we will try and evaluate which removals seem legitimate and which not.
There can be multiple reasons for some code to be reported as unused by the `dead_code`analyzer` although it should not be blindly removed from the codebase:
1.  The most obvious and common reason will be that the reported element is part of an exposed API.
    The exported API is probably used outside the project so the element's uses cannot be detected.
    <div class="alert-tip">

    > **TIP**:\
    > Using [sherlocode](https://sherlocode.com) may be helpful to verify if a reported API element is used somewhere.
    > However, it may not be sufficient because it only scans project in `Opam` (I think ?), and unlisted projects may use the element.
    </div>

2.  The build configuration removed/replaced the uses of the reported element.
    This may happen e.g. if there is some platform-dependent code selected at build time,
    or if an environment variable is used to activate certain code paths (e.g. a debug profile).

3. The reported element is part of a work in progress.

The list above is not exhaustive but I believe it must cover most of the cases.

The goal of the exercise presented in this report is to reduce the amount of work required for
the maintainers to review (and approve) the cleanup done using the analyzer.
In order to achive that goal, we will reuse the cleanup done with the naive approach, check if it makes sense and undo it when not.

Let's re-explore the `dead_code_analyzer` results on `Opam` in the same order as for the naive cleanup.

### Unused exported values

The [report](/assets/reports/dca/opam/dca.out)'s unused exported values section initial content is 433 lines long after discarding the header, footer, and blank lines.

#### Client

This section focuses on reports in `/tmp/proj/opam/src/client`.

This component builds into the library [`opam-client`](https://opam.ocaml.org/packages/opam-client/). Thus, we must be very careful when choosing to remove a value.

I was able to find an external use of [`OpamAction.prepare_package_build`](https://github.com/timbertson/opam2nix/blob/v1/src/invoke.ml#L258), thanks to the file's history ([PR #4147](https://github.com/ocaml/opam/pull/4147)). Thus, it should not have been unexported.

The history of `src/client/opamAdminCheck.mli` is not very telling. Similarly to its `.ml` counter part.
Apparently, the reported values were added in the same [PR #3253](https://github.com/ocaml/opam/pull/3253) and never used outside their compilation units.
Let's consider them unused and keep them unexported.

I tried to follow the history of `OpamArg.name_list` and it appears to have been made redundant by the unexported `OpamCommands.name_list`.
From this observation, and the absence of use of the other values (even in Sherlocode),
I'll assume all the reported values in `src/client/opamArg.mli` are indeed unused and can be kept unexported.
The documentation of the module leads to the same conclusion:
```OCaml
(** Command-line argument parsers and helpers *)
```

Based on the documentation of `src/client/opamAuxCommands.mli` and its naming, i'll assume the reported values are indeed unused and can be kept unexported.

My understanding of the module `OpamCliMain` is that it is meant for use by the binary entry point, not as a library. Thus I'll assume the reported values are indeed unused and can be kept unexported.

As far as I can tell by looking the history of `OpamClient.reinstall_t`, was used by `OpamMain` until [PR #2904](https://github.com/ocaml/opam/pull/2904).
The `OpamClient` module seems to be only be used by opam itself. I'll consider its reported values are unused and keep them unexported.

Based on the documentation of `src/client/opamClientConfig.mli`, I would assume its exported values may
be used in other projects and should have not been unexported. However, I doubt the reported value
`search_file` is actually used anywhere outside of opam, so I'll assume it can be kept unexported.

Based on the documentation of `src/client/opamConfigCommand.mli`, I'll assume the reported values are indeed unused and can be kept unexported.

Based on the documentation of `src/client/opamInitDefaults.mli`, I'll assume the reported values are indeed unused and can be kept unexported.

Based on the documentation of `src/client/opamListCommand.mli`, I'll assume the reported values are indeed unused and can be kept unexported.

Based on the documentation of `src/client/opamRepositoryCommand.mli`, I'll assume the reported values are indeed unused and can be kept unexported.

When trying to track the history of `OpamSolution.eq_atom`, I was under the impression that its
package specific version `OpamSolution.eq_atom_of_package` was meant to replace it. Thus `eq_atom` should not be exported.
Regarding `OpamSolution.sum`, it exists almsot since the origins of opam in [2012](https://github.com/ocaml/opam/commit/dd0c0ca284aeb520394acb91d15e01f919ed8b7e). I'll assume it was moved around and forgotten since then, so it can be kept unexported as well.

#### Core

This section focuses on reports in `/tmp/proj/opam/src/core`.

I'll assume all the reports in `src/core/cmdliner` to be valid, because it seems that this component is meant for opam use.

Based on the intent of `OpamCompat`, the value `Lazy.map_val` should not be be removed, although it has never been used according to the project's history.

The reported values in `src/core/opamConsole.mli` were either never used or their uses have been internalized during refactors.
I'll consider they are indeed unused and can be kept unexported.

The reported values in `src/core/opamCoreConfig.mli` were used externally but their uses have been re-internalized during re-factors.
I'll consider they are indeed unused and can be kept unexported.

The reported values in `src/core/opamDirTrack.mli` were never used outside their compilation units.
I'll consider they are indeed unused and can be kept unexported.

The reported values in `src/core/opamFilename.mli` were used externally but their uses external uses have been removed or re-internalized during re-factors.
I'll consider they are indeed unused and can be kept unexported.

The reported values in `src/core/opamHash.mli` were never used externally.Additionally, computing hashes
seems to be meant to do externally via `OpamHash.compute` (12 occurences) or `OpamHash.compute_from_string` (6 occurences)
rather than by calling the direct hash function (`OpamHash.md5` and `OpamHash.sha256`: 0 occurence, `OpamHash.sha512`: 1 occurence).
Thus I'll consider the reported values as unused, keep them updated, and go even further by unexporting `OpamHash.sha512` and replace its use by ``OpamHash.compute ~kind:`SHA512``.

Although `OpamParallel.iter` is not used anymore, it can come in handy and left available for the API consistency.
Also, I found a use [outside of opam](https://github.com/AltGr/opam-bundle/blob/1fcd2e67d91b9062ca79565d6e95dfd0294cebaf/src/opamBundleMain.ml#L732).
Thus, I'll un-remove it.

`OpamProcess` seems to be meant for internal use so I'll consider the reported values are indeed unused and can be kept unexported.

The same observation as for `OpamHash` can be made for the reported values in `src/core/opamSHA.mli`. Once again, I'll consider the reported values as unused, keep them removed, and go even further by unexporting `OpamSHA.sha1_string` and replace its use by ``OpamSHA.hash_string `SHA1``.

Based on the intent of `OpamStd`, none of its values should be removed.

According to the comment in `src/core/opamStubs.mli`, most of its functions are windows-specific. I am using Linux, and the compilation of opam is dependent on os-type, as shown in `src/core/dune`:
```dune
(rule
  (enabled_if (<> %{os_type} "Win32"))
  (action (copy# opamStubs.unix.ml opamStubs.ml)))

(rule
 (enabled_if (= %{os_type} "Win32"))
 (action (copy# opamWin32Stubs.win32.ml opamWin32Stubs.ml)))
```
Thus, I'll ignore the reports and its values should not be removed.

In `src/core/opamSystem.mli` there is the following comment line 216:
```OCaml
(** OLD COMMAND API, DEPRECATED *)
```
Thus, I'll consider everything reported below that line as effectively unused.
Regarding the 4 values reported above that comment, a quick history check show that they became unused externally through consecutive improvements of opam. I'll consider that these values are indeed unused and that all can be kept removed.

The reported values in `src/core/opamVersion` are indeed not used anymore and can be removed.

`OpamVersionCompare.equal` does not seem to have ever been used. Thus, I'll consider it as indeed unused and keep it removed.

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

#### Client

This section focuses on reports in `/tmp/proj/opam/src/client`.

The documentation of `src/client/opamListCommand.mli` indicates that it is intended for the `opam list` subcommand.
Additionally, there is no use of this module outside opam.
Thus, I'll consider its reported constructors and fields are indeed unused and can be kept removed

