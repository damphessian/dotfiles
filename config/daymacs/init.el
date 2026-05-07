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


;;; ————————————————————————————
;;; Utility functions
;;; ————————————————————————————

(require 'dm-text)
(require 'dm-files)

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

(defun dm-wrapping-disable ()
  "Disable visual wrapping in the current buffer."
  (interactive)
  (visual-line-mode -1)
  (when (fboundp 'visual-fill-column-mode)
    (visual-fill-column-mode -1))
  (setq-local word-wrap nil)
  (setq-local truncate-lines t)
  (recenter))

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

(defun dm-find-in-home ()
  "Two-stage `fd' selection for directory and file within $HOME."
  (interactive)
  (let* ((home (expand-file-name "~"))
         (default-directory home)
         (find-dir  "fd . --max-depth 10 --type directory --hidden")
         (find-file "fd . --max-depth 3 --type file --type symlink --hidden")
         (dirs (split-string (shell-command-to-string find-dir) "\n" t))
         (choice-dir (completing-read "Directory: " dirs nil t)))
    (when (and choice-dir (not (string-empty-p choice-dir)))
      (let* ((default-directory (expand-file-name (format "~/%s" choice-dir)))
             (files (split-string (shell-command-to-string find-file) "\n" t))
             (choice-file (completing-read "File: " files nil t)))
        (when (and choice-file (not (string-empty-p choice-file)))
          (find-file choice-file))))))

;;; ————————————————————————————
;;; Popup window dismissals
;;; ————————————————————————————
(require 'dm-popup-quit)

(setq dm-quit-or-close-popup-buffer-names
      '("*compilation*" "*Messages*" "*Warnings*" "*Help*"))

(setq dm-quit-or-close-popup-buffer-prefixes
      '("*Flycheck" "*Embark Collect" "*xref"))

;;; ————————————————————————————
;;; Test/Implementation Toggle
;;; ————————————————————————————
(require 'dm-test-toggle)
(with-eval-after-load 'evil
  (evil-define-command dm-evil-toggle-test-implementation ()
    "Toggle between implementation and test file."
    :repeat nil
    (dm-toggle-test-implementation))
  (evil-ex-define-cmd "A" #'dm-evil-toggle-test-implementation)
  (global-set-key (kbd "C-c t") #'dm-toggle-test-implementation))

;;; ————————————————————————————
;;; Core Emacs settings
;;; ————————————————————————————

;; Prefer UTF-8 everywhere.
(set-language-environment "UTF-8")
(set-default-coding-systems 'utf-8)

;; Enable editorconfig mode (assumes Emacs >= 30)
(editorconfig-mode 1)

;; Redirect backups to a single directory instead of littering alongside files.
(setq backup-directory-alist `(("." . ,(concat user-emacs-directory "backups")))
      backup-by-copying t       ; don't clobber symlinks
      version-control t         ; numbered backup files
      delete-old-versions t)

;; Auto-save files also go to a dedicated directory.
(setq auto-save-file-name-transforms
      `((".*" ,(concat user-emacs-directory "auto-save/") t)))

;; Lock files (.#foo) are only useful for multi-user editing; skip them.
(setq create-lockfiles nil)

;; Track recently visited files; used by consult-recent-file.
(setq recentf-auto-cleanup "11:00pm")
(let ((inhibit-message t)
      (message-log-max nil))
  (recentf-mode 1))
(setq recentf-max-saved-items 200)

;; Persist minibuffer history (commands, searches, consult inputs)
;; across sessions.
(savehist-mode 1)
(setq history-length 300)

;; Relative line numbers match evil's jump-count workflow (e.g. 5j, 12k).
(setq display-line-numbers-type 'relative)
(global-display-line-numbers-mode 1)

;; Highlight matching parens immediately.
(setq show-paren-delay 0)
(show-paren-mode 1)

;; Single space after sentences — affects fill-paragraph.
(setq sentence-end-double-space nil)

;; Silence the audible bell entirely.
(setq ring-bell-function #'ignore)

;; Follow symlinks to version-controlled files without prompting.
(setq vc-follow-symlinks t)

;; Drop legacy and hipster VCS integrations you don't use.
(setq-default vc-handled-backends '(Git))

;; Empty scratch buffer on launch (inhibit-startup-screen is in early-init.el).
(setq initial-scratch-message nil)

;; Use spaces for alignment, truncate lines by default
(setq-default indent-tabs-mode nil)
(setq-default tab-width 8)
(setq-default truncate-lines t)
(setq-default fill-column 80)

;; Display column number in the modeline
(column-number-mode)

;; delete by moving to trash
(setq delete-by-moving-to-trash t)

(defconst dm-git-commit-filename-regexp
  "/\\(?:\\(?:\\(?:COMMIT\\|NOTES\\|PULLREQ\\|MERGEREQ\\|TAG\\)_EDIT\\|MERGE_\\|\\)MSG\\|\\(?:BRANCH\\|EDIT\\)_DESCRIPTION\\)\\'"
  "Regexp matching Git message files that `git-commit' edits.")

(defun dm-git-commit-file-p (&optional file)
  "Return non-nil when FILE or the current buffer is a Git message file."
  (let ((path (or file buffer-file-name)))
    (and path
         (string-match-p dm-git-commit-filename-regexp path))))

;; Show project name in title bar, falling back to buffer name.
(defun dm-frame-title-project-or-buffer ()
  "Show project name in title bar, falling back to buffer name."
  (if-let* ((proj (project-current)))
      (project-name proj)
    (buffer-name)))

(setq frame-title-format
      '((:eval
         (dm-frame-title-project-or-buffer))))

(defun dm-open-daymacs-init-in-new-tab ()
  "Open the Daymacs init.el file in a new tab."
  (interactive)
  (tab-new)
  (find-file (expand-file-name "init.el" user-emacs-directory)))

;;; ————————————————————————————
;;; Appearance
;;; ————————————————————————————

(set-face-attribute 'default nil :family "Source Code Pro" :height 180)

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

;;; ————————————————————————————
;;; Evil — vi keybindings
;;; ————————————————————————————

(use-package evil
  :init
  ;; These must be set before evil loads.
  (setq evil-echo-state nil)
  (setq evil-respect-visual-line-mode t) ; j/k act like gj/gk when VL mode enabled
  (setq evil-split-window-below  t)
  (setq evil-undo-system 'undo-redo) ; use native Emacs 28+ undo/redo
  (setq evil-vsplit-window-right t)
  (setq evil-want-C-u-scroll nil)
  (setq evil-want-integration t)
  (setq evil-want-keybinding nil)    ; evil-collection provides these instead
  :config
  (evil-mode 1)
  (require 'dm-evil-text)
  (dm-evil-text-setup))

(use-package evil-collection
  ;; Provides sensible evil keybindings for magit, dired, help, ibuffer, etc.
  ;; Must load after evil.
  :after evil
  :config
  (evil-collection-init))

(use-package evil-commentary
  :after evil
  :config
  (evil-commentary-mode))

(use-package evil-numbers
  :after evil
  :config
  (evil-define-key 'normal 'global
    (kbd "g-") #'evil-numbers/dec-at-pt
    (kbd "g=") #'evil-numbers/inc-at-pt))

(use-package evil-surround
  :after evil
  :config
  (global-evil-surround-mode 1))

(use-package evil-embrace
  :after evil-surround
  :config
  (with-eval-after-load 'org
    (add-hook 'org-mode-hook 'embrace-org-mode-hook))
  (evil-embrace-enable-evil-surround-integration))

(use-package evil-iedit-state
  :after evil)

(use-package avy
  :after evil
  :hook
  (org-mode . avy-setup-default)
  :custom
  (avy-keys '(?a ?s ?d ?f ?g ?h ?j ?k ?l))
  (avy-style 'at-full))

(use-package evil-lion
  :after evil
  :config
  (setq evil-lion-left-align-key (kbd "g l"))
  (setq evil-lion-right-align-key (kbd "g L"))
  (evil-lion-mode 1))

(use-package evil-snipe
  ;; Extends s/S to 2-char sneak motions (like vim-sneak/leap).
  ;; Disabled in modes where evil-collection claims s/S.
  :after evil
  :config
  (evil-snipe-mode 1)
  (evil-snipe-override-mode 1)
  (add-to-list 'evil-snipe-disabled-modes 'magit-mode)
  (add-to-list 'evil-snipe-disabled-modes 'Info-mode))

(use-package evil-visualstar
  :after evil
  :config
  (global-evil-visualstar-mode))

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

(defun dm-dired-jump-keybindings ()
  "Bind - to `dired-jump' in Evil normal state."
  (evil-local-set-key 'normal (kbd "-") #'dired-jump))

(defun dm-text-formatting-keybindings ()
  "Bind Super text-formatting commands in the current buffer."
  (dolist (state '(normal visual insert))
    (evil-local-set-key state (kbd "s-b") #'dm-text-make-bold)
    (evil-local-set-key state (kbd "s-i") #'dm-text-make-italic)
    (evil-local-set-key state (kbd "s-u") #'dm-text-make-underlined)
    (evil-local-set-key state (kbd "s-X") #'dm-text-make-strikethrough)))

(dolist (hook '(LaTeX-mode-hook
                latex-mode-hook
                markdown-mode-hook
                gfm-mode-hook
                org-mode-hook))
  (add-hook hook #'dm-text-formatting-keybindings))

(defun dm-text-latex-keybindings ()
  "Bind latex-formatting commands in the current buffer."
  (dolist (state '(visual))
    (evil-local-set-key state (kbd "C-b") #'dm-text-latex-wrap-as-boxed)
    (evil-local-set-key state (kbd "C-f") #'dm-text-latex-wrap-as-frac)
    (evil-local-set-key state (kbd "C-e") #'dm-text-latex-evaluate-selection)
    (evil-local-set-key state (kbd "C-m") #'dm-text-latex-wrap-as-math)
    (evil-local-set-key state (kbd "C-s") #'dm-text-latex-wrap-as-si)))

(dolist (hook '(LaTeX-mode-hook latex-mode-hook))
  (add-hook hook #'dm-text-latex-keybindings))

;;; ————————————————————————————
;;; ENV vars
;;; ————————————————————————————

(use-package exec-path-from-shell
  :if (memq window-system '(mac ns x))
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
;;; Hydra — transient keymaps
;;; ————————————————————————————

(use-package hydra
  ;; Repeatable keymaps for commands you want to apply several times in a row.
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

;;; ————————————————————————————
;;; General — leader key bindings
;;; ————————————————————————————

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


    ;; Files
    "f"   '(:ignore t                           :which-key "file")
    "f d" '(dm-delete-this-file                 :which-key "delete")
    "f f" '(consult-fd                          :which-key "find file")
    "f h" '(dm-find-in-home                     :which-key "find in ~")
    "f p" '(dm-open-daymacs-init-in-new-tab     :which-key "emacs init")
    "f r" '(consult-recent-file                 :which-key "recent files")

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

    ;; Project (project.el — built-in)
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
    "l d" '(flymake-show-project-diagnostics      :which-key "diagnostics")

    ;; Windows
    "w"   '(:ignore t                  :which-key "window")
    "w v" '(evil-window-vsplit         :which-key "vertical split")
    "w s" '(evil-window-split          :which-key "horizontal split")
    "w d" '(dm-delete-window-dwim         :which-key "close")
    "w m" '(delete-other-windows       :which-key "maximize")
    "w r" '(dm-window-resize-hydra/body :which-key "resize hydra")
    "w h" '(windmove-left              :which-key "go left")
    "w l" '(windmove-right             :which-key "go right")
    "w j" '(windmove-down              :which-key "go down")
    "w k" '(windmove-up                :which-key "go up"))

  (general-define-key
   "s-["   #'previous-buffer
   "s-]"   #'next-buffer
   "s-{"   #'tab-bar-switch-to-prev-tab
   "s-}"   #'tab-bar-switch-to-next-tab
   "s-P"   #'execute-extended-command
   "s-C-p" #'execute-extended-command-for-buffer
   "s-f"   #'avy-goto-char-2
   "s-g"   #'magit-status
   "s-t"   #'tab-new
   "s-W"   #'tab-close
   "s-w"   #'dm-delete-window-dwim
   "s-k"   #'kill-current-buffer
   "s-'"   #'eat
   "C-,"   #'embark-act
   "C-;"   #'embark-dwim
   "C-g"     #'dm-quit-or-close-popup
   "C-c C-'" #'claude-code-ide-menu))

;;; ————————————————————————————
;;; which-key — keybinding hints
;;; ————————————————————————————

(use-package which-key
  ;; Displays available key completions in a popup after a short delay.
  ;; Essential while building muscle memory for the leader bindings above.
  :config
  (which-key-mode 1)
  (setq which-key-idle-delay 0.15)
  (setq which-key-idle-secondary-delay 0.1))

;;; ————————————————————————————
;;; Vertico — minibuffer completion UI
;;; ————————————————————————————

(use-package vertico
  ;; Replaces the default horizontal completion with a clean vertical list.
  :custom
  (vertico-cycle t)
  :config
  (vertico-mode 1))

(use-package vertico-multiform
  ;; Built-in Vertico extension for per-command/category display styles.
  :straight nil
  :after vertico
  :custom
  ;; M-B -> `vertico-multiform-buffer'
  ;; M-F -> `vertico-multiform-flat'
  ;; M-G -> `vertico-multiform-grid'
  ;; M-R -> `vertico-multiform-reverse'
  ;; M-U -> `vertico-multiform-unobtrusive'
  ;; M-V -> `vertico-multiform-vertical'
  (vertico-multiform-commands
   '((consult-find buffer)
     (consult-git-grep buffer)
     (consult-grep buffer)
     (consult-imenu buffer)
     (consult-imenu-multi buffer)
     (consult-line unobtrusive)
     (consult-outline buffer)
     (consult-org-heading buffer)
     (consult-ripgrep buffer)
     (project-find-file grid))
   vertico-multiform-categories
   '((file grid)))
  :config
  (vertico-reverse-mode)
  (vertico-mouse-mode 1)
  (vertico-multiform-mode 1))

;; Unstable:
;; > Personally I am critical of using child frames for minibuffer completion. From my experience it introduces more problems than it solves. Most importantly child frames hide the content of the underlying buffer. Furthermore child frames do not play well together with changing windows and entering recursive minibuffer sessions. On top, child frames can feel slow and sometimes flicker.
;; https://github.com/minad/vertico#child-frames-and-popups
;;
;; (use-package mini-frame
;;   :config
;;   (defun dm-mini-frame-clamped-dimensions ()
;;     (let* ((parent (selected-frame))
;;            (frame-cols (frame-parameter parent 'width)) ; in columns
;;            (desired (* 0.9 frame-cols))
;;            (max-cols 120)
;;            (width (min desired max-cols)))
;;       `((top . 0.15)
;;         (left . 0.5)
;;         (width . ,(truncate width))
;;         (child-frame-border-width . 1)
;;         (left-fringe . 25)
;;         (right-fringe . 25)
;;         (background-color . ,(face-attribute 'default :background)))))
;;   (setq mini-frame-show-parameters #'dm-mini-frame-clamped-dimensions)
;;   (set-face-attribute 'child-frame-border nil :background (face-attribute 'mode-line :foreground))
;;   (mini-frame-mode 1))

(use-package orderless
  ;; Matching style: space-separated components match in any order.
  ;; e.g. "foo bar" finds "bar-foo" and "foobar-baz".
  ;; The override for 'file keeps basic prefix matching for path completion,
  ;; where orderless can otherwise interfere with / separators.
  :ensure t
  :custom
  (completion-styles '(orderless basic))
  (completion-category-overrides '((file (styles partial-completion))))
  (completion-pcm-leading-wildcard t)) ;; Emacs 31: partial-completion behaves like substring

(use-package consult
  ;; Rich completion commands: consult-ripgrep, consult-find, consult-buffer,
  ;; consult-line, consult-recent-file, etc. Integrates with vertico.
  :config
  ;; Avoid jumping through target buffers while scrolling search candidates.
  ;; Press M-. on a candidate to preview it explicitly.
  (consult-customize
   consult-ripgrep
   consult-grep
   consult-git-grep
   :preview-key "M-."))

(defun dm-search-project-for-symbol-at-point ()
  "Search the current project for the symbol at point."
  (interactive)
  (let ((symbol (thing-at-point 'symbol t)))
    (consult-ripgrep
     (project-root (project-current t))
     symbol)))

(with-eval-after-load 'evil
  (evil-define-key 'normal 'global
    (kbd "SPC *") #'dm-search-project-for-symbol-at-point))

(use-package marginalia
  ;; Adds annotations to completion candidates: file sizes, docstrings,
  ;; command key bindings, etc. Works with any completing-read UI.
  :config
  (marginalia-mode 1))

(use-package embark-consult
  ;; Register the integration package before Embark loads so Embark's
  ;; startup check can `require' it without warning.
  :after (embark consult)
  :hook (embark-collect-mode . consult-preview-at-point-mode))

(use-package embark
  ;; "Act on this candidate" layer for any completing-read UI.
  ;; C-, on any vertico candidate: open in other window, copy, delete, etc.
  :after general)

(use-package wgrep
  ;; Edit consult-ripgrep results in-buffer, then apply across all files.
  ;; In a grep results buffer: C-c C-p to enter edit mode, C-c C-c to apply.
  :custom
  (wgrep-auto-save-buffer t))

;;; ————————————————————————————
;;; Tabspaces — per-tab buffer isolation
;;; ————————————————————————————

(use-package tabspaces
  :config
  (tabspaces-mode 1)
  :custom
  (tabspaces-use-filtered-buffers-as-default t)
  (tabspaces-default-tab "main")
  (tabspaces-remove-to-default t)
  (tabspaces-include-buffers '("*scratch*")))

;; Filter consult-buffer to show only current-workspace buffers.
;; Nested with-eval-after-load ensures both packages are fully loaded
;; before consult--source-buffer is customized.
(with-eval-after-load 'consult
  (with-eval-after-load 'tabspaces
    (consult-customize consult-source-buffer :hidden t :default nil)
    (defvar consult--source-workspace
      (list :name     "Workspace buffers"
            :narrow   ?w
            :history  'buffer-name-history
            :category 'buffer
            :state    #'consult--buffer-state
            :default  t
            :items    (lambda ()
                        (consult--buffer-query
                         :predicate #'tabspaces--local-buffer-p
                         :sort 'visibility
                         :as #'buffer-name))))
    (add-to-list 'consult-buffer-sources 'consult--source-workspace)))

;;; ————————————————————————————
;;; Dired
;;; ————————————————————————————

(use-package dired
  :straight nil
  :after evil
  :init
  (autoload 'dired-jump "dired-x" nil t)
  :hook ((prog-mode . dm-dired-jump-keybindings)
         (text-mode . dm-dired-jump-keybindings)
         (sgml-mode . dm-dired-jump-keybindings)))

;;; ————————————————————————————
;;; Markdown
;;; ————————————————————————————

(use-package visual-fill-column
  :hook ((markdown-mode . visual-line-mode)
         (markdown-mode . visual-fill-column-mode))
  :custom
  (visual-fill-column-width 80))

(use-package markdown-mode
  :hook ((markdown-mode . outline-minor-mode)
         (markdown-mode . dm-disable-line-numbers-h)
         (gfm-mode . outline-minor-mode)
         (gfm-mode . dm-disable-line-numbers-h))
  :mode (("\\.md\\'" . gfm-mode)
         ("\\.markdown\\'" . gfm-mode)))

;;; ————————————————————————————
;;; Git
;;; ————————————————————————————

(defun dm-skip-treesit-auto-for-git-commit-file-a (fn &rest args)
  "Skip `treesit-auto' remap setup for transient Git message buffers.
FN and ARGS are the advised `treesit-auto--set-major-remap' arguments."
  (unless (dm-git-commit-file-p)
    (apply fn args)))

(with-eval-after-load 'treesit-auto
  ;; `treesit-auto' advises `set-auto-mode-0', which sits on the
  ;; `git-commit-setup' path via `normal-mode'. Doom doesn't use this package,
  ;; and the targeted tracer shows the hand-rolled config is spending most of
  ;; its extra time in the unwrapped portion of `git-commit-setup'.
  (advice-add #'treesit-auto--set-major-remap
              :around #'dm-skip-treesit-auto-for-git-commit-file-a))

;;; ————————————————————————————
;;; Magit (TODO: extract)
;;; ————————————————————————————

(defvar dm-magit-pending-generated-commit-message nil
  "Generated commit message waiting to be inserted into a commit buffer.")

(defun dm-git-commit-message-region-end ()
  "Return end of editable commit message area before Git comment template."
  (save-excursion
    (goto-char (point-min))
    (if (re-search-forward "^#" nil t)
        (line-beginning-position)
      (point-max))))

(defun dm-git-commit-insert-pending-generated-message ()
  "Insert pending generated commit message into the current commit buffer."
  (when dm-magit-pending-generated-commit-message
    (let ((message dm-magit-pending-generated-commit-message))
      (setq dm-magit-pending-generated-commit-message nil)
      (goto-char (point-min))
      (delete-region (point-min) (dm-git-commit-message-region-end))
      (insert message)
      (unless (string-suffix-p "\n" message)
        (insert "\n"))
      (goto-char (point-min)))))

(defun dm-git-commit-generated-message (&optional steering)
  "Return a generated commit message for the staged diff.
Optionally, a string STEERING can be provided to tailor the content."
  (let* ((default-directory (magit-toplevel))
         (args (append '("--message-only")
                       (unless (string-empty-p steering)
                         (list steering)))))
    (with-temp-buffer
      (let ((exit-code
             (apply #'process-file "git-commit-generator" nil t nil args)))
        (unless (zerop exit-code)
          (error "Git commit generator failed:\n%s" (buffer-string)))
        (string-trim (buffer-string))))))

(defun dm-magit-commit-generate ()
  "Generate a commit message, then open Magit's commit buffer."
  (interactive)
  (let ((steering (read-string "Steering, optional: ")))
    (setq dm-magit-pending-generated-commit-message
          (dm-git-commit-generated-message steering))
    (magit-commit-create)))

(defun dm-magit-display-buffer-fn (buffer)
  "Display Magit BUFFER with less window churn.
This follows Doom's strategy closely enough for the status-to-commit
transition: reuse the current window for most non-diff buffers and keep
process buffers below the selected window."
  (let ((buffer-mode (buffer-local-value 'major-mode buffer)))
    (display-buffer
     buffer
     (cond
      ((and (eq buffer-mode 'magit-status-mode)
            (get-buffer-window buffer))
       '(display-buffer-reuse-window))
      ((or (bound-and-true-p git-commit-mode)
           (eq buffer-mode 'magit-process-mode)
           (eq major-mode 'magit-log-select-mode))
       (let ((size (if (eq buffer-mode 'magit-process-mode) 0.35 0.7)))
         `(display-buffer-below-selected
           . ((window-height . ,(truncate (* (window-height) size)))))))
      ((or (not (derived-mode-p 'magit-mode))
           (and (eq major-mode 'magit-status-mode)
                (memq buffer-mode '(magit-diff-mode magit-stash-mode)))
           (not (memq buffer-mode
                      '(magit-process-mode
                        magit-revision-mode
                        magit-stash-mode
                        magit-status-mode))))
       '(display-buffer-same-window))
      (t
       '(display-buffer-pop-up-window))))))

(defun dm-git-commit-disable-completion ()
  "Disable dabbrev in Git commit message buffers."
  (setq-local completion-at-point-functions nil)
  (when (bound-and-true-p corfu-mode)
    (corfu-mode -1)))

(use-package magit
  :commands (magit-status magit-blame)
  :init
  (setq magit-auto-revert-mode nil
        magit-revision-insert-related-refs nil
        magit-save-repository-buffers nil
        magit-git-executable (or (executable-find "git") "git"))
  :custom
  (magit-display-buffer-function #'dm-magit-display-buffer-fn)
  (magit-commit-show-diff nil)
  :config
  (add-hook 'git-commit-mode-hook #'dm-git-commit-disable-completion 90)
  (with-eval-after-load 'git-commit
    (add-hook 'git-commit-setup-hook #'dm-git-commit-insert-pending-generated-message))
  (with-eval-after-load 'magit-commit
    (oset (get 'magit-commit 'transient--prefix) value nil)
    (transient-append-suffix 'magit-commit "c"
      '("g" "Generate commit message" dm-magit-commit-generate))))

(use-package git-timemachine
  :config
  (evil-make-overriding-map git-timemachine-mode-map 'normal)
  (add-hook 'git-timemachine-mode-hook #'evil-normalize-keymaps))

(use-package posframe)

(use-package diff-hl
  ;; Inline git diff indicators in the fringe (added/modified/removed lines).
  :config
  (global-diff-hl-mode 1)
  (setq diff-hl-show-hunk-function #'diff-hl-show-hunk-posframe)
  (add-hook 'magit-post-refresh-hook #'diff-hl-magit-post-refresh)
  (with-eval-after-load 'evil
    (evil-define-key 'normal 'global
      (kbd "[h") #'diff-hl-show-hunk-previous
      (kbd "]h") #'diff-hl-show-hunk-next)))

;; Route GPG passphrase prompts through the Emacs minibuffer instead of a TTY
;; pinentry. Required for GPG commit signing to work in magit's subprocess.
;; GNUPGHOME is set by the XDG LaunchAgent.
(setq epg-pinentry-mode 'loopback)

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
  ;; :hook (prog-mode . copilot-mode) ; disabled by default
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
  (require 'evil-org-agenda)
  (evil-org-agenda-set-keys))

;;; ————————————————————————————
;;; Eglot — language server protocol (built-in, Emacs 29+)
;;; ————————————————————————————

(use-package eglot
  :straight nil
  ;; Add per-language hooks as needed, e.g.:
  ;;   (add-hook 'python-ts-mode-hook #'eglot-ensure)
  :custom
  (eglot-autoshutdown t))

;;; ————————————————————————————
;;; Apheleia — async code formatting
;;; ————————————————————————————

(use-package apheleia
  :config
  ;; Prefer ecosystem-standard formatters for common editing modes.
  ;; These tools still need to be installed on PATH for Apheleia to run them.
  (dolist (entry '((emacs-lisp-mode       . lisp-indent)
                   (lisp-interaction-mode . lisp-indent)
                   (sh-mode               . shfmt)
                   (bash-ts-mode          . shfmt)
                   (ruby-mode             . rubocop)
                   (ruby-ts-mode          . rubocop)
                   (python-mode           . (ruff-isort ruff))
                   (python-ts-mode        . (ruff-isort ruff))
                   (go-mode               . goimports)
                   (go-ts-mode            . goimports)
                   (rust-mode             . rustfmt)
                   (rust-ts-mode          . rustfmt)
                   (js-mode               . prettier-javascript)
                   (js-ts-mode            . prettier-javascript)
                   (jsx-ts-mode           . prettier)
                   (typescript-mode       . prettier-typescript)
                   (typescript-ts-mode    . prettier-typescript)
                   (tsx-ts-mode           . prettier-typescript)
                   (css-mode              . prettier-css)
                   (css-ts-mode           . prettier-css)
                   (json-mode             . prettier-json)
                   (json-ts-mode          . prettier-json)))
    (setf (alist-get (car entry) apheleia-mode-alist) (cdr entry)))
  (apheleia-global-mode -1))

;;; ————————————————————————————
;;; Corfu — in-buffer completion popup
;;; ————————————————————————————

(use-package corfu
  ;; Popup at point for in-buffer completions. Pairs with eglot and cape.
  :custom
  (corfu-auto t)
  (corfu-auto-delay 0.1)
  (corfu-cycle t)
  (corfu-separator ?\s)
  (corfu-quit-at-boundary nil)
  (corfu-quit-no-match nil) ;; (corfu-quit-no-match t)
  (corfu-preview-current nil)
  :config
  ;; Keep completion acceptance on Enter so TAB remains available for snippets.
  (keymap-set corfu-map "RET" #'corfu-insert)
  (keymap-set corfu-map "<return>" #'corfu-insert)
  (keymap-unset corfu-map "TAB")
  (keymap-unset corfu-map "<tab>")
  (global-corfu-mode 1))

(use-package cape
  ;; Extra completion-at-point sources: dabbrev, file paths, etc.
  :config
  (add-hook 'completion-at-point-functions #'cape-dabbrev)
  (add-hook 'completion-at-point-functions #'cape-file))

;;; ————————————————————————————
;;; Tempel — templates/snippets via completion-at-point
;;; ————————————————————————————

(use-package tempel
  :bind (("M-+" . tempel-complete)
         ("M-*" . tempel-insert)
         :map tempel-map
         ("TAB" . tempel-next)
         ("<tab>" . tempel-next)
         ("S-TAB" . tempel-previous)
         ("<backtab>" . tempel-previous)
         ("C-j" . tempel-next)
         ("C-k" . tempel-previous))
  :init
  (defun dm-tempel-setup-capf ()
    "Add Tempel template expansion before the mode's main CAPF."
    (setq-local completion-at-point-functions
                (cons #'tempel-expand completion-at-point-functions)))

  (add-hook 'conf-mode-hook #'dm-tempel-setup-capf)
  (add-hook 'prog-mode-hook #'dm-tempel-setup-capf)
  (add-hook 'text-mode-hook #'dm-tempel-setup-capf))

(use-package tempel-collection
  :after tempel)

;;; ————————————————————————————
;;; Web editing
;;; ————————————————————————————

(use-package emmet-mode
  ;; Abbreviation expansion for HTML, CSS, JSX, and TSX buffers.
  :hook ((mhtml-mode   . emmet-mode)
         (html-mode    . emmet-mode)
         (html-ts-mode . emmet-mode)
         (css-mode     . emmet-mode)
         (css-ts-mode  . emmet-mode)
         (js-ts-mode   . emmet-mode)
         (tsx-ts-mode  . emmet-mode))
  :custom
  (emmet-move-cursor-between-quotes t)
  :config
  (keymap-set emmet-mode-keymap "TAB" #'emmet-expand-line)
  (keymap-set emmet-mode-keymap "<tab>" #'emmet-expand-line)
  (dolist (mode '(js-ts-mode tsx-ts-mode))
    (add-to-list 'emmet-jsx-major-modes mode)))

;;; ————————————————————————————
;;; Tree-sitter — structural syntax (built-in, Emacs 29+)
;;; ————————————————————————————

(use-package treesit-auto
  ;; Auto-installs tree-sitter grammars and remaps major modes to *-ts-mode.
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
          (go "https://github.com/tree-sitter/tree-sitter-go")
          (html "https://github.com/tree-sitter/tree-sitter-html")
          (javascript "https://github.com/tree-sitter/tree-sitter-javascript" "master" "src")
          (json "https://github.com/tree-sitter/tree-sitter-json")
          (make "https://github.com/alemuller/tree-sitter-make")
          (markdown "https://github.com/ikatyang/tree-sitter-markdown")
          (python "https://github.com/tree-sitter/tree-sitter-python")
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

;;; ————————————————————————————
;;; Hideshow - fallback folding
;;; ————————————————————————————

(use-package hideshow
  ;; Evil's z* folds need one of its supported backends.  Elisp does not always
  ;; get `treesit-fold-mode', so keep a sexp-based fallback active there.
  :straight nil
  :hook ((emacs-lisp-mode . hs-minor-mode)
         (lisp-interaction-mode . hs-minor-mode)))

;;; ————————————————————————————
;;; GC reset
;;; ————————————————————————————

;; Lower GC threshold back to something reasonable now that startup is done.
;; 16 MB is a comfortable value for interactive use; adjust upward if you
;; notice GC pauses during heavy operations.
(add-hook 'emacs-startup-hook
          (lambda ()
            (setq gc-cons-threshold (* 16 1024 1024)
                  gc-cons-percentage 0.1)))

(provide 'init)
;;; init.el ends here
