;;; init.el --- -*- lexical-binding: t; -*-

;;; Commentary:

;; A bare-metal Emacs config.
;; Minimal, fast, pragmatic. No fluff.

;;; Code:

;;; ————————————————————————————
;;; Preliminaries
;;; ————————————————————————————
;; Note: See init.compiled.el for a more compiler-friendly but slower to execute
;; preamble.
(add-to-list 'load-path (expand-file-name "modules/" user-emacs-directory))
(require 'dm-log)
(dm-log-initialize)

;;; ————————————————————————————
;;; Bootstrap straight.el
;;; ————————————————————————————
;; pins exact commits, and integrates with use-package via :straight t.
;; Setting straight-use-package-by-default means every use-package form
;; automatically installs via straight unless told otherwise.
(defvar bootstrap-file-path)
(defvar bootstrap-version)
(defvar straight-base-dir)
(defvar straight-install-url)
(defvar straight-use-package-by-default)
(declare-function straight-use-package "straight")

;; Treat bare `use-package' declarations as straight-managed packages.
;; Use `:straight nil' for built-in packages or packages managed elsewhere.
(setq bootstrap-file-path "straight/repos/straight.el/bootstrap.el")
(setq bootstrap-version 7)
(setq straight-base-dir dm-data-home)
(setq straight-install-url "https://raw.githubusercontent.com/radian-software/straight.el/develop/install.el")
(setq straight-use-package-by-default t)

(let ((bootstrap-file (expand-file-name bootstrap-file-path straight-base-dir)))
  (unless (file-exists-p bootstrap-file)
    (with-current-buffer
        (url-retrieve-synchronously straight-install-url 'silent 'inhibit-cookies)
      (goto-char (point-max))
      (eval-print-last-sexp)))
  (load bootstrap-file nil 'nomessage))

;; use-package is the declaration macro. straight.el handles the installation.
(straight-use-package 'use-package)
;; Use built-in project.el
(straight-use-package '(project :type built-in))


;;; ————————————————————————————
;;; Lazy-load submodules
;;; ————————————————————————————
;; Lazy-load `dm-*' modules via a generated `loaddefs.el'. The generator picks
;; up `;;;###autoload' cookies in `config/*.el' and writes one file with all
;; the `(autoload ...)' forms. We rebuild it whenever any source file is newer
;; than the cache, so adding a new module or cookie just works on next boot.
(let* ((config-dir dm-modules-dir)
       (loaddefs (expand-file-name "loaddefs.el" config-dir))
       (sources (and (file-directory-p config-dir)
                     (directory-files config-dir t "\\`dm-.*\\.el\\'")))
       (stale (or (not (file-exists-p loaddefs))
                  (let ((cached (file-attribute-modification-time
                                 (file-attributes loaddefs))))
                    (seq-some (lambda (f)
                                (time-less-p
                                 cached
                                 (file-attribute-modification-time
                                  (file-attributes f))))
                              sources)))))
  (when stale
    (require 'loaddefs-gen)
    ;; `loaddefs-generate' reports each scrape pass with INFO messages. Keep
    ;; startup quiet while preserving the automatic autoload refresh.
    (let ((inhibit-message t)
          (message-log-max nil))
      (loaddefs-generate config-dir loaddefs)))
  (load loaddefs nil 'nomessage))

(require 'dm-xdg)

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
(when (dm-designated-tty-daemon-p)
  (require 'dm-tty))

(message (emacs-init-time "%.2fs"))

(provide 'init)
;;; init.el ends here
