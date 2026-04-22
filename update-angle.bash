#!/bin/bash
# 1. Fetches the ANGLE repository
# 2. Gets git revisions of all the required deps
# 3. Updates the build.zig.zon to match the upstream repo

set -euo pipefail
hash git zig mktemp

tmpdir="$(mktemp -d)"
trap 'rm -rf "$tmpdir"' EXIT

declare -a deps=(
  # the zlib google uses is their own fork
  # we use the allyourcodebase one and provide the missing google files in src/zlib-google
  # zlib
  glslang
  astc-encoder
  vulkan-headers
  spirv-headers
  spirv-tools
  # upstream points to a reference that does not exist :shrug:
  # vulkan-memory-allocator
)

declare -A src
src[angle]="https://github.com/google/angle.git"
src[glslang]="https://github.com/KhronosGroup/glslang.git"
src[astc-encoder]="https://github.com/ARM-software/astc-encoder.git"
src[vulkan-headers]="https://github.com/KhronosGroup/Vulkan-Headers.git"
src[spirv-headers]="https://github.com/KhronosGroup/SPIRV-Headers.git"
src[spirv-tools]="https://github.com/KhronosGroup/SPIRV-Tools.git"
src[vulkan-memory-allocator]="https://github.com/GPUOpen-LibrariesAndSDKs/VulkanMemoryAllocator.git"
src[zlib]="https://github.com/allyourcodebase/zlib.git"

pwd="$PWD"
cp "build.zig.zon" "$tmpdir/build.zig.zon"
touch "$tmpdir/build.zig"
cd "$tmpdir"
git clone --depth 1 https://github.com/google/angle.git

# newer ANGLE uses too recent C++ which zig 0.15.2 can't compile :shrug:
sha1=4b22060b65be0da43cfb59c5f80858849f6a11d4
(cd angle && git fetch --depth 1 origin "$sha1")
(cd angle && git checkout "$sha1")

angle_rev="$(cd angle && git rev-parse HEAD)"
angle_date="$(cd angle && git log -1 --format=%cd)"

for dep in "${deps[@]}"; do
  rev="$(cd angle && git rev-parse HEAD:third_party/"$dep"/src)"
  printf -- 'git+%s#%s\n' "${src[$dep]}" "$rev" 1>&2
  zig fetch --save="$dep" --global-cache-dir "$tmpdir" "git+${src[$dep]}#${rev}"
done

# update these to latest
for dep in "vulkan-memory-allocator" "zlib"; do
  printf -- 'git+%s\n' "${src[$dep]}" 1>&2
  zig fetch --save="$dep" --global-cache-dir "$tmpdir" "git+${src[$dep]}"
done

printf -- 'git+%s#%s\n' "${src[angle]}" "$angle_rev" 1>&2
zig fetch --save=angle --global-cache-dir "$tmpdir" "git+${src[angle]}#${angle_rev}"

cp -f build.zig.zon "$pwd/build.zig.zon"
cat <<EOF > "$pwd/meta.zon"
.{
  .angle_rev = "${angle_rev}",
  .angle_date = "${angle_date}",
}
EOF
