#!/bin/bash
set -euo pipefail

############################
# Inject Runtime Values
############################
echo "🔧 Injecting runtime values..."
./scripts/inject-runtime-values.sh
