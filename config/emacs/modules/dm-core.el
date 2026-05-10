;;; dm-core.el --- Daymacs baseline Emacs setup  -*- lexical-binding: t; -*-

;;; Commentary:

;; Small, eager defaults that define how this Emacs behaves before the larger
;; feature modules layer on package-specific configuration.

;;; Code:

;;; Popup policy used by `dm-popup-quit'.

(setq dm-quit-or-close-popup-buffer-names
      '("*Backtrace*"
        "*Compile-Log*"
        "*Help*"
        "*Messages*"
        "*Warnings*"
        "*compilation*"
        "*eldoc*"))

(setq dm-quit-or-close-popup-buffer-prefixes
      '("*Embark Collect"
        "*Flycheck"
        "*helpful"
        "*xref"))

;;; Test/implementation toggle bridge.

(with-eval-after-load 'evil
  (evil-define-command dm-evil-toggle-test-implementation ()
    "Toggle between implementation and test file."
    :repeat nil
    (dm-toggle-test-implementation))
  (evil-ex-define-cmd "A" #'dm-evil-toggle-test-implementation))

;;; Core Emacs settings.

;; Prefer UTF-8 everywhere.
(set-language-environment "UTF-8")
(set-default-coding-systems 'utf-8)

;; Redirect backups to a single directory instead of littering alongside files.
(setq backup-by-copying t)
(setq version-control t)
(setq delete-old-versions t)

;; Lock files (.#foo) are only useful for multi-user editing; skip them.
(setq create-lockfiles nil)

;; Auto-revert files, avoid polling.
(setq auto-revert-avoid-polling t)

(use-package recentf
  :ensure nil
  :straight (:type built-in)
  :init
  :custom
  (recentf-save-file dm-file-recentf)
  (recentf-auto-cleanup "11:00pm")
  (recentf-max-saved-items 200)
  :config
  (defun dm-log-quietly-recentf-mode ()
    (let ((inhibit-message t)
          (message-log-max nil))
      (recentf-mode 1)))
  ;; Run recentf cleanup quietly. With `recentf-auto-cleanup' set to a time
  ;; string, cleanup runs via `run-at-time' -- an async timer dispatch that
  ;; loses any `inhibit-message' let-binding from the surrounding call site.
  (advice-add 'recentf-cleanup :around #'dm-log-quietly))

;; Delay global mode activation
;; ----------------------------
;; Activate cross-cutting global modes after the first frame is up. None of
;; these need to run before the user can start typing, and recentf-mode in
;; particular reads/writes its history file, so it stays off the boot path.
(defun dm-core-global-minor-modes ()
  (editorconfig-mode 1)
  (global-auto-revert-mode -1) ;; disabled for safety
  (global-eldoc-mode -1) ;; disabled because noisy
  (dm-log-quietly-recentf-mode)
  (savehist-mode 1))
(add-hook 'emacs-startup-hook #'dm-core-global-minor-modes)

(defun dm-core-daemon-is-tty-p ()
  "Return non-nil when this Emacs daemon name contains \"tty\"."
  (let ((daemon-name (daemonp)))
    (and (stringp daemon-name)
         (string-match-p "tty" daemon-name))))

;; Persist minibuffer history (commands, searches, consult inputs) across
;; sessions.
(setq history-length 300)

;; Follow symlinks to version-controlled files without prompting.
(setq vc-follow-symlinks t)

;; Drop legacy and hipster VCS integrations you don't use.
(setq-default vc-handled-backends '(Git))

;; Empty scratch buffer on launch (`inhibit-startup-screen' is in early-init.el).
(setq initial-scratch-message nil)

;; Empty scratch buffer in fundamental-mode.
(setq initial-major-mode 'fundamental-mode)

;; Use spaces for alignment, truncate lines by default.
(setq-default indent-tabs-mode nil)
(setq-default tab-width 8)
(setq-default truncate-lines t)
(setq-default fill-column 80)

;; Show trailing whitespace
(setq show-trailing-whitespace t)

;; Delete by moving to trash.
(setq delete-by-moving-to-trash t)

;; Lower GC threshold back to something reasonable once startup is done. 16 MB
;; is comfortable for interactive use and keeps startup's high threshold local.
(add-hook 'emacs-startup-hook
          (lambda ()
            (setq gc-cons-threshold (* 16 1024 1024)
                  gc-cons-percentage 0.1)))

(provide 'dm-core)
;;; dm-core.el ends here
