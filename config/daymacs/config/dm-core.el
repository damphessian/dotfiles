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
  (evil-ex-define-cmd "A" #'dm-evil-toggle-test-implementation)
  (global-set-key (kbd "C-c t") #'dm-toggle-test-implementation))

;;; Core Emacs settings.

;; Prefer UTF-8 everywhere.
(set-language-environment "UTF-8")
(set-default-coding-systems 'utf-8)

;; Redirect backups to a single directory instead of littering alongside files.
(setq backup-directory-alist `(("." . ,(concat user-emacs-directory "backups")))
      backup-by-copying t
      version-control t
      delete-old-versions t)

;; Auto-save files also go to a dedicated directory.
(setq auto-save-file-name-transforms
      `((".*" ,(concat user-emacs-directory "auto-save/") t)))

;; Lock files (.#foo) are only useful for multi-user editing; skip them.
(setq create-lockfiles nil)

;; Auto-revert files, avoid polling.
(setq auto-revert-avoid-polling t)

;; Track recently visited files; used by consult-recent-file.
(setq recentf-auto-cleanup "11:00pm")
(setq recentf-max-saved-items 200)

;; Run recentf cleanup quietly. With `recentf-auto-cleanup' set to a time
;; string, cleanup runs via `run-at-time' -- an async timer dispatch that
;; loses any `inhibit-message' let-binding from the surrounding call site.
(with-eval-after-load 'recentf
  (advice-add 'recentf-cleanup :around
              (lambda (fn &rest args)
                (let ((inhibit-message t)
                      (message-log-max nil))
                  (apply fn args)))))

;; Persist minibuffer history (commands, searches, consult inputs) across
;; sessions.
(setq history-length 300)

;; Activate cross-cutting global modes after the first frame is up. None of
;; these need to run before the user can start typing, and recentf-mode in
;; particular reads/writes its history file, so it stays off the boot path.
(add-hook 'emacs-startup-hook
          (lambda ()
            (editorconfig-mode 1)
            (global-auto-revert-mode 1)
            (let ((inhibit-message t)
                  (message-log-max nil))
              (recentf-mode 1))
            (savehist-mode 1)))

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
