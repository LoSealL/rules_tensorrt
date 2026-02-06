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

TRT_HEADERS = [
    "NvInfer.h",
    "NvInferImpl.h",
    "NvInferLegacyDims.h",
    "NvInferPlugin.h",
    "NvInferPluginBase.h",
    "NvInferPluginUtils.h",
    "NvInferRuntime.h",
    "NvInferRuntimeBase.h",
    "NvInferRuntimeCommon.h",
    "NvInferRuntimePlugin.h",
    "NvInferVersion.h",
    "NvOnnxConfig.h",
    "NvOnnxParser.h",
]

TRT_BUILDER_RESOURCES = [
    "nvinfer_builder_resource",
    "nvinfer_builder_resource_ptx",
    "nvinfer_builder_resource_sm75",
    "nvinfer_builder_resource_sm80",
    "nvinfer_builder_resource_sm86",
    "nvinfer_builder_resource_sm89",
    "nvinfer_builder_resource_sm90",
    "nvinfer_builder_resource_sm120",
]

TRT_LIBS = [
    "nvinfer",
    "nvinfer_dispatch",
    "nvinfer_lean",
    "nvinfer_plugin",
    "nvinfer_vc_plugin",
    "nvonnxparser",
]

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

def _read_trt_version(ctx, version_file):
    contents = ctx.read(version_file).splitlines()
    macros = {}
    for line in contents:
        line = line.strip()
        if line.startswith("#define") and len(line.split(" ")) > 2:
            _, key, value = line.strip().split(" ", 2)
            macros[key] = value
    trt_major = macros.get("TRT_MAJOR_ENTERPRISE", 10)
    trt_minor = macros.get("TRT_MINOR_ENTERPRISE", 0)
    trt_patch = macros.get("TRT_PATCH_ENTERPRISE", 0)
    return (trt_major, trt_minor, trt_patch)

def _find_builder_resources(ctx, lib_path, versions):
    resources_found = []
    major, minor, patch = versions
    for res in TRT_BUILDER_RESOURCES:
        if "windows" in ctx.os.name.lower():
            res_file = lib_path.get_child("{}_{}.dll".format(res, major))
        elif "linux" in ctx.os.name.lower():
            res_file = lib_path.get_child("lib{}.so.{}.{}.{}".format(res, major, minor, patch))
        else:
            fail("MacOS is not supported!")
        if res_file.exists:
            resources_found.append(res)
    return resources_found

def _mapping_headers(ctx, headers_path):
    missing_headers = []
    for hdr in TRT_HEADERS:
        header_file = headers_path.get_child(hdr)
        if header_file.exists:
            ctx.symlink(header_file, "include/" + hdr)
        else:
            missing_headers.append(hdr)
    if missing_headers:
        fail("Missing following headers: {}".format(",".join(missing_headers)))

def _mapping_libs(ctx, lib_path, bin_path, resources, versions):
    missing_libs = []
    major, minor, patch = versions
    for lib in resources:
        if "windows" in ctx.os.name.lower():
            dll_file = bin_path.get_child("{}_{}.dll".format(lib, major))
            lib_file = lib_path.get_child("{}_{}.lib".format(lib, major))
            if dll_file.exists:
                ctx.symlink(dll_file, dll_file.basename)
            else:
                missing_libs.append(lib)
            if lib_file.exists:
                ctx.symlink(lib_file, lib_file.basename)
        elif "linux" in ctx.os.name.lower():
            lib_file = lib_path.get_child("lib{}.so.{}".format(lib, major))
            specific_lib_file = lib_path.get_child("lib{}.so.{}.{}.{}".format(lib, major, minor, patch))
            if lib_file.exists:
                ctx.symlink(lib_file, lib_file.basename)
            elif specific_lib_file.exists:
                ctx.symlink(specific_lib_file, specific_lib_file.basename)
            else:
                missing_libs.append(lib)
        else:
            fail("MacOS is not supported!")
    if missing_libs:
        fail("Missing following libraries: {}".format(",".join(missing_libs)))

def _impl(ctx):
    # Prefer the tensorrt_root attribute; fall back to the TENSORRT_ROOT environment variable
    tensorrt_root = ctx.attr.tensorrt_root or ctx.os.environ.get("TENSORRT_ROOT", "")
    if not tensorrt_root or not ctx.path(tensorrt_root).exists:
        if "linux" in ctx.os.name.lower():
            headers_path = ctx.path("/usr/include/{}-linux-gnu".format(ctx.os.arch))
            lib_path = ctx.path("/usr/lib/{}-linux-gnu".format(ctx.os.arch))
            bin_path = lib_path
        else:
            _print_or_fail(ctx, "Either the 'tensorrt_root' attribute must be set, or the TENSORRT_ROOT environment variable must be defined.")
            return
    else:
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
    versions = _read_trt_version(ctx, nvinfer_version)
    trt_major, trt_minor, trt_patch = versions
    builder_resources = _find_builder_resources(ctx, bin_path, versions)

    # link headers and libraries
    _mapping_headers(ctx, headers_path)
    _mapping_libs(ctx, lib_path, bin_path, builder_resources + TRT_LIBS, versions)

    # Generate the BUILD file content
    ctx.template(
        "BUILD.bazel",
        ctx.attr._build_file,
        {
            "%{TENSORRT_MAJOR_VERSION}": trt_major,
            "%{TENSORRT_MINOR_VERSION}": trt_minor,
            "%{TENSORRT_PATCH_VERSION}": trt_patch,
            "%{TENSORRT_BUILDER_RESOURCES}": ",\n".join(['"' + r + '"' for r in builder_resources]),
        },
    )
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
