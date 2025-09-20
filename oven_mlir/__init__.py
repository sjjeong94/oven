"""
Oven MLIR Compiler - Python Bindings

This package provides Python bindings for the Oven MLIR compiler,
allowing seamless integration of MLIR compilation into Python workflows.

Example usage:

    import oven

    # Simple compilation
    compiler = oven.OvenCompiler()
    result = compiler.compile_file('my_kernel.mlir', format='llvm')

    # Or use convenience function
    llvm_ir = oven.compile_oven_mlir('my_kernel.mlir', format='llvm')

    # Direct nanobind access
    optimizer = oven.OvenOptimizer()
    result = optimizer.optimize_mlir(mlir_code)
"""

__version__ = "0.1.0"
__author__ = "Oven MLIR Team"

# Import the native module
try:
    from .oven_opt_py import (
        OvenOptimizer,
        optimize_string,
        optimize_file,
        to_llvm_ir,
        to_ptx,
        optimize_and_convert,
    )

    _NATIVE_MODULE_AVAILABLE = True
except ImportError as e:
    _NATIVE_MODULE_AVAILABLE = False
    _IMPORT_ERROR = str(e)

# Import high-level interface
if _NATIVE_MODULE_AVAILABLE:
    from .oven import OvenCompiler, compile_oven_mlir

    # Import integrated Python to PTX compiler
    try:
        from .python_to_ptx import (
            PythonToPTXCompiler,
            compile_python_string_to_ptx,
            compile_python_file_to_ptx,
        )

        _PYTHON_TO_PTX_AVAILABLE = True
    except ImportError:
        _PYTHON_TO_PTX_AVAILABLE = False

        # Create placeholder classes for missing dependencies
        class PythonToPTXCompiler:
            def __init__(self, *args, **kwargs):
                raise ImportError(
                    "oven-compiler is required for Python to PTX compilation. Install with: pip install oven-compiler"
                )

        def compile_python_string_to_ptx(*args, **kwargs):
            raise ImportError(
                "oven-compiler is required for Python to PTX compilation. Install with: pip install oven-compiler"
            )

        def compile_python_file_to_ptx(*args, **kwargs):
            raise ImportError(
                "oven-compiler is required for Python to PTX compilation. Install with: pip install oven-compiler"
            )

else:
    # Provide helpful error messages when native module is not available
    class _MissingNativeModule:
        def __init__(self, name):
            self.name = name

        def __call__(self, *args, **kwargs):
            raise ImportError(f"Native module not available: {_IMPORT_ERROR}")

    OvenOptimizer = _MissingNativeModule("OvenOptimizer")
    OvenCompiler = _MissingNativeModule("OvenCompiler")
    optimize_string = _MissingNativeModule("optimize_string")
    optimize_file = _MissingNativeModule("optimize_file")
    to_llvm_ir = _MissingNativeModule("to_llvm_ir")
    to_ptx = _MissingNativeModule("to_ptx")
    optimize_and_convert = _MissingNativeModule("optimize_and_convert")
    compile_oven_mlir = _MissingNativeModule("compile_oven_mlir")
    compile_oven_mlir = _MissingNativeModule("compile_oven_mlir")

# Export public API
__all__ = [
    # Core MLIR compilation
    "OvenOptimizer",
    "OvenCompiler",
    "optimize_string",
    "optimize_file",
    "to_llvm_ir",
    "to_ptx",
    "optimize_and_convert",
    "compile_oven_mlir",
    # Integrated Python to PTX compilation
    "PythonToPTXCompiler",
    "compile_python_string_to_ptx",
    "compile_python_file_to_ptx",
]
