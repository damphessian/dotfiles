;;; dm-evil.el --- Daymacs Evil setup  -*- lexical-binding: t; -*-

;;; Commentary:

;; Vim-style editing packages and the small bits of glue that need to happen
;; as Evil comes online. Mode-local bindings live with the mode modules.

;;; Code:

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
  (dm-evil-text-setup)
  ;; Let the main readline-style keys fall through to the global map in insert
  ;; state. C-k/C-t/C-y keep their Evil insert-state meanings.
  (dolist (key '("C-a" "C-e" "C-b" "C-f" "C-n" "C-p" "C-d"))
    (define-key evil-insert-state-map (kbd key) nil)))

(use-package evil-collection
  ;; Provides sensible evil keybindings for magit, dired, help, ibuffer, etc.
  ;; Must load after evil.
  :after evil
  :init
    (setq evil-collection-calendar-want-org-bindings  nil)
    (setq evil-collection-outline-bind-tab-p            t)
    (setq evil-collection-setup-debugger-keys           t)
    (setq evil-collection-setup-minibuffer              t)
    (setq evil-collection-term-sync-state-and-mode-p    t)
    (setq evil-collection-want-find-usages-bindings     t)
    (setq evil-collection-want-unimpaired-p           nil)
    (setq evil-collection-state-denylist              nil)
    (setq evil-collection-state-passlist              nil)
    (setq evil-collection-key-blacklist               nil)
    (setq evil-collection-key-whitelist               nil)
  :config
  (evil-collection-init))

(use-package evil-commentary
  :after evil
  :config
  (evil-commentary-mode))

(use-package evil-numbers
  :commands (evil-numbers/dec-at-pt evil-numbers/inc-at-pt)
  :init
  (with-eval-after-load 'evil
    (evil-define-key 'normal 'global
      (kbd "g-") #'evil-numbers/dec-at-pt
      (kbd "g=") #'evil-numbers/inc-at-pt)))

(use-package evil-surround
  :after evil
  :config
  (global-evil-surround-mode 1))

(use-package evil-embrace
  :after evil-surround
  :config
  (with-eval-after-load 'org
    (add-hook 'org-mode-hook 'embrace-org-mode-hook))
  ;; Route single-char fence delimiters through evil-surround so `cs-_'
  ;; etc. resolve via the text objects in `dm-evil-text-setup'. Anything
  ;; outside this list goes to embrace, which requires `embrace-add-pair'.
  (setq-default evil-embrace-evil-surround-keys
                (append (default-value 'evil-embrace-evil-surround-keys)
                        '(?- ?_ ?| ?/ ?$)))
  (evil-embrace-enable-evil-surround-integration))

(use-package evil-iedit-state
  :commands (evil-iedit-state/iedit-mode evil-iedit-state)
  :custom (iedit-toggle-key-default nil))

(use-package avy
  :commands (avy-goto-char-2 avy-goto-char avy-goto-line avy-goto-word-1
             avy-setup-default)
  :hook (org-mode . avy-setup-default)
  :custom
  (avy-keys '(?a ?s ?d ?f ?g ?h ?j ?k ?l))
  (avy-style 'at-full))

(use-package evil-lion
  ;; Defer until evil is settled; evil-lion-mode just registers keybindings.
  :defer 0.5
  :init
  (setq evil-lion-left-align-key (kbd "g l"))
  (setq evil-lion-right-align-key (kbd "g L"))
  :config
  (evil-lion-mode 1))

(use-package evil-visualstar
  :after evil
  :config
  (global-evil-visualstar-mode))

(provide 'dm-evil)
;;; dm-evil.el ends here
