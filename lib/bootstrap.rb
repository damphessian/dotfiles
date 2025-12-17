#!/usr/bin/env ruby
# frozen_string_literal: true

require "set"
require "fileutils"

# Utility commands
# ----------------

def prompt_and_wait(prompt)
  puts prompt
  loop { break if get_yes_no("Continue?") }
end

def setup(group_name, default: true)
  gated_prompt("Set up", group_name, default: default) { yield if block_given? }
end

def setup_writing(project)
  FileUtils.mkdir_p(File.expand_path("~/Writing/#{project}"))
  execho("git clone --recursive -j2 https://github.com/damphessian/#{project}.git ~/Writing/#{project}")
end

def configure(group_name)
  gated_prompt("Configure", group_name) { yield if block_given? }
end

def perform(group_name)
  gated_prompt("Perform", group_name) { yield if block_given? }
end

def gated_prompt(message, group_name, default: true)
  prompt = "#{message} #{humanized group_name}?"
  puts "\n", prompt, "-" * prompt.length

  if get_yes_no(default: default)
    yield if block_given?
  else
    puts "Skipping."
  end
end

def get_yes_no(prompt = "", default: true)
  options = default ? "[Y/n]: " : "[y/N]: "
  loop do
    print [prompt, options].reject(&:empty?).join(" ")

    case gets.to_s.strip
    when /^(yes|y)$/i then return true
    when /^(no|n)$/i then return false
    when "" then return default
    end
  end
rescue Interrupt
  exit 0
end

def execho(command)
  puts(command)
  system(ENVIRONMENT, command)
end

def humanized(str)
  str.to_s.tr("_", " ")
end

def dashified(str)
  str.to_s.gsub(/[_\s]/, "-")
end

def flagified(str)
  "--#{dashified str}"
end

def machine_is?(machine_type)
  arch = `uname -ps`
  case machine_type
  when :mac then arch.match?(/^Darwin/)
  when :apple then arch.match?(/^Darwin arm/)
  when :intel then arch.match?(/^Darwin i386/)
  when :linux then arch.match?(/^Linux/)
  end
end

def homebrew_prefix
  return "/opt/homebrew" if machine_is?(:apple)
  return "/usr/local" if machine_is?(:intel)
  return "/home/linuxbrew/.linuxbrew" if machine_is?(:linux)
  raise ValueError("unrecognized architecture")
end

# Xcode-related
# -------------

def ensure_xcode_is_set_up
  return unless machine_is?(:mac)

  unless xcode_installed?
    puts "Please install Xcode before running this script."
    abort
  end

  xcode_configure
end

def xcode_installed?
  system("test -d /Applications/Xcode.app")
end

def xcode_configured?
  system("xcode-select --print-path | grep -q '^/Applications/Xcode'")
end

def xcode_configure
  return if xcode_configured?

  puts("Enter your password to configure Xcode CLI tools.")
  system("sudo xcode-select --switch /Applications/Xcode.app")
end

# Shell commands
# --------------
def install_system_zshenv
  zshenv = File.expand_path("#{DOTFILES_DIR}/env/xdg.core.sh")
  target = machine_is?(:mac) ? "/etc/zshenv" : "/etc/zsh/zshenv"

  if File.exist?("#{target}.pre_bootstrap")
    return puts("System zshenv already set. Skipping.")
  end

  if File.exist?(target)
    execho("sudo cp #{target} #{target}.pre_bootstrap")
  else
    execho("sudo touch #{target}.pre_bootstrap")
  end

  execho("sudo cp #{zshenv} #{target}")
end

def install_launchagent(filename)
  return unless machine_is?(:mac)
  return if File.exist?(File.expand_path("~/Library/LaunchAgents/#{filename}.plist"))

  FileUtils.mkdir_p(File.expand_path("~/Library/LaunchAgents/"))
  execho("ln -sfv ${DOTFILES_DIR}/launch_agents/#{filename}.plist ~/Library/LaunchAgents/#{filename}.plist")
  execho("launchctl unload ~/Library/LaunchAgents/#{filename}.plist 2>/dev/null")
  execho("launchctl load ~/Library/LaunchAgents/#{filename}.plist")
