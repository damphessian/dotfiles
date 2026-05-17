#!/usr/bin/env bash

[[ -z "${MACHINE_CORES}" ]] && echo "WARNING: MACHINE_CORES is not set in ${0}"

if [[ "${MACHINE_CORES}" =~ ^[0-9]+$ ]] && [[ "${MACHINE_CORES}" -gt 0 ]]; then
  export BUNDLE_JOBS="${MACHINE_CORES}"
else
  export BUNDLE_JOBS=1
fi
export BUNDLE_CONSOLE="pry"
export BUNDLE_GEM__COC="false"
export BUNDLE_GEM__MIT="true"
export BUNDLE_GEM__TEST="rspec"
