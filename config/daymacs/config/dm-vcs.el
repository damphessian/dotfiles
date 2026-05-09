;;; dm-vcs.el --- Daymacs version-control setup  -*- lexical-binding: t; -*-

;;; Commentary:

;; Git-facing behavior: Magit, fringe diffs, commit-message helpers, and the
;; tree-sitter remap advice that keeps transient Git message buffers fast.

;;; Code:

(defconst dm-git-commit-filename-regexp
  "/\\(?:\\(?:\\(?:COMMIT\\|NOTES\\|PULLREQ\\|MERGEREQ\\|TAG\\)_EDIT\\|MERGE_\\|\\)MSG\\|\\(?:BRANCH\\|EDIT\\)_DESCRIPTION\\)\\'"
  "Regexp matching Git message files that `git-commit' edits.")

(defun dm-git-commit-file-p (&optional file)
  "Return non-nil when FILE or the current buffer is a Git message file."
  (let ((path (or file buffer-file-name)))
    (and path
         (string-match-p dm-git-commit-filename-regexp path))))

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
              :around #'dm-skip-treesit-auto-for-git-commit-file-a)

  ;; Memoize the remap-alist build. `treesit-auto--build-major-mode-remap-alist'
  ;; is called on every file open and dlopens every grammar to check
  ;; availability. Grammars don't change within a session, so cache once.
  (defvar dm-treesit-auto--remap-alist-cache nil
    "Memoized result of `treesit-auto--build-major-mode-remap-alist'.")

  (defun dm-treesit-auto--cached-remap-alist-a (fn &rest args)
    "Return cached treesit-auto remap alist, building it once."
    (or dm-treesit-auto--remap-alist-cache
        (setq dm-treesit-auto--remap-alist-cache (apply fn args))))

  (defun dm-treesit-auto-invalidate-cache ()
    "Drop cached treesit-auto remap alist after grammar changes."
    (interactive)
    (setq dm-treesit-auto--remap-alist-cache nil))

  (advice-add 'treesit-auto--build-major-mode-remap-alist
              :around #'dm-treesit-auto--cached-remap-alist-a)
  (advice-add 'treesit-install-language-grammar
              :after (lambda (&rest _) (dm-treesit-auto-invalidate-cache)))

  ;; Pre-warm at idle so the first find-file doesn't pay the build cost.
  (run-with-idle-timer
   1 nil
   (lambda ()
     (when (fboundp 'treesit-auto--build-major-mode-remap-alist)
       (treesit-auto--build-major-mode-remap-alist)))))

;; Helper defuns live in `dm-magit.el' and load via autoload cookies on first
;; interactive use (commit generation, display routing, etc.).
(use-package magit
  :commands (magit-status magit-blame)
  :init
  (setq magit-auto-revert-mode nil
        magit-revision-insert-related-refs nil
        magit-save-repository-buffers nil
        magit-git-executable (or (executable-find "git") "git"))
  :custom
  (magit-display-buffer-function #'dm-magit-display-buffer-fn)
  (magit-commit-show-diff t)
  :config
  ;; Remove sections to speed up load.
  (remove-hook 'magit-status-sections-hook #'magit-insert-status-headers)
  (remove-hook 'magit-status-sections-hook #'magit-insert-am-sequence)
  (remove-hook 'magit-status-sections-hook #'magit-insert-bisect-log)
  (remove-hook 'magit-status-sections-hook #'magit-insert-bisect-output)
  (remove-hook 'magit-status-sections-hook #'magit-insert-bisect-rest)
  (remove-hook 'magit-status-sections-hook #'magit-insert-merge-log)
  (remove-hook 'magit-status-sections-hook #'magit-insert-rebase-sequence)
  (remove-hook 'magit-status-sections-hook #'magit-insert-sequencer-sequence)
  (remove-hook 'magit-status-sections-hook #'magit-insert-stashes)
  (remove-hook 'magit-status-sections-hook #'magit-insert-unpulled-from-pushremote)
  (remove-hook 'magit-status-sections-hook #'magit-insert-unpulled-from-upstream)
  (remove-hook 'magit-status-sections-hook #'magit-insert-unpushed-to-pushremote)
  (remove-hook 'magit-status-sections-hook #'magit-insert-unpushed-to-upstream-or-recent)
  (remove-hook 'magit-status-sections-hook #'magit-insert-untracked-files)
  (with-eval-after-load 'git-commit
    (add-hook 'git-commit-mode-hook #'dm-git-commit-disable-completion 90)
    (add-hook 'git-commit-setup-hook #'dm-git-commit-insert-pending-generated-message))
  (with-eval-after-load 'magit-commit
    (oset (get 'magit-commit 'transient--prefix) value nil)
    (transient-append-suffix 'magit-commit "c"
      '("g" "Generate commit message" dm-magit-commit-generate))))

(use-package git-timemachine
  :commands git-timemachine
  :config
  (evil-make-overriding-map git-timemachine-mode-map 'normal)
  (add-hook 'git-timemachine-mode-hook #'evil-normalize-keymaps))

(use-package posframe
  :defer t)

(use-package diff-hl
  ;; Inline git diff indicators in the fringe. Activated per buffer instead of
  ;; globally so the package loads on the first file-backed buffer.
  :hook ((find-file . diff-hl-mode)
         (dired-mode . diff-hl-dired-mode)
         (vc-dir-mode . diff-hl-dir-mode))
  :config
  (setq diff-hl-show-hunk-function #'diff-hl-show-hunk-posframe)
  (add-hook 'magit-post-refresh-hook #'diff-hl-magit-post-refresh)
  (with-eval-after-load 'evil
    (evil-define-key 'normal 'global
      (kbd "[h") #'diff-hl-show-hunk-previous
      (kbd "]h") #'diff-hl-show-hunk-next)))

;; Route GPG passphrase prompts through the Emacs minibuffer instead of a TTY
;; pinentry. Required for GPG commit signing to work in Magit's subprocess.
;; GNUPGHOME is set by the XDG LaunchAgent.
(setq epg-pinentry-mode 'loopback)

(provide 'dm-vcs)
;;; dm-vcs.el ends here
