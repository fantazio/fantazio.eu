open Yocaml

let www = Path.rel [ "_www" ]
let assets = Path.rel [ "assets" ]
let images = Path.(assets / "images")
let css = Path.(assets / "css")
let templates = Path.(assets / "templates")
let content = Path.rel [ "content" ]
let pages = Path.(content / "pages")

let track_binary =
  Sys.executable_name |> Yocaml.Path.from_string |> Pipeline.track_file

let with_ext exts file =
  List.exists (fun ext -> Path.has_extension ext file) exts

let build_paths dir filenames =
  List.map (fun filename -> Path.(dir / filename)) filenames

let create_page source =
  let www_page =
    source |> Path.move ~into:www |> Path.change_extension "html"
  in
  let pipeline =
    let open Task in
    let templates = build_paths templates [ "page.html"; "layout.html" ] in
    let+ () = track_binary
    and+ apply_templates = Yocaml_jingoo.read_templates templates
    and+ metadata, content =
      Yocaml_yaml.Pipeline.read_file_with_metadata
        (module Archetype.Page)
        source
    in
    content
    |> Yocaml_markdown.from_string_to_html
    |> apply_templates (module Archetype.Page) ~metadata
  in
  Action.Static.write_file www_page pipeline

let create_pages =
  let is_markdown file = with_ext [ "md"; "markdown"; "mdown" ] file in
  Batch.iter_files ~where:is_markdown pages create_page

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
  >>= Action.store_cache cache

let () =
  match Sys.argv.(1) with
  | "server" -> Yocaml_unix.serve ~level:`Info ~target:www ~port:8000 program
  | _ | (exception _) -> Yocaml_unix.run ~level:`Debug program
