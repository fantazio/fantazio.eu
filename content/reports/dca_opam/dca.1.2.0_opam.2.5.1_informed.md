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
