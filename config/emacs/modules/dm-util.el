;;; dm-util.el --- -*- lexical-binding: t; -*-

;;; Commentary:

;;; Code:

(defun dm-util-working-dir (&optional directory)
  "Return the project root for DIRECTORY, or DIRECTORY/default-directory.

If DIRECTORY is nil, use `default-directory'.  If DIRECTORY is inside a
known project, return that project's root.  Otherwise return DIRECTORY."
  (let ((default-directory (or directory default-directory)))
    (if-let* ((project (project-current nil)))
        (project-root project)
      default-directory)))

(defun dm-util-daemon-is-tty-p ()
  "Return non-nil when this Emacs daemon name contains \"tty\"."
  (let ((daemon-name (daemonp)))
    (and (stringp daemon-name)
         (string-match-p "tty" daemon-name))))


(provide 'dm-util)
;;; dm-util.el ends here
