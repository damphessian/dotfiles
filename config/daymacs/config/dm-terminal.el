;;; dm-terminal.el --- Daymacs terminal setup  -*- lexical-binding: t; -*-

;;; Commentary:

;; Eat terminal setup and paste integration. This is separate from editing
;; because terminal buffers need their own paste semantics.

;;; Code:

(use-package eat
  :hook ((eshell-load . eat-eshell-mode)
         (eat-mode    . dm-disable-line-numbers-h))
  :custom
  (eat-kill-buffer-on-exit t)
  (eat-term-name "xterm-256color")
  :config
  (defun dm-eat--string-for-terminal (text)
    "Return TEXT as a plain string suitable for sending to Eat."
    (let ((string (cond
                   ((stringp text) (copy-sequence text))
                   ((vectorp text) (evil-vector-to-string text))
                   ((null text) "")
                   (t (format "%s" text)))))
      (set-text-properties 0 (length string) nil string)
      string))

  (defun dm-eat--send-string-as-yank (text &optional count)
    "Send TEXT to the current Eat terminal COUNT times."
    (unless eat-terminal
      (user-error "Process not running"))
    (let* ((string (dm-eat--string-for-terminal text))
           (repeat (max 1 (prefix-numeric-value count))))
      (when (> (length string) 0)
        (eat-term-send-string-as-yank
         eat-terminal
         (apply #'concat (make-list repeat string))))))

  (with-eval-after-load 'evil
    (evil-define-command dm-eat-evil-paste-after (count &optional register)
      "Send the current Evil paste text to the Eat terminal."
      :suppress-operator t
      (interactive "P<x>")
      (let ((text (if register
                      (evil-get-register register)
                    (current-kill 0))))
        (setq evil-this-register nil)
        (dm-eat--send-string-as-yank text count)))

    (evil-define-command dm-eat-evil-paste-before (count &optional register)
      "Send the current Evil paste text to the Eat terminal."
      :suppress-operator t
      (interactive "P<x>")
      (dm-eat-evil-paste-after count register)))

  (defun dm-eat-setup-paste-bindings ()
    "Route paste commands through Eat instead of inserting into the buffer."
    (define-key eat-mode-map (kbd "s-v") #'eat-yank)
    (define-key eat-mode-map [remap yank] #'eat-yank)
    (define-key eat-mode-map [remap clipboard-yank] #'eat-yank)
    (define-key eat-semi-char-mode-map (kbd "s-v") #'eat-yank)
    (define-key eat-semi-char-mode-map (kbd "C-y") #'eat-yank)
    (define-key eat-semi-char-mode-map (kbd "S-<insert>") #'eat-yank)
    (define-key eat-semi-char-mode-map [remap yank] #'eat-yank)
    (define-key eat-semi-char-mode-map [remap clipboard-yank] #'eat-yank)
    (define-key eat-char-mode-map (kbd "s-v") #'eat-yank)
    (define-key eat-char-mode-map [remap yank] #'eat-yank)
    (define-key eat-char-mode-map [remap clipboard-yank] #'eat-yank)
    (with-eval-after-load 'evil
      (evil-define-key 'normal eat-mode-map
        (kbd "p") #'dm-eat-evil-paste-after
        (kbd "P") #'dm-eat-evil-paste-before)
      (evil-define-key 'insert eat-mode-map
        (kbd "s-v") #'eat-yank
        (kbd "C-y") #'eat-yank
        (kbd "S-<insert>") #'eat-yank
        [remap yank] #'eat-yank
        [remap clipboard-yank] #'eat-yank)))

  (dm-eat-setup-paste-bindings)
  (with-eval-after-load 'evil-collection-eat
    (dm-eat-setup-paste-bindings)))

(provide 'dm-terminal)
;;; dm-terminal.el ends here
