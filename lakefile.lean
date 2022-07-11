import Lake
open System Lake DSL

def pythonver := "3.10"
def pythonverFull := "3.10.5"
def python := s!"python{pythonver}"
def releaseTarball := s!"Python-{pythonverFull}.tar.xz"
def pythonReleaseUrl := s!"https://www.python.org/ftp/python/{pythonverFull}/{releaseTarball}"

package pythonraw {
  srcDir := "lean"
  libRoots := #[`Python.Raw]
  defaultFacet := PackageFacet.leanLib
  precompileModules := true
}

lean_lib PythonRaw {
}

def pkgDir := __dir__
def cDir := pkgDir / "c"
def ffiSrc := cDir / "ffi.cpp"
def buildDir := pkgDir / _package.buildDir

namespace Utils

def wgetFile (url : String) (targ : FilePath) : FileTarget :=
  fileTargetWithDep targ (Target.nil) (extraDepTrace := computeHash url) fun _ => do
    createParentDirs targ
    proc {
      cmd := "wget"
      args := #[url, "-O", targ.toString]
    }

end Utils

-- tarball containing 
def pythonTarball : FileTarget := Utils.wgetFile pythonReleaseUrl $ buildDir / releaseTarball

-- a hack : we are settings the `configure` file as the target, in reality we want the whole directory
def pythonSourceDir : FileTarget :=
  let pythonSourceDir := buildDir / s!"Python-{pythonverFull}"
  fileTargetWithDep  (pythonSourceDir / "configure") pythonTarball fun srcFile => do
    proc {
      cmd := "tar"
      args := #["-xf", srcFile.toString, "-C", buildDir.toString]
    }

def pythonAFile : FileTarget :=
  let pySourceDir := pythonSourceDir.info.parent.get!
  let targetA := pySourceDir / s!"libpython{pythonver}.a"
  fileTargetWithDep targetA pythonSourceDir fun srcFile => do
    proc {
      cmd := "./configure"
      args := #["--enable-shared", "--enable-optimizations"]
      cwd := srcFile.parent.get!
    }

    proc {
      cmd := "make"
      args := #["-C", srcFile.parent.get!.toString, s!"-j4", s!"libpython{pythonver}.a"]
    }

-- again, I don't know how to have a filetarget directory, so just cheat and say that a file in the directory is the target
def pythonInclude : FileTarget :=
  let pySourceDir := pythonSourceDir.info.parent.get!
  fileTargetWithDep (pySourceDir / "Include" / "Python.h") pythonSourceDir fun _ => return

extern_lib libPython := pythonAFile

def ffiOTarget : FileTarget :=
  let oFile := buildDir / cDir / "ffi.o"
  let srcTarget := inputFileTarget <| pkgDir / ffiSrc
  fileTargetWithDepList oFile [srcTarget, pythonInclude] fun srcFile => do
    compileO oFile (srcFile.get! 0) #["-std=c++17", "-fno-threadsafe-statics", "-fno-exceptions",
                                      "-I", (← getLeanIncludeDir).toString,
                                      "-I", ((srcFile.get! 1).parent.get!.toString),
                                      "-I", ((srcFile.get! 1).parent.get!.parent.get!.toString), -- needed for pyconfig.h
                                      "-fPIC"] "c++"

extern_lib cLib :=
  let libFile := buildDir / nameToStaticLib "pythonffi"
  staticLibTarget libFile #[ffiOTarget]