;;; dm-magit.el --- Daymacs Magit helpers  -*- lexical-binding: t; -*-

;;; Commentary:

;; Display, completion, and commit-message-generation helpers for Magit.
;; Loaded lazily via autoload cookies; see init.el's `use-package magit'
;; block for how these are wired into Magit's hooks and customizations.

;;; Code:

(declare-function magit-toplevel "magit-git")
(declare-function magit-commit-create "magit-commit")
(declare-function corfu-mode "corfu")

(defvar dm-magit-pending-generated-commit-message nil
  "Generated commit message waiting to be inserted into a commit buffer.")

(defun dm-git-commit-message-region-end ()
  "Return end of editable commit message area before Git comment template."
  (save-excursion
    (goto-char (point-min))
    (if (re-search-forward "^#" nil t)
        (line-beginning-position)
      (point-max))))

;;;###autoload
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

;;;###autoload
(defun dm-magit-commit-generate ()
  "Generate a commit message, then open Magit's commit buffer."
  (interactive)
  (let ((steering (read-string "Steering, optional: ")))
    (setq dm-magit-pending-generated-commit-message
          (dm-git-commit-generated-message steering))
    (magit-commit-create)))

;;;###autoload
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

;;;###autoload
(defun dm-git-commit-disable-completion ()
  "Disable dabbrev in Git commit message buffers."
  (setq-local completion-at-point-functions nil)
  (when (bound-and-true-p corfu-mode)
    (corfu-mode -1)))

(provide 'dm-magit)
;;; dm-magit.el ends here
