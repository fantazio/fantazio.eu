---
title: Dead code analyzing Opam
description: Running the dead_code_analyzer on opam
date: 2026-05-05
tags: [dead_code_analyzer, opam, ocaml, static analysis, ocaml software foundation]
---

This experiment uses the `dead_code_analyzer 1.2.0` on `opam 2.5.1`.
It is funded by the [OCaml Software Fundation](https://ocaml-sf.org/).

## Installing opam from source

In order to analyzer Opam, we need to build the project and generate the `.cmt` and `.cmti` files necessary for the `dead_code_analyzer`.

Following [these instructions](https://github.com/ocaml/opam/tree/2.5.1#compiling-this-repo) to build opam is pretty straigthforward.
However, it needed a few adjustment:
1. Run `opam install . --deps-only` before `./configure`. This ensures all the dependencies are installed.
2. When running `make`, only the `.cmi` and `.cmti` files are generated, but not the `.cmt` files. This is because the OCaml compiler flag `-keep-locs` is enabled by default but not `-bin-annot`.
   The output of `make` is:
   ```
   $ make
   dune build --profile=release --root .  --promote-install-files -- opam-installer.install opam.install
   sed -f process.sed opam.install > processed-opam.install
   dune build --profile=release --root .  --promote-install-files -- opam-installer.install
   sed -f process.sed opam-installer.install > processed-opam-installer.install
   ```
   We can see tha building opam relies on `dune`. `Dune` has a nice alias [`@check`](https://dune.readthedocs.io/en/stable/reference/aliases/check.html) to build the `.cmi`, `cmt`, and `.cmti` files.
   We can run a single `dune` command with the alias :
   ```
   $ dune build @check
   File "src/tools/opam_admin_topstart.ml", line 1:
   Warning 70 [missing-mli]: Cannot find interface file.
   ```
   As a result, there are `.cmt` files generated aloongside the `.cmi` and `.cmti` in `_build`.
3. We do not run `make install`

<div class="alert-note">

> **NOTE**:\
> Using `./configure --enable-developer-mode` does not enable `-bin-annot`, so the manual call to `dune build @check` command is still necessary.
</div>

Now that we have generated the necessary files, let's move on to running the `dead_code_analyzer`.

## Running the `dead_code_analyzer`

Now that we have the `.cmti` and `.cmti` files, let's run the `dead_code_analyzer`:
```
$ dead_code_analyzer --verbose _build 2> dca.err > dca.out
```
Before looking at the results, let's dissect the command above.

We run the `dead_code_analyzer` with the `--verbose` flag.
This will print out all the files that are analyzed on stderr and indicate issues (if any) when reading some files. Thus, we redirect this output in `dca.err`.
The analyzer is given `_build` as argument. The `.cmt` and `.cmti` files are somewhere within that directory. We could have been more precise and provided e.g. `_build/default` as argument or even `_build/default/src` but we'll keep things as simple as possible for now.
Finally, the results are redirected in `dca.out`.

I would generally recommend redirecting the output of the analyzer to a file.
Similarly, on the first run, I'd recommend using `--verbose` to verify that nothing went wrong. Issues when reading files or noticing some files are missing from the nalyzer's list can quickly help debug some unexpected results.

We are not using any other argument. The analyzer is running on the defaults dead code categories :
- unused exported values
- unused methods
- unused fields and constructors

For more information on the report sections and the usage of the analyzer, fell free to explore [its documentation](https://github.com/LexiFi/dead_code_analyzer/blob/master/docs/USER_DOC.md)

According to the `dca.err`, 248 files were scanned successfully and interfaces and implemenations are perfectly interlaced.
The analyzer reads the interface and the implementation of a compilation unit, in that order, before moving to the next.

We can get an order of magnitude of the amount of reports by using :
```
$ wc -l dca.out
545 dca.out
```
The analyzer reported 500+ unused exported values, unused methods, and unused fields and constructors.
Let's explore the reports by section.

### Unused exported values

The [report](../assets/reports/dca/opam/dca.out)'s unused exported values section initial content is 433 lines long after discarding the header, footer, and blank lines.
<details><summary>446 lines report output (<i>click to expand/hide</i>)</summary>

```
.> UNUSED EXPORTED VALUES:
=========================
/tmp/proj/opam/_build/default/src/client/opamAction.mli:42: prepare_package_build
/tmp/proj/opam/_build/default/src/client/opamAdminCheck.mli:16: installability_check
/tmp/proj/opam/_build/default/src/client/opamAdminCheck.mli:20: cycle_check
/tmp/proj/opam/_build/default/src/client/opamAdminCheck.mli:32: get_obsolete
/tmp/proj/opam/_build/default/src/client/opamArg.mli:29: cli2_5
/tmp/proj/opam/_build/default/src/client/opamArg.mli:100: escape_path
/tmp/proj/opam/_build/default/src/client/opamArg.mli:129: name_list
/tmp/proj/opam/_build/default/src/client/opamArg.mli:132: param_list
/tmp/proj/opam/_build/default/src/client/opamArg.mli:135: atom_list
/tmp/proj/opam/_build/default/src/client/opamArg.mli:138: nonempty_atom_list
/tmp/proj/opam/_build/default/src/client/opamArg.mli:214: locked
/tmp/proj/opam/_build/default/src/client/opamArg.mli:280: package_with_version
/tmp/proj/opam/_build/default/src/client/opamArg.mli:286: atom_or_local
/tmp/proj/opam/_build/default/src/client/opamArg.mli:289: atom_or_dir
/tmp/proj/opam/_build/default/src/client/opamArg.mli:301: opamlist_columns
/tmp/proj/opam/_build/default/src/client/opamArg.mli:385: scrubbed_environment_variables
/tmp/proj/opam/_build/default/src/client/opamAuxCommands.mli:34: name_and_dir_of_opam_file
/tmp/proj/opam/_build/default/src/client/opamAuxCommands.mli:57: resolve_locals
/tmp/proj/opam/_build/default/src/client/opamCliMain.mli:20: check_and_run_external_commands
/tmp/proj/opam/_build/default/src/client/opamCliMain.mli:26: main_catch_all
/tmp/proj/opam/_build/default/src/client/opamCliMain.mli:29: json_out
/tmp/proj/opam/_build/default/src/client/opamCliMain.mli:33: run
/tmp/proj/opam/_build/default/src/client/opamClient.mli:95: reinstall_t
/tmp/proj/opam/_build/default/src/client/opamClient.mli:120: upgrade_t
/tmp/proj/opam/_build/default/src/client/opamClient.mli:172: PIN.post_pin_action
/tmp/proj/opam/_build/default/src/client/opamClientConfig.mli:93: search_files
/tmp/proj/opam/_build/default/src/client/opamConfigCommand.mli:76: parse_whole
/tmp/proj/opam/_build/default/src/client/opamInitDefaults.mli:20: default_compiler
/tmp/proj/opam/_build/default/src/client/opamInitDefaults.mli:22: eval_variables
/tmp/proj/opam/_build/default/src/client/opamListCommand.mli:31: default_dependency_toggles
/tmp/proj/opam/_build/default/src/client/opamListCommand.mli:132: field_of_string
/tmp/proj/opam/_build/default/src/client/opamRepositoryCommand.mli:40: update_global_selection
/tmp/proj/opam/_build/default/src/client/opamSolution.mli:102: eq_atom
/tmp/proj/opam/_build/default/src/client/opamSolution.mli:136: sum

/tmp/proj/opam/_build/default/src/core/cmdliner/cmdliner_msg.mli:33: pp_try_help
/tmp/proj/opam/_build/default/src/core/cmdliner/cmdliner_trie.mli:14: is_empty
/tmp/proj/opam/_build/default/src/core/cmdliner/opamCmdliner.mli:79: Manpage.s_name
/tmp/proj/opam/_build/default/src/core/cmdliner/opamCmdliner.mli:83: Manpage.s_synopsis
/tmp/proj/opam/_build/default/src/core/cmdliner/opamCmdliner.mli:117: Manpage.s_environment_intro
/tmp/proj/opam/_build/default/src/core/cmdliner/opamCmdliner.mli:133: Manpage.s_see_also
/tmp/proj/opam/_build/default/src/core/cmdliner/opamCmdliner.mli:136: Manpage.s_none
/tmp/proj/opam/_build/default/src/core/cmdliner/opamCmdliner.mli:155: Manpage.print
/tmp/proj/opam/_build/default/src/core/cmdliner/opamCmdliner.mli:184: Term.app
/tmp/proj/opam/_build/default/src/core/cmdliner/opamCmdliner.mli:187: Term.map
/tmp/proj/opam/_build/default/src/core/cmdliner/opamCmdliner.mli:190: Term.product
/tmp/proj/opam/_build/default/src/core/cmdliner/opamCmdliner.mli:195: Term.Syntax.let+
/tmp/proj/opam/_build/default/src/core/cmdliner/opamCmdliner.mli:198: Term.Syntax.and+
/tmp/proj/opam/_build/default/src/core/cmdliner/opamCmdliner.mli:204: Term.term_result
/tmp/proj/opam/_build/default/src/core/cmdliner/opamCmdliner.mli:214: Term.term_result'
/tmp/proj/opam/_build/default/src/core/cmdliner/opamCmdliner.mli:218: Term.cli_parse_result
/tmp/proj/opam/_build/default/src/core/cmdliner/opamCmdliner.mli:227: Term.cli_parse_result'
/tmp/proj/opam/_build/default/src/core/cmdliner/opamCmdliner.mli:231: Term.main_name
/tmp/proj/opam/_build/default/src/core/cmdliner/opamCmdliner.mli:239: Term.with_used_args
/tmp/proj/opam/_build/default/src/core/cmdliner/opamCmdliner.mli:282: Term.exit_info
/tmp/proj/opam/_build/default/src/core/cmdliner/opamCmdliner.mli:297: Term.default_exits
/tmp/proj/opam/_build/default/src/core/cmdliner/opamCmdliner.mli:303: Term.default_error_exits
/tmp/proj/opam/_build/default/src/core/cmdliner/opamCmdliner.mli:312: Term.env_info
/tmp/proj/opam/_build/default/src/core/cmdliner/opamCmdliner.mli:364: Term.name
/tmp/proj/opam/_build/default/src/core/cmdliner/opamCmdliner.mli:404: Term.eval_choice
/tmp/proj/opam/_build/default/src/core/cmdliner/opamCmdliner.mli:418: Term.eval_peek_opts
/tmp/proj/opam/_build/default/src/core/cmdliner/opamCmdliner.mli:460: Term.exit_status_success
/tmp/proj/opam/_build/default/src/core/cmdliner/opamCmdliner.mli:464: Term.exit_status_cli_error
/tmp/proj/opam/_build/default/src/core/cmdliner/opamCmdliner.mli:469: Term.exit_status_internal_error
/tmp/proj/opam/_build/default/src/core/cmdliner/opamCmdliner.mli:474: Term.exit_status_of_result
/tmp/proj/opam/_build/default/src/core/cmdliner/opamCmdliner.mli:484: Term.exit_status_of_status_result
/tmp/proj/opam/_build/default/src/core/cmdliner/opamCmdliner.mli:489: Term.exit
/tmp/proj/opam/_build/default/src/core/cmdliner/opamCmdliner.mli:494: Term.exit_status
/tmp/proj/opam/_build/default/src/core/cmdliner/opamCmdliner.mli:500: Term.pure
/tmp/proj/opam/_build/default/src/core/cmdliner/opamCmdliner.mli:504: Term.man_format
/tmp/proj/opam/_build/default/src/core/cmdliner/opamCmdliner.mli:538: Cmd.Exit.ok
/tmp/proj/opam/_build/default/src/core/cmdliner/opamCmdliner.mli:541: Cmd.Exit.some_error
/tmp/proj/opam/_build/default/src/core/cmdliner/opamCmdliner.mli:545: Cmd.Exit.cli_error
/tmp/proj/opam/_build/default/src/core/cmdliner/opamCmdliner.mli:549: Cmd.Exit.internal_error
/tmp/proj/opam/_build/default/src/core/cmdliner/opamCmdliner.mli:558: Cmd.Exit.info
/tmp/proj/opam/_build/default/src/core/cmdliner/opamCmdliner.mli:572: Cmd.Exit.info_code
/tmp/proj/opam/_build/default/src/core/cmdliner/opamCmdliner.mli:575: Cmd.Exit.defaults
/tmp/proj/opam/_build/default/src/core/cmdliner/opamCmdliner.mli:595: Cmd.Env.info
/tmp/proj/opam/_build/default/src/core/cmdliner/opamCmdliner.mli:691: Cmd.eval
/tmp/proj/opam/_build/default/src/core/cmdliner/opamCmdliner.mli:698: Cmd.eval'
/tmp/proj/opam/_build/default/src/core/cmdliner/opamCmdliner.mli:705: Cmd.eval_result
/tmp/proj/opam/_build/default/src/core/cmdliner/opamCmdliner.mli:716: Cmd.eval_result'
/tmp/proj/opam/_build/default/src/core/cmdliner/opamCmdliner.mli:766: Cmd.eval_value'
/tmp/proj/opam/_build/default/src/core/cmdliner/opamCmdliner.mli:775: Cmd.eval_peek_opts
/tmp/proj/opam/_build/default/src/core/cmdliner/opamCmdliner.mli:840: Arg.conv
/tmp/proj/opam/_build/default/src/core/cmdliner/opamCmdliner.mli:849: Arg.conv'
/tmp/proj/opam/_build/default/src/core/cmdliner/opamCmdliner.mli:855: Arg.conv_parser
/tmp/proj/opam/_build/default/src/core/cmdliner/opamCmdliner.mli:858: Arg.conv_printer
/tmp/proj/opam/_build/default/src/core/cmdliner/opamCmdliner.mli:861: Arg.conv_docv
/tmp/proj/opam/_build/default/src/core/cmdliner/opamCmdliner.mli:867: Arg.parser_of_kind_of_string
/tmp/proj/opam/_build/default/src/core/cmdliner/opamCmdliner.mli:874: Arg.some'
/tmp/proj/opam/_build/default/src/core/cmdliner/opamCmdliner.mli:1025: Arg.pos_left
/tmp/proj/opam/_build/default/src/core/cmdliner/opamCmdliner.mli:1057: Arg.last
/tmp/proj/opam/_build/default/src/core/cmdliner/opamCmdliner.mli:1071: Arg.bool
/tmp/proj/opam/_build/default/src/core/cmdliner/opamCmdliner.mli:1074: Arg.char
/tmp/proj/opam/_build/default/src/core/cmdliner/opamCmdliner.mli:1080: Arg.nativeint
/tmp/proj/opam/_build/default/src/core/cmdliner/opamCmdliner.mli:1083: Arg.int32
/tmp/proj/opam/_build/default/src/core/cmdliner/opamCmdliner.mli:1086: Arg.int64
/tmp/proj/opam/_build/default/src/core/cmdliner/opamCmdliner.mli:1089: Arg.float
/tmp/proj/opam/_build/default/src/core/cmdliner/opamCmdliner.mli:1103: Arg.file
/tmp/proj/opam/_build/default/src/core/cmdliner/opamCmdliner.mli:1107: Arg.dir
/tmp/proj/opam/_build/default/src/core/cmdliner/opamCmdliner.mli:1112: Arg.non_dir_file
/tmp/proj/opam/_build/default/src/core/cmdliner/opamCmdliner.mli:1121: Arg.array
/tmp/proj/opam/_build/default/src/core/cmdliner/opamCmdliner.mli:1130: Arg.t2
/tmp/proj/opam/_build/default/src/core/cmdliner/opamCmdliner.mli:1133: Arg.t3
/tmp/proj/opam/_build/default/src/core/cmdliner/opamCmdliner.mli:1138: Arg.t4
/tmp/proj/opam/_build/default/src/core/cmdliner/opamCmdliner.mli:1147: Arg.doc_quote
/tmp/proj/opam/_build/default/src/core/cmdliner/opamCmdliner.mli:1150: Arg.doc_alts
/tmp/proj/opam/_build/default/src/core/cmdliner/opamCmdliner.mli:1174: Arg.pconv
/tmp/proj/opam/_build/default/src/core/cmdliner/opamCmdliner.mli:1185: Arg.env_var

/tmp/proj/opam/_build/default/src/core/opamCompat.mli:45: Lazy.map_val
/tmp/proj/opam/_build/default/src/core/opamConsole.mli:19: color
/tmp/proj/opam/_build/default/src/core/opamConsole.mli:21: utf8_extended
/tmp/proj/opam/_build/default/src/core/opamConsole.mli:45: acolor
/tmp/proj/opam/_build/default/src/core/opamConsole.mli:46: acolor_w
/tmp/proj/opam/_build/default/src/core/opamConsole.mli:61: Symbols.latin_capital_letter_o_with_stroke
/tmp/proj/opam/_build/default/src/core/opamConsole.mli:172: Tree.get_default_symbols
/tmp/proj/opam/_build/default/src/core/opamCoreConfig.mli:34: E.confirmlevel
/tmp/proj/opam/_build/default/src/core/opamCoreConfig.mli:37: E.yes
/tmp/proj/opam/_build/default/src/core/opamCoreConfig.mli:113: set
/tmp/proj/opam/_build/default/src/core/opamCoreConfig.mli:115: setk
/tmp/proj/opam/_build/default/src/core/opamDirTrack.mli:29: to_string
/tmp/proj/opam/_build/default/src/core/opamDirTrack.mli:38: string_of_change
/tmp/proj/opam/_build/default/src/core/opamFilename.mli:64: env_of_list
/tmp/proj/opam/_build/default/src/core/opamFilename.mli:97: to_list_dir
/tmp/proj/opam/_build/default/src/core/opamFilename.mli:158: with_open_out_bin
/tmp/proj/opam/_build/default/src/core/opamFilename.mli:181: with_tmp_file
/tmp/proj/opam/_build/default/src/core/opamFilename.mli:184: with_tmp_file_job
/tmp/proj/opam/_build/default/src/core/opamFilename.mli:206: with_contents
/tmp/proj/opam/_build/default/src/core/opamFilename.mli:211: copy_in
/tmp/proj/opam/_build/default/src/core/opamFilename.mli:244: extract
/tmp/proj/opam/_build/default/src/core/opamFilename.mli:257: extract_generic_file
/tmp/proj/opam/_build/default/src/core/opamFilename.mli:277: remove_suffix
/tmp/proj/opam/_build/default/src/core/opamFilename.mli:331: with_flock_write_then_read
/tmp/proj/opam/_build/default/src/core/opamFilename.mli:349: Attribute.to_string_list
/tmp/proj/opam/_build/default/src/core/opamFilename.mli:351: Attribute.of_string_list
/tmp/proj/opam/_build/default/src/core/opamHash.mli:26: md5
/tmp/proj/opam/_build/default/src/core/opamHash.mli:27: sha256
/tmp/proj/opam/_build/default/src/core/opamParallel.mli:42: iter
/tmp/proj/opam/_build/default/src/core/opamProcess.mli:54: is_verbose_command
/tmp/proj/opam/_build/default/src/core/opamProcess.mli:217: Job.seq_map
/tmp/proj/opam/_build/default/src/core/opamSHA.mli:14: sha1_file
/tmp/proj/opam/_build/default/src/core/opamSHA.mli:16: sha256_file
/tmp/proj/opam/_build/default/src/core/opamSHA.mli:18: sha512_file
/tmp/proj/opam/_build/default/src/core/opamSHA.mli:25: sha256_string
/tmp/proj/opam/_build/default/src/core/opamSHA.mli:27: sha512_string
/tmp/proj/opam/_build/default/src/core/opamStd.mli:144: Option.default_map
/tmp/proj/opam/_build/default/src/core/opamStd.mli:179: List.remove_duplicates
/tmp/proj/opam/_build/default/src/core/opamStd.mli:197: List.insert
/tmp/proj/opam/_build/default/src/core/opamStd.mli:229: List.update_assoc
/tmp/proj/opam/_build/default/src/core/opamStd.mli:298: String.split_quoted
/tmp/proj/opam/_build/default/src/core/opamStd.mli:319: Format.indent_left
/tmp/proj/opam/_build/default/src/core/opamStd.mli:321: Format.indent_right
/tmp/proj/opam/_build/default/src/core/opamStd.mli:379: Env.reset_value
/tmp/proj/opam/_build/default/src/core/opamStd.mli:386: Env.cut_value
/tmp/proj/opam/_build/default/src/core/opamStd.mli:472: Sys.system
/tmp/proj/opam/_build/default/src/core/opamStd.mli:502: Sys.chop_exe_suffix
/tmp/proj/opam/_build/default/src/core/opamStd.mli:524: Sys.path_sep
/tmp/proj/opam/_build/default/src/core/opamStd.mli:570: Sys.get_cygwin_variant
/tmp/proj/opam/_build/default/src/core/opamStd.mli:621: Win32.RegistryHive.to_string
/tmp/proj/opam/_build/default/src/core/opamStd.mli:622: Win32.RegistryHive.of_string
/tmp/proj/opam/_build/default/src/core/opamStd.mli:625: Win32.set_parent_pid
/tmp/proj/opam/_build/default/src/core/opamStd.mli:629: Win32.parent_putenv
/tmp/proj/opam/_build/default/src/core/opamStd.mli:633: Win32.persistHomeDirectory
/tmp/proj/opam/_build/default/src/core/opamStd.mli:688: Config.resolve_when
/tmp/proj/opam/_build/default/src/core/opamStd.mli:736: Config.E.find
/tmp/proj/opam/_build/default/src/core/opamStd.mli:741: Config.E.update
/tmp/proj/opam/_build/default/src/core/opamStd.mli:751: Compare.compare
/tmp/proj/opam/_build/default/src/core/opamStd.mli:753: Compare.=
/tmp/proj/opam/_build/default/src/core/opamStd.mli:754: Compare.<>
/tmp/proj/opam/_build/default/src/core/opamStd.mli:755: Compare.<
/tmp/proj/opam/_build/default/src/core/opamStd.mli:756: Compare.>
/tmp/proj/opam/_build/default/src/core/opamStd.mli:757: Compare.<=
/tmp/proj/opam/_build/default/src/core/opamStd.mli:758: Compare.>=
/tmp/proj/opam/_build/default/src/core/opamStubs.mli:25: getCurrentProcessID
/tmp/proj/opam/_build/default/src/core/opamStubs.mli:140: getConsoleAlias
/tmp/proj/opam/_build/default/src/core/opamStubsTypes.ml:128: nproc
/tmp/proj/opam/_build/default/src/core/opamSystem.mli:55: verbose_for_base_commands
/tmp/proj/opam/_build/default/src/core/opamSystem.mli:134: get_files
/tmp/proj/opam/_build/default/src/core/opamSystem.mli:173: files_with_links
/tmp/proj/opam/_build/default/src/core/opamSystem.mli:200: directories_with_links
/tmp/proj/opam/_build/default/src/core/opamSystem.mli:337: lock_max
/tmp/proj/opam/_build/default/src/core/opamSystem.mli:388: register_printer
/tmp/proj/opam/_build/default/src/core/opamSystem.mli:405: classify_executable
/tmp/proj/opam/_build/default/src/core/opamVersion.mli:20: major
/tmp/proj/opam/_build/default/src/core/opamVersion.mli:29: git
/tmp/proj/opam/_build/default/src/core/opamVersion.mli:44: message
/tmp/proj/opam/_build/default/src/core/opamVersionCompare.mli:35: equal

/tmp/proj/opam/_build/default/src/format/opamFile.mli:112: Wrappers.with_wrap_remove
/tmp/proj/opam/_build/default/src/format/opamFile.mli:145: Config.with_best_effort_prefix
/tmp/proj/opam/_build/default/src/format/opamFile.mli:148: Config.with_solver
/tmp/proj/opam/_build/default/src/format/opamFile.mli:153: Config.with_dl_tool
/tmp/proj/opam/_build/default/src/format/opamFile.mli:257: InitConfig.opam_version
/tmp/proj/opam/_build/default/src/format/opamFile.mli:276: InitConfig.with_opam_version
/tmp/proj/opam/_build/default/src/format/opamFile.mli:281: InitConfig.with_jobs
/tmp/proj/opam/_build/default/src/format/opamFile.mli:283: InitConfig.with_dl_jobs
/tmp/proj/opam/_build/default/src/format/opamFile.mli:284: InitConfig.with_dl_cache
/tmp/proj/opam/_build/default/src/format/opamFile.mli:285: InitConfig.with_solver_criteria
/tmp/proj/opam/_build/default/src/format/opamFile.mli:286: InitConfig.with_solver
/tmp/proj/opam/_build/default/src/format/opamFile.mli:288: InitConfig.with_global_variables
/tmp/proj/opam/_build/default/src/format/opamFile.mli:307: Descr.of_string
/tmp/proj/opam/_build/default/src/format/opamFile.mli:316: Descr.full
/tmp/proj/opam/_build/default/src/format/opamFile.mli:342: URL.with_mirrors
/tmp/proj/opam/_build/default/src/format/opamFile.mli:343: URL.with_swhid
/tmp/proj/opam/_build/default/src/format/opamFile.mli:345: URL.with_subpath
/tmp/proj/opam/_build/default/src/format/opamFile.mli:346: URL.with_subpath_opt
/tmp/proj/opam/_build/default/src/format/opamFile.mli:504: OPAM.extensions
/tmp/proj/opam/_build/default/src/format/opamFile.mli:507: OPAM.extended
/tmp/proj/opam/_build/default/src/format/opamFile.mli:519: OPAM.features
/tmp/proj/opam/_build/default/src/format/opamFile.mli:522: OPAM.libraries
/tmp/proj/opam/_build/default/src/format/opamFile.mli:525: OPAM.syntax
/tmp/proj/opam/_build/default/src/format/opamFile.mli:531: OPAM.homepage
/tmp/proj/opam/_build/default/src/format/opamFile.mli:534: OPAM.author
/tmp/proj/opam/_build/default/src/format/opamFile.mli:537: OPAM.license
/tmp/proj/opam/_build/default/src/format/opamFile.mli:540: OPAM.doc
/tmp/proj/opam/_build/default/src/format/opamFile.mli:561: OPAM.bug_reports
/tmp/proj/opam/_build/default/src/format/opamFile.mli:575: OPAM.synopsis
/tmp/proj/opam/_build/default/src/format/opamFile.mli:576: OPAM.descr_body
/tmp/proj/opam/_build/default/src/format/opamFile.mli:619: OPAM.with_version_opt
/tmp/proj/opam/_build/default/src/format/opamFile.mli:690: OPAM.with_extensions
/tmp/proj/opam/_build/default/src/format/opamFile.mli:692: OPAM.add_extension
/tmp/proj/opam/_build/default/src/format/opamFile.mli:694: OPAM.remove_extension
/tmp/proj/opam/_build/default/src/format/opamFile.mli:701: OPAM.with_descr_opt
/tmp/proj/opam/_build/default/src/format/opamFile.mli:724: OPAM.to_string_with_preserved_format
/tmp/proj/opam/_build/default/src/format/opamFile.mli:743: OPAM.sections
/tmp/proj/opam/_build/default/src/format/opamFile.mli:750: OPAM.contents
/tmp/proj/opam/_build/default/src/format/opamFile.mli:761: OPAM.rewrite_xfield
/tmp/proj/opam/_build/default/src/format/opamFile.mli:804: Environment.read
/tmp/proj/opam/_build/default/src/format/opamFile.mli:807: Environment.read_from_channel
/tmp/proj/opam/_build/default/src/format/opamFile.mli:808: Environment.read_from_string
/tmp/proj/opam/_build/default/src/format/opamFile.mli:821: Comp.create_preinstalled
/tmp/proj/opam/_build/default/src/format/opamFile.mli:828: Comp.opam_version
/tmp/proj/opam/_build/default/src/format/opamFile.mli:831: Comp.name
/tmp/proj/opam/_build/default/src/format/opamFile.mli:837: Comp.src
/tmp/proj/opam/_build/default/src/format/opamFile.mli:843: Comp.configure
/tmp/proj/opam/_build/default/src/format/opamFile.mli:846: Comp.make
/tmp/proj/opam/_build/default/src/format/opamFile.mli:850: Comp.build
/tmp/proj/opam/_build/default/src/format/opamFile.mli:857: Comp.env
/tmp/proj/opam/_build/default/src/format/opamFile.mli:859: Comp.tags
/tmp/proj/opam/_build/default/src/format/opamFile.mli:861: Comp.with_src
/tmp/proj/opam/_build/default/src/format/opamFile.mli:862: Comp.with_patches
/tmp/proj/opam/_build/default/src/format/opamFile.mli:863: Comp.with_configure
/tmp/proj/opam/_build/default/src/format/opamFile.mli:864: Comp.with_make
/tmp/proj/opam/_build/default/src/format/opamFile.mli:865: Comp.with_build
/tmp/proj/opam/_build/default/src/format/opamFile.mli:866: Comp.with_packages
/tmp/proj/opam/_build/default/src/format/opamFile.mli:929: Dot_install.with_bin
/tmp/proj/opam/_build/default/src/format/opamFile.mli:932: Dot_install.with_sbin
/tmp/proj/opam/_build/default/src/format/opamFile.mli:935: Dot_install.with_lib
/tmp/proj/opam/_build/default/src/format/opamFile.mli:938: Dot_install.with_toplevel
/tmp/proj/opam/_build/default/src/format/opamFile.mli:941: Dot_install.with_stublibs
/tmp/proj/opam/_build/default/src/format/opamFile.mli:944: Dot_install.with_share
/tmp/proj/opam/_build/default/src/format/opamFile.mli:947: Dot_install.with_share_root
/tmp/proj/opam/_build/default/src/format/opamFile.mli:950: Dot_install.with_etc
/tmp/proj/opam/_build/default/src/format/opamFile.mli:953: Dot_install.with_doc
/tmp/proj/opam/_build/default/src/format/opamFile.mli:956: Dot_install.with_man
/tmp/proj/opam/_build/default/src/format/opamFile.mli:959: Dot_install.with_libexec
/tmp/proj/opam/_build/default/src/format/opamFile.mli:962: Dot_install.with_lib_root
/tmp/proj/opam/_build/default/src/format/opamFile.mli:965: Dot_install.with_libexec_root
/tmp/proj/opam/_build/default/src/format/opamFile.mli:968: Dot_install.with_misc
/tmp/proj/opam/_build/default/src/format/opamFile.mli:998: Dot_config.variables
/tmp/proj/opam/_build/default/src/format/opamFile.mli:1087: Repo.browse
/tmp/proj/opam/_build/default/src/format/opamFile.mli:1090: Repo.upstream
/tmp/proj/opam/_build/default/src/format/opamFile.mli:1108: Repo.with_browse
/tmp/proj/opam/_build/default/src/format/opamFile.mli:1110: Repo.with_upstream
/tmp/proj/opam/_build/default/src/format/opamFile.mli:1118: Repo.with_announce
/tmp/proj/opam/_build/default/src/format/opamFile.mli:1122: Repo.with_stamp_opt
/tmp/proj/opam/_build/default/src/format/opamFile.mli:1132: Syntax.pp_channel
/tmp/proj/opam/_build/default/src/format/opamFile.mli:1137: Syntax.to_channel
/tmp/proj/opam/_build/default/src/format/opamFile.mli:1139: Syntax.to_string
/tmp/proj/opam/_build/default/src/format/opamFile.mli:1140: Syntax.to_string_with_preserved_format
/tmp/proj/opam/_build/default/src/format/opamFilter.mli:55: string_interp_regex
/tmp/proj/opam/_build/default/src/format/opamFilter.mli:109: eval
/tmp/proj/opam/_build/default/src/format/opamFilter.mli:121: eval_to_string
/tmp/proj/opam/_build/default/src/format/opamFilter.mli:134: ident_value
/tmp/proj/opam/_build/default/src/format/opamFilter.mli:140: ident_bool
/tmp/proj/opam/_build/default/src/format/opamFilter.mli:142: expand_interpolations_in_file_full
/tmp/proj/opam/_build/default/src/format/opamFilter.mli:188: gen_filter_formula
/tmp/proj/opam/_build/default/src/format/opamFormat.mli:19: value_pos
/tmp/proj/opam/_build/default/src/format/opamFormat.mli:64: V.simple_arg
/tmp/proj/opam/_build/default/src/format/opamFormat.mli:73: V.group
/tmp/proj/opam/_build/default/src/format/opamFormat.mli:80: V.map_group
/tmp/proj/opam/_build/default/src/format/opamFormat.mli:122: V.filter_ident
/tmp/proj/opam/_build/default/src/format/opamFormat.mli:157: V.package_atom
/tmp/proj/opam/_build/default/src/format/opamFormat.mli:196: I.file
/tmp/proj/opam/_build/default/src/format/opamFormat.mli:200: I.item
/tmp/proj/opam/_build/default/src/format/opamFormat.mli:271: I.extract_field
/tmp/proj/opam/_build/default/src/format/opamFormat.mli:292: I.signature
/tmp/proj/opam/_build/default/src/format/opamFormat.mli:299: I.signed
/tmp/proj/opam/_build/default/src/format/opamFormula.mli:18: compare_relop
/tmp/proj/opam/_build/default/src/format/opamFormula.mli:31: compare_version_constraint
/tmp/proj/opam/_build/default/src/format/opamFormula.mli:73: string_of_disjunction
/tmp/proj/opam/_build/default/src/format/opamFormula.mli:82: string_of_cnf
/tmp/proj/opam/_build/default/src/format/opamFormula.mli:85: string_of_dnf
/tmp/proj/opam/_build/default/src/format/opamFormula.mli:144: iter
/tmp/proj/opam/_build/default/src/format/opamFormula.mli:172: compare
/tmp/proj/opam/_build/default/src/format/opamFormula.mli:190: compare_nc
/tmp/proj/opam/_build/default/src/format/opamFormula.mli:199: formula_to_cnf
/tmp/proj/opam/_build/default/src/format/opamFormula.mli:202: dnf_of_formula
/tmp/proj/opam/_build/default/src/format/opamFormula.mli:218: simplify_ineq_formula
/tmp/proj/opam/_build/default/src/format/opamFormula.mli:245: to_conjunction
/tmp/proj/opam/_build/default/src/format/opamFormula.mli:248: of_conjunction
/tmp/proj/opam/_build/default/src/format/opamFormula.mli:252: to_disjunction
/tmp/proj/opam/_build/default/src/format/opamFormula.mli:260: of_disjunction
/tmp/proj/opam/_build/default/src/format/opamPath.mli:65: backup
/tmp/proj/opam/_build/default/src/format/opamPath.mli:71: plugins
/tmp/proj/opam/_build/default/src/format/opamPath.mli:82: plugin
/tmp/proj/opam/_build/default/src/format/opamPath.mli:103: Switch.meta_dirname
/tmp/proj/opam/_build/default/src/format/opamPath.mli:174: Switch.extra_file
/tmp/proj/opam/_build/default/src/format/opamPath.mli:219: Switch.Default.lib_dir
/tmp/proj/opam/_build/default/src/format/opamPath.mli:222: Switch.Default.stublibs
/tmp/proj/opam/_build/default/src/format/opamPath.mli:225: Switch.Default.toplevel
/tmp/proj/opam/_build/default/src/format/opamPath.mli:232: Switch.Default.doc_dir
/tmp/proj/opam/_build/default/src/format/opamPath.mli:235: Switch.Default.share_dir
/tmp/proj/opam/_build/default/src/format/opamPath.mli:242: Switch.Default.etc_dir
/tmp/proj/opam/_build/default/src/format/opamPath.mli:250: Switch.Default.man_dir
/tmp/proj/opam/_build/default/src/format/opamPath.mli:253: Switch.Default.man_dirs
/tmp/proj/opam/_build/default/src/format/opamPath.mli:256: Switch.Default.bin
/tmp/proj/opam/_build/default/src/format/opamPath.mli:259: Switch.Default.sbin
/tmp/proj/opam/_build/default/src/format/opamPath.mli:275: Switch.DefaultF.doc_dir
/tmp/proj/opam/_build/default/src/format/opamPath.mli:281: Switch.DefaultF.etc_dir
/tmp/proj/opam/_build/default/src/format/opamPath.mli:287: Switch.DefaultF.man_dirs
/tmp/proj/opam/_build/default/src/format/opamPp.mli:96: ignore
/tmp/proj/opam/_build/default/src/format/opamSysPkg.mli:29: string_of_status
/tmp/proj/opam/_build/default/src/format/opamSysPkg.mli:45: string_of_to_install
/tmp/proj/opam/_build/default/src/format/opamTypesBase.mli:29: map_atomic_action
/tmp/proj/opam/_build/default/src/format/opamTypesBase.mli:30: map_highlevel_action
/tmp/proj/opam/_build/default/src/format/opamTypesBase.mli:31: map_concrete_action
/tmp/proj/opam/_build/default/src/format/opamTypesBase.mli:47: nullify_pos_map
/tmp/proj/opam/_build/default/src/format/opamTypesBase.mli:52: pos_best
/tmp/proj/opam/_build/default/src/format/opamTypesBase.mli:96: iter_success
/tmp/proj/opam/_build/default/src/format/opamTypesBase.mli:100: env_update
/tmp/proj/opam/_build/default/src/format/opamTypesBase.mli:124: switch_selections_compare
/tmp/proj/opam/_build/default/src/format/opamTypesBase.mli:127: simple_arg_equal
/tmp/proj/opam/_build/default/src/format/opamTypesBase.mli:128: arg_equal
/tmp/proj/opam/_build/default/src/format/opamTypesBase.mli:129: filter_equal

/tmp/proj/opam/_build/default/src/repository/opamRepository.mli:87: find_backend
/tmp/proj/opam/_build/default/src/repository/opamRepositoryBackend.mli:97: to_json
/tmp/proj/opam/_build/default/src/repository/opamRepositoryBackend.mli:100: compare
/tmp/proj/opam/_build/default/src/repository/opamRepositoryBackend.mli:104: check_digest
/tmp/proj/opam/_build/default/src/repository/opamRepositoryConfig.mli:24: E.curl
/tmp/proj/opam/_build/default/src/repository/opamRepositoryConfig.mli:25: E.fetch
/tmp/proj/opam/_build/default/src/repository/opamRepositoryPath.mli:58: Remote.repo
/tmp/proj/opam/_build/default/src/repository/opamRepositoryPath.mli:64: Remote.archive

/tmp/proj/opam/_build/default/src/solver/opamCudf.mli:19: Package.equal
/tmp/proj/opam/_build/default/src/solver/opamCudf.mli:20: Package.compare
/tmp/proj/opam/_build/default/src/solver/opamCudf.mli:21: Package.to_json
/tmp/proj/opam/_build/default/src/solver/opamCudf.mli:22: Package.of_json
/tmp/proj/opam/_build/default/src/solver/opamCudf.mli:52: diff
/tmp/proj/opam/_build/default/src/solver/opamCudf.mli:71: check_request
/tmp/proj/opam/_build/default/src/solver/opamCudf.mli:79: get_final_universe
/tmp/proj/opam/_build/default/src/solver/opamCudf.mli:89: actions_of_diff
/tmp/proj/opam/_build/default/src/solver/opamCudf.mli:153: remove
/tmp/proj/opam/_build/default/src/solver/opamCudf.mli:156: uninstall_all
/tmp/proj/opam/_build/default/src/solver/opamCudf.mli:161: install
/tmp/proj/opam/_build/default/src/solver/opamCudf.mli:164: remove_all_uninstalled_versions_but
/tmp/proj/opam/_build/default/src/solver/opamCudf.mli:191: opam_invariant_package_name
/tmp/proj/opam/_build/default/src/solver/opamCudf.mli:197: opam_deprequest_package_name
/tmp/proj/opam/_build/default/src/solver/opamCudf.mli:204: unavailable_package
/tmp/proj/opam/_build/default/src/solver/opamCudf.mli:205: is_unavailable_package
/tmp/proj/opam/_build/default/src/solver/opamCudf.mli:210: string_of_vpkgs
/tmp/proj/opam/_build/default/src/solver/opamCudf.mli:244: string_of_explanation
/tmp/proj/opam/_build/default/src/solver/opamCudf.mli:256: conflict_cycles
/tmp/proj/opam/_build/default/src/solver/opamCudf.mli:262: string_of_atom
/tmp/proj/opam/_build/default/src/solver/opamCudf.mli:265: string_of_request
/tmp/proj/opam/_build/default/src/solver/opamCudf.mli:268: string_of_universe
/tmp/proj/opam/_build/default/src/solver/opamCudf.mli:271: string_of_packages
/tmp/proj/opam/_build/default/src/solver/opamCudf.mli:277: packages
/tmp/proj/opam/_build/default/src/solver/opamCudf.mli:281: to_cudf
/tmp/proj/opam/_build/default/src/solver/opamCudf.mli:291: Json.version_to_json
/tmp/proj/opam/_build/default/src/solver/opamCudf.mli:292: Json.version_of_json
/tmp/proj/opam/_build/default/src/solver/opamCudf.mli:294: Json.relop_to_json
/tmp/proj/opam/_build/default/src/solver/opamCudf.mli:295: Json.relop_of_json
/tmp/proj/opam/_build/default/src/solver/opamCudf.mli:297: Json.enum_keep_to_json
/tmp/proj/opam/_build/default/src/solver/opamCudf.mli:298: Json.enum_keep_of_json
/tmp/proj/opam/_build/default/src/solver/opamCudf.mli:300: Json.constr_to_json
/tmp/proj/opam/_build/default/src/solver/opamCudf.mli:301: Json.constr_of_json
/tmp/proj/opam/_build/default/src/solver/opamCudf.mli:303: Json.vpkg_to_json
/tmp/proj/opam/_build/default/src/solver/opamCudf.mli:304: Json.vpkg_of_json
/tmp/proj/opam/_build/default/src/solver/opamCudf.mli:305: Json.vpkglist_to_json
/tmp/proj/opam/_build/default/src/solver/opamCudf.mli:306: Json.vpkglist_of_json
/tmp/proj/opam/_build/default/src/solver/opamCudf.mli:308: Json.veqpkg_to_json
/tmp/proj/opam/_build/default/src/solver/opamCudf.mli:309: Json.veqpkg_of_json
/tmp/proj/opam/_build/default/src/solver/opamCudf.mli:310: Json.veqpkglist_to_json
/tmp/proj/opam/_build/default/src/solver/opamCudf.mli:311: Json.veqpkglist_of_json
/tmp/proj/opam/_build/default/src/solver/opamCudf.mli:313: Json.vpkgformula_to_json
/tmp/proj/opam/_build/default/src/solver/opamCudf.mli:314: Json.vpkgformula_of_json
/tmp/proj/opam/_build/default/src/solver/opamCudf.mli:316: Json.typedecl1_to_json
/tmp/proj/opam/_build/default/src/solver/opamCudf.mli:317: Json.typedecl1_of_json
/tmp/proj/opam/_build/default/src/solver/opamCudf.mli:318: Json.typedecl_to_json
/tmp/proj/opam/_build/default/src/solver/opamCudf.mli:319: Json.typedecl_of_json
/tmp/proj/opam/_build/default/src/solver/opamCudf.mli:321: Json.typed_value_to_json
/tmp/proj/opam/_build/default/src/solver/opamCudf.mli:322: Json.typed_value_of_json
/tmp/proj/opam/_build/default/src/solver/opamCudf.mli:324: Json.package_to_json
/tmp/proj/opam/_build/default/src/solver/opamCudf.mli:325: Json.package_of_json
/tmp/proj/opam/_build/default/src/solver/opamSolver.mli:22: empty_universe
/tmp/proj/opam/_build/default/src/solver/opamSolver.mli:27: string_of_request
/tmp/proj/opam/_build/default/src/solver/opamSolver.mli:57: solution_to_json
/tmp/proj/opam/_build/default/src/solver/opamSolver.mli:58: solution_of_json
/tmp/proj/opam/_build/default/src/solver/opamSolver.mli:61: cudf_versions_map
/tmp/proj/opam/_build/default/src/solver/opamSolver.mli:122: check_for_conflicts
/tmp/proj/opam/_build/default/src/solver/opamSolver.mli:126: coinstallability_check

/tmp/proj/opam/_build/default/src/state/opamEnv.mli:37: get_opam
/tmp/proj/opam/_build/default/src/state/opamEnv.mli:45: get_opam_raw
/tmp/proj/opam/_build/default/src/state/opamEnv.mli:68: cygwin_non_shadowed_programs
/tmp/proj/opam/_build/default/src/state/opamEnv.mli:110: path
/tmp/proj/opam/_build/default/src/state/opamEnv.mli:133: update_user_setup
/tmp/proj/opam/_build/default/src/state/opamEnv.mli:140: write_static_init_scripts
/tmp/proj/opam/_build/default/src/state/opamEnv.mli:157: clear_dynamic_init_scripts
/tmp/proj/opam/_build/default/src/state/opamFileTools.mli:54: lint_string
/tmp/proj/opam/_build/default/src/state/opamFormatUpgrade.mli:26: latest_version
/tmp/proj/opam/_build/default/src/state/opamGlobalState.mli:26: all_installed
/tmp/proj/opam/_build/default/src/state/opamGlobalState.mli:50: unlock
/tmp/proj/opam/_build/default/src/state/opamRepositoryState.mli:71: load_repo
/tmp/proj/opam/_build/default/src/state/opamRepositoryState.mli:118: cleanup
/tmp/proj/opam/_build/default/src/state/opamScript.mli:16: prompt
/tmp/proj/opam/_build/default/src/state/opamStateConfig.mli:96: safe_load
/tmp/proj/opam/_build/default/src/state/opamStateConfig.mli:132: load_config_root
/tmp/proj/opam/_build/default/src/state/opamSwitchState.mli:62: get_conflicts_t
/tmp/proj/opam/_build/default/src/state/opamSwitchState.mli:71: unlock
/tmp/proj/opam/_build/default/src/state/opamSwitchState.mli:114: descr
/tmp/proj/opam/_build/default/src/state/opamSwitchState.mli:117: descr_opt
/tmp/proj/opam/_build/default/src/state/opamSwitchState.mli:151: dev_packages
/tmp/proj/opam/_build/default/src/state/opamSysPoll.mli:21: os_version
/tmp/proj/opam/_build/default/src/state/opamUpdate.mli:61: dev_package
/tmp/proj/opam/_build/default/src/state/opamUpdate.mli:70: pinned_packages
/tmp/proj/opam/_build/default/src/state/opamUpdate.mli:79: pinned_package

/tmp/proj/opam/_build/default/src/tools/opam_admin_top.mli:15: repo
/tmp/proj/opam/_build/default/src/tools/opam_admin_top.mli:18: packages
/tmp/proj/opam/_build/default/src/tools/opam_admin_top.mli:26: iter_packages_gen
/tmp/proj/opam/_build/default/src/tools/opam_admin_top.mli:39: filter_packages
/tmp/proj/opam/_build/default/src/tools/opam_admin_top.mli:42: iter_packages

/tmp/proj/opam/_build/default/tests/lib/typeGymnastics.mli:16: open_env_updates
/tmp/proj/opam/_build/default/tests/lib/typeGymnastics.mli:20: op_of_raw
/tmp/proj/opam/_build/default/tests/lib/typeGymnastics.mli:21: raw_of_op

Nothing else to report in this section
--------------------------------------------------------------------------------
```
</details>

<div class="alert-note">

> **NOTE**:\
> All the reports use the absolute paths of the files. In my case, the opam
> project is located at `/tmp/proj/opam`. This prefix may vary depending on the
> location of the clone on your machine.
</div>

<div class="alert-warning">

> **WARNING**:\
> The locations point to files if the `_build/default` directory. This is because `dune` copies and
> builds the file in that directory. The actual source files are located outside of it.
</div>

The reports are ordered in lexicographical order and a blank line is inserted in between changes of directory. This allows for an easier focus on each "component" of the codebase.

The analyzer does not track "transitively" dead elements of code (i.e. code only used by dead code).
Thus all thre reports can be examined independently from each other.
Cleaning up unused exported values is pretty straightforward: go to the reported location and remove
that value (along with its associated attributes and comments). Because removing content from a file
will change the location of subsequent content, I would recommend to start at the bottom of a file
and go up.

This naive cleaning process could theorically be automatised easily but has not been done for the
`dead_code_analyzer` yet.

#### Client

This section focuses on reports in `/tmp/proj/opam/src/client`.

Removing the reported values went smoothly. The code does not hit the dead_code_analyzer's  [limitations](https://github.com/LexiFi/dead_code_analyzer/blob/master/docs/exported_values/EXPORTED_VALUES.md#limitations).

After the removal, running our initial `dune build @check` command ensures that everything still compiles as expected:
```
$ dune build @check
File "src/client/opamClientConfig.ml", line 207, characters 4-16:
207 | let search_files = ["findlib"]
          ^^^^^^^^^^^^
Error (warning 32 [unused-value-declaration]): unused value search_files.
File "src/tools/opam_admin_topstart.ml", line 1:
Warning 70 [missing-mli]: Cannot find interface file.
File "src/client/opamListCommand.ml", line 32, characters 4-30:
32 | let default_dependency_toggles = {
         ^^^^^^^^^^^^^^^^^^^^^^^^^^
Error (warning 32 [unused-value-declaration]): unused value default_dependency_toggles.
File "src/client/opamConfigCommand.ml", line 526, characters 4-15:
526 | let parse_whole fv =
          ^^^^^^^^^^^
Error (warning 32 [unused-value-declaration]): unused value parse_whole.
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
File "src/client/opamSolution.ml", line 117, characters 4-7:
117 | let sum stats =

          ^^^
Error (warning 32 [unused-value-declaration]): unused value sum.
```

As we can see un-exporting some values triggered compiler warnings (as errors), indicating that those values are not used internally either.
They can be removed, just like the reports from the analyzer.

<div class="alert-tip">

> **TIP**:\
> The warnings appear as errors because of dune's default configuration.
> They can be kept as warnings by using the `--profile=release` flag.

#### Core

This section focuses on reports in `/tmp/proj/opam/src/core`.

The vast majority of the reports in `core/cmdliner` are in the `core/cmdliner/opamCmdliner.mli`.
A naive cleanup can be applied very smoothly and running our `dune` command will work fine :
```
$ dune build @check
File "src/tools/opam_admin_topstart.ml", line 1:
Warning 70 [missing-mli]: Cannot find interface file.
```

Among the 75 reported values in this subdirectory, 18 (i.e. 24%) were marked as deprecated.
The analyzer does not report unused types and modules yet. However, a more thorough cleanup
can be applied as some types (e.g. `Manpage.t`) are only used by unused values
and a module (`Term.Syntax`) is only composed of unused values.


Among the rest of the unused exported values in `core/`, only 1 out of 68 is marked as deprecated.
A module (`OpamStd.Win32.RegistryHive`) only contains unused values and a module (`OpamStd.Compare`) almost only contains unused values except for one (`equal`).

After cleanup, running our `dune` command triggers compilation warnings (most as errors) :
<details><summary>180 lines compilation output (<i>click to expand/hide</i>)</summary>

```
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
File "src/core/opamHash.ml", line 72, characters 4-10:
72 | let sha256 = make `SHA256
         ^^^^^^
Error (warning 32 [unused-value-declaration]): unused value sha256.
File "src/core/opamVersion.ml", line 43, characters 4-9:
43 | let major v =
         ^^^^^
Error (warning 32 [unused-value-declaration]): unused value major.

File "src/core/opamVersion.ml", line 65, characters 4-11:
65 | let message () =
         ^^^^^^^
Error (warning 32 [unused-value-declaration]): unused value message.
File "src/core/opamConsole.ml", line 100, characters 6-40:
100 |   let latin_capital_letter_o_with_stroke = Uchar.of_int 0x00d8
            ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^
Error (warning 32 [unused-value-declaration]): unused value latin_capital_letter_o_with_stroke.
File "src/core/opamProcess.ml", line 972, characters 6-13:
972 |   let seq_map f l =
            ^^^^^^^
Error (warning 32 [unused-value-declaration]): unused value seq_map.
File "src/core/opamSystem.ml", line 633, characters 4-29:
633 | let verbose_for_base_commands () =
          ^^^^^^^^^^^^^^^^^^^^^^^^^
Error (warning 32 [unused-value-declaration]): unused value verbose_for_base_commands.
File "src/core/opamDirTrack.ml", line 45, characters 4-13:
45 | let to_string t =
         ^^^^^^^^^
Error (warning 32 [unused-value-declaration]): unused value to_string.
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
File "src/core/opamParallel.ml", line 488, characters 4-8:
488 | let iter ~jobs ~command ?dry_run l =
          ^^^^
Error (warning 32 [unused-value-declaration]): unused value iter.
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
File "src/tools/opam_admin_topstart.ml", line 1:
Warning 70 [missing-mli]: Cannot find interface file.
```
</details>

The warnings 32 are triggered because the values are not exported (anymore) and not used inside their compilation unit.
The warning 60 on module `RegistryHive` appears because I removed it from `src/core/opamStd.mli` since it was only exporting unused values.

All the reported unused values and modules can be removed, just like the reports from the analyzer.

#### Format

This section focuses on reports in `/tmp/proj/opam/src/format`.

More than half of the reports (82 out of 147) are located in the file `format/opamFile.ml`.
A naive cleanup can be applied very smoothly and running our `dune` command will trigger warnings as errors:
```
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
File "src/tools/opam_admin_topstart.ml", line 1:
Warning 70 [missing-mli]: Cannot find interface file.
```

The warnings 32 are triggered because the values are not exported (anymore) and not used inside their compilation unit.
All the reported unused values can be removed, just like reports from the analyzer.

The rest of the reports in `format` can be naively cleaned up.
Running our `dune` command will trigger warnings as errors:
<details><summary>116 lines compilation output (<i>click to expand/hide</i>)</summary>

```
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
File "src/tools/opam_admin_topstart.ml", line 1:
Warning 70 [missing-mli]: Cannot find interface file.
```
</details>

The warnings 32 are triggered because the values are not exported (anymore) and not used inside their compilation unit.
All the reported unused values can be removed, just like reports from the analyzer.

After removing them, re-running our `dune` command will show that we are not done with the cleanup.
Indeed some values were only used internally by unused values that appear in the above compilation
output. Now that we removed these unused values, new unused values are uncovered:
```
$ dune build @check
File "src/format/opamFilter.ml", line 155, characters 4-9:
155 | let value ?default = function
          ^^^^^
Error (warning 32 [unused-value-declaration]): unused value value.
File "src/format/opamFormat.ml", line 139, characters 6-11:
139 |   let group =
            ^^^^^
Error (warning 32 [unused-value-declaration]): unused value group.

File "src/format/opamFormat.ml", line 883, characters 6-19:
883 |   let extract_field name =
            ^^^^^^^^^^^^^
Error (warning 32 [unused-value-declaration]): unused value extract_field.

File "src/format/opamFormat.ml", line 948, characters 6-15:
948 |   let signature =
            ^^^^^^^^^
Error (warning 32 [unused-value-declaration]): unused value signature.
```

We can once again remove the reported unused values, and the compilation will succeed.

<div class="alert-warning">

> **IMPORTANT**:\
> Removing unused values reported by the compiler can lead to the discovery of new unused values for
> both the compiler and the analyzer.
> Similarly, removing unused values reported by analyzer can lead to the discovery of new unused
> values for both the compiler and the analyzer.
> Because neither the compiler nor the analyzer reports "transitively" unused values, multiple runs
> may be necessary to uncover them all.
>
> The current report is focused on a single iteration of the analyzer, followed by
> as-many-as-necessary iterations of the compiler. This whole process could be repeated multiple
> times until neither the analyzer nor the compiler reports anything.
</div>

Going ever further, there is a type and an exception that are unused in `OpamFormat`: `signature` and `Invalid_signature`.
They can be removed both from the `.mli` and the `.ml` without breaking the compilation.

#### Repository

This section focuses on reports in `/tmp/proj/opam/src/repository`.

There are not a lot of reports (8) in that direcotry. Applying a naive cleanup is straightforward.
Our `dune` command provides the following output:
```
$ dune build @check
File "src/repository/opamRepositoryPath.ml", line 60, characters 6-10:
60 |   let repo root_url =
           ^^^^
Error (warning 32 [unused-value-declaration]): unused value repo.

File "src/repository/opamRepositoryPath.ml", line 66, characters 6-13:
66 |   let archive root_url nv =
           ^^^^^^^
Error (warning 32 [unused-value-declaration]): unused value archive.
File "src/repository/opamRepositoryBackend.ml", line 40, characters 4-11:
40 | let compare r1 r2 = compare r1.repo_name r2.repo_name
         ^^^^^^^
Error (warning 32 [unused-value-declaration]): unused value compare.

File "src/repository/opamRepositoryBackend.ml", line 47, characters 4-11:
47 | let to_json r =
         ^^^^^^^
Error (warning 32 [unused-value-declaration]): unused value to_json.

File "src/repository/opamRepositoryBackend.ml", line 52, characters 4-16:
52 | let check_digest filename = function
         ^^^^^^^^^^^^
Error (warning 32 [unused-value-declaration]): unused value check_digest.
File "src/tools/opam_admin_topstart.ml", line 1:
Warning 70 [missing-mli]: Cannot find interface file.
```

The warnings 32 are triggered because the values are not exported (anymore) and not used inside their compilation unit.
All the reported unused values can be removed, just like reports from the analyzer.

#### Solver

This section focuses on reports in `/tmp/proj/opam/src/solver`.

The vast majority of reports (51 out of 58, i.e. ~88%) are within `src/solver/opamCudf.mli`.
They can all be cleaned very smoothly. However, all the values exported by `OpamCudf.Json` are unused. This leaves the module's signature defined as:
```OCaml
module Json: sig
  open Cudf_types
end
```
The unused `open` will  trigger a compiler warning 33 (reported as an error using our `dune` command).
The module `Json` does not export anything anymore, so it can be removed as a whole.

Let's run our `dune` command to discover all the unveiled unused values:
```
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
File "src/tools/opam_admin_topstart.ml", line 1:
Warning 70 [missing-mli]: Cannot find interface file.
```
The warnings 32 are triggered because the values are not exported (anymore) and not used inside their compilation unit. All the reported unused values can be removed, just like reports from the analyzer.

Once these are taken care of, re-running our command triggers new compiler reports:
```
$ dune build @check
File "src/solver/opamCudf.ml", line 50, characters 4-31:
50 | let unavailable_package_version = 1
         ^^^^^^^^^^^^^^^^^^^^^^^^^^^
Error (warning 32 [unused-value-declaration]): unused value unavailable_package_version.

File "src/solver/opamCudf.ml", line 94, characters 4-22:
94 | let string_of_packages l =
         ^^^^^^^^^^^^^^^^^^
Error (warning 32 [unused-value-declaration]): unused value string_of_packages.
```

Once again, we can cleanup the dead code and rerun our command:
```
$ dune build @check
File "src/solver/opamCudf.ml", line 87, characters 4-21:
87 | let string_of_package p =
         ^^^^^^^^^^^^^^^^^
Error (warning 32 [unused-value-declaration]): unused value string_of_package.
```

After removing this last unused value, the compiler will not report any more of them.

The same overall process can be applied to the remaining `dead_code_analyzer` reports in `src/solver`.

#### State

This section focuses on reports in `/tmp/proj/opam/src/state`.

Applying a naive cleanup is straightforward. Our dune command provides the following output:
```
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
File "src/tools/opam_admin_topstart.ml", line 1:
Warning 70 [missing-mli]: Cannot find interface file.
```
The warnings 32 are triggered because the values are not exported (anymore) and not used inside their compilation unit. All the reported unused values can be removed, just like reports from the analyzer.

I was able to trivially fix all the reports except for this one:
```
File "src/state/opamScript.ml", line 23, characters 4-10:
23 | let prompt =
         ^^^^^^
Error (warning 32 [unused-value-declaration]): unused value prompt.
```
This is because the file `src/state/opamScript.ml` does not exist. I will come back to this later.

After this first cleanup, running our `dune` command a second time outputs:
```
$ dune build @check
File "src/state/opamScript.ml", line 23, characters 4-10:
23 | let prompt =
         ^^^^^^
Error (warning 32 [unused-value-declaration]): unused value prompt.
File "src/state/opamSwitchState.ml", line 702, characters 4-13:
702 | let descr_opt st nv =
          ^^^^^^^^^
Error (warning 32 [unused-value-declaration]): unused value descr_opt.
```
`descr_opt` can be removed an we are done with the naive cleanup.

Let's come back to our unused `prompt` value in `src/state/opamScript.ml`.
The file is actually generated by a rule in `src/state/dune`:
```dune
(rule
  (targets opamScript.ml)
  (deps    ../../shell/crunch.ml (glob_files shellscripts/*.*sh))
  (action  (with-stdout-to %{targets} (run ocaml %{deps}))))
```
The `crunch.ml` script simply prints out the name of the script and its content in following format for each script provided as argument:
```OCaml
let <name> =
"<content>"

```
As a result, this rule creates the `src/state/opamScript.ml` file and fills it
with variables named after the shell scripts found in `src/state/shellscripts`.

If we continue applying a naive cleanup, we hit a wall here. 2 choices can be made:
- go as far as possible in the cleanup and remove the unused script (`src/state/shellscripts/prompt.sh`);
- or tolerate to leave the unused `prompt` variable in `src/state/opamScript.mli` because it is linked with generated code.

I chose to go the agressive route and remove the script. After this, the compiler does not report any unused value.

#### Tools

This section focuses on reports in `/tmp/proj/opam/src/tools`.

The `dead_code_analyzer` only reports values in `src/tools/opam_admin_top.mli` and reports all the values in that file.
There is a type that is exported that only seems to be used by the exported values, and an open that becomes unused without the values.
Consequently, we can go even further than a naive cleanup and remove all the content of the file (except for the copyright and module description).

Running our `dune` command gives a few compiler reports:
```
$ dune build @check
File "src/tools/opam_admin_topstart.ml", line 1:
Warning 70 [missing-mli]: Cannot find interface file.
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
The warnings 32 are triggered because the values are not exported (anymore) and not used inside their compilation unit. All the reported unused values can be removed, just like reports from the analyzer.

After this first cleanup, running our `dune` command a second time outputs even more reports:
```
$ dune build @check
File "src/tools/opam_admin_top.ml", line 14, characters 4-12:
14 | let identity _ x = x
         ^^^^^^^^
Error (warning 32 [unused-value-declaration]): unused value identity.

File "src/tools/opam_admin_top.ml", line 15, characters 4-9:
15 | let true_ _ = true
         ^^^^^
Error (warning 32 [unused-value-declaration]): unused value true_.

File "src/tools/opam_admin_top.ml", line 23, characters 4-9:
23 | let apply f x prefix y =
         ^^^^^
Error (warning 32 [unused-value-declaration]): unused value apply.

File "src/tools/opam_admin_top.ml", line 28, characters 4-13:
28 | let to_action f x y =
         ^^^^^^^^^
Error (warning 32 [unused-value-declaration]): unused value to_action.

File "src/tools/opam_admin_top.ml", line 40, characters 4-21:
40 | let iter_packages_gen ?(quiet=false) f =
         ^^^^^^^^^^^^^^^^^
Error (warning 32 [unused-value-declaration]): unused value iter_packages_gen.

File "src/tools/opam_admin_top.ml", line 105, characters 4-10:
105 | let filter fn patterns =
          ^^^^^^
Error (warning 32 [unused-value-declaration]): unused value filter.
```

Once again, we can cleanup the compiler reports and run our command:
```
$ dune build @check
File "src/tools/opam_admin_top.ml", line 12, characters 0-20:
12 | open OpamFilename.Op
     ^^^^^^^^^^^^^^^^^^^^
Error (warning 33 [unused-open]): unused open OpamFilename.Op.

File "src/tools/opam_admin_top.ml", line 14, characters 4-8:
14 | let repo = OpamFilename.cwd ()
         ^^^^
Error (warning 32 [unused-value-declaration]): unused value repo.

File "src/tools/opam_admin_top.ml", line 16, characters 4-8:
16 | let wopt w f = function
         ^^^^
Error (warning 32 [unused-value-declaration]): unused value wopt.

File "src/tools/opam_admin_top.ml", line 20, characters 4-13:
20 | let of_action o = function
         ^^^^^^^^^
Error (warning 32 [unused-value-declaration]): unused value of_action.

File "src/tools/opam_admin_top.ml", line 25, characters 4-23:
25 | let regexps_of_patterns patterns =
         ^^^^^^^^^^^^^^^^^^^
Error (warning 32 [unused-value-declaration]): unused value regexps_of_patterns.
```

Third time's the charm. After cleaning up these reports, the file does not contain anything but comments.
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

Then we also need to edit the `executable` stanza in the same file, to replace the dependecy on the removed lib to a dependency on the ocaml toplevel:
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

Finally, we must update the rule to generate `src/tools/opam_admin_topstart.ml` in the same `dune` file:
```diff
-(rule (with-stdout-to opam_admin_topstart.ml (echo "include Opam_admin_top\n\nlet _ = Topmain.main ()")))
+(rule (with-stdout-to opam_admin_topstart.ml (echo "let _ = Topmain.main ()")))
```

#### Tests

This section focuses on reports in `/tmp/proj/opam/tests`.

We don't want to remove them for now but actaully to ignore them in the analyzer's report.
To do this, we can update our `dead_code_analyzer` command to:
```
$ dead_code_analyzer --exclude _build/default/tests --references _build/default/tests --verbose _build 2> dca.err > dca.out
```
2 new options are used:
- `--exclude <path>` skips the `.cmt` and `.cmti` files found in `<path>`
- `--references <path>` adds the `.cmt` and `.cmti` files found in `<path>` to account uses found in them.

Alternatively, because we want to focus on values exported in `src` while accounting for uses in the whole codebase, we can use the following simpler command:
```
$ dead_code_analyzer --references _build --verbose _build/default/src 2> dca.err > dca.out
```
This command gather uses from the whole codebase (`_build`) but only tracks elements of code declared in `_build/default/src`.

### Unused methods

The [report](../assets/reports/dca/opam/dca.out)'s unused methods section is empty.
```
.> UNUSED METHODS:
=================

Nothing else to report in this section
--------------------------------------------------------------------------------
```

By grepping the codebase, we can quickly verify that there is no use of objects or classes, confirming that there cannot be any unused method:
```
$ pwd
/tmp/proj/opam

$ grep -rnw -e object -e class src
src/state/opamSwitchState.mli:179:    backward conflict definition or common conflict-class. Packages in [subset]
src/core/opamStubs.mli:92:    and a font object, which will have been selected into the DC.
src/core/opamStubs.mli:97:(** Windows only. Given [(dc, font)], deletes the font object and releases the
src/core/opamStubs.mli:141:(** Windows only. Returns the name of the class for the Console window or [None]
src/core/cmdliner/cmdliner_base.ml:11:  (* Thread-safe UIDs, Oo.id (object end) was used before.
src/client/opamListCommand.ml:821:    Field "conflict-class";
src/client/opamArg.ml:1615:       list, from the other package, or by a common $(b,conflict-class:) \
src/format/opamFile.ml:2994:      "conflict-class", no_cleanup Pp.ppacc with_conflict_class conflict_class
```

### Unused constructors/record fields

The [report](../assets/reports/dca/opam/dca.out)'s unused constructors/record fields section initial content is 75 lines long after discarding the header, footer, and blank lines.
<details><summary>88 lines report output (<i>click to expand/hide</i>)</summary>

```
.> UNUSED CONSTRUCTORS/RECORD FIELDS:
====================================
/tmp/proj/opam/src/client/opamListCommand.mli:38: pattern_selector.ext_fields
/tmp/proj/opam/src/client/opamListCommand.mli:59: selector.Atoms

/tmp/proj/opam/src/core/opamCompat.mli:36: Either.t.Left
/tmp/proj/opam/src/core/opamCompat.mli:37: Either.t.Right
/tmp/proj/opam/src/core/opamProcess.mli:73: t.p_info
/tmp/proj/opam/src/core/opamStd.mli:474: Sys.os.Darwin
/tmp/proj/opam/src/core/opamStd.mli:475: Sys.os.Linux
/tmp/proj/opam/src/core/opamStd.mli:476: Sys.os.FreeBSD
/tmp/proj/opam/src/core/opamStd.mli:477: Sys.os.OpenBSD
/tmp/proj/opam/src/core/opamStd.mli:478: Sys.os.NetBSD
/tmp/proj/opam/src/core/opamStd.mli:479: Sys.os.DragonFly
/tmp/proj/opam/src/core/opamStd.mli:482: Sys.os.Unix
/tmp/proj/opam/src/core/opamStd.mli:483: Sys.os.Other
/tmp/proj/opam/src/core/opamStd.mli:505: Sys.powershell_host.Powershell_pwsh
/tmp/proj/opam/src/core/opamStd.mli:505: Sys.powershell_host.Powershell
/tmp/proj/opam/src/core/opamStd.mli:506: Sys.shell.SH_sh
/tmp/proj/opam/src/core/opamStd.mli:506: Sys.shell.SH_bash
/tmp/proj/opam/src/core/opamStd.mli:506: Sys.shell.SH_zsh
/tmp/proj/opam/src/core/opamStd.mli:506: Sys.shell.SH_csh
/tmp/proj/opam/src/core/opamStd.mli:506: Sys.shell.SH_fish
/tmp/proj/opam/src/core/opamStd.mli:507: Sys.shell.SH_pwsh
/tmp/proj/opam/src/core/opamStd.mli:507: Sys.shell.SH_cmd
/tmp/proj/opam/src/core/opamStd.mli:613: Sys.warning_printer.warning
/tmp/proj/opam/src/core/opamStubsTypes.ml:23: console_screen_buffer_info.window
/tmp/proj/opam/src/core/opamStubsTypes.ml:26: console_screen_buffer_info.maximumWindowSize
/tmp/proj/opam/src/core/opamStubsTypes.ml:34: console_font_infoex.font
/tmp/proj/opam/src/core/opamStubsTypes.ml:36: console_font_infoex.fontSize
/tmp/proj/opam/src/core/opamStubsTypes.ml:42: console_font_infoex.fontWeight
/tmp/proj/opam/src/core/opamStubsTypes.ml:77: windows_cpu_architecture.AMD64
/tmp/proj/opam/src/core/opamStubsTypes.ml:78: windows_cpu_architecture.ARM
/tmp/proj/opam/src/core/opamStubsTypes.ml:79: windows_cpu_architecture.ARM64
/tmp/proj/opam/src/core/opamStubsTypes.ml:80: windows_cpu_architecture.IA64
/tmp/proj/opam/src/core/opamStubsTypes.ml:81: windows_cpu_architecture.Intel
/tmp/proj/opam/src/core/opamStubsTypes.ml:82: windows_cpu_architecture.Unknown
/tmp/proj/opam/src/core/opamStubsTypes.ml:87: win32_non_fixed_version_info.comments
/tmp/proj/opam/src/core/opamStubsTypes.ml:88: win32_non_fixed_version_info.companyName
/tmp/proj/opam/src/core/opamStubsTypes.ml:89: win32_non_fixed_version_info.fileDescription
/tmp/proj/opam/src/core/opamStubsTypes.ml:90: win32_non_fixed_version_info.fileVersionString
/tmp/proj/opam/src/core/opamStubsTypes.ml:91: win32_non_fixed_version_info.internalName
/tmp/proj/opam/src/core/opamStubsTypes.ml:92: win32_non_fixed_version_info.legalCopyright
/tmp/proj/opam/src/core/opamStubsTypes.ml:93: win32_non_fixed_version_info.legalTrademarks
/tmp/proj/opam/src/core/opamStubsTypes.ml:94: win32_non_fixed_version_info.originalFilename
/tmp/proj/opam/src/core/opamStubsTypes.ml:95: win32_non_fixed_version_info.productName
/tmp/proj/opam/src/core/opamStubsTypes.ml:97: win32_non_fixed_version_info.privateBuild
/tmp/proj/opam/src/core/opamStubsTypes.ml:98: win32_non_fixed_version_info.specialBuild
/tmp/proj/opam/src/core/opamStubsTypes.ml:103: win32_version_info.signature
/tmp/proj/opam/src/core/opamStubsTypes.ml:104: win32_version_info.version
/tmp/proj/opam/src/core/opamStubsTypes.ml:105: win32_version_info.fileVersion
/tmp/proj/opam/src/core/opamStubsTypes.ml:106: win32_version_info.productVersion
/tmp/proj/opam/src/core/opamStubsTypes.ml:107: win32_version_info.fileFlagsMask
/tmp/proj/opam/src/core/opamStubsTypes.ml:108: win32_version_info.fileFlags
/tmp/proj/opam/src/core/opamStubsTypes.ml:109: win32_version_info.fileOS
/tmp/proj/opam/src/core/opamStubsTypes.ml:110: win32_version_info.fileType
/tmp/proj/opam/src/core/opamStubsTypes.ml:111: win32_version_info.fileSubtype
/tmp/proj/opam/src/core/opamStubsTypes.ml:112: win32_version_info.fileDate
/tmp/proj/opam/src/core/opamStubsTypes.ml:118: uname.sysname
/tmp/proj/opam/src/core/opamStubsTypes.ml:119: uname.release
/tmp/proj/opam/src/core/opamStubsTypes.ml:120: uname.machine

/tmp/proj/opam/src/format/opamFile.mli:366: OPAM.t.conflict_class
/tmp/proj/opam/src/format/opamFile.mli:369: OPAM.t.env
/tmp/proj/opam/src/format/opamFile.mli:378: OPAM.t.substs
/tmp/proj/opam/src/format/opamFile.mli:380: OPAM.t.build_env
/tmp/proj/opam/src/format/opamFile.mli:403: OPAM.t.extensions
/tmp/proj/opam/src/format/opamFile.mli:413: OPAM.t.metadata_dir
/tmp/proj/opam/src/format/opamFile.mli:419: OPAM.t.locked
/tmp/proj/opam/src/format/opamFile.mli:1019: Repo_config_legacy.t.repo_name
/tmp/proj/opam/src/format/opamFile.mli:1020: Repo_config_legacy.t.repo_root
/tmp/proj/opam/src/format/opamFile.mli:1038: Switch_config.t.paths
/tmp/proj/opam/src/format/opamTypes.mli:308: universe.u_action
/tmp/proj/opam/src/format/opamTypes.mli:364: lock.Read_lock
/tmp/proj/opam/src/format/opamTypes.mli:368: lock.Global_lock
/tmp/proj/opam/src/format/opamTypes.mli:372: lock.Switch_lock
/tmp/proj/opam/src/format/opamTypes.mli:377: lock.Global_with_switch_cont_lock
/tmp/proj/opam/src/format/opamVariable.mli:26: variable_contents.L

/tmp/proj/opam/src/solver/opamCudfSolverSig.ml:12: criteria_def.crit_default
/tmp/proj/opam/src/solver/opamCudfSolverSig.ml:13: criteria_def.crit_upgrade
/tmp/proj/opam/src/solver/opamCudfSolverSig.ml:14: criteria_def.crit_fixup
/tmp/proj/opam/src/solver/opamCudfSolverSig.ml:15: criteria_def.crit_best_effort_prefix

/tmp/proj/opam/src/state/opamStateTypes.mli:164: switch_state.invalidated

Nothing else to report in this section
--------------------------------------------------------------------------------
```
</details>

The observation made for the unused values remain valid here.
A small difference exists in the naive cleanup technique: removing a field or a constructor will most likely trigger compilation errors.
This is for 2 reasons:
1. the types described in the signature and the structure must be equal;
2. a field is considered unused if it is never read (but it must be written when creating a value),
and a constructor is considered unused if it is never constructed (but it may be destructed e.g. in pattern matching).

Therefore, cleaning up an unused field or constructor requires compiling the code to fix all the places impacted by the removal of the unused element.

Because we already removed some code during the cleanup of unused exported values, the lines of the reports are not exact anymore.
For the sake of this example, we will pretend that they are. One can run the analyzer on unused fields and constructors specifically by running the `dead_code_analyzer` command with the `--nothing -T all` arguments.
