#!/usr/bin/env bash
# validate-quick — single entry point for the harness validation ladder.
# Runs per-package `swift test` + SwiftLint. iOS xcodebuild is intentionally
# NOT run here (slow, simulator-bound); CI / verification phases run it
# separately. Exits non-zero on the first failure.
#
# Usage:  ios/scripts/validate-quick.sh
# Env:    set SEE_TAROT_TEST_EMAIL / SEE_TAROT_TEST_PASSWORD /
#         SEE_TAROT_BASE_URL to also exercise the env-gated live smokes
#         (otherwise they XCTSkip cleanly — never fakes green).
set -euo pipefail

IOS_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
PACKAGES=(SeeTarotCore SeeTarotNetworking SeeTarotPersistence \
          SeeTarotDesignSystem SeeTarotCardEngine SeeTarotFeatures)

fail() { echo "❌ validate-quick FAILED: $1" >&2; exit 1; }

echo "▶ swift test (6 packages)"
for pkg in "${PACKAGES[@]}"; do
  echo "  • $pkg"
  ( cd "$IOS_DIR/Packages/$pkg" && swift test ) \
    || fail "swift test $pkg"
done

echo "▶ swiftlint"
if command -v swiftlint >/dev/null 2>&1; then
  ( cd "$IOS_DIR" && swiftlint lint --quiet --strict ) \
    || fail "swiftlint (errors/warnings present)"
else
  echo "  ⚠ swiftlint not installed — skipped"
fi

echo "✅ validate-quick PASSED"
