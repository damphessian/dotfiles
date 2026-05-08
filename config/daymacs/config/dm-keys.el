;;; dm-keys.el --- Daymacs global keymaps  -*- lexical-binding: t; -*-

;;; Commentary:

;; Global and leader keybindings. This module intentionally stays declarative:
;; command implementations live in their domain modules, while this file owns
;; discoverability and the top-level command vocabulary.

;;; Code:

(use-package general
  :config
  ;; Define a SPC leader available in normal, visual, and motion states.
  (general-create-definer leader!
    :states '(normal visual motion)
    :keymaps 'override
    :prefix "SPC")

  (leader!
    ;; Top-level
    "SPC" '(consult-buffer      :which-key "buffers")

    ;; Agent (claude-code-ide / codex-ide, toggled at runtime via SPC a A)
    "a"   '(:ignore t                       :which-key "agent")
    "a a" '(dm-agent-open                   :which-key "show or dismiss")
    "a A" '(dm-toggle-agent                 :which-key "switch agent")
    "a t" '(dm-agent-toggle                 :which-key "toggle window")
    "a c" '(claude-code-ide-continue        :which-key "continue")
    "a r" '(claude-code-ide-resume          :which-key "resume")
    "a l" '(claude-code-ide-list-sessions   :which-key "list sessions")
    "a m" '(claude-code-ide-menu            :which-key "menu")

    ;; Buffers
    "b"   '(:ignore t                   :which-key "buffer")
    "b b" '(consult-buffer              :which-key "switch buffer")
    "b f" '(apheleia-format-buffer      :which-key "format")
    "b d" '(kill-current-buffer         :which-key "kill buffer")

    ;; Directory
    "d"   '(:ignore t                  :which-key "directory")
    "d o" '(dm-directory-open          :which-key "open here")
    "d p" '(dm-directory-open-project  :which-key "open at project root")

    ;; Files
    "f"   '(:ignore t                           :which-key "file")
    "f d" '(dm-delete-this-file                 :which-key "delete")
    "f f" '(consult-fd                          :which-key "find file")
    "f h" '(dm-find-in-home                     :which-key "find in ~")
    "f p" '(dm-open-daymacs-init-in-new-tab     :which-key "emacs init")
    "f r" '(consult-recent-file                 :which-key "recent files")
    "f o" '(dm-file-open                        :which-key "open")
    "f y" '(:ignore t                           :which-key "yank")
    "f y p" '(dm-copy-file-path-dwim            :which-key "path")
    "f y a" '(dm-copy-file-abspath              :which-key "/ path")
    "f y h" '(dm-copy-file-path                 :which-key "~ path")

    ;; Search
    "s"   '(:ignore t                        :which-key "search")
    "s e" '(evil-iedit-state/iedit-mode      :which-key "iedit")
    "s i" '(consult-imenu-multi              :which-key "imenu")
    "s p" '(consult-ripgrep                  :which-key "ripgrep")
    "s s" '(consult-line                     :which-key "line in buffer")

    ;; Jump (avy)
    "j"   '(:ignore t           :which-key "jump")
    "j j" '(avy-goto-char-2     :which-key "2-char")

    ;; Git
    "g"   '(:ignore t                   :which-key "git")
    "g g" '(magit-status                :which-key "magit status")
    "g b" '(magit-blame                 :which-key "magit blame")
    "g t" '(git-timemachine             :which-key "time machine")
    "g n" '(diff-hl-show-hunk-next      :which-key "next hunk")
    "g p" '(diff-hl-show-hunk-previous  :which-key "prev hunk")

    ;; Org
    "o"   '(:ignore t     :which-key "org")
    "o a" '(org-agenda    :which-key "agenda")
    "o c" '(org-capture   :which-key "capture")

    ;; Toggle
    "t"   '(:ignore t          :which-key "toggle")
    "t c" '(copilot-mode       :which-key "copilot")
    "t w" '(dm-wrapping-toggle :which-key "word wrap")

    ;; Workspaces (tabspaces)
    "TAB"   '(:ignore t                    :which-key "workspace")
    "TAB TAB" '(tabspaces-switch-or-create-workspace :which-key "switch/create")
    "TAB n" '(tabspaces-open-or-create-project-and-workspace :which-key "new project")
    "TAB d" '(tabspaces-close-workspace    :which-key "close")
    "TAB r" '(tabspaces-rename-workspace   :which-key "rename")
    "TAB b" '(tabspaces-switch-to-buffer   :which-key "workspace buffer")
    "TAB B" '(tabspaces-move-buffer-to-tab :which-key "move buffer here")

    ;; Project (project.el, built-in)
    "p"   '(:ignore t                  :which-key "project")
    "p d" '(project-dired              :which-key "dired")
    "p p" '(project-switch-project     :which-key "switch project")
    "p f" '(project-find-file          :which-key "find file")
    "p b" '(project-switch-to-buffer   :which-key "project buffer")
    "p k" '(project-kill-buffers       :which-key "kill buffers")
    "p s" '(consult-ripgrep            :which-key "search")

    ;; LSP (eglot)
    "l"   '(:ignore t                             :which-key "lsp")
    "l r" '(eglot-rename                          :which-key "rename")
    "l a" '(eglot-code-actions                    :which-key "actions")
    "l e" '(consult-flymake                       :which-key "errors")
    "l d" '(flymake-show-project-diagnostics      :which-key "diagnostics")

    ;; REPL / tight loop
    "r"   '(:ignore t                  :which-key "repl")
    "r r" '(dm-repl-start-or-pop       :which-key "start/pop")
    "r e" '(dm-repl-eval-dwim          :which-key "eval dwim")
    "r l" '(dm-repl-eval-line          :which-key "eval line")
    "r b" '(dm-repl-eval-buffer        :which-key "eval buffer")
    "r c" '(dm-repl-eval-cell          :which-key "eval cell")
    "r n" '(dm-repl-next-cell          :which-key "next cell")
    "r p" '(dm-repl-previous-cell      :which-key "prev cell")
    "r k" '(dm-repl-check-dwim         :which-key "check")
    "r t" '(dm-repl-test-dwim          :which-key "test dwim")
    "r a" '(dm-repl-test-all           :which-key "test all")

    ;; Windows
    "w"   '(:ignore t                  :which-key "window")
    "w v" '(evil-window-vsplit         :which-key "vertical split")
    "w s" '(evil-window-split          :which-key "horizontal split")
    "w d" '(dm-delete-window-dwim      :which-key "close")
    "w m" '(delete-other-windows       :which-key "maximize")
    "w r" '(dm-window-resize-hydra/body :which-key "resize hydra")
    "w h" '(windmove-left              :which-key "go left")
    "w l" '(windmove-right             :which-key "go right")
    "w j" '(windmove-down              :which-key "go down")
    "w k" '(windmove-up                :which-key "go up"))

  (general-define-key
   "s-["     #'previous-buffer
   "s-]"     #'next-buffer
   "s-{"     #'tab-bar-switch-to-prev-tab
   "s-}"     #'tab-bar-switch-to-next-tab
   "s-P"     #'execute-extended-command
   "s-C-p"   #'execute-extended-command-for-buffer
   "s-f"     #'avy-goto-char-2
   "s-g"     #'magit-status
   "s-t"     #'tab-new
   "s-W"     #'tab-close
   "s-w"     #'dm-delete-window-dwim
   "s-k"     #'kill-current-buffer
   "s-'"     #'eat
   "s-\""    #'eat-project
   "C-,"     #'embark-act
   "C-;"     #'embark-dwim
   "C-g"     #'dm-quit-or-close-popup
   "C-c C-'" #'claude-code-ide-menu))

(use-package which-key
  ;; Displays available key completions after a short delay. Deferred because
  ;; nothing needs it before the first partial key sequence.
  :defer 0.5
  :config
  (which-key-mode 1)
  (setq which-key-idle-delay 0.15)
  (setq which-key-idle-secondary-delay 0.1))

(provide 'dm-keys)
;;; dm-keys.el ends here
