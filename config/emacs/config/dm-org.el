;;; dm-org.el --- Daymacs Org setup  -*- lexical-binding: t; -*-

;;; Commentary:

;; Org setup is kept together because its first-load cost is meaningful and the
;; Evil integration depends on Org's own load lifecycle.

;;; Code:

(use-package org
  ;; Use the ELPA version rather than the built-in one for up-to-date features.
  :straight t
  :hook ((org-mode . dm-disable-line-numbers-h))
  :custom
  ;; Skip the default `org-modules' cascade (ol-doi ol-w3m ol-bbdb ol-bibtex
  ;; ol-docview ol-gnus ol-info ol-irc ol-mhe ol-rmail ol-eww). Loading them
  ;; via `org-load-modules-maybe' on first org-mode activation accounted for
  ;; roughly half of the open cost. Add specific modules back here as needed.
  (org-modules nil)
  ;; ORG_HOME is set in env/emacs.sh; fall back to ~/Org.
  (org-directory (or (getenv "ORG_HOME") (expand-file-name "~/Org")))
  (org-agenda-files (list org-directory))
  ;; Visual preferences.
  (org-startup-indented t)
  (org-hide-leading-stars t)
  (org-ellipsis " ▾")
  ;; Capture and logging.
  (org-log-done 'time)
  (org-log-into-drawer t))

(use-package evil-org
  ;; Evil keybindings for org: heading navigation, table editing, agenda.
  :after (evil org)
  :hook (org-mode . evil-org-mode)
  :config
  ;; Agenda bindings only matter once `org-agenda' loads, which happens on
  ;; first `M-x org-agenda'. Don't pull in evil-org-agenda before then.
  (with-eval-after-load 'org-agenda
    (require 'evil-org-agenda)
    (evil-org-agenda-set-keys)))

(provide 'dm-org)
;;; dm-org.el ends here
