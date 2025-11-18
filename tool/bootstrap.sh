#!/usr/bin/env bash
set -e
echo "Bootstrap: Ensure Flutter available"
flutter --version || { echo "Install Flutter first"; exit 1; }
echo "Run: dart format --output=none ."
echo "Run: dart analyze"

