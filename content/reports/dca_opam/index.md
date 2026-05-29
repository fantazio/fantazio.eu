---
title: Dead code analyzing Opam
description: This report is the result of an audit of opam using the dead_code_analyzer.
date: 2026-05-28
tags: [dead_code_analyzer, opam, ocaml, static analysis, dead code, ocaml software foundation]
---

## Table of content
- [Foreword](#foreword)
- [Setup](#setup)
    - [opam](#opam)
    - [dead_code_analyzer](#dead_code_analyzer)
- [Observations](#observations)
- [Methodology](#methodology)
    - [Cleaning up unused exported values](#cleaning-up-unused-exported-values)
    - [Cleaning up unused constructors and fields](#cleaning-up-unused-constructors-and-fields)
    - [Informed cleanup](#informed-cleanup)
- [Cleanup](#cleanup)
    - [src/client](#srcclient)
    - [src/core](#srccore)
    - [src/format](#srcformat)
    - [src/solver](#srcsolver)
    - [src/state](#srcstate)
    - [src/tools](#srctools)

## Foreword

This audit was funded by the [OCaml Software Fundation](https://ocaml-sf.org/).
Thanks again for their trust.

It has 2 main goals :
1. Audit opam and provide feedback to the maintainers;
2. Test the `dead_code_analyzer` on "real-world" code.

Hopefully, this report will provide more visibility to the `dead_code_analyzer`
and a practical demonstration of its usage.

To keep this report accessible and its goals explicit, the report is organized
by "component" although, in practice, I followed the analyzer's results by
"report section". This will be discussed in more details at the end of this report.

<div class="alert-caution">

> **Disclaimer:**\
> I am not an opam developer. My observations and judgements are those of a
> newcomer and may be mistaken. They will be corrected by an external
> review process.
</div>

## Setup

This work is done using **OCaml 5.3**.

### opam

In order to analyze opam, we need to build the project and generate the `.cmt`
and `.cmti` files necessary for the `dead_code_analyzer`.

First, we will clone the repository where we want it and checkout its latest
release tag. In our case, we will work in `/tmp/proj` and the
[latest release](https://github.com/ocaml/opam/releases/tag/2.5.1) is `2.5.1`:
```bash
$ pwd
/tmp/proj
$ git clone https://github.com/ocaml/opam
Cloning into 'opam'...
remote: Enumerating objects: 77143, done.
remote: Counting objects: 100% (1101/1101), done.
remote: Compressing objects: 100% (478/478), done.
remote: Total 77143 (delta 853), reused 623 (delta 623), pack-reused 76042 (from 3)
Receiving objects: 100% (77143/77143), 42.13 MiB | 26.00 KiB/s, done.
Resolving deltas: 100% (59557/59557), done.
$ cd opam
$ git checkout -b dca_opam 2.5.1 # create branch `dca_opam` starting at tag 2.5.1
Switched to a new branch 'dca_opam'
```

<div class="alert-note">

> **Note:**\
> We are selecting a specific release as reference (2.5.1) for 2 reasons:
> 1. For reproducibility. Without it, depending on the date, the code may be
>    different and the results as well.
> 2. I assume a release state is a "stable state".
>    Thus, there are less chances of encountering works in progress.
</div>


Then, following [these instructions](https://github.com/ocaml/opam/tree/2.5.1#compiling-this-repo)
to build opam is pretty straigthforward. However, it needed a few adjustment:
1.  Run `opam install . --deps-only` before `./configure`.\
    This ensures all the dependencies are installed.
2.  Run `dune build @check` instead of `make`.\
    Dune's alias [`@check`](https://dune.readthedocs.io/en/stable/reference/aliases/check.html)
    produces the `.cmi`, `cmt`, and `.cmti` files.
    ```bash
    $ dune build @check
    File "src/tools/opam_admin_topstart.ml", line 1:
    Warning 70 [missing-mli]: Cannot find interface file.
    ```
3. We do not run `make install`

<div class="alert-note">

> **Note:**\
> When running `make`, only the `.cmi` and `.cmti` files are generated, but
> not the `.cmt` files. This is because the OCaml compiler flag `-keep-locs`
> is enabled by default but not `-bin-annot`.
>
> Using `./configure --enable-developer-mode` does not enable `-bin-annot`,
> so the call to `dune build @check` is still necessary.
>
> We can tell that building opam relies on dune by the output of `make`.
>   ```bash
>   $ make
>   dune build --profile=release --root .  --promote-install-files -- opam-installer.install opam.install
>   sed -f process.sed opam.install > processed-opam.install
>   dune build --profile=release --root .  --promote-install-files -- opam-installer.install
>   sed -f process.sed opam-installer.install > processed-opam-installer.install
>   ```
</div>

Now that we have generated the necessary files, let's move on to running the
`dead_code_analyzer`.

### dead_code_analyzer

This audit is made using the
[latest release](https://github.com/LexiFi/dead_code_analyzer/releases/tag/1.2.0)
of the `dead_code_analyzer` available : `1.2.0`. It is available via opam.
```bash
$ opam install dead_code_analyzer.1.2.0
The following actions will be performed:
=== install 1 package
  ∗ dead_code_analyzer 1.2.0

<><> Processing actions <><><><><><><><><><><><><><><><><><><><><><><><><><><><>
⬇ retrieved dead_code_analyzer.1.2.0  (cached)
∗ installed dead_code_analyzer.1.2.0
Done.
```

Now that we have opam's `.cmt` and `.cmti` files, and the analyzer installed, let's run it:
```bash
$ dead_code_analyzer --verbose _build 2> dca.err > dca.out
```
Before looking at the results, let's dissect the command above.

We run the `dead_code_analyzer` with the `--verbose` flag. This will print out
all the files that are analyzed on `stderr` and indicate issues (if any) when
reading some files.\
The analyzer is given `_build` as argument. The `.cmt` and `.cmti` files are
somewhere within that directory. We could have been more precise and provided
e.g. `_build/default` as argument or even `_build/default/src` but we'll keep
things as simple as possible for now.\
Finally, the `stderr` (output of verbose) is redirected to `dca.err`, and
`stdout` (the results) is redirected to `dca.out`.

[dca.out is available here.](../../assets/reports/dca/opam/dca.1.2.0_opam.2.5.1.out)\
[dca.err is available here.](../../assets/reports/dca/opam/dca.1.2.0_opam.2.5.1.err)

<div class="alert-tip">

> **Tip:**\
> I would generally recommend redirecting the output of the analyzer to a file.\
> Similarly, on the first run, I'd recommend using `--verbose` to verify that
> nothing went wrong. Issues when reading files or noticing some files are
> missing from the analyzer's list can quickly help debug some unexpected results.

We are not using any other argument. The analyzer is running with the default
sections activated:
- unused exported values
- unused methods
- unused fields and constructors

For more information on the report sections and the usage of the analyzer,
feel free to explore [its documentation](https://github.com/LexiFi/dead_code_analyzer/blob/master/docs/USER_DOC.md)

According to the `dca.err`, 248 files were scanned successfully, and nothing
seems to be missing.

We can get an order of magnitude of the amount of reports by counting the lines
in the output :
```bash
$ wc -l dca.out
545 dca.out
```
The analyzer reported 500+ unused exported values, unused methods, and unused
constructors and fields. 508 more precisely. Let's explore the reports !

## Observations

Before exploiting the findings of the analyzer, let's make some observations
about them.

The paths of the locations are absolute.\
In this report, the opam project is located at`/tmp/proj/opam`. This prefix may
vary depending on the location of your clone.\
Because dune copies (and generates) the files in `_build` before compiling them,
files located in `/tmp/proj/opam/src` appear in
`/tmp/proj/opam/_build/default/src`. The modifications must be done on the
original files and not on their copies.

The findings are organized by section. Each section is delimited by a header and
a footer.\
Within sections, the findings are sorted in lexicographical order and a blank
line is inserted between each change of directory. This allows for an easier
focus on each "component" of the codebase.\
In this report, we can distinguish 7 components and 1 subcomponent :
- `src/client`
- `src/core/cmdliner` (subcomponent of `src/core`)
- `src/core`
- `src/format`
- `src/solver`
- `src/state`
- `src/tools`
- `tests/lib`

We will focus only on the findings in `src`.
<div class="alert-tip">

> **Tip:**
> In order to avoid tracking declarations in `tests` (and reporting on it),
> we can update our `dead_code_analyzer` command to:
> ```bash
> $ dead_code_analyzer --exclude _build/default/tests --references _build/default/tests --verbose _build 2> dca.err > dca.out
> ```
> 2 new options are used:
> - `--exclude <path>` skips the `.cmt` and `.cmti` files found in `<path>`
> - `--references <path>` analyzes the `.cmt` and `.cmti` files found in
>   `<path>` to find uses in them.
>
> Alternatively, because we want to focus on code in `src` while tracking uses
> in the whole codebase, we can use the following simpler command:
> ```bash
> $ dead_code_analyzer --references _build --verbose _build/default/src 2> dca.err > dca.out
> ```
> This command gather uses from `_build` but only tracks code declared in
> `_build/default/src`.
</div>

The unused methods' section is empty:
```dca
.> UNUSED METHODS:
=================

Nothing else to report in this section
--------------------------------------------------------------------------------
```
By grepping the codebase, we can quickly verify that there is no use of objects or classes, confirming that there cannot be any unused method:
```bash
$ grep -rnw -e object -e class src
grep -rnw -e object -e class src
src/state/opamSwitchState.mli:  199:        backward conflict definition or common conflict-class. Packages in [subset]
src/core/opamStubs.mli:  96:        and a font object, which will have been selected into the DC.
src/core/opamStubs.mli: 101:    (** Windows only. Given [(dc, font)], deletes the font object and releases the
src/core/opamStubs.mli: 150:    (** Windows only. Returns the name of the class for the Console window or [None]
src/core/cmdliner/cmdliner_base.ml:   11:         (* Thread-safe UIDs, Oo.id (object end) was used before.
src/client/opamListCommand.ml:  832:        Field "conflict-class";
src/client/opamArg.ml: 1633:           list, from the other package, or by a common $(b,conflict-class:) \
src/format/opamFile.ml:  3008:        "conflict-class", no_cleanup Pp.ppacc with_conflict_class conflict_class
```

## Methodology

The analyzer does not track "transitively" dead elements of code (i.e. code only used by dead code).
Thus, all the findings can be examined independently from each other.

Because there are 2 goals to this audit, I processed the analyzer's reports in
2 phases:
1.  An agressive cleanup, which assumes all the findings can be removed from the
    codebase. The goal is to verify that none of them is a false positive.
    Otherwise, identify the cause and document it if necessary.
2.  An informed cleanup, which relies on contextual information to ensure that
    removing some code is reasonable.

The second phase is necessary because opam exposes its internals as libraries
and we want to reduce the work required for the maintainers to review (and
approve) the cleanup done using the analyzer.

Although I followed the analyzer's output in order (by section), and applied each
phase separately, this report will discuss the findings by component (grouping
sections) and discuss the 2 phases for each component.
I hope the results will be clearer to follow this way.

<div class="alert-warning">

> **Important**:\
> Removing dead code reported by either the analyzer or the compiler can lead to
> the discovery of new dead code for both the analyzer and the analyzer.
> Because neither the analyzer nor the compiler reports "transitively" dead code,
> multiple iterations may be necessary to uncover it all.
>
> The current report is focused on a single iteration of the analyzer, followed
> by as-many-as-necessary iterations of the compiler. This whole process could
> be repeated multiple times until neither the analyzer nor the compiler reports
> anything new.
</div>

### Cleaning up unused exported values

Cleaning up unused exported values is pretty straightforward:
1. go to the reported locations,
2. remove the values (along with their associated attributes and comments),
3. build and fix the warnings and errors,
4. repeat step 3 until there is nothing left to fix.

<div class="alert-tip">

> **Tip:**\
> Because removing content from a file will change the location of subsequent
> content, I would recommend to start at the bottom of a file and go up.
</div>

### Cleaning up unused constructors and fields

Cleaning up unused constructors and fields is almost straightforward.
In general, it is the same as for unused exported values:
1. go to the reported locations,
2. remove the elements (along with their associated attributes and comments),
3. build and fix the warnings and errors,
4. repeat step 3 until there is nothing left to fix.

However, sometimes the findings cumulate to whole types. The analyzer does not
report unused types yet but will report all their components. In this situation,
step 2 changes and more cleanup iterations are necessary:
1. go to the reported locations,
2. make the exported types `private`,
3. build, fix, repeat,
4. make the exported types abstract,
5. build, fix, repeat,
6. remove the exported types,
7. build, fix, repeat.

In this new process, the cleanup may not reach the end but stop after step 3 or 5.\
Making types abstract (step 4) means that you completely lose the ability to match on
the constructors. This should not be an issue with records because reading a field is considered as a use.\
Removing a type from an interface (step 6) means that it cannot be referenced
in any signature, so values of that type or manipulating it cannot be exported.
There can be cases of types used externally but not their content.

<div class="alert-caution">

> **Caution:**\
> Removing a field or a constructor will most likely trigger compilation errors.
> This is for 2 reasons:
> 1. the types described in the signature and the structure must be equal,
> 2. a field is considered unused if it is never read (but it must be written
>    when creating a value),
     and a constructor is considered unused if it is never constructed (but it
     may be destructed e.g. in pattern matching).
>
> Therefore, cleaning up an unused field or constructor may have a greater
> impact on a codebase than a simple removal.
</div>

### Informed cleanup

There are multiple reasons for some code to be reported as unused by the
`dead_code_analyzer` while it should not be cleaned up from the codebase:
1.  The most obvious and common reason is that the reported element is part
    of an exposed API.
    The API is probably used outside the project so the element's uses cannot be
    detected.\
    If unused, the element may still exist for coherence.

2.  The build configuration removed/replaced the uses of the reported element.
    This may happen e.g. if there is some platform-dependent code selected at
    build time,
    or if an environment variable is used to activate certain code paths (e.g. a debug profile).

3. The reported element is part of a work in progress.

This list is non-exhaustive but provides a scope to guide what to look for when
deciding whether a finding should be cleaned up.\
There are different sources of information that can be used to contextualize a
finding (in no particular order):
-   related documentation,
-   [Sherlocode](https://sherlocode.com) to look for external uses,
-   [ocaml.org](https://ocaml.org/packages) to look for reverse dependencies
    and search in them,
-   surrounding code,
-   `Makefile` and `dune` files,
-   `git log -S` to look for the finding's history,
-   naming conventions,
-   instinct and experience.

<div class="alert-caution">

> **Caution**:\
> Using Sherlocode may be helpful to verify if a finding is used somewhere.
> However, it may not be sufficient because it only scans opam packages (I think?),
> and may be slightly outdated. Consequently, unlisted projects or newer
> versions may use the finding.
</div>

## Cleanup

For each component, we will first give a quick description of the findings,
then we will describe the aggressive cleanup phase, followed by the informed
cleanup. Finally, we will conclude on the results of the cleanups.

To avoid redundancy, the first phase will be focused on the actual cleanup
actions, while the second will discuss contextualization and indicate which
findings are actually considered for cleanup and which are ignored.

Here are the different components that we will explore:
- [src/client](#srcclient)
- [src/core](#srccore)
- [src/format](#srcformat)
- [src/solver](#srcsolver)
- [src/state](#srcstate)
- [src/tools](#srctools)

<div class="alert-tip">

> **Tip**:\
> During the agressive cleanup, some compiler warnings will be reported as errors.
> More sepecifically, we will encounter warnings 16, 27, 32, 33, 34, 37, and 60.\
> The obtain a list and short description of available compiler warnings, use
> `ocamlopt -warn-help`.
>
> The warnings appear as errors because of dune's default configuration.
> They can be kept as warnings by using the `--profile=release` flag.
</div>
