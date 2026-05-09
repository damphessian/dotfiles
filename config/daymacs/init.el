;;; init.el --- -*- lexical-binding: t; -*-

;;; Commentary:

;; A bare-metal Emacs config.
;; Minimal, fast, pragmatic. No fluff.

;;; Code:

;; For enabling flymake checking:
;; (eval-and-compile
;;   (defconst dm-config-root (file-name-as-directory (file-truename "~/.config/daymacs")))
;;   ;; Trust config directory
;;   (add-to-list 'trusted-content (abbreviate-file-name dm-config-root))
;;   ;; Add submodule directory to load path
;;   (add-to-list 'load-path (expand-file-name "config/" dm-config-root))
;;   ;; For Flymake: Add straight.el build directories to load path at compile time
;;   (let ((build-dir (expand-file-name "straight/build/" dm-config-root)))
;;     (when (file-directory-p build-dir)
;;       (dolist (dir (directory-files build-dir t "\\`[^.]"))
;;         (when (file-directory-p dir)
;;           (add-to-list 'load-path dir))))))

;; Trust config directory, add submodule directory to load path
(defconst dm-config-root (file-name-as-directory (file-truename "~/.config/daymacs")))
(add-to-list 'trusted-content (abbreviate-file-name dm-config-root))
(add-to-list 'load-path (expand-file-name "config/" dm-config-root))

;; Enable logging
(require 'dm-log)
(dm-log-initialize)

;;; ————————————————————————————
;;; straight.el bootstrap
;;; ————————————————————————————

;; pins exact commits, and integrates with use-package via :straight t.
;; Setting straight-use-package-by-default means every use-package form
;; automatically installs via straight unless told otherwise.
(defvar bootstrap-version)
(defvar straight-use-package-by-default)
(declare-function straight-use-package "straight")

;; Treat bare `use-package' declarations as straight-managed packages.
;; Use `:straight nil' for built-in packages or packages managed elsewhere.
(setq straight-use-package-by-default t)

(let ((bootstrap-file
       (expand-file-name
        "straight/repos/straight.el/bootstrap.el"
        (or (bound-and-true-p straight-base-dir)
            user-emacs-directory)))
      (bootstrap-version 7))
  (unless (file-exists-p bootstrap-file)
    (with-current-buffer
        (url-retrieve-synchronously
         "https://raw.githubusercontent.com/radian-software/straight.el/develop/install.el"
         'silent 'inhibit-cookies)
      (goto-char (point-max))
      (eval-print-last-sexp)))
  (load bootstrap-file nil 'nomessage))

;; use-package is the declaration macro. straight.el handles the installation.
(straight-use-package 'use-package)

;; Use built-in project.el
(straight-use-package '(project :type built-in))

;; Lazy-load `dm-*' modules via a generated `loaddefs.el'. The generator picks
;; up `;;;###autoload' cookies in `config/*.el' and writes one file with all
;; the `(autoload ...)' forms. We rebuild it whenever any source file is newer
;; than the cache, so adding a new module or cookie just works on next boot.
(let* ((config-dir (expand-file-name "config" user-emacs-directory))
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
