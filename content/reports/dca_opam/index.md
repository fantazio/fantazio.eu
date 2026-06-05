---
title: Dead code analyzing opam
description: This is a study report of using the dead_code_analyzer on opam.
date: 2026-06-04
tags: [dead_code_analyzer, opam, ocaml, static analysis, dead code, ocaml software foundation]
---

## Table of content
- [Foreword](#foreword)
- [Setup](#setup)
    - [opam](#opam)
    - [dead_code_analyzer](#dead_code_analyzer)
- [General observations](#general-observations)
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
- [Conclusion](#conclusion)
    - [Results](#results)
    - [Lessons learned](#lessons-learned)

## Foreword

This study was funded by the [OCaml Software Fundation](https://ocaml-sf.org/).
Thanks again for their trust.

It has 2 main goals :
1. Audit opam and provide feedback to the maintainers;
2. Test the `dead_code_analyzer` on "real-world" code.

Hopefully, this report will provide more visibility to the `dead_code_analyzer`
and a practical demonstration of its usage.

To keep this report accessible and its goals explicit, the cleanup is organized
by "component" although, in practice, I followed the analyzer's results by
"report section". This will be discussed in more details at the end of this report.

<div class="alert-caution" style='--alert-title: "Disclaimer"'>

> I am not an opam developer. My observations and judgements are those of a
> newcomer and may be mistaken. They will be corrected by an external
> review process ([PR #6954](https://github.com/ocaml/opam/pull/6954)).
</div>

## Setup

This work is done using **OCaml 5.3**.

### <li>opam</li>

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

> We are selecting a specific release as reference (2.5.1) for 2 reasons:
> 1. For reproducibility. Without it, depending on the date, the code may be
>    different and the results as well.
> 2. I assume a release state is a "stable state".
>    Thus, there are less chances of encountering works in progress.
</div>


Then, following [these instructions](https://github.com/ocaml/opam/tree/2.5.1#compiling-this-repo)
to build opam is pretty straigthforward. However, it needed a few adjustments:
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

> When running `make`, only the `.cmi` and `.cmti` files are generated,
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

### <li>dead_code_analyzer</li>

This study is made using the
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
`stdout` (the findings) is redirected to `dca.out`.

[dca.out is available here.](./dca.1.2.0_opam.2.5.1.out)\
[dca.err is available here.](./dca.1.2.0_opam.2.5.1.err)

<div class="alert-tip">

> I would generally recommend redirecting the output of the analyzer to a file.\
> Similarly, on the first run, I'd recommend using `--verbose` to verify that
> nothing went wrong. Reported issues or noticing files are missing from
> the analyzer's list can quickly help debug some unexpected results.

We are not using any other argument. The analyzer is running with the default
sections activated:
- unused exported values
- unused methods
- unused constructors and fields

For more information on the report sections and the usage of the analyzer,
feel free to explore [its documentation](https://github.com/LexiFi/dead_code_analyzer/blob/master/docs/USER_DOC.md)

According to `dca.err`, 248 files were scanned successfully, and nothing
seems to be missing.

We can get an order of magnitude of the amount of findings by counting the lines
in the output :
```bash
$ wc -l dca.out
545 dca.out
```
The analyzer reported 500+ unused exported values, unused methods, and unused
constructors and fields. 512 more precisely. Let's explore them !

## General observations

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

Because there are 2 goals to this study, I processed the analyzer's findings in
2 phases:
1.  An aggressive cleanup, which assumes all the findings can be removed from the
    codebase. The goal is to verify that none of them is a false positive.
    Otherwise, identify the cause and document it if necessary.
2.  An informed cleanup, which relies on contextual information to ensure that
    removing some code is reasonable.

The second phase is necessary because opam exposes its internals as libraries
and we want to reduce the work required for the maintainers to review (and
approve) the cleanup done using the analyzer.

Although I followed the analyzer's output in order (by section), and applied each
phase separately, this report will explore the findings by component (grouping
sections) and discuss the 2 phases for each component.
I hope the results will be clearer to follow this way.

<div class="alert-caution" style='--alert-title: "Important"'>

> Removing dead code reported by either the analyzer or the compiler can lead to
> the discovery of new dead code for both the analyzer and the compiler.
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

However, sometimes the findings accumulate to whole types. The analyzer does not
report unused types yet but will report all their components. In this situation,
step 2 changes and more cleanup steps are necessary:
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
-  The most obvious and common reason is that the reported element is part
    of a library.
    Its API is probably used outside the project so its uses cannot be detected.\
    If unused, the element may still exist for coherence.

-  The build configuration removed/replaced the uses of the reported element.
    This may happen e.g. if there is some platform-dependent code selected at
    build time,
    or if an environment variable is used to activate certain code paths (e.g. a debug profile).

- The reported element is part of a work in progress.

This list is non-exhaustive but provides a scope to guide what to look for when
deciding whether a finding should be cleaned up.\
There are different sources of information that can be used to contextualize a
finding (in no particular order):
-   related documentation, surrounding code, `Makefile` and `dune` files,
    naming conventions,
-   [Sherlocode](https://sherlocode.com) to look for uses in other projects,
    and [ocaml.org](https://ocaml.org/packages) to look for reverse dependencies
    and search in them,
-   `git log -S` to look for the finding's history
-   instinct and experience.

<div class="alert-caution">

> Using Sherlocode may be helpful to verify if a finding is used somewhere.
> However, it may not be sufficient because it only scans opam packages (I think?),
> and may be slightly outdated. Consequently, unlisted projects or newer
> versions may use the finding.
</div>

## Cleanup

This section only reports the results of the cleanup for each component.
For more details on the cleanup actions, see
[the detailed cleanup report available here](./detailed_cleanup.html).\
The detailed cleanup report describes for each component: a quick overview of
the component and its findings, the aggressive cleanup phase, the informed
cleanup phase, and the results.

### <li>src/client</li>

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

### <li>src/core</li>

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

### <li>src/format</li>

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

### <li>src/repository</li>

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

### <li>src/solver</li>

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

### <li>src/state</li>

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

### <li>src/tools</li>

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

## Conclusion

The changes of the aggressive cleanup are available on my fork of opam in branch
[fantazio/dca_naive](https://github.com/fantazio/opam/tree/dca_naive)
and remove
[more than 2.3k lines of code](https://github.com/fantazio/opam/compare/2.5.1...dca_naive).\
The changes of the informed cleanup are available on my fork of opam in branch
[fantazio/dca_informed](https://github.com/fantazio/opam/tree/dca_informed)
and remove [more than 1.8k lines of code](https://github.com/fantazio/opam/compare/2.5.1...dca_informed).

### Results

Overall, the analyzer reported 512 findings in opam:
433 unused values, and 79 constructors and fields.

Out of them, 3 unused values findings were discarded from the study for being
out of `src`.\
We discovered <span class="alert-danger">39 actual false positives</span>
(1 value and 38 constructors and fields), and documented 4 new limitations (
[issue #79](https://github.com/LexiFi/dead_code_analyzer/issues/79),
[issue #80](https://github.com/LexiFi/dead_code_analyzer/issues/80),
[issue #81](https://github.com/LexiFi/dead_code_analyzer/issues/81), and
[issue #82](https://github.com/LexiFi/dead_code_analyzer/issues/82))\
during the aggressive cleanup phase.\
We also labeled an <span class="alert-danger">extra 104 findings as false
positives</span> (72 values and 32 fields) during the informed cleanup phase.
The reasons are, in order of importance:
1. Platform (Windows) specific code and FFI (34 findings, in
    `src/core/opamStubs.mli`, and `src/core/opamStubsTypes.ml`)
2. Module's intent (29 findings, 28 in `src/core/opamStd.mli`)
3. Use outside opam (28 findings)
4. Methodology mistake (6 findings, used in `admin-scripts`)
5. Work in progress (2 findings)
6. Mistake in opam (1 finding)

From these results, we can compute the precision of the analyzer shown in the
table below. The estimated precision after the informed cleanup can be
extrapolated as the potential fix rate.

| section                 | aggressive | + informed |
|:-----------------------:|:----------:|:----------:|
| exported values         | 99.8%      | 83.0%      |
| constructors and fields | 51.9%      | 11.4%      |
| total                   | 92.3%      | 71.9%      |

The _total_ precision after both cleanups is reassuring, but there is a clear
unbalance in the precision of the analyzer on exported values and on
constructors and fields.

Despite the large amount of actual or labeled false positives, the
`dead_code_analyzer` actually helped discover a lot of actual dead code and _more_.\
Indeed, during the agressive cleanup phase, we were able to easily discover
exported types and modules that were only related to the analyzer's findings,
and even remove entire files.\
Additionally, during the informed cleanup, we discovered that the `OpamHash` and
`OpamSha` modules were exporting more entry-points for hash and sha computations
than they should, and simplified their API.\
Finally, as mentionned at the bottom of the list above, the findings actually
pointed out a value (`OpamFile.Wrappers.with_wrap_remove`) that should not have
been dead, which helped fix a mistake in opam.

### Lessons learned

Cleaning up dead code is time consuming. Although often easy (just follow the
analyzer's and compiler's reports), the lack of automated way of doing it makes
the task repetitive and tedious. Ideally, I think that an "auto-cleaner" tool
should take care of most of the cleanup and developers should only worry about
filtering what the tool will take care of (the "informed" part).\
Such a tool should be not be tied to the `dead_code_analyzer` specifically but
offer its service to all the refactoring-related tools.

In practice, a user may want to do an informed cleanup first, and aggressive
second. This way, there are less chances to face limitations of the tool,
and the overall cleanup will be focused on meaningful efforts.\
Also, focusing the cleanup by component has the benefit of naturally creating
"chunks" of findings (although unbalanced) with a similar context.

Identifying and documenting actual false positives is time consuming
.\
However, they are often grouped (e.g. 4 limitations in `src/core/opamStd.mli`)
or related to similar limitations (e.g.
[issue #82](https://github.com/LexiFi/dead_code_analyzer/issues/82) causes
10 false positives in `src/format/opamFile.mli` and 3 in
`src/core/opamStubsTypes.ml`).\
Moreover, by applying an informed cleanup first some actual false positives
would be labeled as such before doing an aggressive cleanup, discarding the need
to identify and document them (e.g. the 18 false positives in `src/core/opamStd.mli`).\
At last, I assume the informed cleanup was more time consuming for me (undoing
cleanups, learning and verifying a lot of things) than it would have been for
an opam developer (already knowing things), so the transfer of false positives
from the aggressive cleanup phase to the informed cleanup would make them even
more tolerable.

Doing an occasional cleanup can be effective to audit a codebase, and I would
recommend doing it (but I might biased). The analyzer is fast, but doing
an overall cleanup can take a lot of human time.\
Thus, I would also recommend to try and use the analyzer more regularly for
differential analysis. Although the feature is not available yet, the idea would
be to detect dead code introduced or cleaned up by a change (e.g. a PR), and a
poor man's version of it can be implemented with shell scripts.\
A differential analysis would help maintaining the codebase quality, and,
consequently, speed up audits during the occasional overall cleanups.

We only did 1 iteration with the analyzer on opam's codebase but could apply
more. It would probably take a few iterations before we reach a fixpoint.\
However, I do not think that going as deep as possible at once is a good idea in
this situation. As I said, I am not an opam developer and this work will require
going through a review process. The goal is not to put too big of a workload on
the reviewers. Going deeper would require more work on both sides.\
Upon success, additional iterations may be applied during future audits.

We only used the default sections of the analyzer: unused exported values,
unused methods, and unused constructors and fields. There are 3 more sections
that are left to explore in future audits: optional arguments always used,
optional arguments never used, and stylistic issues. Again, the goal is not to
put too big of a workload on the reviewers. This is why those sections will be
considered in future audits, and probably independently of the default ones
first to ease their introduction in the cleanup process.

Overall, I spent ~55h on this study: triaging the results and documenting issues
during the aggressive cleanup phase, triaging the results and undoing wrongful
cleanups in the informed cleanup phase, writing the report, proof reading, and
proof checking the results.\
I believe that for an opam developer, doing a complete informed cleanup should
not take a third of that time. Maybe a couple days.\
Because writing this report was interlaced with applying the cleanups, it is
harder to estimate a precise duration per action. However, I can identify two
clear pain points/mistakes I made during this study:
1. Not planning the structure of the report ahead. This forced me to adapt the
    structure as I was going, sometimes taking long and wordly notes that were
    removed during the final re-write. It also lead to a full re-write to
    clarify and focus its structure and content.
2. Applying the aggressive cleanup entirely before doing the informed one.
    This forced to come back and undo cleanups done days before, and remembering
    important things I observed for future actions when I could just have done
    both at once and organize the observations from the beginning. Also, while
    applying each cleanup phase, I followed the findings by section, when in the
    end it would have been more natural to follow them by component, as
    presented in this report.

The 2 points above are connected, and mostly related to the dual objective:
study the analyzer's results and audit opam.

<span class="thanks">for reading</span>
