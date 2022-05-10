import Lake
open System Lake DSL

def python := "python3.9"

package leanpythonraw {
  srcDir := "lean"
  libRoots := #[`Python.Raw]
  defaultFacet := PackageFacet.sharedLib
  moreLinkArgs := #[s!"-l{python}"]
}

lean_lib LeanPythonRaw {

}

def includeDir := s!"/usr/include/{python}"

-- extern_lib cLib :=

def pkgDir := __dir__
def cDir := pkgDir / "c"
def ffiSrc := cDir / "ffi.cpp"
def buildDir := pkgDir / _package.buildDir / "c"

def ffiOTarget : FileTarget :=
  let oFile := pkgDir / buildDir / cDir / "ffi.o"
  let srcTarget := inputFileTarget <| pkgDir / ffiSrc
  fileTargetWithDep oFile srcTarget fun srcFile => do
    compileO oFile srcFile #["-std=c++17", "-fno-threadsafe-statics", "-fno-exceptions", "-I", (← getLeanIncludeDir).toString, "-I", includeDir, "-fPIC"] "c++"


extern_lib cLib :=
  let libFile := buildDir / "libpythonffi.so"
  --staticLibTarget libFile #[ffiOTarget]
  cSharedLibTarget libFile #[ffiOTarget]

-- 
-- def sharedLibDir (pkgDir : FilePath) : FilePath :=
--   pkgDir / buildDir / cDir / "libpythonffi.so"
-- 
-- def cLibTarget (pkgDir : FilePath) : FileTarget :=
--   let libFile := sharedLibDir pkgDir
--   leanSharedLibTarget libFile #[ffiOTarget pkgDir] #[s!"-l{python}"]
--   -- staticLibTarget libFile #[ffiOTarget pkgDir]
-- 
-- 
-- package leanpythonraw (pkgDir) {
--   -- add configuration options here
--   srcDir := "lean"
--   libRoots := #[`Python.Raw]
--   moreLibTargets := #[cLibTarget pkgDir]
--   moreServerArgs := #[]
--   defaultFacet := PackageFacet.sharedLib
--   supportInterpreter := true
--   -- moreLinkArgs := #[s!"-l{python}"]
-- }
-- 