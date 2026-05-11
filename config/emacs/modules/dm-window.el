;;; dm-window.el --- Daymacs window commands  -*- lexical-binding: t; -*-

;;; Commentary:

;; Window commands used from global and leader keybindings. The hydra is loaded
;; eagerly with this module so `dm-window-resize-hydra/body' is defined before
;; the keymap layer refers to it.

;;; Code:

(require 'cl-lib)

;;;###autoload
(defun dm-delete-window-dwim ()
  "Delete window, do what I mean.
Close tab if sole window in tab, close frame if multiple frames exist,
otherwise kill Emacs."
  (interactive)
  (let ((top-level-frames
         (cl-remove-if
          (lambda (f) (eq (frame-parameter f 'minibuffer)
                          'only))
          (frame-list))))
    (cond
     ((not (one-window-p))             (delete-window))
     ((> (length (tab-bar-tabs)) 1)    (tab-close))
     ((> (length top-level-frames) 1)  (delete-frame))
     (t                                (save-buffers-kill-emacs)))))

(defvar dm-window-resize-step 5
  "Number of rows or columns to resize by in the window hydra.")

(defun dm-window-shrink-horizontally ()
  "Shrink the current window horizontally."
  (interactive)
  (shrink-window-horizontally dm-window-resize-step))

(defun dm-window-enlarge-horizontally ()
  "Enlarge the current window horizontally."
  (interactive)
  (enlarge-window-horizontally dm-window-resize-step))

(defun dm-window-shrink-vertically ()
  "Shrink the current window vertically."
  (interactive)
  (shrink-window dm-window-resize-step))

(defun dm-window-enlarge-vertically ()
  "Enlarge the current window vertically."
  (interactive)
  (enlarge-window dm-window-resize-step))

(use-package hydra
  ;; Repeatable keymaps for commands you want to apply several times in a row.
  :defer 0.3
  :config
  (defhydra dm-window-resize-hydra (:hint nil)
    "
Resize window: [_h_] narrower [_j_] shorter [_k_] taller [_l_] wider [_=_] balance [_q_] quit
"
    ("h" dm-window-shrink-horizontally)
    ("j" dm-window-shrink-vertically)
    ("k" dm-window-enlarge-vertically)
    ("l" dm-window-enlarge-horizontally)
    ("=" balance-windows)
    ("q" nil :color blue)))

(provide 'dm-window)
;;; dm-window.el ends here
