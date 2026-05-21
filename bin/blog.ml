open Yocaml

let www = Path.rel [ "_www" ]
let assets = Path.rel [ "assets" ]
let images = Path.(assets / "images")
let css = Path.(assets / "css")
let templates = Path.(assets / "templates")
let content = Path.rel [ "content" ]
let pages = Path.(content / "pages")
let articles = Path.(content / "articles")
let reports = Path.(content / "reports")

type document_kind = Page | Article | Report

let track_binary =
  Sys.executable_name |> Yocaml.Path.from_string |> Pipeline.track_file

let with_ext exts file =
  List.exists (fun ext -> Path.has_extension ext file) exts

let is_markdown file = with_ext [ "md"; "markdown"; "mdown" ] file

let is_index file =
  match Path.remove_extension file |> Path.basename with
  | Some "index" -> true
  | _ -> false

let build_paths dir filenames =
  List.map (fun filename -> Path.(dir / filename)) filenames

let relocate document_kind ~into source =
  match document_kind with
  | Page -> Path.move ~into source
  | Article -> Path.trim ~prefix:articles source |> Path.relocate ~into
  | Report -> Path.trim ~prefix:reports source |> Path.relocate ~into

let www_target document_kind source =
  let into =
    match document_kind with
    | Page -> www
    | Article -> Path.(www / "articles")
    | Report -> Path.(www / "reports")
  in
  source |> relocate document_kind ~into |> Path.change_extension "html"

let get_templates document_kind =
  let specific_template =
    match document_kind with
    | Page -> "page.html"
    | Article -> "article.html"
    | Report -> "article.html"
  in
  build_paths templates [ specific_template; "layout.html" ]

module type ARCHETYPE = sig
  include Yocaml.Required.DATA_INJECTABLE
  include Yocaml.Required.DATA_READABLE with type t := t
end

let document_archetype : document_kind -> (module ARCHETYPE) = function
  | Page -> (module Archetype.Page)
  | Article -> (module Archetype.Article)
  | Report -> (module Archetype.Article)

let create_document document_kind source =
  let www_target = www_target document_kind source in
  let module Archetype = (val document_archetype document_kind) in
  let pipeline =
    let open Task in
    let+ () = track_binary
    and+ apply_templates =
      get_templates document_kind |> Yocaml_jingoo.read_templates
    and+ metadata, content =
      Yocaml_yaml.Pipeline.read_file_with_metadata (module Archetype) source
    in
    content
    |> Yocaml_markdown.from_string_to_html
    |> apply_templates (module Archetype) ~metadata
  in
  Action.Static.write_file www_target pipeline

let create_page source = create_document Page source
let create_article source = create_document Article source
let create_report source = create_document Report source

let create_documents document_kind =
  let paths =
    match document_kind with
    | Page -> pages
    | Article -> articles
    | Report -> reports
  in
  let is_file = ref false in
  let where = function
    | `Directory ->
        is_file := false;
        fun _ -> true
    | `File ->
        is_file := true;
        is_markdown
  in
  let action path =
    if !is_file then create_document document_kind path else Eff.return
  in
  Batch.iter_tree ~where paths action

let create_pages = create_documents Page
let create_articles = create_documents Article
let create_reports = create_documents Report

let fetch_articles =
  let compute_link source =
    let into = Path.abs [ "articles" ] in
    source |> relocate Article ~into |> Path.change_extension "html"
  in
  Archetype.Articles.fetch ~where:is_markdown ~compute_link
    (module Yocaml_yaml)
    articles

let create_index =
  let source = Path.(content / "index.md") in
  let www_index = www_target Page source in
  let pipeline =
    let open Task in
    let templates = Path.(templates / "index.html") :: get_templates Page in
    let+ () = track_binary
    and+ apply_templates = Yocaml_jingoo.read_templates templates
    and+ articles = fetch_articles
    and+ metadata, content =
      Yocaml_yaml.Pipeline.read_file_with_metadata
        (module Archetype.Page)
        source
    in
    let metadata = Archetype.Articles.with_page ~page:metadata ~articles in
    content
    |> Yocaml_markdown.from_string_to_html
    |> apply_templates (module Archetype.Articles) ~metadata
  in
  Action.Static.write_file www_index pipeline

let create_css =
  let www_style = Path.(www / "style.css") in
  let pipeline =
    let open Task in
    let css_paths = build_paths css [ "reset.css"; "style.css" ] in
    let+ () = track_binary
    and+ content = Pipeline.pipe_files ~separator:"\n" css_paths in
    content
  in
  Action.Static.write_file www_style pipeline

let copy_images =
  let www_images = Path.(www / "images") in
  let is_image file = with_ext [ "svg"; "png"; "jpg"; "gif" ] file in
  let copy_image image_path = Action.copy_file ~into:www_images image_path in
  Batch.iter_files ~where:is_image images copy_image

let program () =
  let open Eff in
  let cache = Path.(www / ".cache") in
  Action.restore_cache cache
  >>= copy_images
  >>= create_css
  >>= create_pages
  >>= create_articles
  >>= create_reports
  >>= create_index
  >>= Action.store_cache cache

let () =
  match Sys.argv.(1) with
  | "server" -> Yocaml_unix.serve ~level:`Info ~target:www ~port:8000 program
  | _ | (exception _) -> Yocaml_unix.run ~level:`Debug program
