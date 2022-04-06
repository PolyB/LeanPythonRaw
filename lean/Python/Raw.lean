import Python.Raw.Ffi

open Python.Raw.Ffi

namespace Python.Raw

variable [Monad pym] [MonadExcept PyObject pym] [MonadLiftT IO pym]

private def RunRawFfi (cmd : IO $ Except PyObject a) : pym a := do
  match ←monadLift cmd with
  | (Except.ok val) => return val
  | (Except.error err) => throw err


def Initialize : IO Unit := Py_Initialize
def IsInitialized : IO Bool := Py_IsInitialized
def Finalize : IO Bool := Py_FinalizeEx

def MkString : String → IO PyObject := PyUnicode_FromString
def GetString (str : PyObject) : pym String := RunRawFfi $ PyUnicode_AsUTF8 str

def GetObjAttr (obj : PyObject) (attr : String) : pym PyObject := RunRawFfi $ PyObject_GetAttrString obj attr

def Import (modName : PyObject) : pym PyObject := RunRawFfi $ PyImport_Import modName

def MakeTuple (objs : Array PyObject) : pym PyObject := RunRawFfi $ PyTuple_Make objs

def MakeList (objs : Array PyObject) : pym PyObject := RunRawFfi $ PyList_Make objs

def MakeDict : pym PyObject := RunRawFfi $ PyDict_New
def DictSetItem (dict : PyObject) (key : String) (val : PyObject): pym Unit := RunRawFfi $ PyDict_SetItemString dict key val

def Call (callable : PyObject) (args_tuple : PyObject) (kwargs_dict : PyObject) : pym PyObject := RunRawFfi $ PyObject_Call callable args_tuple kwargs_dict
def CallNoArgs (callable : PyObject) : pym PyObject := RunRawFfi $ PyObject_CallNoArgs callable
def CallOneArg (callable : PyObject) (arg : PyObject) : pym PyObject := RunRawFfi $ PyObject_CallOneArg callable arg

def DebugPrint : PyObject → IO Unit := PyObject_Print