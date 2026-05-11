;;; early-init.el --- -*- lexical-binding: t; -*-

;; Maximize GC threshold during startup to reduce collections while loading
;; packages. Reset to a reasonable value in emacs-startup-hook (see init.el).
(setq gc-cons-threshold most-positive-fixnum
      gc-cons-percentage 0.6)

;; Suppress UI chrome before the first frame is created. Doing this here
;; (rather than in init.el) avoids a brief flash of the full toolbar UI.
(setq default-frame-alist
      '((tool-bar-lines . 0)
        (menu-bar-lines . 0)
        (fullscreen . maximized)
        (vertical-scroll-bars . nil)
        (horizontal-scroll-bars . nil)
        (ns-transparent-titlebar . t)
        (ns-appearance . dark)
        (background-color . "#282c34")
        (foreground-color . "#bbc2cf")))

;; Seed the initial frame with Doom One colors before the full theme loads.
(set-face-attribute 'default nil
                    :background "#282c34"
                    :foreground "#bbc2cf")

;; Seed the startup mode-line too, so it doesn't flash the default palette
;; before the full theme and modeline packages load.
(set-face-attribute 'mode-line nil
                    :background "#1e2026"
                    :foreground "#bbc2cf"
                    :box nil)
(set-face-attribute 'mode-line-inactive nil
                    :background "#1e2026"
                    :foreground "#5B6268"
                    :box nil)
(when (facep 'mode-line-active)
  (set-face-attribute 'mode-line-active nil
                      :background "#1e2026"
                      :foreground "#bbc2cf"
                      :box nil))

;; Skip the "Welcome to GNU Emacs" splash screen.
(setq inhibit-startup-screen t)

;; Suppress the "For information about GNU Emacs..." minibuffer message.
;; inhibit-startup-echo-area-message is unreliable; redefining the function
;; that displays it is the dependable approach.
(defun display-startup-echo-area-message () nil)

;; Prevent package.el from activating packages — straight.el owns that.
(setq package-enable-at-startup nil)

(defconst dm-cache-home              "~/.dotfiles/cache/emacs")
(defconst dm-config-home             "~/.dotfiles/config/emacs")
(defconst dm-data-home               "~/.dotfiles/share/emacs")
(defconst dm-state-home              "~/.dotfiles/state/emacs")

(defconst dm-dir-eln-cache           "~/.dotfiles/cache/emacs/eln-cache/")
(defconst dm-dir-url-cache           "~/.dotfiles/cache/emacs/url/")

(defconst dm-dir-elpa                "~/.dotfiles/share/emacs/elpa/")
(defconst dm-dir-eshell              "~/.dotfiles/share/emacs/eshell/")
(defconst dm-dir-tree-sitter-libs    "~/.dotfiles/share/emacs/tree-sitter/lib/")
(defconst dm-dir-tree-sitter-repos   "~/.dotfiles/share/emacs/tree-sitter/repos/")

(defconst dm-dir-auto-save           "~/.dotfiles/state/emacs/auto-save/")
(defconst dm-dir-backups             "~/.dotfiles/state/emacs/backups/")
(defconst dm-dir-desktop             "~/.dotfiles/state/emacs/desktop/")
(defconst dm-file-abbrev-defs        "~/.dotfiles/state/emacs/abbrev_defs")
(defconst dm-file-auto-save-prefix   "~/.dotfiles/state/emacs/auto-save/saves-")
(defconst dm-file-bookmarks          "~/.dotfiles/state/emacs/bookmarks")
(defconst dm-file-customizations     "~/.dotfiles/state/emacs/custom.el")
(defconst dm-file-project-list       "~/.dotfiles/state/emacs/project-list")
(defconst dm-file-recentf            "~/.dotfiles/state/emacs/recentf")
(defconst dm-file-savehist           "~/.dotfiles/state/emacs/savehist")
(defconst dm-file-saveplace          "~/.dotfiles/state/emacs/saveplaces")
(defconst dm-file-scratch            "~/.dotfiles/state/emacs/scratch")
(defconst dm-file-tabspaces          "~/.dotfiles/state/emacs/tabsession.el")
(defconst dm-file-tramp              "~/.dotfiles/state/emacs/tramp")
(defconst dm-file-transient-history  "~/.dotfiles/state/emacs/transient/history.el")
(defconst dm-file-transient-levels   "~/.dotfiles/state/emacs/transient/levels.el")
(defconst dm-file-transient-values   "~/.dotfiles/state/emacs/transient/values.el")

;; Save compiled lisp to xdg state dir
(when (fboundp 'startup-redirect-eln-cache)
  (startup-redirect-eln-cache dm-dir-eln-cache))

(defconst dm-modules-dir (expand-file-name "modules/" dm-config-home))
(add-to-list 'load-path dm-modules-dir)
(add-to-list 'trusted-content (file-name-as-directory (abbreviate-file-name dm-config-home)))
