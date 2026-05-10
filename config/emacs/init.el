;;; init.el --- -*- lexical-binding: t; -*-

;;; Commentary:

;; A bare-metal Emacs config.

;;; Code:

(require 'dm-paths)
(require 'dm-log)
(dm-log-initialize)

(require 'dm-straight)
(require 'dm-autoload)

;; Eager, cross-cutting setup lives in cohesive modules; command-only helpers
;; keep using autoload cookies and stay out of the startup path.
(require 'dm-session)
(require 'dm-core)
(require 'dm-ui)
(require 'dm-evil)
(require 'dm-window)
(require 'dm-completion)
(require 'dm-editing)
(require 'dm-env)
(require 'dm-vcs)
(require 'dm-ai)
(require 'dm-terminal)
(require 'dm-org)
(require 'dm-langs)
(require 'dm-keys)

(when (dm-core-daemon-is-tty-p)
  (require 'dm-tty))

(message (emacs-init-time "%.2fs"))

(provide 'init)
;;; init.el ends here
