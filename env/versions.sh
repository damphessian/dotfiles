# version manager configuration
# https://mise.jdx.dev

[[ -z "${XDG_CONFIG_HOME}" ]] && echo "WARNING: XDG_CONFIG_HOME is not set in ${0}"
[[ -z "${XDG_DATA_HOME}" ]]   && echo "WARNING: XDG_DATA_HOME is not set in ${0}"
[[ -z "${MACHINE_CORES}" ]]   && echo "WARNING: MACHINE_CORES is not set in ${0}"

export MISE_DIR="${XDG_DATA_HOME}/mise"
if [[ "${MACHINE_CORES}" =~ ^[0-9]+$ ]] && [[ "${MACHINE_CORES}" -gt 0 ]]; then
  export MISE_JOBS="${MACHINE_CORES}"
else
  export MISE_JOBS=1
fi

export MISE_GO_DEFAULT_PACKAGES_FILE="${XDG_CONFIG_HOME}/mise/default-libraries-golang"
export MISE_NODE_DEFAULT_PACKAGES_FILE="${XDG_CONFIG_HOME}/mise/default-libraries-nodejs"
export MISE_PERL_DEFAULT_PACKAGES_FILE="${XDG_CONFIG_HOME}/mise/default-libraries-perl"
export MISE_PYTHON_DEFAULT_PACKAGES_FILE="${XDG_CONFIG_HOME}/mise/default-libraries-python"
export MISE_RUBY_DEFAULT_PACKAGES_FILE="${XDG_CONFIG_HOME}/mise/default-libraries-ruby"

# extra config options for installs
export POSTGRES_EXTRA_CONFIGURE_OPTIONS="--with-uuid=e2fs --with-libxml"
export REDIS_EXTRA_CONFIGURE_OPTIONS="BUILD_TLS=yes"
