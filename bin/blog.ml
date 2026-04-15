let program () = Yocaml.Eff.log ~level:`Info "Hello World, from YOCaml"
let () = Yocaml_unix.run ~level:`Debug program
