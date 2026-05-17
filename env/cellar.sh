#!/usr/bin/env bash

if [[ "${MACHINE}" != "linux" ]]; then
  export CELLAR_HOME="/Volumes/Cellar"

  export COLIMA_HOME="${CELLAR_HOME}/Colima"
  export HF_HOME="${CELLAR_HOME}/Huggingface"
  export OLLAMA_MODELS="${CELLAR_HOME}/Ollama"

fi

export LMSTUDIO_HOME="$(\cat ${HOME}/.lmstudio-home-pointer 2>/dev/null)"
