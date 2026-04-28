;;; init.el --- -*- lexical-binding: t; -*-

;;; ————————————————————————————
;;; straight.el bootstrap
;;; ————————————————————————————

;; straight.el replaces package.el entirely: it clones packages from source,
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

;;; ————————————————————————————
;;; Core Emacs settings
;;; ————————————————————————————

;; Prefer UTF-8 everywhere.
(set-language-environment "UTF-8")
(set-default-coding-systems 'utf-8)

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
(recentf-mode 1)
(setq recentf-max-saved-items 200)

;; Relative line numbers match evil's jump-count workflow (e.g. 5j, 12k).
(setq display-line-numbers-type 'relative)
(global-display-line-numbers-mode 1)

;; Highlight matching parens immediately.
(setq show-paren-delay 0)
(show-paren-mode 1)

;; Single space after sentences — affects fill-paragraph.
(setq sentence-end-double-space nil)

;; Follow symlinks to version-controlled files without prompting.
(setq vc-follow-symlinks t)

;; Empty scratch buffer on launch (inhibit-startup-screen is in early-init.el).
(setq initial-scratch-message nil)

;; Show project name in title bar, falling back to buffer name.
(setq frame-title-format
      '((:eval
         (if-let* ((proj (project-current)))
             (project-name proj)
           (buffer-name)))))

;;; ————————————————————————————
;;; Appearance
;;; ————————————————————————————

(set-face-attribute 'default nil
                    :family "Source Code Pro Ligaturized"
                    :height 180)

(use-package doom-themes
  :config
  (load-theme 'doom-one t))

;;; ————————————————————————————
;;; Evil — vi keybindings
;;; ————————————————————————————

(use-package evil
  :init
  ;; These must be set before evil loads.
  (setq evil-want-integration t)     ; integrates evil with other Emacs subsystems
  (setq evil-want-keybinding nil)    ; evil-collection provides these instead
  (setq evil-undo-system 'undo-redo) ; use native Emacs 28+ undo/redo
  (setq evil-want-C-u-scroll t)      ; C-u scrolls up (mirrors vim default)
  :config
  (evil-mode 1))

(use-package evil-collection
  ;; Provides sensible evil keybindings for magit, dired, help, ibuffer, etc.
  ;; Must load after evil.
  :after evil
  :config
  (evil-collection-init))

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

    ;; Files
    "f"   '(:ignore t           :which-key "file")
    "f f" '(consult-fd          :which-key "find file")
    "f r" '(consult-recent-file :which-key "recent files")

    ;; Search
    "s"   '(:ignore t           :which-key "search")
    "s g" '(consult-ripgrep     :which-key "ripgrep")
    "s s" '(consult-line        :which-key "line in buffer")

    ;; Git
    "g"   '(:ignore t           :which-key "git")
    "g g" '(magit-status        :which-key "magit status")
    "g b" '(magit-blame         :which-key "magit blame")

    ;; Org
    "o"   '(:ignore t           :which-key "org")
    "o a" '(org-agenda          :which-key "agenda")
    "o c" '(org-capture         :which-key "capture")

    ;; Buffers
    "b"   '(:ignore t           :which-key "buffer")
    "b d" '(kill-current-buffer :which-key "kill buffer")
    "b b" '(consult-buffer      :which-key "switch buffer")

    ;; Toggle
    "t"   '(:ignore t           :which-key "toggle")
    "t w" '(visual-fill-column-mode :which-key "word wrap")

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
    "p p" '(project-switch-project     :which-key "switch project")
    "p f" '(project-find-file          :which-key "find file")
    "p b" '(project-switch-to-buffer   :which-key "project buffer")
    "p k" '(project-kill-buffers       :which-key "kill buffers")
    "p s" '(consult-ripgrep            :which-key "search"))

  (general-define-key
   "s-["   #'previous-buffer
   "s-]"   #'next-buffer
   "s-{"   #'tab-bar-switch-to-prev-tab
   "s-}"   #'tab-bar-switch-to-next-tab
   "s-P"   #'execute-extended-command
   "s-C-p" #'execute-extended-command-for-buffer
   "s-t"   #'tab-new
   "s-W"   #'tab-close
   "s-w"   #'delete-window
   "s-k"   #'kill-current-buffer
   "s-C-g" #'magit-status))

;;; ————————————————————————————
;;; which-key — keybinding hints
;;; ————————————————————————————

(use-package which-key
  ;; Displays available key completions in a popup after a short delay.
  ;; Essential while building muscle memory for the leader bindings above.
  :config
  (which-key-mode 1)
  (setq which-key-idle-delay 0.4))

;;; ————————————————————————————
;;; Vertico — minibuffer completion UI
;;; ————————————————————————————

(use-package vertico
  ;; Replaces the default horizontal completion with a clean vertical list.
  :config
  (vertico-mode 1))

(use-package mini-frame
  :config
  (mini-frame-mode 1)
  (set-face-attribute 'child-frame-border nil
                      :background (face-attribute 'mode-line :background))
  :custom
  (mini-frame-show-parameters
   (lambda ()
     `((top    . 0.3)
       (width  . 0.7)
       (left   . 0.15)
       (child-frame-border-width . 2)
       (background-color . ,(face-attribute 'default :background))))))

(use-package orderless
  ;; Matching style: space-separated components match in any order.
  ;; e.g. "foo bar" finds "bar-foo" and "foobar-baz".
  ;; The override for 'file keeps basic prefix matching for path completion,
  ;; where orderless can otherwise interfere with / separators.
  :custom
  (completion-styles '(orderless basic))
  (completion-category-overrides '((file (styles basic partial-completion)))))

(use-package consult
  ;; Rich completion commands: consult-ripgrep, consult-find, consult-buffer,
  ;; consult-line, consult-recent-file, etc. Integrates with vertico.
  :config)

(use-package marginalia
  ;; Adds annotations to completion candidates: file sizes, docstrings,
  ;; command key bindings, etc. Works with any completing-read UI.
  :config
  (marginalia-mode 1))

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
;;; Markdown
;;; ————————————————————————————

(use-package visual-fill-column
  :hook ((markdown-mode . visual-line-mode)
         (markdown-mode . visual-fill-column-mode))
  :custom
  (visual-fill-column-width 80))

(use-package markdown-mode
  :mode (("\\.md\\'" . gfm-mode)
         ("\\.markdown\\'" . gfm-mode)))

;;; ————————————————————————————
;;; Magit — git interface
;;; ————————————————————————————

(use-package magit
  :custom
  (magit-display-buffer-function #'magit-display-buffer-fullframe-status-v1)
  (magit-commit-show-diff t))

;;; ————————————————————————————
;;; Org
;;; ————————————————————————————

(use-package org
  ;; Use the ELPA version rather than the built-in one for up-to-date features.
  :straight t
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
;;; GC reset
;;; ————————————————————————————

;; Lower GC threshold back to something reasonable now that startup is done.
;; 16 MB is a comfortable value for interactive use; adjust upward if you
;; notice GC pauses during heavy operations.
(add-hook 'emacs-startup-hook
          (lambda ()
            (setq gc-cons-threshold (* 16 1024 1024)
                  gc-cons-percentage 0.1)))
