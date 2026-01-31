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

load("//private:repository.bzl", "config_tensorrt")

tensorrt_toolkit_tag = tag_class(attrs = {
    "name": attr.string(default = "tensorrt", doc = "Name for the toolchain repository"),
    "required": attr.bool(default = False, doc = "fail(warning) when no tensorrt found if (not) required"),
})

def _find_modules(module_ctx):
    root = None
    our_module = None
    for mod in module_ctx.modules:
        if mod.is_root:
            root = mod
        if mod.name == "rules_tensorrt":
            our_module = mod
    if root == None:
        root = our_module
    if root == None:
        fail("Unable to find rules_tensorrt module")

    return root, our_module

def _impl(module_ctx):
    root, rules_tensorrt = _find_modules(module_ctx)
    if root.tags.toolkit:
        toolkits = root.tags.toolkit
    else:
        toolkits = rules_tensorrt.tags.toolkit
    for toolkit in toolkits:
        name = toolkit.name
        required = toolkit.required
    config_tensorrt(name = name, required = required)

tensorrt_extention = module_extension(
    implementation = _impl,
    tag_classes = {
        "toolkit": tensorrt_toolkit_tag,
    },
)
