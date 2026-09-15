#!/usr/bin/env bash
#
# Builds the AWARE Apple Watch framework into XCFrameworks so that the
# compiled binaries - and not the source - can be shipped with this plugin.
#
# The AWARE sources are compiled once per module and platform, packed into
# static libraries, and assembled into one XCFramework per module:
#
#   com_awareframework_ios_sensor_applewatch_shared   iOS + watchOS (+ simulators)
#   com_awareframework_ios_sensor_applewatch_iOS      iOS (+ simulator)
#   com_awareframework_ios_sensor_applewatch_watchOS  watchOS (+ simulator)
#
# The module names are kept byte-for-byte identical to the ones SwiftPM derives
# from the AWARE target names, so existing `import com_awareframework_...`
# statements keep working against the binaries.
#
# The libraries are static, which means the third-party packages AWARE depends
# on (aware core, GRDB, DataCompression) are *not* baked into them. Consumers
# resolve those from source, so there is exactly one copy of GRDB in the app -
# which matters, because the AWARE public API exposes GRDB.DatabaseQueue.
#
# That is also why library evolution is enabled per target rather than through
# BUILD_LIBRARY_FOR_DISTRIBUTION on the command line: the latter would apply to
# the dependencies as well, and the AWARE binaries would then call into them
# through resilient dispatch thunks that a consumer's own source build of those
# same packages never emits, failing the link with undefined symbols. Only the
# three AWARE targets are built resiliently; everything they link against is
# compiled exactly the way the consuming app compiles it.
#
# Usage:
#   tool/build_xcframeworks.sh [--output DIR] [--source DIR] [--keep-build]
#
set -euo pipefail

PKG_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
SOURCE_DIR="$PKG_ROOT/com.awareframework.ios.sensor.applewatch"
OUTPUT_DIR="$PKG_ROOT/ios/carp_aware_package/Frameworks"
BUILD_DIR="$PKG_ROOT/.build/xcframeworks"
KEEP_BUILD=0

while [[ $# -gt 0 ]]; do
  case "$1" in
    --output) OUTPUT_DIR="$2"; shift 2 ;;
    --source) SOURCE_DIR="$2"; shift 2 ;;
    --keep-build) KEEP_BUILD=1; shift ;;
    -h|--help) sed -n '2,30p' "${BASH_SOURCE[0]}"; exit 0 ;;
    *) echo "unknown option: $1" >&2; exit 2 ;;
  esac
done

if [[ ! -f "$SOURCE_DIR/Package.swift" ]]; then
  echo "error: AWARE sources not found at $SOURCE_DIR" >&2
  echo "       run 'git submodule update --init' first, or pass --source DIR" >&2
  exit 1
fi

STAGE="$BUILD_DIR/AwareAppleWatch"
ARCHIVES="$BUILD_DIR/archives"
LIBS="$BUILD_DIR/libs"

rm -rf "$BUILD_DIR"
mkdir -p "$STAGE" "$ARCHIVES" "$LIBS"

echo "==> staging AWARE sources from $SOURCE_DIR"
cp -R "$SOURCE_DIR/Sources" "$STAGE/Sources"
# Reuse the upstream resolution so the binaries are built against exactly the
# dependency versions the AWARE package itself pins.
[[ -f "$SOURCE_DIR/Package.resolved" ]] && cp "$SOURCE_DIR/Package.resolved" "$STAGE/Package.resolved"

# A build-only manifest. The upstream manifest exposes all three targets through
# a single product, which cannot be archived per platform - the watchOS sources
# do not compile for iOS and vice versa. One product per target fixes that.
cat > "$STAGE/Package.swift" <<'EOF'
// swift-tools-version: 6.0
import PackageDescription

// Applied to the AWARE targets only - never to their dependencies. See the
// note at the top of this script.
let evolution: [SwiftSetting] = [.unsafeFlags(["-enable-library-evolution"])]

