;;; dm-popup-quit --- Summary: Daymacs popup windows quit  -*- lexical-binding: t; -*-

;;; Commentary:

;; Facilities for dismissing popup windows without navigating to them.

;;; Code:

(defgroup dm-popups nil
  "Small utilities for dismissing popup windows."
  :group 'convenience)

(defcustom dm-quit-or-close-popup-buffer-names
  '("*compilation*" "*Messages*" "*Warnings*")
  "Exact buffer names that `dm-quit-or-close-popup' should close."
  :type '(repeat string)
  :group 'dm-popups)

(defcustom dm-quit-or-close-popup-buffer-prefixes
  '()
  "Buffer name prefixes that `dm-quit-or-close-popup' should close.
For example, a prefix of \"*Flycheck\" matches buffers such as
\"*Flycheck errors*\"."
  :type '(repeat string)
  :group 'dm-popups)

(defun dm-quit-or-close-popup--popup-buffer-p (buffer)
  "Return non-nil if BUFFER should be treated as a dismissible popup."
  (let ((name (buffer-name buffer)))
    (or (member name dm-quit-or-close-popup-buffer-names)
        (seq-some
         (lambda (prefix)
           (string-prefix-p prefix name))
         dm-quit-or-close-popup-buffer-prefixes))))

;;;###autoload
(defun dm-quit-or-close-popup ()
  "Close a visible popup window, or otherwise run `keyboard-quit'.
A popup window is any non-selected visible window whose buffer name is listed
in `dm-quit-or-close-popup-buffer-names' or starts with one of
`dm-quit-or-close-popup-buffer-prefixes'."
  (interactive)
  (let ((win
         (seq-find
          (lambda (w)
            (and (dm-quit-or-close-popup--popup-buffer-p
                  (window-buffer w))))
          (window-list nil 'no-minibuf (selected-window)))))
    (if win
        (quit-window nil win)
      (keyboard-quit))))

(provide 'dm-popup-quit)
;;; dm-popup-quit.el ends here
