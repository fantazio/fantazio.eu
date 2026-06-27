---
title: Static Analysis for OCaml
description: I got a plan
date: 2026-06-19
---

<div class="alert-note" style='--alert-title: "Update"'>

> _2026-06-25_: Apply feedback from [the discuss thread](https://discuss.ocaml.org/t/blog-static-analysis-for-ocaml/18287)
</div>

## Context

OCaml is described on its [official website](https://ocaml.org/) as:
<div class="alert-cite">

> An industrial-strength functional programming language with an emphasis on expressiveness and safety
</div>

A more thorough (and opinonated) description of the language and its ecosystem is available on
[Xavier Van de Woestyne's blog](https://xvw.lol/en/articles/why-ocaml.html).

Among [the software written in OCaml](https://en.wikipedia.org/wiki/OCaml#Software_written_in_OCaml),
a category stands out:
[program analysis](https://en.wikipedia.org/wiki/Program_analysis) tools.
I mean it in a _broad_ sense. This includes:
- compilers (e.g.
[the first Rust compiler](https://en.wikipedia.org/wiki/Rust_\(programming_language\)#2006%E2%80%932009:_Early_years),
    and [Haxe](https://haxe.org/));
- type checkers (e.g. [Hack](https://github.com/facebook/hhvm/tree/master/hphp/hack),
    and [Flow](https://github.com/facebook/flow)
    ([until very recently](https://x.com/flowtype/status/2069836762403459342))),
- interpreters (e.g. [WebAssembly reference interpreter](https://github.com/WebAssembly/spec/tree/main/interpreter),
    and [Liquidsoap](https://github.com/savonet/liquidsoap)),
- interactive theorem provers (e.g. [Rocq](https://rocq-prover.org/), and
    [anterior versions of F*](https://en.wikipedia.org/wiki/F*_\(programming_language\)#Versions)),
- static analyzers (e.g. [Frama-C](https://frama-c.com/), and [Astrée](https://www.astree.ens.fr/)).

I had the chance to work on a few static analyzers written in OCaml (e.g.
[Coccinelle](https://coccinelle.gitlabpages.inria.fr/website/), and
[Infer](https://github.com/facebook/infer)) in academic and industrial contexts.

Although OCaml is used to build successful static analysis tools for other
languages, it seems to not be able to benefit from them as much.
There are great tools (such as the compiler itself), don't get me wrong.
But there is a hole in the ecosystem that is having a hard time to fill up.\
For example, [Simmo Saan](https://sim642.eu) put in the effort to survey the existing
linters in the ecosystem [2 years ago](https://sim642.eu/blog/2024/05/01/ocaml-linting/)
with the specific intent to find all catch-all exception handlers in
[Goblint](https://github.com/goblint/analyzer/). He listed no less than
9 linters and observed that:
<div class="alert-cite">

> Ocamllint and ocp-lint are the most universal attempts at OCaml linting, however they’re long dead and no replacement seems to have emerged.
</div>

<figure>

![xkcd standards](https://imgs.xkcd.com/comics/standards.png)
<figcaption>

[xkcd - Standards](https://xkcd.com/927/) | 9 linters for OCaml</figcaption>
</figure>

Speaking of exceptions there have been multiple attempts to add
[checked exceptions](https://en.wikipedia.org/wiki/Exception_handling_\(programming\)#Checked_exceptions)
to the OCaml ecosystem, like
[ocamlexc](https://caml.inria.fr/pub/old_caml_site/ocamlexc/ocamlexc.htm)
at the end of the 90's,
[ocp-analyzer](https://github.com/OCamlPro/ocp-analyzer)
in the middle of the 2010's, or
[reanalyze](https://github.com/rescript-lang/reanalyze/blob/master/EXCEPTION.md)
in the 2020's.

These are few examples to show that there is a desire for static
analysis tools, and people are actually trying to build them.\
Sadly, some remain in an "experimental" state (e.g.
[Semgrep for OCaml](https://docs.semgrep.dev/semgrep-ce-languages#click-to-view-experimental-languages)),
or in the academic world (e.g. [CAVOC](https://gitlab.inria.fr/cavoc/cavoc-proto)),
while others may live in private settings, never meet their public, or be left
behind (e.g [RaML](https://www.raml.co/), and
[ROTOR](https://trustworthy-refactoring.gitlab.io/refactorer/)) for lack of
funding, time or interest.
[Paraphrasing Nicolás Ojeda Bär](https://discuss.ocaml.org/t/refactoring-tools-for-ocaml-type-based-refactoring/8206/6),
"_the investment of writing this kind of tools is only worth it if you have a
large codebase to [process]_".

## Why develop more static analysis ?

A common counter-argument for the development of such tools is that the language
itself is already pretty safe, and the compiler emits warnings on smelly code.\
I would add that the need/desire for such tools is often very targeted,
like in Simmo's case, to which an easy response could be to write an ad-hoc
automatic tool to help (see [ocamlgrep](https://github.com/LexiFi/ocamlgrep))
or to do it "by hand"
(loosely [paraphrasing Nicolás again](https://discuss.ocaml.org/t/refactoring-tools-for-ocaml-type-based-refactoring/8206/6)).

### The curse of LLMs

To support my claim that there is an interest in building the tools for the
community, rather than ad-hoc for immediate tasks or even not at all,
I'll start by going back in time. More than 10 years ago started the project
_SecurOCaml_, with a 3 years plan. It was based on a study named _LaFoSec_
(for _**La**ngages **Fo**nctionnels **Séc**urité_
or _**La**nguages **Fo**r **Sec**ure applications_)
directed by the [ANSSI](https://cyber.gouv.fr/), the French Cybersecurity
Agency. The idea was to make OCaml more secure, through improvements to the
language (e.g. [extension points](https://ocaml.org/docs/metaprogramming))
and to its ecosystem
(e.g. [dead_code_analyzer](https://github.com/LexiFi/dead_code_analyzer)),
and involved a consortium of 5 companies and 3 academic partners.\
Coming back to the present and the near future, the increasing use of LLMs to
produce code or find vulnerabilities increases the aforementionned need for
security improvements.

In addition to security, the debit of code[^on_debit] is much more important in LLMs than in humans, creating
a bottleneck at review time. Reviews and CI often are the last stand before
sending code in production. In a context where some code could have been
massively produced, by someone who may not have taken the time to read the
content of their own PR (iykyk), extra-caution is required. Using LLMs to review
LLMs code is not an answer but adding risk. Using linters, formal verification,
and other forms of static analysis will provide reviewers a lot of help
detecting subtle mistakes and smells.

[^on_debit]: Some people and companies bafflingly consider the debit of code a
metric of productivity. This naturally results in more quantity and less
quality. Quality takes time among other things.

Finally, in order to reduce the chances of producing unlawful code, whose
behavior diverges from its engineered natural language description, having
formal specifications to match against will help venerably.

For more information on the rising need for formal methods caused by LLMs,
see [Yaron Minsky's post on JaneStreet's blog](https://blog.janestreet.com/formal-methods-at-jane-street-index/)[^js_fm].

[^js_fm]: Following this announce, I hope they will contribute to community
solutions rather than duplicate the efforts with their custom solutions.

### Human first

Humans make mistakes.\
The more code in a codebase, the more chances a mistake is hiding.\
The more legacy code, the more complex to maintain.\
The more dependencies, the more chances a behavior discreetly changes.\
The list can go on.

When developing collaboratively, there is an implicit contract that the writer
owns their production (in the sense that they take responsibility for it,
understand it to the best of their ability, and are honest about it).
However, we are not machines and our knowledge is always bounded. This is true
of the writer but also of the reader. Thus, bugs, vulnerabilities, mistakes will
happen. Adding tools to help development and review can protect against a wide
range of mistakes. Linters can quickly detect code smells and report them,
refactoring tools can automatize attention-numbing repetitive tasks, formal
methods can help design, produce, and verify that a system
conforms to expectations.

Writing ad-hoc tools is not a satisfying answer. First, because indeed this
requires investment which might not be worth it for a small codebase or a
potentially limited impact. Second, writing one-off throwaway code in a hundred
different flavors feels wrong.\
Both issues can be fixed by having a collective investment in those tools.

This desire for more/better tooling is not only mine but shows up regularly in
discussions.\
If we [search for "checked exceptions" on the forum](https://discuss.ocaml.org/search?q=checked%20exception),
it appears in threads in
[2018](https://discuss.ocaml.org/t/specific-reason-for-not-embracing-the-use-of-exceptions-for-error-propagation/1666),
[2020](https://discuss.ocaml.org/t/exception-vs-result/6931),
[2022](https://discuss.ocaml.org/t/am-i-wrong-about-effects-i-see-them-as-a-step-back/10829),
[2023](https://discuss.ocaml.org/t/poor-mans-static-exception-analysis-with-alerts/11296)
[a couple times](https://discuss.ocaml.org/t/is-annotating-and-checking-purity-of-functions-feasible/13728),
and [2025](https://discuss.ocaml.org/t/book-draft-control-structures-in-programming-languages/17443).\
The same can be done for linters, found in threads from
[2020](https://discuss.ocaml.org/t/is-there-a-linter-that-points-out-nested-conditionals/6006),
[2021](https://discuss.ocaml.org/t/how-possible-is-a-clippy-like-linter-for-ocaml/7779),
[2023](https://discuss.ocaml.org/t/tools-for-static-analysis-of-ocaml-code/13590),
and [2024](https://discuss.ocaml.org/t/blog-ocaml-linting-tools-and-techniques/14574).\
Even a very specific tool rather than a category, like the dead_code_analyzer is
mentionned in
[2018](https://discuss.ocaml.org/t/good-tool-to-find-dead-code/2497),
[2021](https://discuss.ocaml.org/t/refactoring-tools-for-ocaml-type-based-refactoring/8206),
and [this year](https://discuss.ocaml.org/t/list-of-used-functions-from-a-given-library/17728).

The desire for this tooling does not only appear in discussions but also in
actions. If I zoom in on the
[dead_code_analyzer's activity](https://github.com/LexiFi/dead_code_analyzer/graphs/contributors?all=1),
it was initiated in Janurary 2015 but primarily developed between September 2015
and January 2016 (it is part of SecurOCaml). It was followed by sporadic
interactions and improvements in 2017, 2018 (mostly), and 2019. Then the project
was left for dead until Edwin Ansari revived it in
[2025](https://github.com/LexiFi/dead_code_analyzer/pull/16). Since then, the
tool was [used on Frama-C](https://github.com/LexiFi/dead_code_analyzer/issues/23)
(it was already in 2015), [on opam](/reports/dca_opam),
[on Goblint](https://github.com/LexiFi/dead_code_analyzer/issues/85#issuecomment-4721950945),
and [at TrustInSoft](https://github.com/LexiFi/dead_code_analyzer/pull/84).

## I got a plan

I kept you waiting long enough to get to the subtitle of this article.
<div class="alert-caution" style='--alert-title: "Disclaimer"'>

> Usually, when I say that I have a plan, there is a devil hiding in the
> details. Feel free to point it out.
</div>

I'll split the static analysis tools into 3 categories: linters, formal methods,
and the in-betweens.

### Linters

Among linters are code formatting tools, which I'll consider out of scope for
this article. There are already 2 strong competitors in that space:
[ocamlformat](https://github.com/ocaml-ppx/ocamlformat), and
[ocp-indent](https://github.com/OCamlPro/ocp-indent).\
By linters I mean surface-level local static analysis tools. Usually, they would
be focused on finding coding style issues and bad patterns.

As Simmo pointed out, there are already many linters but none is general enough
yet to replace the former champions.\
I think there is value in a
[clippy](https://doc.rust-lang.org/stable/clippy/usage.html)-like linter
([Sasha-Élie Ayoun too](https://discuss.ocaml.org/t/how-possible-is-a-clippy-like-linter-for-ocaml/7779)).
The benefit would be to centralize some of OCaml best practices, dangerous
patterns, and other warnings that are not the compiler's responsibility.\
There is work in progress in that direction :
[zanuda](https://github.com/Kakadu/zanuda) for OCaml 4.14 and 5.3
([5.5 in progress](https://github.com/Kakadu/zanuda/pull/90)),
and [camelot](https://github.com/upenn-cis1xx/camelot) for OCaml < 4.14
([4.14 in progress](https://github.com/upenn-cis1xx/camelot/pull/95), and
[5.4.1 in progress](https://github.com/upenn-cis1xx/camelot/pull/98)).

I don't think there is interest in splitting the efforts further. The 2 projects
listed can be supported by different actors. I believe zanuda is on the right
track to fill the "clippy" spot in the OCaml ecosystem.

### Formal Methods

There are long standing tools that can produce OCaml from formal specifications,
like [Rocq](https://rocq-prover.org/) and [F*](https://fstar-lang.org/).
These are already solid options if you have the skillset to write in these
languages instead of OCaml.\
There is also a work in progress to enable the use of Rocq on existing OCaml code:
[rocq-of-ocaml](https://github.com/formal-land/rocq-of-ocaml). Again, using a
proof assistant to add formal specification over code is a great idea, but
it requires specific non-trivial skills.

Rather than producing OCaml from formal specifications, writing such
specifications directly in the OCaml code might be more accessible. There is
work in progress in that direction:
[Gospel](https://ocaml-gospel.github.io/gospel/).\
From those specifications one can then use tools to verify them statically
(e.g. [camleer](https://github.com/ocaml-gospel/cameleer),
[peter](https://github.com/ocaml-gospel/peter)) or dynamically
([ortac](https://github.com/ocaml-gospel/ortac))).

Finally, having formal verification without writing formal specifications is
also a possibility. In this case, rather than custom properties, such a tool
would look for more general pitfalls of the language, like uncaught exceptions,
out of bound array accesses, or always-failing asserts (which can encode the
custom properties). Again, there is work in progress:
[Salto](https://salto.gitlabpages.inria.fr/)

Because this category of tools requires specialized skills, I don't think
splitting the efforts is a good idea. The current distribution of projects
is reasonable and support should focus on them.

### In-betweens

This is a broad abstract category. This includes tools that provide global
codebase analysis, possibly specialized, not entirely formal methods based.
It ranges from global codebase linters to semi-formal verification tools.
I would qualify these tools as "pragamatic" because they try to provide more
complex analysis than linters without the cost of formal verification.

One such tool is the [dead_code_analyzer](https://github.com/LexiFi/dead_code_analyzer).
As demonstrated, there is a request for it and the project is actively
maintained. There is a competitor to the tool:
[reanalyze](https://github.com/rescript-lang/reanalyze). The main difference[^on_reanalyze], despite
the latter being inspired by the former, is the target community. Reanalyze is
part of the [rescript](https://github.com/rescript-lang/rescript/) (forked from
OCaml) ecosystem, while the dead_code_analyzer is part of the OCaml ecosystem.\
I don't think there is any interest in splitting the efforts further.

[^on_reanalyze]: There are more differences between the dead_code_analyzer and
reanalyze. The latter looks for transitively dead code, works with extra
attributes to silence/trigger specific warnings, adds checked exceptions and
a termination analysis.

Another tool of interest is an exception checker, as demonstrated previously.
Salto is already working towards this, and reanalyze already provides an
analysis which requires manual code annotations.\
Even better than an exception checker, an effect typer would subsume it and
provide missing safety to OCaml's effect system. There is interest for it and
an [attempt to add one to the language exists](https://github.com/lpw25/ocaml-typed-effects).
In my opinion, there is space for an external effect typer, that would provide
the missing feature à la
[ocamlexc](https://caml.inria.fr/pub/old_caml_site/ocamlexc/ocamlexc.htm),
but would report potential uncaught effect/exception traces instead of the
typed exceptions, with pluggable models for external libraries (e.g. `Stdlib`).\
I have not seen efforts put on this topic despite the demand and potential
benefit to the ecosystem (+ it would lift worries on the usage of exceptions
and effects). I have a plan to build such a tool (codenamed _exceff_) and am
looking for funding to develop a first version. This first version, although
incomplete would help enabling feedback-based iterations to drive efforts and
possibly attract contributors.

<div class="alert-note" style='--alert-title: "Update"'>

> Adding [Owi](https://github.com/ocamlpro/owi) to the list. OCaml support and
> abstract interpretation are in progress.
</div>

#### Refactoring tools

Refactoring tools are also in demand. Often implcitly when looking for linters.

There was one ([ROTOR](https://trustworthy-refactoring.gitlab.io/refactorer/))
for renaming values. It might be worth resuscitating.

For some time I was thinking of developing a tool similar to
[Coccinelle](https://github.com/coccinelle/coccinelle) for OCaml. There is already
[Semgrep](https://github.com/semgrep/semgrep), a descendant of Coccinelle, which
has experimental support for OCaml. Because this tool is the main product of
the eponym company, and it is written in OCaml itself, I assume that support
will eventually [come from the company itself](https://en.wikipedia.org/wiki/Eating_your_own_dog_food).
<div class="alert-note" style='--alert-title: "Update"'>

> Semgrep will probably not dogfood any time soon. Yoann Padioleau
> [forked the tool to add OCaml support](https://github.com/aryx/osemgrep).
</div>

Another refactoring task, which is often very repetitive, is simply to fix
compiler errors after a manual update like adding/removing a field/constructor,
renaming something, or moving a value into a different module. This is a task
we all have to face at some point, which is straightforward but can sometimes
feel needlessly tedious or even discourage refactoring some parts of a codebase
that could impact many places.\
I have not found a tool that would automatically fix up compiler errors during
a refactor. Because cleaning up code reported by the dead_code_analyzer can
lead to a lot of simple automatisable efforts, I would like to develop such a
tool (codenamed _auto-cleaner_) and am looking for funding. Ideally, the tool
would be easily extensible to non-compiler results in order to e.g.
auto-refactor linter results.

Finally, I have fantasized for a long time a tool that would be able to point
out code duplication or similar pieces that could be abstracted together.\
A tool that seems to enable such results exists: [asak](https://github.com/nobrakal/asak),
and it has an experimental client: [inzad](https://gitlab.inria.fr/guesdon/inzad).
I don't think splitting efforts is worth it. Providing support to the listed
projects could result in an intuitive clone detector.

### Program information

The development of static analysis tools requires access to program information.

The [compiler-libs](https://ocaml.github.io/odoc/ocaml-base-compiler/compiler-libs.common/)
provides access to the OCaml compiler's internal representations of code.
Among them, the ones of interest are
the [`Parsetree`](https://ocaml.github.io/odoc/ocaml-base-compiler/compiler-libs.common/Parsetree/index.html),
the [`Typedtree`](https://ocaml.github.io/odoc/ocaml-base-compiler/compiler-libs.common/Typedtree/index.html),
and [`Lambda`](https://ocaml.github.io/odoc/ocaml-base-compiler/compiler-libs.common/Lambda/index.html).\
One observation I made about the `Typedtree` is that it breaks in-between OCaml
versions. This forces tools relying on it to either also break compatibility
with previous versions when updating to the latest, or to support them using
compiler-dependent versions of code (e.g. via
[cppo](https://github.com/ocaml-community/cppo) like
[ocp-index](https://github.com/OCamlPro/ocp-index), or by branching like
[merlin](https://github.com/ocaml/merlin)).
The dead_code_analyzer is a victim of those breaking changes. It could be
adapted to support multiple versions of OCaml like other projects. However, this
would be yet another ad-hoc solution to a more general problem.\
Thus, I plan on developing a library (study in progress, codenamed _Vaast_) that
would provide a more stable and reliable API over the `Typedtree` (and possibly
other representations). The idea would be that tools depending on the
`Typedtree` would transparently accept multiple OCaml versions, and the
adaptation effort would be commonized. This would also help the development of
new tools, which would not be left behind by the time they are made available.\
There is a study in progress on the topic, and I am open to funding. The plan
would be to develop a prototype with a version of the dead_code_analyzer
using it as proof of concept, before reaching out to the community and
maintainers of other concerned projects to get feedback and guide development
towards an agreed solution. The intent of this process is to reduce the amount
of efforts and "noise" in the discussion before reaching a consensus.\
[The same observation on the `Parsetree`](https://discuss.ocaml.org/t/the-future-of-ppx/3766)
(in the context of ppx) lead to the [multi-version-compatible design of
ppxlib](https://ocaml-ppx.github.io/ppxlib/ppxlib/compatibility.html).

Another tool that provides access to program information is
[merlin](https://github.com/ocaml/merlin). It, for example, builds an index of
value definitions (actually
[ocaml-index](https://github.com/ocaml/merlin/tree/main/src/ocaml-index)
does it).

## Conclusion

Static analysis for OCaml has a long-winded history. The current state of
tooling is nice, and the progress is very encouraging. I have not used or
contributed to as many tools in the ecosystem as I have listed, so this article
is to take with a pinch of salt.

Formal verification tools are gaining traction. The linter world is also
catching up with other ecosystems. Yet, there is still room and demand for a
wide category of tools.\
If you are interested in filling up this space, funding my work
(dead_code_analyzer, exceff, auto-cleaner, Vaast), or collaborating to improve
existing tools, feel free to [contact me](/contact.html).

<span class="thanks">for reading</span>
