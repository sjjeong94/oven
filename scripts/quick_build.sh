#!/bin/bash
#
# Quick build script for development with GPU compute capability support
#

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"

echo "🔧 Quick oven-mlir build with GPU support"
echo "=========================================="

cd "$PROJECT_ROOT"

# Check if native modules need to be built
if [[ ! -f "oven_mlir/oven_opt_py"*".so" ]]; then
    echo "⚡ Building native modules first..."
    
    # Set up build directory with proper CMake configuration
    if [[ ! -f "build/Makefile" && ! -f "build/build.ninja" ]]; then
        echo "🔧 Setting up CMake configuration..."
        rm -rf build
        mkdir -p build
        cd build
        
        if [[ -d "../llvm-project/build" ]]; then
            cmake .. -DCMAKE_BUILD_TYPE=Release \
                    -DMLIR_DIR="$PWD/../llvm-project/build/lib/cmake/mlir" \
                    -DLLVM_DIR="$PWD/../llvm-project/build/lib/cmake/llvm"
        else
            echo "❌ LLVM/MLIR not found. Please run install_mlir.sh first:"
            echo "   ./scripts/install_mlir.sh"
            exit 1
        fi
        cd "$PROJECT_ROOT"
    fi
    
    # Build native modules and tools
    cd build
    if [[ -f "build.ninja" ]]; then
        ninja oven_opt_py oven-opt
    else
        make oven_opt_py oven-opt -j$(nproc)
    fi
    
    # Copy built modules to the correct location
    find . -name "oven_opt_py*.so" -exec cp {} "$PROJECT_ROOT/oven_mlir/" \;
    
    # Create tools directory if it doesn't exist and copy oven-opt
    mkdir -p "$PROJECT_ROOT/tools/build"
    if [[ -f "tools/oven-opt" ]]; then
        cp tools/oven-opt "$PROJECT_ROOT/tools/build/"
        # Create a symlink in project root for easier access
        ln -sf "tools/build/oven-opt" "$PROJECT_ROOT/oven-opt"
        echo "✅ oven-opt tool built and copied to tools/build/"
        echo "✅ oven-opt symlink created in project root"
    fi
    
    cd "$PROJECT_ROOT"
    echo "✅ Native modules and tools built and copied"
fi

# Install build dependencies if needed
echo "📦 Installing build dependencies..."
pip install -q build twine wheel

# Clean previous builds
echo "🧹 Cleaning previous builds..."
rm -rf dist/ build/ *.egg-info/

# Build package
echo "🏗️  Building package with GPU compute capability support..."
python -m build --wheel

# Validate package
echo "✅ Validating package..."
python -m twine check dist/*

# Test GPU functionality
echo "🎯 Testing GPU compute capability functionality..."
if pip install dist/*.whl --force-reinstall --quiet; then
    python -c "
import oven_mlir
print('✅ Current compute capability:', oven_mlir.get_compute_capability())
oven_mlir.set_compute_capability('sm_80')
print('✅ Set to sm_80:', oven_mlir.get_compute_capability())
print('✅ PTX support:', oven_mlir.check_ptx_support())
print('✅ GPU functionality test passed')
"
else
    echo "❌ Package installation failed"
    exit 1
fi

echo
echo "🎉 Build completed successfully with GPU support!"
echo "📁 Files created:"
ls -lah dist/

echo
echo "🎯 GPU Features Included:"
echo "   ✅ Dynamic compute capability detection"
echo "   ✅ CLI options: --compute-capability, --sm"
echo "   ✅ Environment variable: OVEN_SM_ARCH"
echo "   ✅ Python API: get/set_compute_capability()"
echo "   ✅ Target checking: check_targets(), check_ptx_support()"

echo
echo "🚀 To upload to Test PyPI:"
echo "   python -m twine upload --repository testpypi dist/*"
echo
echo "🚀 To upload to PyPI:"  
echo "   python -m twine upload dist/*"

echo
echo "🧪 To test GPU functionality:"
echo "   oven-mlir input.mlir --format ptx --compute-capability sm_80"
echo "   OVEN_SM_ARCH=sm_75 oven-mlir input.mlir --format ptx"
echo
echo "🔧 To use oven-opt tool:"
echo "   ./oven-opt input.mlir --oven-to-llvm"
echo "   ./oven-opt tests/reduce_sum_axis1.mlir --oven-to-llvm"