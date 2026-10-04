#!/bin/sh
# Run the same camera script with MakeUp and Complementary; screenshots land in build/compare/<pack>/
cd "$(dirname "$0")"
for pack in MakeUp.zip ComplementaryUnbound.zip; do
    rm -rf build/run/clientGameTest/screenshots
    gradle runClientGameTest -Ppack=$pack --console=plain > build/run-$pack.log 2>&1 || { echo "$pack failed"; exit 1; }
    out=build/compare/${pack%.zip}
    rm -rf "$out"; mkdir -p "$out"
    cp build/run/clientGameTest/screenshots/*.png "$out"; rm -f "$out"/*_aim.png
done