let package = Package(
    name: "AwareAppleWatch",
    platforms: [.iOS(.v16), .watchOS(.v8)],
    products: [
        .library(name: "AwareAppleWatchShared", targets: ["com.awareframework.ios.sensor.applewatch.shared"]),
        .library(name: "AwareAppleWatchIOS", targets: ["com.awareframework.ios.sensor.applewatch.iOS"]),
        .library(name: "AwareAppleWatchWatchOS", targets: ["com.awareframework.ios.sensor.applewatch.watchOS"]),
    ],
    dependencies: [
        .package(url: "https://github.com/awareframework/com.awareframework.ios.core.git", from: "1.3.0"),
        .package(url: "https://github.com/mw99/DataCompression.git", from: "3.8.0"),
        .package(url: "https://github.com/groue/GRDB.swift.git", from: "7.3.0"),
    ],
    targets: [
        .target(
            name: "com.awareframework.ios.sensor.applewatch.shared",
            dependencies: [
                .product(name: "com.awareframework.ios.core", package: "com.awareframework.ios.core"),
                .product(name: "DataCompression", package: "DataCompression"),
                .product(name: "GRDB", package: "GRDB.swift"),
            ],
            path: "Sources/com.awareframework.ios.sensor.applewatch/shared",
            swiftSettings: evolution
        ),
        .target(
            name: "com.awareframework.ios.sensor.applewatch.iOS",
            dependencies: [
                .product(name: "com.awareframework.ios.core", package: "com.awareframework.ios.core"),
                "com.awareframework.ios.sensor.applewatch.shared",
                .product(name: "DataCompression", package: "DataCompression"),
            ],
            path: "Sources/com.awareframework.ios.sensor.applewatch/ios",
            swiftSettings: evolution
        ),
        .target(
            name: "com.awareframework.ios.sensor.applewatch.watchOS",
            dependencies: [
                .product(name: "com.awareframework.ios.core", package: "com.awareframework.ios.core"),
                "com.awareframework.ios.sensor.applewatch.shared",
                .product(name: "DataCompression", package: "DataCompression"),
            ],
            path: "Sources/com.awareframework.ios.sensor.applewatch/watchos",
            swiftSettings: evolution
        ),
    ],
    swiftLanguageModes: [.v5]
)
EOF

# module | scheme | SwiftPM target | destinations (| separated)
MODULES=(
  "com_awareframework_ios_sensor_applewatch_shared|AwareAppleWatchShared|com.awareframework.ios.sensor.applewatch.shared|iOS|iOS Simulator|watchOS|watchOS Simulator"
  "com_awareframework_ios_sensor_applewatch_iOS|AwareAppleWatchIOS|com.awareframework.ios.sensor.applewatch.iOS|iOS|iOS Simulator"
  "com_awareframework_ios_sensor_applewatch_watchOS|AwareAppleWatchWatchOS|com.awareframework.ios.sensor.applewatch.watchOS|watchOS|watchOS Simulator"
)

# Turns "iOS Simulator" into the slug used for build directories.
slug() { echo "$1" | tr '[:upper:] ' '[:lower:]-'; }

for entry in "${MODULES[@]}"; do
  IFS='|' read -r -a fields <<< "$entry"
  module="${fields[0]}"
  scheme="${fields[1]}"
  target="${fields[2]}"
  destinations=("${fields[@]:3}")

  echo
  echo "==> building $module"
  lib_args=()
  for destination in "${destinations[@]}"; do
    dest_slug="$(slug "$destination")"
    archive="$ARCHIVES/$module-$dest_slug.xcarchive"
    derived="$BUILD_DIR/dd/$module-$dest_slug"

    echo "    archiving for $destination"
    ( cd "$STAGE" && xcodebuild archive \
        -scheme "$scheme" \
        -destination "generic/platform=$destination" \
        -archivePath "$archive" \
        -derivedDataPath "$derived" \
        SKIP_INSTALL=NO \
        SWIFT_EMIT_MODULE_INTERFACE=YES \
        ONLY_ACTIVE_ARCH=NO ) > "$BUILD_DIR/$module-$dest_slug.log" 2>&1 || {
      echo "    ERROR: archive failed - see $BUILD_DIR/$module-$dest_slug.log" >&2
      tail -30 "$BUILD_DIR/$module-$dest_slug.log" >&2
      exit 1
    }

    # SwiftPM installs library targets as a single merged object file rather
    # than a library, so pack it into a static archive for -create-xcframework.
    object="$(find "$archive/Products" -name "$target.o" -print -quit)"
    [[ -n "$object" ]] || { echo "    ERROR: no object file in $archive" >&2; exit 1; }

    lib_dir="$LIBS/$module/$dest_slug"
    mkdir -p "$lib_dir"
    libtool -static -o "$lib_dir/lib$module.a" "$object"

    # Stash the .swiftmodule next to it; it is folded into the XCFramework below.
    swiftmodule="$(find "$derived/Build/Intermediates.noindex/ArchiveIntermediates/$scheme/BuildProductsPath" \
      -maxdepth 2 -name "$module.swiftmodule" -print -quit)"
    [[ -n "$swiftmodule" ]] || { echo "    ERROR: no .swiftmodule for $destination" >&2; exit 1; }
    cp -R "$swiftmodule" "$lib_dir/"

    lib_args+=(-library "$lib_dir/lib$module.a")
  done

  mkdir -p "$OUTPUT_DIR"
  rm -rf "$OUTPUT_DIR/$module.xcframework"
  xcodebuild -create-xcframework "${lib_args[@]}" -output "$OUTPUT_DIR/$module.xcframework" > /dev/null

  # The .swiftmodule copied next to each static library above is folded into
  # the matching slice by -create-xcframework. That module - and specifically
  # its .swiftinterface, which only exists because of
  # SWIFT_EMIT_MODULE_INTERFACE - is what makes `import <module>` resolve
  # against the binary, so fail loudly rather than ship a slice without one.
  python3 - "$OUTPUT_DIR/$module.xcframework" "$module" <<'PY'
