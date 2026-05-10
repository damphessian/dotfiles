;;; dm-straight.el --- -*- lexical-binding: t; -*-

;;; Commentary:

;; Bootstraps straight.el for package management.
;;
;; Pins exact commits, and integrates with use-package via :straight t.
;;
;; Setting straight-use-package-by-default means every use-package form
;; automatically installs via straight unless told otherwise.

;;; Code:

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

(provide 'dm-straight)
;;; dm-straight.el ends here
