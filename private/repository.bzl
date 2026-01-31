"""
Copyright (C) 2026 Wenyi Tang.

Licensed under the Apache License, Version 2.0 (the "License");
you may not use this file except in compliance with the License.
You may obtain a copy of the License at

    http://www.apache.org/licenses/LICENSE-2.0

Unless required by applicable law or agreed to in writing, software
distributed under the License is distributed on an "AS IS" BASIS,
WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
See the License for the specific language governing permissions and
limitations under the License.
"""

def _print_or_fail(ctx, _msg):
    if ctx.attr.required:
        fail(_msg)
    ctx.file("BUILD", """# tensorrt not found
cc_library(
    name = "tensorrt",
    visibility = ["//visibility:public"],
)
""")
    print("[WARNING] " + _msg)

def _impl(ctx):
    # Prefer the tensorrt_root attribute; fall back to the TENSORRT_ROOT environment variable
    tensorrt_root = ctx.attr.tensorrt_root or ctx.os.environ.get("TENSORRT_ROOT", "")
    if not tensorrt_root or not ctx.path(tensorrt_root).exists:
        _print_or_fail(ctx, "Either the 'tensorrt_root' attribute must be set, or the TENSORRT_ROOT environment variable must be defined.")
        return

    # Convert to an absolute path
    tensorrt_root = ctx.path(tensorrt_root)

    # Check that required directories exist
    headers_path = tensorrt_root.get_child("include")
    lib_path = tensorrt_root.get_child("lib")
    bin_path = tensorrt_root.get_child("bin")

    if not headers_path.exists:
        _print_or_fail(ctx, "TensorRT headers not found at %s" % headers_path)
        return
    if not lib_path.exists:
        _print_or_fail(ctx, "TensorRT libraries not found at %s" % lib_path)
        return

    # Read version
    nvinfer_version = headers_path.get_child("NvInferVersion.h")
    contents = ctx.read(nvinfer_version).splitlines()
    macros = {}
    for line in contents:
        line = line.strip()
        if line.startswith("#define") and len(line.split(" ")) > 2:
            _, key, value = line.strip().split(" ", 2)
            macros[key] = value
    trt_major = macros.get("TRT_MAJOR_ENTERPRISE", 10)
    trt_minor = macros.get("TRT_MINOR_ENTERPRISE", 0)

    # link headers and libraries
    ctx.symlink(headers_path, "include")
    ctx.symlink(lib_path, "lib")
    ctx.symlink(bin_path, "bin")

    # Generate the BUILD file content
    ctx.template("BUILD.bazel", ctx.attr._build_file, {"%{TENSORRT_MAJOR_VERSION}": trt_major})
    ctx.file("WORKSPACE", "")

config_tensorrt = repository_rule(
    implementation = _impl,
    attrs = {
        "tensorrt_root": attr.string(
            doc = "Path to the TensorRT installation root directory. If not provided, falls back to the TENSORRT_ROOT environment variable.",
        ),
        "required": attr.bool(default = True, doc = "fail(warning) if (not) required"),
        "_build_file": attr.label(default = "//private/template:trt.tpl", allow_single_file = True),
    },
    environ = ["TENSORRT_ROOT"],
    configure = True,
    local = True,
)