import plistlib, sys
from pathlib import Path

xcframework, module = Path(sys.argv[1]), sys.argv[2]

# Compiling emits these next to the module, but nothing that links against the
# binary reads them: .abi.json is a diagnostic dump for Swift's ABI checker
# (and by far the largest thing in the XCFramework), and
# .package.swiftinterface only serves `package` access from within the package
# that built it.
DROP = ("*.abi.json", "*.package.swiftinterface")

info = plistlib.loads((xcframework / "Info.plist").read_bytes())
for library in info["AvailableLibraries"]:
    identifier = library["LibraryIdentifier"]
    swiftmodule = xcframework / identifier / f"{module}.swiftmodule"
    if not swiftmodule.is_dir():
        raise SystemExit(f"    ERROR: {identifier} carries no Swift module")

    for pattern in DROP:
        for junk in swiftmodule.glob(pattern):
            junk.unlink()

    # The .swiftinterface is what lets a newer Swift compiler than the one used
    # here read the module, so a slice without one is not shippable.
    interfaces = sorted(
        p for p in swiftmodule.glob("*.swiftinterface")
        if not p.name.endswith((".private.swiftinterface", ".package.swiftinterface"))
    )
    if not interfaces:
        raise SystemExit(f"    ERROR: {identifier} carries no Swift module interface")
    print(f"    + {identifier}: {', '.join(p.stem for p in interfaces)}")
PY
done

# The open-source packages the binaries were compiled against. They are linked
# by the consumer, not by us, so the versions matter.
python3 - "$STAGE/Package.resolved" > "$BUILD_DIR/dependencies.txt" <<'PY'
import json, sys
from pathlib import Path

resolved = Path(sys.argv[1])
if not resolved.is_file():
    raise SystemExit(0)
for pin in json.loads(resolved.read_text())["pins"]:
    state = pin["state"]
    print("  %-34s %s" % (pin["identity"], state.get("version") or state["revision"]))
PY

# Record what the binaries were built from - without the sources there is no
# other way to tell which AWARE revision a given XCFramework came from.
aware_revision="$(git -C "$SOURCE_DIR" rev-parse HEAD 2>/dev/null || echo unknown)"
aware_describe="$(git -C "$SOURCE_DIR" describe --tags --always 2>/dev/null || echo unknown)"
cat > "$OUTPUT_DIR/BUILD-INFO.txt" <<EOF
AWARE Apple Watch XCFrameworks

Built from : https://github.com/awareframework/com.awareframework.ios.sensor.applewatch
Revision   : $aware_revision
Version    : $aware_describe
Xcode      : $(xcodebuild -version | head -1)
Swift      : $(swift --version 2>&1 | head -1)

Compiled against:
$(cat "$BUILD_DIR/dependencies.txt")

Those packages are not baked into the binaries - a consumer has to resolve the
same major versions, and build with this Xcode release or newer.

Rebuild with: tool/build_xcframeworks.sh
EOF

[[ $KEEP_BUILD -eq 1 ]] || rm -rf "$BUILD_DIR"

echo
echo "==> wrote to $OUTPUT_DIR"
du -sh "$OUTPUT_DIR"/*.xcframework
