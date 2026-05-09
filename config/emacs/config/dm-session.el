;;; dm-session --- Summary: Daymacs session configuration  -*- lexical-binding: t; -*-

;;; Commentary:

;; Session persistence and restore.

;;; Code:

(use-package desktop
  :ensure nil
  :init
  (setq desktop-dirname "~/.dotfiles/config/emacs/")
  :config
  (desktop-save-mode 1)
  (defun dm-restart-and-restore-emacs ()
    "Save desktop and restart Emacs."
    (interactive)
    (desktop-save desktop-dirname)
    (restart-emacs)))

(provide 'dm-session)
;;; dm-session.el ends here
