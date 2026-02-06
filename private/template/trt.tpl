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

# bazel BUILD file for tensorrt headers and libs

trt_libs = [
    "nvinfer",
    "nvinfer_dispatch",
    "nvinfer_lean",
    "nvinfer_plugin",
    "nvinfer_vc_plugin",
    "nvonnxparser",
]

trt_builder_resources = [
%{TENSORRT_BUILDER_RESOURCES}
]

trt_major = %{TENSORRT_MAJOR_VERSION}
trt_minor = %{TENSORRT_MINOR_VERSION}
trt_patch = %{TENSORRT_PATCH_VERSION}

[cc_import(
    name = lib + "_win32",
    interface_library = ":{}_{}.lib".format(lib, trt_major),
    shared_library = ":{}_{}.dll".format(lib, trt_major),
    target_compatible_with = ["@platforms//os:windows"],
) for lib in trt_libs]

[cc_import(
    name = lib + "_linux",
    shared_library = ":lib{}.so.{}".format(lib, trt_major),
    target_compatible_with = ["@platforms//os:linux"],
) for lib in trt_libs]

[cc_library(
    name = lib,
    deps = select({
        "@platforms//os:windows": [":{}_win32".format(lib)],
        "//conditions:default": [":{}_linux".format(lib)],
    }),
) for lib in trt_libs]

[cc_import(
    name = lib + "_win32",
    shared_library = ":{}_{}.dll".format(lib, trt_major),
    target_compatible_with = ["@platforms//os:windows"],
) for lib in trt_builder_resources]

[cc_import(
    name = lib + "_linux",
    shared_library = ":lib{}.so.{}.{}.{}".format(lib, trt_major, trt_minor, trt_patch),
    target_compatible_with = ["@platforms//os:linux"],
) for lib in trt_builder_resources]

[cc_library(
    name = lib,
    deps = select({
        "@platforms//os:windows": [":{}_win32".format(lib)],
        "//conditions:default": [":{}_linux".format(lib)],
    }),
) for lib in trt_builder_resources]

cc_library(
    name = "tensorrt",
    hdrs = [
        "include/NvOnnxConfig.h",
        "include/NvOnnxParser.h",
    ] + glob([
        "include/NvInfer*.h",
    ]),
    includes = ["include"],
    visibility = ["//visibility:public"],
    deps = [
        "@rules_cuda//cuda:runtime",
    ] + trt_libs + trt_builder_resources,
)
