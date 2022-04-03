import Python.Raw.Ffi

open Python.Raw

def str := PyUnicode_FromString

def throwIfBad : Except PyObject a → IO a
| Except.error err => do
                        PyObject_Print err
                        println! "" -- python doesn't print newline
                        throw $ IO.userError "python error"
| Except.ok res => pure res

-- import rich ; rich.print(arg)
def rich_prettyPrint (obj : PyObject) : IO Unit := do
  let rich_str ← PyUnicode_FromString "rich"
  let rich_import ← throwIfBad $ ← PyImport_Import rich_str
  let rich_print ← throwIfBad $ ← PyObject_GetAttrString rich_import "print"
  let emptyDict ← throwIfBad $ ← PyDict_New
  let emptyDictTuple ← throwIfBad $ ←PyTuple_Make #[obj]
  _ ← throwIfBad $ ← (PyObject_Call rich_print emptyDictTuple emptyDict)


def main : IO PUnit := do

  Py_Initialize
  println! "Initialized : {←Py_IsInitialized}"

  let emptyDict ← throwIfBad $ ← PyDict_New
  let dict ← throwIfBad $ ← PyDict_SetItemString emptyDict "Test" emptyDict
  let s ←PyUnicode_FromString "Hello !"
  let array ← throwIfBad $ ←PyTuple_Make #[emptyDict, s]

  rich_prettyPrint array