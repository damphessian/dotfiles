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
(require 'dm-env)
(require 'dm-ai)
(require 'dm-terminal)
(require 'dm-org)
(require 'dm-keys)

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
