;;; dm-editing.el --- Daymacs buffer editing tools  -*- lexical-binding: t; -*-

;;; Commentary:

;; Buffer-local editing ergonomics: local Evil bindings, scratch/workspace
;; behavior, formatting, completion-at-point, snippets, web helpers, and simple
;; folding fallback. Language-server and tree-sitter setup live elsewhere.

;;; Code:

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

(use-package persistent-scratch
  :ensure t
  :hook (emacs-startup . persistent-scratch-setup-default))

(use-package tabspaces
  :hook (emacs-startup . tabspaces-mode)
  :custom
  (tabspaces-use-filtered-buffers-as-default t)
  (tabspaces-default-tab "main")
  (tabspaces-remove-to-default t)
  (tabspaces-include-buffers '("*scratch*")))

;; Filter `consult-buffer' to show only current-workspace buffers. The nested
;; `with-eval-after-load' keeps Consult/Tabspaces internals off the boot path.
(with-eval-after-load 'consult
  (with-eval-after-load 'tabspaces
    (consult-customize consult-source-buffer :hidden t :default nil)
    ;; Hide file-loading sources from default consult-buffer view; still
    ;; accessible by narrowing (r recent, p project, m bookmarks).
    (consult-customize
     consult-source-recent-file
     consult-source-project-recent-file
     consult-source-project-recent-file-hidden
     consult-source-bookmark
     :hidden t)
    (defvar consult-source-workspace
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
    (add-to-list 'consult-buffer-sources 'consult-source-workspace)))

(use-package dired
  :straight nil
  :after evil
  :init
  (autoload 'dired-jump "dired-x" nil t)
  :hook ((prog-mode . dm-dired-jump-keybindings)
         (text-mode . dm-dired-jump-keybindings)
         (sgml-mode . dm-dired-jump-keybindings)
         (dired-mode . dired-hide-details-mode))
  :custom
  (dired-listing-switches "-Ah --group-directories-first"))

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

(use-package helpful
  :commands (helpful-at-point
             helpful-callable
             helpful-command
             helpful-function
             helpful-key
             helpful-symbol
             helpful-variable)
  :init
  (with-eval-after-load 'evil
    (evil-define-key 'normal emacs-lisp-mode-map
      (kbd "K") #'helpful-at-point)
    (evil-define-key 'normal lisp-interaction-mode-map
      (kbd "K") #'helpful-at-point))
  :config
  (global-set-key (kbd "C-h f") #'helpful-callable)
  (global-set-key (kbd "C-h v") #'helpful-variable)
  (global-set-key (kbd "C-h k") #'helpful-key)
  (global-set-key (kbd "C-h x") #'helpful-command)
  (with-eval-after-load 'evil
    (evil-define-key 'normal helpful-mode-map
      (kbd "K") #'helpful-at-point)))

(use-package apheleia
  :commands (apheleia-format-buffer apheleia-mode apheleia-global-mode)
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

(use-package corfu
  ;; Popup at point for in-buffer completions. Pairs with Eglot and Cape.
  ;; Loaded on demand by editable buffers instead of at startup.
  :hook ((prog-mode . corfu-mode)
         (text-mode . corfu-mode)
         (conf-mode . corfu-mode))
  :custom
  (corfu-auto t)
  (corfu-auto-delay 0.1)
  (corfu-cycle t)
  (corfu-separator ?\s)
  (corfu-quit-at-boundary nil)
  (corfu-quit-no-match nil)
  (corfu-preview-current nil)
  :config
  ;; Keep completion acceptance on Enter so TAB remains available for snippets.
  (keymap-set corfu-map "RET" #'corfu-insert)
  (keymap-set corfu-map "<return>" #'corfu-insert)
  (keymap-unset corfu-map "TAB")
  (keymap-unset corfu-map "<tab>"))

(use-package cape
  ;; Extra completion-at-point sources: dabbrev, file paths, etc.
  :after corfu
  :config
  (defun dm-cape-dabbrev ()
    "Run `cape-dabbrev' as a quiet optional CAPF."
    (cape-wrap-silent #'cape-dabbrev))

  (add-hook 'completion-at-point-functions #'dm-cape-dabbrev)
  (add-hook 'completion-at-point-functions #'cape-file))

;;;###autoload
(defun dm-tab-dwim ()
  "Smart TAB: advance Tempel field, expand snippet, or indent."
  (interactive)
  (cond
   ((bound-and-true-p tempel--active) (tempel-next 1))
   ((tempel-expand t))
   (t (indent-for-tab-command))))

(use-package tempel
  :bind (("C-l" . tempel-insert)
         :map tempel-map
         ("C-j" . tempel-next)
         ("C-k" . tempel-previous))
  :init
  (defun dm-tempel-setup-capf ()
    "Add Tempel template expansion before the mode's main CAPF."
    (setq-local completion-at-point-functions
                (cons #'tempel-expand completion-at-point-functions)))
  (add-hook 'conf-mode-hook #'dm-tempel-setup-capf)
  (add-hook 'prog-mode-hook #'dm-tempel-setup-capf)
  (add-hook 'text-mode-hook #'dm-tempel-setup-capf)
  ;; Bind tab to complete selectively in editable buffers.
  (defun dm-tab-dwim-setup ()
    (local-set-key (kbd "<tab>") #'dm-tab-dwim)
    (local-set-key (kbd "TAB")   #'dm-tab-dwim))
  (add-hook 'conf-mode-hook #'dm-tab-dwim-setup)
  (add-hook 'prog-mode-hook #'dm-tab-dwim-setup)
  (add-hook 'text-mode-hook #'dm-tab-dwim-setup))

(use-package tempel-collection
  :after tempel)

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

(use-package hideshow
  ;; Evil's z* folds need one supported backend. Elisp does not always get
  ;; `treesit-fold-mode', so keep a sexp-based fallback active there.
  :straight nil
  :hook ((emacs-lisp-mode . hs-minor-mode)
         (lisp-interaction-mode . hs-minor-mode)))

(provide 'dm-editing)
;;; dm-editing.el ends here
