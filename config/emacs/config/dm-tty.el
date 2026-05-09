;;; dm-tty.el --- Daymacs TTY config  -*- lexical-binding: t; -*-

;;; Commentary:

;; Customizations for TTY Emacs, mainly meta keybindings.
;; Assumptions:
;;   - TTY Emacs is run daemonized with a socket name that includes `tty`.
;;

;;; Code:

;; git commit daemon: load magit eagerly
(dm-log :debug "Eager-loading Magit...")
(require 'magit)

(defun dm-pbcut (beg end)
  "Cut region to the system clipboard."
  (interactive "r")
  (unless (use-region-p)
    (user-error "No active region"))
  (call-process-region beg end "pbcopy")
  (delete-region beg end))

(defun dm-pbcopy (beg end)
  "Copy region to the system clipboard."
  (interactive "r")
  (let ((text (buffer-substring-no-properties beg end)))
    (with-temp-buffer
      (insert text)
      (call-process-region (point-min) (point-max) "pbcopy"))))

(defun dm-pbpaste ()
  "Insert the contents of the system clipboard."
  (interactive)
  (insert (shell-command-to-string "pbpaste")))

(use-package general
  :config
  (defun dm-bind-tty-keys (&optional frame)
    "Set up keybindings specific to TTY Emacs."
    (dm-log :debug "Setting up TTY keybindings: %s" server-name)
    (with-selected-frame (or frame (selected-frame))
      (general-define-key
       "M-["   #'previous-buffer
       "M-]"   #'next-buffer
       "M-{"   #'tab-bar-switch-to-prev-tab
       "M-}"   #'tab-bar-switch-to-next-tab
       "M-C-p" #'execute-extended-command-for-buffer
       "M-f"   #'avy-goto-char-2
       "M-g"   #'magit-status
       "M-k"   #'bury-buffer
       "M-K"   #'kill-current-buffer
       "M-n"   #'evil-buffer-new
       "M-t"   #'tab-new
       "M-W"   #'tab-close
       "M-w"   #'dm-delete-window-dwim
       "C-c y" #'dm-pbcopy
       "C-c d" #'dm-pbcut
       "C-c p" #'dm-pbpaste)))
  ;; Run on new frames, and for the initial frame in non-daemonized Emacs
  (add-hook 'after-make-frame-functions #'dm-bind-tty-keys))

;; TODO: idle delay may need tweaking in tty
(use-package which-key
  :defer 0.6
  :config
  (setq which-key-idle-delay 0.15)
  (setq which-key-idle-secondary-delay 0.1))

(provide 'dm-tty)
;;; dm-tty.el ends here
