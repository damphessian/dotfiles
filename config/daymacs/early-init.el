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
        (vertical-scroll-bars . nil)
        (horizontal-scroll-bars . nil)))

;; Skip the "Welcome to GNU Emacs" splash screen.
(setq inhibit-startup-screen t)

;; Prevent package.el from activating packages — straight.el owns that.
(setq package-enable-at-startup nil)
