;;; dm-files --- Summary: Daymacs file management facilities  -*- lexical-binding: t; -*-

;;; Commentary:

;; Helpers for managing files.

;; Consider stealing from:
;; https://github.com/doomemacs/doomemacs/blob/master/lisp/lib/buffers.el
;; https://github.com/doomemacs/doomemacs/blob/master/lisp/lib/files.el

;;; Code:

(defun dm-delete-this-file (&optional path)
  "Delete the current buffer's file."
  (interactive)
  (let* ((path (or path (buffer-file-name (buffer-base-buffer))))
         (short-path (and path (abbreviate-file-name path))))
    (unless path
      (user-error "Buffer is not visiting any file"))
    (let ((buf (current-buffer)))
      (unwind-protect
          (progn (delete-file path t) t)
        (if (file-exists-p path)
            (error "Failed to delete %S" short-path)
          (progn
            (kill-buffer)
            (revert-buffer)
            (message "Deleted %S" short-path)))))))

(provide 'dm-files)
;;; dm-files.el ends here
