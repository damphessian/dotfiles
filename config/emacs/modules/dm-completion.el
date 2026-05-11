;;; dm-completion.el --- Daymacs minibuffer completion and search  -*- lexical-binding: t; -*-

;;; Commentary:

;; The minibuffer completion stack is configured as one module so Vertico,
;; Orderless, Consult, Marginalia, Embark, and editable grep stay in sync.

;;; Code:

(require 'subr-x)

(use-package vertico
  ;; Replaces the default horizontal completion with a clean vertical list.
  :defer 0.1
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
  (vertico-mouse-mode 1)
  (vertico-multiform-mode 1))

(use-package orderless
  ;; Space-separated components match in any order, while file completion keeps
  ;; path-aware prefix matching so "/" keeps its normal meaning.
  :ensure t
  :defer 0.1
  :custom
  (completion-styles '(orderless basic))
  (completion-category-overrides '((file (styles partial-completion))))
  (completion-pcm-leading-wildcard t)) ;; Emacs 31: partial-completion substring

(use-package consult
  ;; Rich completion commands: consult-ripgrep, consult-find, consult-buffer,
  ;; consult-line, consult-recent-file, etc. Integrates with vertico.
  :defer 0.2
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
(defun dm-search-for-this-dwim (&optional beg end)
  "Search the current visual selection, or symbol-at-point if no selection.
Search in the current project if one is active, otherwise search the current
directory hierarchy."
  (interactive "r")
  (let* ((selection (when (use-region-p)
                      (string-trim
                       (buffer-substring-no-properties beg end))))
         (symbol (when-let* ((symbol (thing-at-point 'symbol t)))
                   (string-trim symbol)))
         (query (or (and selection (not (string-empty-p selection)) selection)
                    (and symbol (not (string-empty-p symbol)) symbol)
                    ""))
         (dir (if-let* ((project (project-current nil)))
                  (project-root project)
                default-directory)))
    (consult-ripgrep dir query)))

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
