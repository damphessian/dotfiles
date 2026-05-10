;;; dm-xdg.el --- -*- lexical-binding: t; -*-

;;; Commentary:

;; XDG Base Directory Specification helpers

;;; Code:

(defun dm-xdg-ensure-emacs-dir (type)
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

(defun dm-xdg-emacs-path (type path &rest options)
  "Return relative PATH under the Emacs XDG directory TYPE.

PATH must be relative. TYPE should be one of `cache', `config', `data', or
`state'. When OPTIONS contains `:directory', return the path as a directory
with a trailing slash and create it if needed.

Examples:
  (dm-xdg-emacs-path 'state \"desktop\" :directory)
  (dm-xdg-emacs-path 'cache \"tree-sitter/lib\" :directory)
  (dm-xdg-emacs-path 'state \"recentf\")"
  (when (file-name-absolute-p path)
    (error "PATH must be relative: %s" path))
  (let* ((directory-p (memq :directory options))
         (home
          (pcase type
            ('cache  dm-cache-home)
            ('config dm-config-home)
            ('data   dm-data-home)
            ('state  dm-state-home)
            (_ (error "Unknown XDG directory type: %s" type))))
         (expanded-path (expand-file-name path home)))
    (if directory-p
        (let ((dir (file-name-as-directory expanded-path)))
          (make-directory dir t)
          dir)
      expanded-path)))

(defun dm-xdg-cache-path (path)
  "Return PATH under `dm-cache-home'.

If PATH ends with a slash, create it as a directory and return the
directory name with a trailing slash."
  (if (directory-name-p path)
      (dm-xdg-emacs-path 'cache path :directory)
    (dm-xdg-emacs-path 'cache path)))

(defun dm-xdg-config-path (path)
  "Return PATH under `dm-config-home'.

If PATH ends with a slash, create it as a directory and return the
directory name with a trailing slash."
  (if (directory-name-p path)
      (dm-xdg-emacs-path 'config path :directory)
    (dm-xdg-emacs-path 'config path)))

(defun dm-xdg-data-path (path)
  "Return PATH under `dm-data-home'.

If PATH ends with a slash, create it as a directory and return the
directory name with a trailing slash."
  (if (directory-name-p path)
      (dm-xdg-emacs-path 'data path :directory)
    (dm-xdg-emacs-path 'data path)))

(defun dm-xdg-state-path (path)
  "Return PATH under `dm-state-home'.

If PATH ends with a slash, create it as a directory and return the
directory name with a trailing slash."
  (if (directory-name-p path)
      (dm-xdg-emacs-path 'state path :directory)
    (dm-xdg-emacs-path 'state path)))

(setq custom-file dm-file-customizations)
(setq backup-directory-alist `(("." . ,dm-dir-backups)))
(setq auto-save-file-name-transforms `((".*" ,dm-dir-auto-save t)))
(setq auto-save-list-file-prefix dm-file-auto-save-prefix)
(setq package-user-dir dm-dir-elpa)
(setq abbrev-file-name dm-file-abbrev-defs)
(setq bookmark-default-file dm-file-bookmarks)
(setq eshell-directory-name dm-dir-eshell)
(setq persistent-scratch-save-file dm-file-scratch)
(setq project-list-file dm-file-project-list)
(setq savehist-file dm-file-savehist)
(setq save-place-file dm-file-saveplace)
(setq tabspaces-session-file dm-file-tabspaces)
(setq tramp-persistency-file-name dm-file-tramp)
(setq transient-history-file dm-file-transient-history)
(setq transient-levels-file  dm-file-transient-levels)
(setq transient-values-file  dm-file-transient-values)
(setq url-configuration-directory dm-dir-url-cache)

(provide 'dm-xdg)
;;; dm-xdg.el ends here
