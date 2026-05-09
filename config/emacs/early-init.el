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
