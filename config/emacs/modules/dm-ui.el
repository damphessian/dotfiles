;;; dm-ui.el --- Daymacs visual and display setup  -*- lexical-binding: t; -*-

;;; Commentary:

;; Display behavior that should be installed eagerly, plus small visual helper
;; commands that are safe to autoload from keybindings.

;;; Code:

(defun dm-disable-line-numbers-h ()
  "Disable line numbers in the current buffer."
  (display-line-numbers-mode -1))

(defcustom dm-visual-fill-column-extra-width 5
  "Extra visual columns used when enabling visual wrapping.

`visual-fill-column-width' is specified in columns, but Emacs
ultimately wraps displayed text according to rendered pixel width.
Depending on font metrics, scaling, ligatures, and word-boundary
wrapping, an 80-column visual fill area may wrap slightly before
80 logical buffer columns.  This value adds a small cushion so
visual wrapping more closely matches the intended `fill-column'."
  :type 'integer)

;;;###autoload
(defun dm-wrapping-enable ()
  "Enable visual wrapping in the current buffer."
  (interactive)
  (setq-local visual-fill-column-width
              (+ fill-column dm-visual-fill-column-extra-width))
  (setq-local visual-fill-column-center-text nil)
  (setq-local word-wrap t)
  (setq-local truncate-lines nil)
  (visual-line-mode 1)
  (when (fboundp 'visual-fill-column-mode)
    (visual-fill-column-mode 1)
    (visual-fill-column-adjust))
  (recenter))

;;;###autoload
(defun dm-wrapping-disable ()
  "Disable visual wrapping in the current buffer."
  (interactive)
  (visual-line-mode -1)
  (when (fboundp 'visual-fill-column-mode)
    (visual-fill-column-mode -1))
  (setq-local word-wrap nil)
  (setq-local truncate-lines t)
  (recenter))

;;;###autoload
(defun dm-wrapping-toggle ()
  "Toggle visual line wrapping in the current buffer."
  (interactive)
  (if (bound-and-true-p visual-line-mode)
      (dm-wrapping-disable)
    (dm-wrapping-enable)))

(with-eval-after-load 'evil
  (evil-define-operator evil-unfill (beg end type)
    "Unfill text in motion/selection."
    :move-point nil
    (let ((fill-column most-positive-fixnum))
      (fill-region beg end)))
  (define-key evil-normal-state-map "gQ" #'evil-unfill))

(defun dm-frame-title-project-or-buffer ()
  "Show project name in title bar, falling back to buffer name."
  (if-let* ((proj (project-current)))
      (project-name proj)
    (buffer-name)))

;;; Core display behavior.

;; Relative line numbers match evil's jump-count workflow (e.g. 5j, 12k).
(setq display-line-numbers-type 'relative)
(global-display-line-numbers-mode 1)

;; Highlight matching parens immediately.
(setq show-paren-delay 0)
(show-paren-mode 1)

;; Single space after sentences affects fill-paragraph.
(setq sentence-end-double-space nil)

;; Silence the audible bell entirely.
(setq ring-bell-function #'ignore)

;; Show project name in title bar, falling back to buffer name.
(setq frame-title-format
      '((:eval
         (dm-frame-title-project-or-buffer))))

;; Display column number in the modeline.
(column-number-mode)

;;; Package-backed appearance.

(set-face-attribute 'default nil :family "Source Code Pro Ligaturized" :height 180)

(use-package doom-themes
  :config
  (load-theme 'doom-one t))

(use-package doom-modeline
  :init
  (setq doom-modeline-major-mode-icon nil)
  (setq doom-modeline-buffer-state-icon nil)
  (setq doom-modeline-vcs-icon nil)
  (setq doom-modeline-icon t)
  :config
  (doom-modeline-mode 1))

(provide 'dm-ui)
;;; dm-ui.el ends here
