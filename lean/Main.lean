import Python.Raw

open Python.Raw

abbrev PyMonad := ExceptT Ffi.PyObject IO

def PyMonad_run (m : PyMonad a) : IO a := do
  let a : Except Ffi.PyObject a ← m.run
  match a with
  | (Except.error err) => throw $ IO.userError "TODO"
  | (Except.ok ok) => return ok

-- import rich ; rich.print(arg)
def rich_prettyPrint [Monad pym] [MonadExcept Ffi.PyObject pym] [MonadLiftT IO pym] (obj : Ffi.PyObject) : pym Unit := do
  let rich_str ← Python.Raw.MkString "rich"
  let rich_import ← Import rich_str
  let rich_print ← GetObjAttr rich_import "print"
  _ ← CallOneArg rich_print obj


def main : IO PUnit := do
  Initialize
  println! "Initialized : {←IsInitialized}"
  PyMonad_run $ do
    let test_str ← Python.Raw.MkString "TEST"
    rich_prettyPrint test_str