end

def reset_quicklookd
  execho("qlmanage -r") if machine_is?(:mac)
end

def script_install(name)
  full_path = "#{DOTFILES_DIR}/lib/install-#{name}"

  if command_exists?(full_path)
    execho(full_path)
  else
    puts "Error: install script for #{name} does not exist or is not executable."
  end
end

def command_exists?(command)
  system("command -v #{command} >/dev/null 2>&1")
end

def ensure_dropbox_synced
  return if File.exist?(File.expand_path "~/Dropbox")

  execho("mkdir ~/Dropbox")
  prompt_and_wait "Issue `maestral gui` (macOS) or `maestral start` (Linux) and wait for sync to complete."
end

def ensure_gpg_permissions_are_set_correctly
  if File.exist?(ENVIRONMENT.fetch("GNUPGHOME"))
    system(ENVIRONMENT, "chmod 600 ${GNUPGHOME}/*")
    system(ENVIRONMENT, "chmod 700 ${GNUPGHOME}/")
  else
    puts "Error: GNUPGHOME not found. Ensure Dropbox is installed and synced."
    exit 1
  end
end

def ensure_locals_are_created
  execho("mkdir -p ${XDG_LOCALS_DIR}/bin")
  execho("mkdir -p ${XDG_LOCALS_DIR}/config/emacs")
  execho("touch ${XDG_LOCALS_DIR}/config/emacs/config.el")

  unless File.exist?(ENVIRONMENT.fetch("ORG_HOME"))
    execho("ln -s ${HOME}/Dropbox/org ${ORG_HOME}")
  end

  unless File.exist?("/usr/local/bin/")
    execho("sudo mkdir -p /usr/local/bin")
  end

  unless File.exist?("/usr/local/bin/pinentry-jmr")
    execho("sudo ln -sf ${DOTFILES_DIR}/bin/pinentry-jmr /usr/local/bin/")
  end

  unless File.exist?(ENVIRONMENT.fetch("XDG_SECURE_DIR"))
    target =
      if machine_is?(:mac)
        "~/Library/Mobile\\ Documents/com~apple~CloudDocs"
      else
        "~/Dropbox"
      end
    execho("ln -s #{target}/dotfiles ${XDG_SECURE_DIR}")
  end

  return unless machine_is?(:mac)

  system("mkdir -p ${HOME}/.local/")

  unless File.exist?(File.expand_path "~/.local/share")
    execho("ln -s ${XDG_DATA_HOME} ${HOME}/.local/share")
  end
  unless File.exist?(File.expand_path "~/.cups")
    execho("ln -s ${XDG_DATA_HOME}/cups ${HOME}/.cups")
  end
  unless File.exist?(File.expand_path "~/Dropbox")
    execho("ln -s ${HOME}/Library/CloudStorage/Dropbox/ ${HOME}/Dropbox")
  end
  unless File.exist?(File.expand_path "~/.config")
    execho("ln -s ${XDG_CONFIG_HOME} ${HOME}/.config")
  end
end

def setup_emacs_plus(version: 30)
  setup :emacs_plus do
    execho "brew unlink emacs"
    brew_tap "d12frosted/emacs-plus"
    yield
    execho <<~SH
      \rm -rf '/Applications/Emacs.app' '/Applications/Emacs Client.app'
      osascript -e 'tell application "Finder" to make alias file to posix file "#{HOMEBREW_PREFIX}/opt/emacs-plus@#{version}/Emacs.app" at posix file "/Applications" with properties {name:"Emacs.app"}'
      osascript -e 'tell application "Finder" to make alias file to posix file "#{HOMEBREW_PREFIX}/opt/emacs-plus@#{version}/Emacs Client.app" at posix file "/Applications" with properties {name:"Emacs Client.app"}'
    SH
  end
end

def disable_press_and_hold
  execho("defaults write NSGlobalDomain ApplePressAndHoldEnabled -bool false")
