;;; dm-session --- Summary: Daymacs session configuration  -*- lexical-binding: t; -*-

;;; Commentary:

;; Session persistence and restore.

;;; Code:

(use-package desktop
  :ensure nil
  :custom
  (desktop-dirname dm-dir-desktop)
  (desktop-base-file-name "emacs.desktop")
  (desktop-base-lock-name "emacs.desktop.lock")

  (desktop-save nil) ;; Do not save automatically on exit.
  (desktop-load-locked-desktop 'check-pid) ;; Do not ask about stale locks.
  ;; Workaround for frame size being broken on restore.
  ;; Avoid reusing the initial frame during desktop restore, which can override
  ;; the frame size/maximization established during early init.
  (desktop-restore-reuses-frames nil)
  :config
  (defun dm-desktop-file ()
    "Return the full path to the configured desktop file."
    (expand-file-name desktop-base-file-name dm-dir-desktop))

  (defun dm-desktop-restore-if-present ()
    "Restore desktop only when a desktop file exists."
    (when (file-exists-p (dm-desktop-file))
      (let ((inhibit-message t)
            (message-log-max nil))
        (desktop-read dm-dir-desktop))))

  (defun dm-desktop-delete-file ()
    "Delete the saved desktop file, if it exists."
    (let ((file (dm-desktop-file)))
      (when (file-exists-p file)
        (delete-file file))))

  (add-hook 'emacs-startup-hook #'dm-desktop-restore-if-present)
  (add-hook 'desktop-after-read-hook #'dm-desktop-delete-file))


;;;###autoload
(defun dm-restart-emacs-no-restore ()
  "Restart Emacs without restoring the desktop."
  (interactive)
  (dm-desktop-delete-file)
  (restart-emacs))

;;;###autoload
(defun dm-restart-emacs-and-restore ()
  "Save desktop and restart Emacs."
  (interactive)
  (desktop-save dm-dir-desktop)
  (restart-emacs))

(provide 'dm-session)
;;; dm-session.el ends here
