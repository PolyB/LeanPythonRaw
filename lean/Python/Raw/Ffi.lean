namespace Python.Raw.Ffi

private constant PyObjectNonempty : NonemptyType
def PyObject : Type := PyObjectNonempty.type


structure PyError where
 exType : PyObject
 exValue : Option PyObject
 exTraceback : Option PyObject

abbrev IOExp (t : Type) := IO $ Except PyError t

@[extern "Lean_Py_Initialize"]
constant Py_Initialize : IO Unit

@[extern "Lean_Py_IsInitialized"]
constant Py_IsInitialized : IO Bool

@[extern "Lean_Py_FinalizeEx"]
constant Py_FinalizeEx : IO Bool

@[extern "Lean_PyUnicode_FromString"]
constant PyUnicode_FromString : String → IO PyObject

@[extern "Lean_PyObject_GetAttrString"]
constant PyObject_GetAttrString : PyObject → String → IOExp PyObject

@[extern "Lean_PyObject_GetAttr"]
constant PyObject_GetAttr : PyObject → PyObject → IOExp PyObject

@[extern "Lean_PyUnicode_AsUTF8"]
constant PyUnicode_AsUTF8 : PyObject → IOExp String

@[extern "Lean_PyImport_Import"]
constant PyImport_Import : PyObject → IOExp PyObject

@[extern "Lean_MakeTuple"]
constant PyTuple_Make : Array PyObject → IOExp PyObject

@[extern "Lean_MakeList"]
constant PyList_Make : Array PyObject → IOExp PyObject

@[extern "Lean_PyDict_New"]
constant PyDict_New : IOExp PyObject

@[extern "Lean_PyDict_SetItemString"]
constant PyDict_SetItemString : (dict : PyObject) → (key : String) → (value : PyObject) → IOExp PUnit

@[extern "Lean_PyDict_SetItem"]
constant PyDict_SetItem: (dict : PyObject) → (key : PyObject) → (value : PyObject) → IOExp PUnit

@[extern "Lean_PyObject_Call"]
constant PyObject_Call : (callable : PyObject) → (args_tuple : PyObject) → (kwargs_dict : PyObject) → IOExp PyObject

@[extern "Lean_PyObject_Call_NoKw"]
constant PyObject_Call_NoKw : (callable : PyObject) → (args_tuple : PyObject) → IOExp PyObject

@[extern "Lean_PyObject_CallNoArgs"]
constant PyObject_CallNoArgs : (callable : PyObject) → IOExp PyObject

@[extern "Lean_PyObject_CallOneArg"]
constant PyObject_CallOneArg : (callable : PyObject) → (arg : PyObject) → IOExp PyObject

@[extern "Lean_PyObject_Print"]
constant PyObject_Print : PyObject → IO PUnit

@[extern "Lean_PyObject_Str"]
constant PyObject_Str : PyObject → IOExp PyObject

@[extern "Lean_PyObject_Repr"]
constant PyObject_Repr : PyObject → IOExp PyObject

-- Py_None is done manually as it is used to define `Inhabited PyObject`

@[extern "Lean_PyObject_Py_None"]
private constant mkPyNone : Unit → PyObject := fun _ => Classical.choice PyObjectNonempty.property
def Py_None : PyObject := mkPyNone ()

instance : Inhabited PyObject where
  default := Py_None

macro "mkpyobj!" name:ident : command =>do
                                          let extern_ident := Lean.mkIdentFrom name (Lean.Name.mkSimple s!"{name.getId.toString}_")
                                          let definition ← `(private constant $extern_ident (u : Unit): PyObject)
                                          let attrdef ← `(attribute [extern $(Lean.quote s!"Lean_PyObject_{name}")] $extern_ident)
                                          let defpub ← `(def $name : PyObject := $extern_ident ())
                                          return Lean.mkNullNode #[definition, attrdef, defpub]
                                         
syntax "mkpyobjs!" ident+ : command
macro_rules
  | `(mkpyobjs! $[$n:ident]*) => do
      return Lean.mkNullNode $ ← n.mapM (λ i => `(mkpyobj! $i))

mkpyobjs!
  -- Fundamental objects
  -- Py_None should be here, but it's manually defined to implement `Inhabited PyObject
  Py_False
  Py_True
  -- exceptions
  PyExc_BaseException
  PyExc_Exception
  PyExc_StopAsyncIteration
  PyExc_StopIteration
  PyExc_GeneratorExit
  PyExc_ArithmeticError
  PyExc_LookupError
  PyExc_AssertionError
  PyExc_AttributeError
  PyExc_BufferError
  PyExc_EOFError
  PyExc_FloatingPointError
  PyExc_OSError
  PyExc_ImportError
  PyExc_ModuleNotFoundError
  PyExc_IndexError
  PyExc_KeyError
  PyExc_KeyboardInterrupt
  PyExc_MemoryError
  PyExc_NameError
  PyExc_OverflowError
  PyExc_RuntimeError
  PyExc_RecursionError
  PyExc_NotImplementedError
  PyExc_SyntaxError
  PyExc_IndentationError
  PyExc_TabError
  PyExc_ReferenceError
  PyExc_SystemError
  PyExc_SystemExit
  PyExc_TypeError
  PyExc_UnboundLocalError
  PyExc_UnicodeError
  PyExc_UnicodeEncodeError
  PyExc_UnicodeDecodeError
  PyExc_UnicodeTranslateError
  PyExc_ValueError
  PyExc_ZeroDivisionError
  PyExc_BlockingIOError
  PyExc_BrokenPipeError
  PyExc_ChildProcessError
  PyExc_ConnectionError
  PyExc_ConnectionAbortedError
  PyExc_ConnectionRefusedError
  PyExc_ConnectionResetError
  PyExc_FileExistsError
  PyExc_FileNotFoundError
  PyExc_InterruptedError
  PyExc_IsADirectoryError
  PyExc_NotADirectoryError
  PyExc_PermissionError
  PyExc_ProcessLookupError
  PyExc_TimeoutError