end

def clear_dock
  execho("defaults write com.apple.dock persistent-apps -array")
  execho("defaults write com.apple.dock persistent-others -array")
  execho("killall Dock")
end

# Homebrew-related commands
# -------------------------

def install_homebrew
  if command_exists?(:brew)
    puts "Homebrew already installed. Skipping."
  else
    execho(`curl -sL brew.sh | grep install.sh | sed -E 's/<[^>]*>//g'`.strip)
  end
end

def brew_tap(tap_name)
  if brew_installed?(tap_name)
    puts("#{tap_name} already tapped. Skipping")
  else
    execho("brew tap #{tap_name}")
  end
end

def brew_install(package, version: nil, options: [])
  package_name = version ? "#{package}@#{version}" : package
  package_name = dashified(package_name) if package.is_a?(Symbol)

  flags = Array(options).map { |option| flagified option }.join(" ")
  is_cask = Array(options).include?(:cask)

  if brew_installed?(package_name, type: is_cask ? :cask : :formula)
    puts "#{package_name} already installed. Skipping."
  else
    execho("brew install #{package_name} #{flags}")
  end
end

def cask_install(package_name, version: nil, options: [])
  return unless machine_is?(:mac)
  brew_install(package_name, version: version, options: [:cask, *options])
end

def brew_cleanup
  execho("brew cleanup")
end

def brew_doctor
  execho("brew doctor")
end

def brew_installed?(name, type: :formula)
  case type
  when :tap
    BREW_INSTALLED_TAPS.include?(name.to_s)
  when :formula
    BREW_INSTALLED_FORMULAS.include?(name.to_s)
  when :cask
    BREW_INSTALLED_CASKS.include?(name.to_s)
  end
end

# Help
# ----------
if ARGV.delete("--help").to_s.eql?("--help")
  puts "Run with --debug to dry-run."
  exit 2
end

# Debug mode
# ----------
DARK_GRAY = "\e[90m"
RESET     = "\e[0m"
DEBUG_ENV = ENV["DEBUG_ENV"]

if (IN_DEBUG_MODE = ARGV.delete("--debug").to_s.eql?("--debug"))
  puts "-*- Running in debug mode -*-"

  def env_debug(env_hash)
    [DARK_GRAY, env_hash.map { |k, v| "#{k}=#{v}" }.join("\n"), RESET].join
  end

  def execho(*args)
    system(ENVIRONMENT, *args)
  end

  def system(*args)
    if args.first.is_a?(Hash) and DEBUG_ENV
      puts(env_debug(args.first), *args[1..])
    elsif args.first.is_a?(Hash)
      puts(*args[1..])
    else
      puts(*args)
    end
    true
  end
end

# Constants
# ---------

DOTFILES_DIR = File.dirname(File.dirname(__FILE__))
HOMEBREW_PREFIX = homebrew_prefix
ENV["DOTFILES_DIR"] = DOTFILES_DIR

ENVIRONMENT =
  `zsh -c "env | grep -E '^(XDG_|MISE_|PATH|GNUPG|ORG_)'"`
  .strip
  .split("\n")
  .map { |line| line.split("=") }
  .push(["HOMEBREW_NO_INSTALL_CLEANUP", true.to_s])
  .push(["HOMEBREW_PREFIX", HOMEBREW_PREFIX])
  .push(["DOTFILES_DIR", DOTFILES_DIR])
  .sort_by(&:first)
  .to_h
  .freeze
  .tap { |env| puts "-" * 60, env_debug(env), "-" * 60 if IN_DEBUG_MODE }

BREW_INSTALLED_FORMULAS =
  `brew list -1 --formula 2>/dev/null`.strip.split("\n").to_set.freeze

BREW_INSTALLED_CASKS =
  `brew list -1 --cask 2>/dev/null`.strip.split("\n").to_set.freeze

BREW_INSTALLED_TAPS =
  `brew tap 2>/dev/null`.strip.split("\n").to_set.freeze
