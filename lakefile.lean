import Lake
open System Lake DSL

def python := "python3.9"

def buildDir := defaultBuildDir
def cDir : FilePath := "c"
def ffiSrc := cDir / "ffi.cpp"
def includeDir := s!"/usr/include/{python}"

def ffiOTarget (pkgDir : FilePath) : FileTarget :=
  let oFile := pkgDir / buildDir / cDir / "ffi.o"
  let srcTarget := inputFileTarget <| pkgDir / ffiSrc
  fileTargetWithDep oFile srcTarget fun srcFile => do
    compileO oFile srcFile #["-std=c++17", "-fno-threadsafe-statics", "-fno-exceptions", "-I", (← getLeanIncludeDir).toString, "-I", includeDir, "-fPIC"] "c++"

def sharedLibDir (pkgDir : FilePath) : FilePath :=
  pkgDir / buildDir / cDir / "libpythonffi.a"

def cLibTarget (pkgDir : FilePath) : FileTarget :=
  let libFile := sharedLibDir pkgDir
  staticLibTarget libFile #[ffiOTarget pkgDir]


package leanpythonraw (pkgDir) (args) {
  -- add configuration options here
  srcDir := "lean"
  libRoots := #[`Python.Raw]
  moreLibTargets := #[cLibTarget pkgDir]
  moreServerArgs := #[]
  defaultFacet := PackageFacet.sharedLib
  supportInterpreter := true
  moreLinkArgs := #[s!"-l{python}"]
}
