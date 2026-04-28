;;; codex-ide.el --- Codex CLI integration via eat -*- lexical-binding: t; -*-

(defgroup codex-ide nil "Codex CLI integration." :group 'tools)

(defcustom codex-ide-cli-path "codex"
  "Path to the codex CLI executable."
  :type 'string :group 'codex-ide)

(defcustom codex-ide-window-side 'right
  "Side for the codex window."
  :type '(choice (const left) (const right) (const top) (const bottom))
  :group 'codex-ide)

(defcustom codex-ide-window-width 100
  "Width in columns for left/right side windows."
  :type 'integer :group 'codex-ide)

(defun codex-ide--working-directory ()
  (if-let* ((proj (project-current)))
      (project-root proj)
    default-directory))

(defun codex-ide--buffer-name (dir)
  (format "*codex[%s]*" (file-name-nondirectory (directory-file-name dir))))

(defun codex-ide--show-window (buf)
  (display-buffer-in-side-window
   buf
   `((side         . ,codex-ide-window-side)
     (window-width . ,codex-ide-window-width)
     (window-parameters . ((no-delete-other-windows . t))))))

(defun codex-ide ()
  "Start or switch to a Codex session for the current project."
  (interactive)
  (let* ((dir (codex-ide--working-directory))
         (name (codex-ide--buffer-name dir)))
    (if (get-buffer name)
        (codex-ide--show-window (get-buffer name))
      (let ((buf (get-buffer-create name)))
        (with-current-buffer buf
          (cd dir)
          (eat-mode)
          (eat-exec buf name codex-ide-cli-path nil nil))
        (codex-ide--show-window buf)))))

(defun codex-ide-toggle ()
  "Toggle visibility of the Codex window for the current project."
  (interactive)
  (let* ((dir (codex-ide--working-directory))
         (name (codex-ide--buffer-name dir))
         (win (get-buffer-window name)))
    (if win
        (delete-window win)
      (codex-ide))))

(defun codex-ide-stop ()
  "Kill the Codex session for the current project."
  (interactive)
  (let* ((dir (codex-ide--working-directory))
         (name (codex-ide--buffer-name dir)))
    (when-let* ((buf (get-buffer name)))
      (kill-buffer buf))))

(provide 'codex-ide)
