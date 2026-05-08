;;; dm-completion.el --- Daymacs minibuffer completion and search  -*- lexical-binding: t; -*-

;;; Commentary:

;; The minibuffer completion stack is configured as one module so Vertico,
;; Orderless, Consult, Marginalia, Embark, and editable grep stay in sync.

;;; Code:

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
   '((consult-find buffer reverse)
     (consult-git-grep buffer reverse)
     (consult-grep buffer reverse)
     (consult-imenu buffer reverse)
     (consult-imenu-multi buffer reverse)
     (consult-line unobtrusive)
     (consult-outline buffer reverse)
     (consult-org-heading buffer reverse)
     (consult-ripgrep buffer reverse)
     (project-find-file grid))
   vertico-multiform-categories
   '((file grid)))
  :config
  (vertico-mouse-mode 1)
  (vertico-multiform-mode 1))

(use-package orderless
  ;; Space-separated components match in any order, while file completion keeps
  ;; path-aware prefix matching so "/" keeps its normal meaning.
  :ensure t
  :custom
  (completion-styles '(orderless basic))
  (completion-category-overrides '((file (styles partial-completion))))
  (completion-pcm-leading-wildcard t)) ;; Emacs 31: partial-completion substring

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
   consult-recent-file
   consult-bookmark
   consult-source-recent-file
   consult-source-project-recent-file
   consult-source-project-recent-file-hidden
   consult-source-bookmark
   :preview-key "M-.")
  (setq consult-narrow-key "?"))

;;;###autoload
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
  :after vertico
  :config
  (marginalia-mode 1))

(use-package embark-consult
  ;; Register the integration package before Embark loads so Embark's startup
  ;; check can `require' it without warning.
  :after (embark consult)
  :hook (embark-collect-mode . consult-preview-at-point-mode))

(use-package embark
  ;; "Act on this candidate" layer for any completing-read UI.
  :after general)

(use-package wgrep
  ;; Edit consult-ripgrep results in-buffer, then apply across all files.
  :commands (wgrep-change-to-wgrep-mode wgrep-finish-edit)
  :custom
  (wgrep-auto-save-buffer t))

(provide 'dm-completion)
;;; dm-completion.el ends here
