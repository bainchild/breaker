local file = loadstring(assert(io.open(assert((...),"no arg"),"rb")):read("*a"))
print(require("dump")(file))
