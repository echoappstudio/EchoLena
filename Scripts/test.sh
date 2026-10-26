#!/bin/bash
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
mkdir -p "$ROOT/.build"

xcrun swiftc \
  -warnings-as-errors \
  "$ROOT/Sources/EchoLenaCore.swift" \
  "$ROOT/Sources/Signature.swift" \
  "$ROOT/Tests/EchoLenaCoreTests.swift" \
  "$ROOT/Tests/SignatureTests.swift" \
  -o "$ROOT/.build/EchoLenaCoreTests"

"$ROOT/.build/EchoLenaCoreTests"
