;;; dm-tty.el --- Daymacs TTY config  -*- lexical-binding: t; -*-

;;; Commentary:

;; Customizations for TTY Emacs, mainly meta keybindings.
;; Assumptions:
;;   - TTY Emacs is run daemonized with a socket name that includes `tty`.
;;

;;; Code:

(use-package general
  :config
  (defun dm-bind-tty-keys (&optional frame)
    "Set up keybindings specific to TTY Emacs."
    (with-selected-frame (or frame (selected-frame))
      (when (dm-designated-tty-daemon-p)
        (dm-log :debug "Setting up TTY keybindings: %s" server-name)
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
         "M-w"   #'dm-delete-window-dwim))))
  ;; Run on new frames, and for the initial frame in non-daemonized Emacs
  (add-hook 'after-make-frame-functions #'dm-bind-tty-keys))

;; TODO: idle delay may need tweaking in tty
(use-package which-key
  :defer 0.6
  :config
  (setq which-key-idle-delay 0.15)
  (setq which-key-idle-secondary-delay 0.1))

;; git commit daemon: load magit eagerly
(when (dm-designated-tty-daemon-p)
  (dm-log :debug "Eager-loading Magit...")
  (require 'magit))

(provide 'dm-tty)
;;; dm-tty.el ends here
