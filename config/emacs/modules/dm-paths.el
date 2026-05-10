;;; dm-paths.el --- -*- lexical-binding: t; -*-

;;; Commentary:

;; File paths compliant with the XDG Base Directory Spec.
;; XDG path constants are defined in early-init.el
;; Set early for downstream initializations here.

;;; Code:

(setq abbrev-file-name dm-file-abbrev-defs)
(setq auto-save-file-name-transforms `((".*" ,dm-dir-auto-save t)))
(setq auto-save-list-file-prefix dm-file-auto-save-prefix)
(setq backup-directory-alist `(("." . ,dm-dir-backups)))
(setq bookmark-default-file dm-file-bookmarks)
(setq custom-file dm-file-customizations)
(setq eshell-directory-name dm-dir-eshell)
(setq package-user-dir dm-dir-elpa)
(setq persistent-scratch-save-file dm-file-scratch)
(setq project-list-file dm-file-project-list)
(setq save-place-file dm-file-saveplace)
(setq savehist-file dm-file-savehist)
(setq straight-base-dir dm-data-home)
(setq tabspaces-session-file dm-file-tabspaces)
(setq tramp-persistency-file-name dm-file-tramp)
(setq transient-history-file dm-file-transient-history)
(setq transient-levels-file  dm-file-transient-levels)
(setq transient-values-file  dm-file-transient-values)
(setq url-configuration-directory dm-dir-url-cache)

(provide 'dm-paths)
;;; dm-paths.el ends here
