;;; dm-langs.el --- Daymacs language tooling setup  -*- lexical-binding: t; -*-

;;; Commentary:

;; Language-server, REPL feedback-loop hooks, startup warmups, and tree-sitter
;; setup. Heavy language packages are still deferred; this module owns the
;; wiring and performance notes.

;;; Code:

(require 'cl-lib)

(defun dm-disable-eldoc-echo-area ()
  "Keep Eldoc providers active, but stop echo-area documentation."
  (setq-local eldoc-display-functions
              (remq #'eldoc-display-in-echo-area
                    eldoc-display-functions)))

;;; ————————————————————————————
;;; eglot
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
  ;; Pre-set this to avoid a macOS Core Text font scan in the defcustom default.
  ;; The residual :type check is paid by the startup warmup below.
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
         (LaTeX-mode         . dm-eglot-ensure-deferred)
         (latex-mode         . dm-eglot-ensure-deferred)
         (tex-mode           . dm-eglot-ensure-deferred)
         (sh-mode            . dm-eglot-ensure-deferred)
         (bash-ts-mode       . dm-eglot-ensure-deferred)
         (eglot-managed-mode . dm-disable-eldoc-echo-area))
  :custom
  (eglot-autoshutdown t)
  ;; Don't auto-reconnect on crash. The default creates an infinite restart
  ;; loop when the cause is persistent, such as file descriptor exhaustion.
  (eglot-autoreconnect nil)
  ;; Drop the JSON-RPC log buffer kept per server; re-enable ad hoc when
  ;; debugging an LSP interaction.
  (eglot-events-buffer-config '(:size 0 :format full))
  :config
  ;; Refuse server-requested file-notify watchers. Each consumes a kqueue FD on
  ;; macOS; dependency-heavy projects can exhaust the per-process limit.
  (cl-defmethod eglot-register-capability
    (_server (_method (eql workspace/didChangeWatchedFiles))
             _id &key _watchers &allow-other-keys)
    nil)

  (add-to-list 'eglot-server-programs
               '((python-mode python-ts-mode)
                 . ("basedpyright-langserver" "--stdio")))

  (when-let* ((tex-ls-command
               (cond
                ((executable-find "digestif")
                 (list (executable-find "digestif")))
                ((executable-find "texlab")
                 (list (executable-find "texlab"))))))
    (add-to-list 'eglot-server-programs
                 `((LaTeX-mode latex-mode tex-mode)
                   . ,tex-ls-command)))

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

  ;; Keep basedpyright out of venvs/build dirs and restrict diagnostics to open
  ;; files, so the initial workspace scan stays cheap.
  (setq-default eglot-workspace-configuration
                '(:python
                  (:analysis
                   (:diagnosticMode "openFilesOnly"
                    :useLibraryCodeForTypes :json-false
                    :exclude ["**/venv" "**/env"
                              "**/dist" "**/build"]))))

  (with-eval-after-load 'evil
    (evil-define-key 'normal eglot-mode-map
      (kbd "K") #'eldoc-print-current-symbol-info)))

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

;; Fixed-delay timers fire even if the user starts working immediately, unlike
;; idle timers. Use them to pay predictable cold-load costs after the frame is
;; up but before the first likely file open.
;; TODO: Add others? named functions
(add-hook 'emacs-startup-hook
          (lambda ()
            (run-with-timer 0.5 nil (lambda () (require 'eglot)))))

(add-hook 'emacs-startup-hook
          (lambda ()
            (run-with-timer 1 nil #'dm-find-in-home--refresh-cache)))

;;; ————————————————————————————
;;; Tree-sitter
;;; ————————————————————————————

(use-package treesit
  :ensure nil
  :straight (:type built-in)
  :when (treesit-available-p)
  :custom
  (treesit-extra-load-path (list dm-dir-tree-sitter-libs)))

(use-package treesit-auto
  ;; Auto-installs tree-sitter grammars and remaps major modes to *-ts-mode.
  ;; Deferred to idle; the first very early file may land in non-ts mode.
  :defer 0.5
  :custom
  (treesit-auto-install t)
  :config
  (setq dm-treesit-language-source-alist
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
          (yaml "https://github.com/ikatyang/tree-sitter-yaml")))
  (treesit-auto-add-to-auto-mode-alist 'all)
  (global-treesit-auto-mode 1))

;;;###autoload
(defun dm-treesit-install-all-languages (&optional use-treesit-auto)
  "Install missing Tree-sitter grammars.

Normally install grammars from `dm-treesit-language-source-alist'.

With prefix argument USE-TREESIT-AUTO, install grammars known to
`treesit-auto' using `treesit-auto--build-treesit-source-alist'
and `treesit-auto-langs'."
  (interactive "P")
  (if use-treesit-auto
      (progn
        (require 'treesit-auto)
        (let ((dm-treesit-language-source-alist
               (treesit-auto--build-treesit-source-alist)))
          (dolist (lang treesit-auto-langs)
            (unless (treesit-language-available-p lang)
              (treesit-install-language-grammar lang)))))
    (dolist (entry dm-treesit-language-source-alist)
      (let ((lang (car entry)))
        (unless (treesit-language-available-p lang)
          (treesit-install-language-grammar lang))))))

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
;;; vimrc
;;; ————————————————————————————

(use-package vimrc-mode
  :straight
  (vimrc-mode :type git :host github :repo "mcandre/vimrc-mode")
  :config
  (add-to-list 'auto-mode-alist '("\\.vim\\(rc\\)?\\'" . vimrc-mode)))

(provide 'dm-langs)
;;; dm-langs.el ends here
