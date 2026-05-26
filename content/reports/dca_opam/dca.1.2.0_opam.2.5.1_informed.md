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
