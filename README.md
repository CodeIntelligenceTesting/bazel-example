# cifuzz bazel example

This is a simple bazel based project, already configured with
**cifuzz**. It should quickly produce a finding, but slow enough to
see the progress of the fuzzer.

To start make sure you installed **cifuzz** according to the
main [README](../../README.md).

You can start the fuzzing with

```bash
cifuzz run //src:explore_me_fuzz_test
```

## Create regression test

After you have discovered a finding, you may want to include this as
part of a regression test. To replay findings from the
`src/explore_me_fuzz_test_inputs` directory:

```bash
bazel test --config=cifuzz-replay //src:explore_me_fuzz_test --test_output=streamed
```

Note that this requires these lines in your `.bazelrc`:

```bash
# Replay cifuzz findings (C/C++ only)
build:cifuzz-replay --@rules_fuzzing//fuzzing:cc_engine_sanitizer=asan-ubsan
build:cifuzz-replay --compilation_mode=opt
build:cifuzz-replay --copt=-g
build:cifuzz-replay --copt=-U_FORTIFY_SOURCE
build:cifuzz-replay --test_env=UBSAN_OPTIONS=halt_on_error=1
```

## C++ Toolchain

This project uses
[toolchains_llvm](https://github.com/bazel-contrib/toolchains_llvm) to configure
the cc toolchain used by bazel to compile fuzz tests. To ensure hermetic
builds a [chromium sysroot](https://chromium.googlesource.com/chromium/src/+/HEAD/docs/linux/sysroot.md)
is used.

The toolchain can be tested using the provided `Dockerfile` which installs
minimal dependencies to run this example project. Note, that no compiler and no
C++ library headers are installed since they are provided with the cc toolchain.

Start by building the docker image

```
export CIFUZZ_DOWNLOAD_TOKEN=<download token from https://downloads.code-intelligence.com>
docker build --tag bazel-example --build-arg CIFUZZ_DOWNLOAD_TOKEN .
```

Warning: Don't push this docker image to a public repository since it could leak
         your personal download token. This image is intended for local
         experimentation.
Warning: This docker image can become quite large because it populates the bazel
         cache with all dependencies and the hermetic toolchain.

Run the docker image

```
docker run --rm -it bazel-example
```

Inside the docker image you need to set `CC` and `CXX` to the toolchain clang
compiler. This can be done with the `set_env.sh` script:

```
$ source set_env.sh
$ $CC --version
clang version 15.0.6
Target: x86_64-unknown-linux-gnu
Thread model: posix
InstalledDir: /root/.cache/bazel/_bazel_root/1e0bb3bee2d09d2e4ad3523530d3b40c/execroot/_main/external/toolchains_llvm~~llvm~llvm_toolchain_llvm/bin
```

Now you can run cifuzz commands on the example project. For `cifuzz run` and
`cifuzz coverage` you should get output similar to this:

```
$ cifuzz run
🚀 Running //src:explore_me_fuzz_test_bin...
 ✅  Building... Done.
Log can be found here:
    /work/.cifuzz-build/logs/build-src_explore_me_fuzz_test.log
 ✅  Initializing... Done.
Fuzz testing will be performed for 10m. Use '--max-fuzzing-duration' to change the duration.
 ✅  Testing code...
34 Unique Test Cases and 2 Findings detected in 0s.

CRITICAL
  💥 NEW [quirky_okapi] heap_buffer_overflow in exploreMe (src/explore_me.cpp:18:11)
LOW
  💥 NEW [stoic_jay] undefined behavior in exploreMe (src/explore_me.cpp:13:11)
```

```
$ cifuzz coverage --format lcov
 ✅  Building //src:explore_me_fuzz_test_bin... Done.
 ✅  Generating lcov report for //src:explore_me_fuzz_test_bin... Done.
 ✅  Creating coverage report... Done.

                        File | Functions Hit/Found |  Lines Hit/Found | Branches Hit/Found
          src/explore_me.cpp |      1 / 1 (100.0%) | 15 / 15 (100.0%) |     8 / 8 (100.0%)
src/explore_me_fuzz_test.cpp |      2 / 2 (100.0%) |   8 / 8 (100.0%) |     0 / 0 (100.0%)
                             |                     |                  |
                             | Functions Hit/Found |  Lines Hit/Found | Branches Hit/Found
                       Total |      3 / 3 (100.0%) | 23 / 23 (100.0%) |     8 / 8 (100.0%)

LCOV report can be found here:
    --src:explore_me_fuzz_test_bin.lcov.info
```
