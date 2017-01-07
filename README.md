# lua-module-path
Lua 5.1 tested Path module provides just string path manipulations.

# path()
return new path object with current path directory (debug.getinfo), also you can set path manually through first string argument of module call (like regular constructor call)

# path("this/is/my/path")
Creates path object with defined string literal. if path ends with delimeter slash, it means path is folder (catalogue) path.
If it ends with non slash character, it means path if file path.
forexample
path("this/is/my/path"):isfile() - true
path("this/is/my/path"):isfolder() - false
