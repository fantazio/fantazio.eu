(lang dune 3.22)
(name blog)
(version dev)
(generate_opam_files)

(source (github fantazio/fantazio.eu))
(license GPL-3.0-or-later)
(authors "Corentin De Souza <corentin@fantazio.eu>")
(maintainers "Corentin De Souza <corentin@fantazio.eu>")

(package
 (name blog)
 (synopsis "My first blog using YOCaml")
 (description
   "My first personal blog using YOCaml for
   fun and profit")
 (depends
  (ocaml (>= 5.3.0))

  (yocaml (>= 2.5.0))
  (yocaml_unix (>= 2.5.0))

;; Dev setup
  (utop :with-dev-setup)
  (ocamlformat :with-dev-setup)
  (ocp-indent :with-dev-setup)
  (merlin :with-dev-setup)
  (ocaml-lsp-server :with-dev-setup)))
