;;; init.el --- -*- lexical-binding: t; -*-

;;; Commentary:

;; A bare-metal Emacs config.
;; Minimal, fast, pragmatic. No fluff.

;;; Code:

;; For enabling flymake checking:
;; (eval-and-compile
;;   (defconst dm-config-root (file-name-as-directory (file-truename "~/.config/emacs")))
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

;;; ————————————————————————————————
;;; Set canonical dirs, load path
;;; ————————————————————————————————
(defun dm-ensure-xdg-emacs-dir (type)
  "Return the XDG directory of TYPE for Emacs, creating it if needed.

TYPE should be one of `config', `state', or `cache'."
  (let* ((type (downcase (format "%s" type)))
         (env-var (format "XDG_%s_HOME" (upcase type)))
         (fallback
          (pcase type
            ("cache"  "~/.cache")
            ("config" "~/.config")
            ("data"   "~/.local/share")
            ("state"  "~/.local/state")
            (_ (error "Unknown XDG directory type: %s" type))))
         (root (or (getenv env-var) fallback))
         (dir (file-name-as-directory (expand-file-name "emacs/" root))))
    (make-directory dir t)
    dir))

(defconst dm-cache-root  (dm-ensure-xdg-emacs-dir 'cache))
(defconst dm-config-root (dm-ensure-xdg-emacs-dir 'config))
(defconst dm-data-root  (dm-ensure-xdg-emacs-dir 'data))
(defconst dm-state-root  (dm-ensure-xdg-emacs-dir 'state))

;; Trust config directory, add submodule directory to load path
(add-to-list 'trusted-content (abbreviate-file-name dm-config-root))
(add-to-list 'load-path (expand-file-name "config/" dm-config-root))

;;; ————————————————————————————
;;; initialize logging
;;; ————————————————————————————
(require 'dm-log)
(dm-log-initialize)

;;; ————————————————————————————
;;; straight.el bootstrap
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
(setq straight-base-dir dm-data-root)
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
;;; lazy-load submodules
;;; ————————————————————————————
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
