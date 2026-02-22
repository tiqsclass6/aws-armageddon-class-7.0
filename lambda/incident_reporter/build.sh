#!/usr/bin/env bash
set -euo pipefail

rm -rf build incident_reporter.zip
mkdir -p build

cp handler.py build/
cp claude.py build/

# Optional deps
# pip install -r requirements.txt -t build/

cd build
zip -r ../incident_reporter.zip .
cd ..