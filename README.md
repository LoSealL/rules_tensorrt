# TensorRT rules for [Bazel](https://bazel.build)

This repository contains [Starlark](https://github.com/bazelbuild/starlark) implementation of [TensorRT](https://developer.nvidia.com/tensorrt) rules in Bazel.

These rules provide some macros and rules that make it easier to build TensorRT applications with Bazel.

## Getting Started

### Traditional WORKSPACE approach

Add the following to your `WORKSPACE` file and replace the placeholders with actual values.

```starlark
load("@bazel_tools//tools/build_defs/repo:http.bzl", "http_archive")
http_archive(
    name = "rules_tensorrt",
    sha256 = "{sha256_to_replace}",
    strip_prefix = "rules_tensorrt-{git_commit_hash}",
    urls = ["https://github.com/loseall/rules_tensorrt/archive/{git_commit_hash}.tar.gz"],
)
load("@rules_tensorrt//:repo.bzl", "config_tensorrt")
config_tensorrt(
    name = "tensorrt",
    tensorrt_root = "/mnt/tensorrt/"
)

load("@bazel_tools//tools/build_defs/repo:http.bzl", "http_archive")

# Jan 4th 2026
rules_cuda_revision = "bfea6eea03ea6acd174ab21ba6309d08d358d0d7"

http_archive(
    name = "rules_cuda",
    integrity = "sha256-Zdphe+6WvAvQgllPus6j5S+cG1qGHtEbp+3ZzirleHw=",
    strip_prefix = "rules_cuda-%s" % rules_cuda_revision,
    urls = ["https://github.com/bazel-contrib/rules_cuda/archive/%s.tar.gz" % rules_cuda_revision],
)

load("@rules_cuda//cuda:repositories.bzl", "rules_cuda_dependencies", "rules_cuda_toolchains")

rules_cuda_dependencies()

rules_cuda_toolchains(register_toolchains = True)
```

**NOTE**: system environment `TENSORRT_ROOT` or argument `tensorrt_root` is used to locate the installation path of a specific TensorRT distribution.

### Bzlmod

Add the following to your `MODULE.bazel` file and replace the placeholders with actual values.

```starlark
bazel_dep(name = "rules_tensorrt", version = "0.0.0")

# pick a specific version (this is optional an can be skipped)
archive_override(
    module_name = "rules_tensorrt",
    integrity = "{SRI value}",  # see https://developer.mozilla.org/en-US/docs/Web/Security/Subresource_Integrity
    url = "https://github.com/loseall/rules_tensorrt/archive/{git_commit_hash}.tar.gz",
    strip_prefix = "rules_tensorrt-{git_commit_hash}",
)

trt_ext = use_extension("@rules_tensorrt//:extensions.bzl", "tensorrt_extention")
use_repo(trt_ext, "tensorrt")
```

## Examples

Checkout the examples to see if it fits your needs.

See [tests](./tests) for basic usage.

## Known issue
