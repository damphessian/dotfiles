;;; dm-cli.el --- Daymacs CLI editor profile  -*- lexical-binding: t; -*-

;;; Commentary:

;; Terminal-only tweaks for editor sessions launched through the git editor
;; wrapper. Keep this profile narrow so the GUI Daymacs setup stays unchanged.

;;; Code:

(declare-function dm-magit-commit-generate "dm-magit")

(defun dm-cli-commit-buffer-setup ()
  "Apply terminal-friendly defaults in commit-editing buffers."
  (setq-local fill-column 72)
  (setq-local truncate-lines nil)
  ;; `with-editor' saves the previous window configuration before switching to
  ;; the commit buffer. In a single-purpose terminal client that configuration
  ;; is usually just *scratch*, so do not restore it after finish/cancel.
  (when (boundp 'with-editor-previous-winconf)
    (setq-local with-editor-previous-winconf nil))
  (visual-line-mode 1)
  (when (fboundp 'display-line-numbers-mode)
    (display-line-numbers-mode -1))
  (when (bound-and-true-p hl-line-mode)
    (hl-line-mode -1)))

(with-eval-after-load 'git-commit
  ;; Git commit buffers inherit the terminal editor profile, so keep them
  ;; compact and make the message generator easy to reach from the keyboard.
  (add-hook 'git-commit-mode-hook #'dm-cli-commit-buffer-setup 95))

(with-eval-after-load 'with-editor
  ;; Rebase todo buffers and other with-editor sessions should keep the same
  ;; low-noise defaults as commit buffers.
  (add-hook 'with-editor-mode-hook #'dm-cli-commit-buffer-setup 95))

(general-define-key
 "M-["  #'previous-buffer
 "M-]"  #'next-buffer
 "M-{"  #'tab-bar-switch-to-prev-tab
 "M-}"  #'tab-bar-switch-to-next-tab
 "M-t"  #'tab-new
 "M-W"  #'tab-close
 "M-w"  #'dm-delete-window-dwim)

(provide 'dm-cli)
;;; dm-cli.el ends here
