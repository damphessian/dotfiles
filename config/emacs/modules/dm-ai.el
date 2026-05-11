;;; dm-ai.el --- Daymacs AI assistant integrations  -*- lexical-binding: t; -*-

;;; Commentary:

;; Agent dispatch and package setup for Codex, Claude Code, and Copilot. The
;; leader map consumes the generic `dm-agent-*' commands defined here.

;;; Code:

(defvar dm-active-agent 'claude
  "Currently active AI agent: `claude' or `codex'.")

(defun dm-toggle-agent ()
  "Switch active agent between `claude-code-ide' and `codex-ide'."
  (interactive)
  (setq dm-active-agent
        (if (eq dm-active-agent 'claude) 'codex 'claude))
  (message "Active agent: %s" dm-active-agent))

(defun dm-active-agent-window ()
  "Return the active agent window for the current project, if visible.
NOTE: speculative."
  (pcase dm-active-agent
    ('claude
     (when-let* ((buf (get-buffer (claude-code-ide--get-buffer-name))))
       (get-buffer-window buf t)))
    ('codex
     (when-let* ((dir (dm-util-working-dir))
                 (buf (get-buffer (codex-ide--buffer-name dir))))
       (get-buffer-window buf t)))))

(defun dm-focus-active-agent-window ()
  "Move focus to the active agent window when it is visible.
NOTE: speculative."
  (when-let* ((win (dm-active-agent-window)))
    (select-window win)))

(defun dm-agent-open ()
  "Show the active AI agent, or dismiss its window when already visible."
  (interactive)
  (if (dm-active-agent-window)
      (dm-agent-toggle)
    (if (eq dm-active-agent 'claude)
        (claude-code-ide)
      (codex-ide))))

(defun dm-agent-toggle ()
  "Toggle the active AI agent's window."
  (interactive)
  (if (eq dm-active-agent 'claude)
      (claude-code-ide-toggle)
    (codex-ide-toggle)))

(use-package copilot
  :straight (:type git :host github :repo "copilot-emacs/copilot.el" :files ("*.el"))
  ;; Disabled by default; toggled via SPC t c.
  :commands copilot-mode
  :bind (:map copilot-completion-map
              ;; Fish-style bindings avoid stealing TAB from Corfu and indentation.
              ("<return>"   . copilot-accept-completion)
              ("C-f"        . copilot-accept-completion)
              ("M-<right>"  . copilot-accept-completion-by-word)
              ("M-f"        . copilot-accept-completion-by-word)
              ("C-e"        . copilot-accept-completion-by-line)
              ("<end>"      . copilot-accept-completion-by-line)
              ("C-n"        . copilot-next-completion)
              ("C-p"        . copilot-previous-completion)
              ("C-g"        . copilot-clear-overlay))
  :init
  (defun dm-copilot-disable-predicate ()
    "Return non-nil when Copilot should stay quiet in the current buffer."
    (or (minibufferp)
        buffer-read-only
        (not buffer-file-name)
        (file-remote-p default-directory)
        (derived-mode-p 'special-mode
                        'comint-mode
                        'term-mode
                        'eat-mode
                        'eshell-mode)))
  :config
  (setq copilot-indent-offset-warning-disable t)
  (add-to-list 'copilot-disable-predicates #'dm-copilot-disable-predicate))

(use-package claude-code-ide
  :straight (:type git :host github :repo "manzaltu/claude-code-ide.el")
  :commands (claude-code-ide
             claude-code-ide-toggle
             claude-code-ide-continue
             claude-code-ide-resume
             claude-code-ide-list-sessions
             claude-code-ide-menu
             claude-code-ide--get-buffer-name)
  :custom
  (claude-code-ide-terminal-backend 'eat)
  (claude-code-ide-window-side 'right)
  (claude-code-ide-window-width 100)
  (claude-code-ide-diagnostics-backend 'auto)
  :config
  (claude-code-ide-emacs-tools-setup))

(provide 'dm-ai)
;;; dm-ai.el ends here
