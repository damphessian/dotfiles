;;; dm-session --- Summary: Daymacs session configuration  -*- lexical-binding: t; -*-

;;; Commentary:

;; Session persistence and restore.

;;; Code:

(use-package desktop
  :ensure nil
  :init
  (setq desktop-dirname (expand-file-name "emacs/" (getenv "XDG_STATE_HOME")))
  (make-directory desktop-dirname t)
  :custom
  (desktop-save nil) ;; Do not save automatically on exit.
  (desktop-load-locked-desktop nil) ;; Do not ask about stale locks.
  ;; Workaround for frame size being broken on restore.
  ;; Avoid reusing the initial frame during desktop restore, which can override
  ;; the frame size/maximization established during early init.
  (desktop-restore-reuses-frames nil)
  :config
  (defun dm-desktop-file ()
    "Return the full path to the configured desktop file."
    (expand-file-name desktop-base-file-name desktop-dirname))

  (defun dm-desktop-restore-if-present ()
  "Restore desktop only when a desktop file exists."
  (when (file-exists-p (dm-desktop-file))
    (let ((inhibit-message t)
          (message-log-max nil))
      (desktop-read desktop-dirname))))

  (defun dm-desktop-delete-file ()
    "Delete the saved desktop file, if it exists."
    (let ((file (desktop-full-file-name)))
      (when (file-exists-p file)
        (delete-file file))))

  (defun dm-restart-emacs-no-restore ()
    "Restart Emacs without restoring the desktop."
    (interactive)
    (dm-desktop-delete-file)
    (restart-emacs))

  (defun dm-restart-emacs-and-restore ()
    "Save desktop and restart Emacs."
    (interactive)
    (desktop-save desktop-dirname)
    (restart-emacs))

  (add-hook 'emacs-startup-hook #'dm-desktop-restore-if-present)
  (add-hook 'desktop-after-read-hook #'dm-desktop-delete-file))

(provide 'dm-session)
;;; dm-session.el ends here
