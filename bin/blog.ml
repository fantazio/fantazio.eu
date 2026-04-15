open Yocaml

let www = Path.rel [ "_www" ]
let assets = Path.rel [ "assets" ]
let images = Path.(assets / "images")
let css = Path.(assets / "css")

let track_binary =
  Sys.executable_name |> Yocaml.Path.from_string |> Pipeline.track_file

let create_css =
  let www_style = Path.(www / "style.css") in
  let pipeline =
    let open Task in
    let css_paths =
      [ "reset.css"; "style.css" ] |> List.map (fun path -> Path.(css / path))
    in
    let+ () = track_binary
    and+ content = Pipeline.pipe_files ~separator:"\n" css_paths in
    content
  in
  Action.Static.write_file www_style pipeline

let with_ext exts file =
  List.exists (fun ext -> Path.has_extension ext file) exts

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
  >>= Action.store_cache cache

let () = Yocaml_unix.run ~level:`Debug program
