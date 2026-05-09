;;; codex-ide.el --- Codex CLI integration via eat -*- lexical-binding: t; -*-

(require 'project)

(declare-function eat-mode "eat")
(declare-function eat-exec "eat")
(declare-function eat-semi-char-mode "eat")

(defgroup codex-ide nil "Codex CLI integration." :group 'tools)

(defcustom codex-ide-cli-path "codex"
  "Path to the codex CLI executable."
  :type 'string :group 'codex-ide)

(defcustom codex-ide-cli-args '("--no-alt-screen")
  "Arguments passed to the Codex CLI."
  :type '(repeat string)
  :group 'codex-ide)

(defcustom codex-ide-window-side 'right
  "Side for the codex window."
  :type '(choice (const left) (const right) (const top) (const bottom))
  :group 'codex-ide)

(defcustom codex-ide-window-width 100
  "Width in columns for left/right side windows."
  :type 'integer :group 'codex-ide)

(defcustom codex-ide-focus-on-open t
  "Whether to focus the Codex window when it opens."
  :type 'boolean :group 'codex-ide)

(defun codex-ide--working-directory ()
  (if-let* ((proj (project-current)))
      (project-root proj)
    default-directory))

(defun codex-ide--buffer-name (dir)
  (format "*codex[%s]*" (file-name-nondirectory (directory-file-name dir))))

(defun codex-ide--show-window (buf)
  (let ((window
         (display-buffer-in-side-window
          buf
          `((side         . ,codex-ide-window-side)
            (window-width . ,codex-ide-window-width)
            (window-parameters . ((no-delete-other-windows . t)))))))
    (when (and window codex-ide-focus-on-open)
      (select-window window))
    window))

(defun codex-ide--live-session-p (buf)
  "Return non-nil when BUF is a live Eat-backed Codex session."
  (and (buffer-live-p buf)
       (with-current-buffer buf
         (and (derived-mode-p 'eat-mode)
              (when-let* ((proc (get-buffer-process buf)))
                (process-live-p proc))))))

(defun codex-ide--start-session (buf name dir)
  "Start a new Codex Eat session in BUF named NAME rooted at DIR."
  (require 'eat)
  (with-current-buffer buf
    (cd dir)
    (eat-mode)
    (eat-exec buf name codex-ide-cli-path nil codex-ide-cli-args)
    (eat-semi-char-mode)))

(defun codex-ide ()
  "Start or switch to a Codex session for the current project."
  (interactive)
  (let* ((dir (codex-ide--working-directory))
         (name (codex-ide--buffer-name dir))
         (buf (get-buffer name)))
    (cond
     ((codex-ide--live-session-p buf)
      (codex-ide--show-window buf))
     (t
      (when (buffer-live-p buf)
        (kill-buffer buf))
      (let ((buf (get-buffer-create name)))
        (condition-case err
            (progn
              (codex-ide--start-session buf name dir)
              (codex-ide--show-window buf))
          (error
           (when (buffer-live-p buf)
             (kill-buffer buf))
           (signal (car err) (cdr err)))))))))

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
