;;; dm-files --- Summary: Daymacs file management facilities  -*- lexical-binding: t; -*-

;;; Commentary:

;; Helpers for managing files.

;; Consider stealing from:
;; https://github.com/doomemacs/doomemacs/blob/master/lisp/lib/buffers.el
;; https://github.com/doomemacs/doomemacs/blob/master/lisp/lib/files.el

;;; Code:

(require 'project)
(require 'subr-x)

(defgroup dm-file-open nil
  "Open files and directories from Emacs."
  :group 'convenience)

(defcustom dm-file-open-apps
  nil
  "Alist mapping file extensions to macOS application names.

Each entry is (EXTENSION . APP), without the leading dot.

Example:

  ((\"pdf\" . \"Preview\")
   (\"md\"  . \"MacDown\"))

If the current file has a matching extension, `dm-file-open' runs:

  open -a APP FILE

Otherwise it runs:

  open FILE"
  :type '(alist :key-type string :value-type string))

(setq dm-file-open-apps
      '(("pdf" . "Skim")
        ("md"  . "Marked 2")))

(defun dm-file-open-app-for-file (file)
  "Return configured macOS app for FILE, or nil."
  (when-let* ((extension (file-name-extension file)))
    (alist-get (downcase extension) dm-file-open-apps nil nil #'string=)))

(defun dm-buffer-file-name ()
  "Return the current buffer's file name, or nil."
  (or buffer-file-name
      (and (derived-mode-p 'dired-mode)
           default-directory)))

(defun dm-current-file-or-error ()
  "Return the current buffer's file name, or signal a user error."
  (or buffer-file-name
      (user-error "Current buffer has no associated file")))

(defun dm-current-directory-or-error ()
  "Return the directory for the current buffer, or signal a user error."
  (cond
   (buffer-file-name
    (file-name-directory buffer-file-name))
   ((derived-mode-p 'dired-mode)
    default-directory)
   (default-directory
    default-directory)
   (t
    (user-error "Current buffer has no associated directory"))))

(defun dm-project-root ()
  "Return the current project root, or nil without prompting."
  (when-let* ((project (project-current nil)))
    (expand-file-name (project-root project))))

(defun dm-path-in-home-p (path)
  "Return non-nil if PATH is inside the user's home directory."
  (let ((path (file-truename path))
        (home (file-name-as-directory (file-truename "~"))))
    (string-prefix-p home path)))

(defun dm-abbreviated-home-path (path)
  "Return PATH abbreviated with `~', or nil if PATH is not in home."
  (when (dm-path-in-home-p path)
    (abbreviate-file-name path)))

(defun dm-project-relative-file-path (path)
  "Return PATH relative to the current project root, or nil.

Returns nil if PATH is not inside the current project."
  (when-let* ((root (dm-project-root)))
    (let ((path-truename (file-truename path))
          (root-truename (file-name-as-directory (file-truename root))))
      (when (string-prefix-p root-truename path-truename)
        (file-relative-name path root)))))

(defun dm-copy-string (string description)
  "Copy STRING to the kill ring and report DESCRIPTION."
  (kill-new string)
  (message "Copied %s: %s" description string)
  string)

(defun dm-open-path (path)
  "Open PATH with macOS `open'."
  (unless (executable-find "open")
    (user-error "Could not find macOS `open' command"))
  (let ((expanded-path (expand-file-name path)))
    (unless (file-exists-p expanded-path)
      (user-error "Path does not exist: %s" expanded-path))
    (let ((status (call-process "open" nil nil nil expanded-path)))
      (unless (zerop status)
        (user-error "`open' failed with status %s: %s" status expanded-path))
      (message "Opened: %s" expanded-path))))

(defun dm-open-file-with-default-or-configured-app (file)
  "Open FILE with macOS `open', using `dm-file-open-apps' if configured."
  (unless (executable-find "open")
    (user-error "Could not find macOS `open' command"))
  (if-let* ((app (dm-file-open-app-for-file file)))
      (progn
        (call-process "open" nil 0 nil "-a" app file)
        (message "Opened with %s: %s" app file))
    (call-process "open" nil 0 nil file)
    (message "Opened: %s" file)))

;;;###autoload
(defun dm-directory-open ()
  "Open the directory of the current buffer's file in Finder."
  (interactive)
  (dm-open-path (dm-current-directory-or-error)))

;;;###autoload
(defun dm-directory-open-project ()
  "Open the current project root, falling back to the current directory.
This never prompts for a project."
  (interactive)
  (dm-open-path
   (or (dm-project-root)
       (dm-current-directory-or-error))))

;;;###autoload
(defun dm-file-open ()
  "Open the current buffer's file with the default or configured app.

Uses `dm-file-open-apps' to choose an app by filename regexp.
Falls back to macOS `open'."
  (interactive)
  (dm-open-file-with-default-or-configured-app
   (dm-current-file-or-error)))

;;;###autoload
(defun dm-copy-file-path ()
  "Copy the current buffer file path with home abbreviated as `~'.

If the file is not under the user's home directory, report nil."
  (interactive)
  (let* ((file (dm-current-file-or-error))
         (path (dm-abbreviated-home-path file)))
    (if path
        (dm-copy-string path "home-relative file path")
      (message "nil: file is not under home directory")
      nil)))

;;;###autoload
(defun dm-copy-file-abspath ()
  "Copy the absolute path of the current buffer's file."
  (interactive)
  (dm-copy-string
   (expand-file-name (dm-current-file-or-error))
   "absolute file path"))

;;;###autoload
(defun dm-copy-file-project-path ()
  "Copy the current buffer file path relative to the project root.

If the file is not inside the current project, report nil."
  (interactive)
  (let* ((file (dm-current-file-or-error))
         (path (dm-project-relative-file-path file)))
    (if path
        (dm-copy-string path "project-relative file path")
      (message "nil: file is not under current project root")
      nil)))

;;;###autoload
(defun dm-copy-file-path-dwim ()
  "Copy the most useful path for the current buffer file.

Preference order:

1. Project-relative path.
2. Home-abbreviated path.
3. Absolute path.

If the buffer has no file, report that instead."
  (interactive)
  (if-let* ((file buffer-file-name))
      (let ((path (or (dm-project-relative-file-path file)
                      (dm-abbreviated-home-path file)
                      (expand-file-name file))))
        (dm-copy-string path "file path"))
    (message "Current buffer has no associated file")
    nil))

;;;###autoload
(defun dm-delete-this-file (&optional path)
  "Delete the current buffer's file."
  (interactive)
  (let* ((path (or path (buffer-file-name (buffer-base-buffer))))
         (short-path (and path (abbreviate-file-name path))))
    (unless path
      (user-error "Buffer is not visiting any file"))
    (unwind-protect
        (progn (delete-file path t) t)
      (if (file-exists-p path)
          (error "Failed to delete %S" short-path)
        (progn
          (kill-buffer)
          (revert-buffer)
          (message "Deleted %S" short-path))))))

(defcustom dm-project-discovery-depth 5
  "Maximum directory depth for `dm-project-discover-projects'."
  :type 'integer)

;;;###autoload
(defun dm-project-discover-projects (&optional directory)
  "Discover Git projects under DIRECTORY and remember them with project.el.
DIRECTORY defaults to the user's home directory."
  (interactive
   (list (read-directory-name "Starting directory: " "~/" nil t)))
  (let* ((directory (file-name-as-directory
                     (expand-file-name (or directory "~/"))))
         (cmd (format "fd -H -t d -d %d '^\\.git$' %s"
                      dm-project-discovery-depth
                      (shell-quote-argument directory))))
    (dolist (git-dir (split-string (shell-command-to-string cmd) "\n" t))
      (let ((dir (file-name-directory (directory-file-name git-dir))))
        (when-let* ((project (project-current nil dir)))
          (project-remember-project project))))))

(provide 'dm-files)
;;; dm-files.el ends here
