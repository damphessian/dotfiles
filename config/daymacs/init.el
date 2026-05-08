;;; init.el --- -*- lexical-binding: t; -*-

;;; Commentary:

;; A bare-metal Emacs config.
;; Minimal, fast, pragmatic. No fluff.

;;; Code:

;;; ————————————————————————————
;;; straight.el bootstrap
;;; ————————————————————————————

;; pins exact commits, and integrates with use-package via :straight t.
;; Setting straight-use-package-by-default means every use-package form
;; automatically installs via straight unless told otherwise.
(setq straight-use-package-by-default t)

(defvar bootstrap-version)
(let ((bootstrap-file
       (expand-file-name
        "straight/repos/straight.el/bootstrap.el"
        (or (bound-and-true-p straight-base-dir)
            user-emacs-directory)))
      (bootstrap-version 7))
  (unless (file-exists-p bootstrap-file)
    (with-current-buffer
        (url-retrieve-synchronously
         "https://raw.githubusercontent.com/radian-software/straight.el/develop/install.el"
         'silent 'inhibit-cookies)
      (goto-char (point-max))
      (eval-print-last-sexp)))
  (load bootstrap-file nil 'nomessage))

;; use-package is the declaration macro. straight.el handles the installation.
(straight-use-package 'use-package)

;; Use built-in project.el
(straight-use-package '(project :type built-in))

;; Load config directory
(add-to-list 'load-path (expand-file-name "config" user-emacs-directory))

;; Lazy-load `dm-*' modules via a generated `loaddefs.el'. The generator picks
;; up `;;;###autoload' cookies in `config/*.el' and writes one file with all
;; the `(autoload ...)' forms. We rebuild it whenever any source file is newer
;; than the cache, so adding a new module or cookie just works on next boot.
(let* ((config-dir (expand-file-name "config" user-emacs-directory))
       (loaddefs (expand-file-name "loaddefs.el" config-dir))
       (sources (and (file-directory-p config-dir)
                     (directory-files config-dir t "\\`dm-.*\\.el\\'")))
       (stale (or (not (file-exists-p loaddefs))
                  (let ((cached (file-attribute-modification-time
                                 (file-attributes loaddefs))))
                    (seq-some (lambda (f)
                                (time-less-p
                                 cached
                                 (file-attribute-modification-time
                                  (file-attributes f))))
                              sources)))))
  (when stale
    (require 'loaddefs-gen)
    (loaddefs-generate config-dir loaddefs))
  (load loaddefs nil 'nomessage))

;; Eager, cross-cutting setup lives in cohesive modules; command-only helpers
;; keep using autoload cookies and stay out of the startup path.
(require 'dm-core)
(require 'dm-ui)
(require 'dm-evil)
(require 'dm-window)
(require 'dm-completion)
(require 'dm-editing)
(require 'dm-vcs)

;;; ————————————————————————————
;;; ENV vars
;;; ————————————————————————————

(use-package exec-path-from-shell
  :if (memq window-system '(mac ns x))
  :defer 0.1
  :custom
  (exec-path-from-shell-variables
   '("DOCKER_HOST"
     "GIT_CG_PROVIDER"
     "GOPATH"
     "HEX_HOME"
     "IPYTHONDIR"
     "MANPATH"
     "MISE_DIR"
     "OLLAMA_API_KEY"
     "OPENAI_API_KEY"
     "OPENAI_API_KEY_GIT"
     "ORG_HOME"
     "PATH"
     "PERL_CPANM_HOME"
     "PNPM_HOME"
     "RUSTUP_HOME"
     "XDG_CACHE_HOME"
     "XDG_CONFIG_DIRS"
     "XDG_CONFIG_HOME"
     "XDG_DATA_HOME"
     "XDG_LOCALS_DIR"
     "XDG_RUNTIME_DIR"
     "XDG_SECURE_DIR"
     "XDG_STATE_HOME"))
  :config
  (exec-path-from-shell-initialize))

;;; ————————————————————————————
;;; Active-agent dispatch (claude-code-ide / codex-ide)
;;; ————————————————————————————

(defvar dm-active-agent 'claude
  "Currently active AI agent: `claude` or `codex`.")

(defun dm-toggle-agent ()
  "Switch active agent between 'claude-code-ide' and 'codex-ide'."
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
     (when-let* ((dir (codex-ide--working-directory))
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

;;; ————————————————————————————
;;; General — leader key bindings
;;; ————————————————————————————

(require 'dm-keys)

;;; ————————————————————————————
;;; eat — terminal emulator
;;; ————————————————————————————

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

;;; ————————————————————————————
;;; codex-ide — OpenAI Codex CLI
;;; ————————————————————————————

(load (expand-file-name "codex-ide" user-emacs-directory) nil 'nomessage)


;;; ————————————————————————————
;;; Copilot — GitHub Copilot inline completions
;;; ————————————————————————————

(use-package copilot
  :straight (:type git :host github :repo "copilot-emacs/copilot.el" :files ("*.el"))
  ;; :hook (prog-mode . copilot-mode) ; disabled by default; toggled via SPC t c
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

;;; ————————————————————————————
;;; claude-code-ide — Claude Code CLI with MCP bridge
;;; ————————————————————————————

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

;;; ————————————————————————————
;;; Org
;;; ————————————————————————————

(use-package org
  ;; Use the ELPA version rather than the built-in one for up-to-date features.
  :straight t
  :hook ((org-mode . dm-disable-line-numbers-h))
  :custom
  ;; Skip the default `org-modules' cascade (ol-doi ol-w3m ol-bbdb ol-bibtex
  ;; ol-docview ol-gnus ol-info ol-irc ol-mhe ol-rmail ol-eww). Loading them
  ;; via `org-load-modules-maybe' on first org-mode activation accounted for
  ;; ~50% of the open cost. Add specific modules back here if a link type
  ;; needs them (e.g. `(ol-info ol-eww)' for info: and eww: links).
  (org-modules nil)
  ;; ORG_HOME is set in env/emacs.sh; fall back to ~/Org.
  (org-directory (or (getenv "ORG_HOME") (expand-file-name "~/Org")))
  (org-agenda-files (list org-directory))
  ;; Visual preferences.
  (org-startup-indented t)      ; indent content under headings
  (org-hide-leading-stars t)    ; show only the last star per heading
  (org-ellipsis " ▾")           ; collapsed subtree indicator
  ;; Capture and logging.
  (org-log-done 'time)          ; timestamp when a TODO is marked DONE
  (org-log-into-drawer t))      ; keep log entries in a LOGBOOK drawer

(use-package evil-org
  ;; Evil keybindings for org: heading navigation, table editing, agenda.
  ;; Adds motions like [[ ]] for headings and gh/gj/gk/gl for outline movement.
  :after (evil org)
  :hook (org-mode . evil-org-mode)
  :config
  ;; Agenda bindings only matter once `org-agenda' loads, which happens
  ;; on first `M-x org-agenda'. Don't pull in evil-org-agenda before then.
  (with-eval-after-load 'org-agenda
    (require 'evil-org-agenda)
    (evil-org-agenda-set-keys)))

;;; ————————————————————————————
;;; Eglot — language server protocol (built-in, Emacs 29+)
;;; ————————————————————————————

(defun dm-eglot-ensure-deferred ()
  "Defer `eglot-ensure' so the buffer becomes interactive immediately.
Eglot's connect call blocks redisplay until the LSP server returns its
`initialize' response. Push it past the find-file critical path."
  (let ((buf (current-buffer)))
    (run-with-idle-timer
     0.5 nil
     (lambda ()
       (when (buffer-live-p buf)
         (with-current-buffer buf (eglot-ensure)))))))

(use-package eglot
  :straight nil
  :init
  ;; eglot's `eglot-code-action-indicator' defcustom picks a glyph by calling
  ;; `char-displayable-p' on a list of unicode chars. On macOS the first such
  ;; call forces a Core Text font scan (~120 ms). Pre-set the variable so the
  ;; defcustom default form is skipped. (The :type form has the same loop and
  ;; runs anyway at load time; that residual is shifted off the critical path
  ;; by the idle-time pre-load below.)
  (setq eglot-code-action-indicator "*")
  :hook ((python-mode        . dm-eglot-ensure-deferred)
         (python-ts-mode     . dm-eglot-ensure-deferred)
         (js-mode            . dm-eglot-ensure-deferred)
         (js-ts-mode         . dm-eglot-ensure-deferred)
         (jsx-ts-mode        . dm-eglot-ensure-deferred)
         (typescript-mode    . dm-eglot-ensure-deferred)
         (typescript-ts-mode . dm-eglot-ensure-deferred)
         (tsx-ts-mode        . dm-eglot-ensure-deferred)
         (go-mode            . dm-eglot-ensure-deferred)
         (go-ts-mode         . dm-eglot-ensure-deferred)
         (rust-mode          . dm-eglot-ensure-deferred)
         (rust-ts-mode       . dm-eglot-ensure-deferred)
         (elixir-mode        . dm-eglot-ensure-deferred)
         (elixir-ts-mode     . dm-eglot-ensure-deferred)
         (heex-ts-mode       . dm-eglot-ensure-deferred)
         (sh-mode            . dm-eglot-ensure-deferred)
         (bash-ts-mode       . dm-eglot-ensure-deferred))
  :custom
  (eglot-autoshutdown t)
  ;; Don't auto-reconnect on crash. The default (3s) creates an infinite
  ;; restart loop when the cause is persistent (e.g. FD exhaustion).
  (eglot-autoreconnect nil)
  ;; Drop the 2 MB JSON-RPC log buffer kept per server; re-enable ad hoc
  ;; when debugging an LSP interaction.
  (eglot-events-buffer-config '(:size 0 :format full))
  :config
  ;; Refuse server-requested file-notify watchers. Each consumes a kqueue
  ;; FD on macOS; dependency-heavy projects exhaust the per-process limit.
  ;; Tradeoff: out-of-Emacs file changes aren't picked up until re-open.
  (cl-defmethod eglot-register-capability
    (_server (_method (eql workspace/didChangeWatchedFiles))
             _id &key _watchers &allow-other-keys)
    nil)

  (add-to-list 'eglot-server-programs
               '((python-mode python-ts-mode)
                 . ("basedpyright-langserver" "--stdio")))

  (when-let* ((elixir-ls-command
               (cond
                ((executable-find "expert")
                 (list (executable-find "expert") "--stdio"))
                ((executable-find "elixir-ls")
                 (list (executable-find "elixir-ls")))
                ((executable-find "language_server.sh")
                 (list (executable-find "language_server.sh"))))))
    (add-to-list 'eglot-server-programs
                 `((elixir-mode elixir-ts-mode heex-ts-mode)
                   . ,elixir-ls-command)))

  ;; Keep basedpyright out of venvs and build dirs and restrict diagnostics
  ;; to open files, so the initial workspace scan stays cheap. Project-wide
  ;; warnings (unused imports across files) only appear once each is opened.
  ;; basedpyright's defaults already exclude **/node_modules, **/__pycache__,
  ;; and **/.* — only non-dot paths need to be listed here.
  (setq-default eglot-workspace-configuration
                '(:python
                  (:analysis
                   (:diagnosticMode "openFilesOnly"
                    :useLibraryCodeForTypes :json-false
                    :exclude ["**/venv" "**/env"
                              "**/dist" "**/build"]))))

  (with-eval-after-load 'evil
    (evil-define-key 'normal eglot-mode-map
      (kbd "K") #'eldoc-doc-buffer)))

;;; ————————————————————————————
;;; REPL / tight feedback loop
;;; ————————————————————————————

(dolist (hook '(python-base-mode-hook
                elixir-mode-hook
                elixir-ts-mode-hook
                rust-mode-hook
                rust-ts-mode-hook
                js-mode-hook
                js-ts-mode-hook
                jsx-ts-mode-hook
                typescript-mode-hook
                typescript-ts-mode-hook
                tsx-ts-mode-hook))
  (add-hook hook #'dm-repl-local-keybindings))

;; Pre-load eglot just after startup so the one-time cold-load costs (the
;; `char-displayable-p' font probe in its defcustom :type, plus the require
;; cascade) are paid before any file open. `run-with-idle-timer' isn't
;; reliable here — it never fires if the user starts working immediately.
;; Use a fixed-delay timer scheduled from `emacs-startup-hook' so it fires
;; ~0.5 s after the frame is up regardless of idle state.
(add-hook 'emacs-startup-hook
          (lambda ()
            (run-with-timer 0.5 nil (lambda () (require 'eglot)))))

;; Pre-warm the `dm-find-in-home' directory cache so stage 1 is instant
;; after the first second of startup. Same fixed-timer pattern as eglot.
(add-hook 'emacs-startup-hook
          (lambda ()
            (run-with-timer 1 nil #'dm-find-in-home--refresh-cache)))

;; Pre-load org so the first `.org' file open doesn't pay the ~300 ms
;; internal require cascade (org-element, ol, oc, …). Same fixed-timer
;; pattern as eglot — `run-with-idle-timer' wouldn't fire if the user
;; jumped straight into a file. Slightly later than eglot since org is
;; heavier and there's no rush to have it ready.
(add-hook 'emacs-startup-hook
          (lambda ()
            (run-with-timer 1.5 nil (lambda () (require 'org)))))

;;; ————————————————————————————
;;; Tree-sitter — structural syntax (built-in, Emacs 29+)
;;; ————————————————————————————

(use-package treesit-auto
  ;; Auto-installs tree-sitter grammars and remaps major modes to *-ts-mode.
  ;; Deferred to idle: the first file opened within ~0.5s of startup may
  ;; land in the non-ts major mode, which is acceptable. Memoization advice
  ;; on `treesit-auto--build-major-mode-remap-alist' below cuts the
  ;; once-per-find-file cost.
  :defer 0.5
  :custom
  (treesit-auto-install t)
  :config
  (treesit-auto-add-to-auto-mode-alist 'all)
  (global-treesit-auto-mode 1)
  (setq treesit-language-source-alist
        '((bash "https://github.com/tree-sitter/tree-sitter-bash")
          (cmake "https://github.com/uyha/tree-sitter-cmake")
          (css "https://github.com/tree-sitter/tree-sitter-css")
          (elisp "https://github.com/Wilfred/tree-sitter-elisp")
          (elixir "https://github.com/elixir-lang/tree-sitter-elixir")
          (go "https://github.com/tree-sitter/tree-sitter-go")
          (heex "https://github.com/phoenixframework/tree-sitter-heex")
          (html "https://github.com/tree-sitter/tree-sitter-html")
          (javascript "https://github.com/tree-sitter/tree-sitter-javascript" "master" "src")
          (json "https://github.com/tree-sitter/tree-sitter-json")
          (make "https://github.com/alemuller/tree-sitter-make")
          (markdown "https://github.com/ikatyang/tree-sitter-markdown")
          (python "https://github.com/tree-sitter/tree-sitter-python")
          (rust "https://github.com/tree-sitter/tree-sitter-rust")
          (toml "https://github.com/tree-sitter/tree-sitter-toml")
          (tsx "https://github.com/tree-sitter/tree-sitter-typescript" "master" "tsx/src")
          (typescript "https://github.com/tree-sitter/tree-sitter-typescript" "master" "typescript/src")
          (yaml "https://github.com/ikatyang/tree-sitter-yaml"))))

(defun dm-treesit-install-all-languages ()
  "Install all Tree-sitter grammars defined in `treesit-language-source-alist'."
  (interactive)
  (dolist (lang treesit-language-source-alist)
    (let ((lang-symbol (car lang)))
      (unless (treesit-language-available-p lang-symbol)
        (treesit-install-language-grammar lang-symbol)))))

(use-package treesit-fold
  ;; Structural folding for tree-sitter modes; integrates with Evil's z* folds
  ;; when `treesit-fold-mode' is active in the buffer.
  :straight (treesit-fold :type git
                          :host github
                          :repo "emacs-tree-sitter/treesit-fold")
  :after treesit-auto
  :config
  (global-treesit-fold-mode 1))

(provide 'init)
;;; init.el ends here
