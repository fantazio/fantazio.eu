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
