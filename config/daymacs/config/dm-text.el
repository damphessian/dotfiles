;;; dm-text.el --- Daymacs text editing helpers -*- lexical-binding: t; -*-

(require 'subr-x)

(declare-function calc-eval "calc")
(declare-function evil-insert "evil-commands")
(declare-function evil-insert-state-p "evil-states")
(declare-function evil-visual-state-p "evil-states")

;;; Code:

(defun dm-text-point-on-empty-line-p ()
  "Return t if the point is on an empty line, nil otherwise."
  (interactive)
  (save-excursion
    (beginning-of-line)
    (looking-at-p "^\\s-*$")))

(defun dm-text--select-around-point-to-whitespace-or-delimiters ()
  "Select characters around the current point up to whitespace in both directions."
  (let ((start (point))
        (end (point)))
    ;; Move start backward to the first whitespace or beginning of the buffer.
    (while (and (not (bobp))
                (not (looking-back "\\s-\\|\n" nil))
                (not (looking-back "[,;=]" nil)))
      (backward-char))
    (setq start (point))

    ;; Move end forward to the first whitespace or end of the buffer.
    (goto-char end)
    (while (and (not (eobp))
                (not (looking-at "\\s-\\|\n"))
                (not (looking-at "[,;.]")))
      (forward-char))
    (setq end (point))

    (set-mark start)
    (goto-char end)
    (activate-mark)))

(defun dm-text--selected-text ()
  "Return the active visual text, or select and return text around point."
  (if (evil-visual-state-p)
      (string-trim (buffer-substring (mark) (point)))
    (dm-text--select-around-point-to-whitespace-or-delimiters)
    (string-trim (buffer-substring (mark) (point)))))

(defun dm-text--delimit-with (char)
  "Wrap the selected text with CHAR."
  (let ((selected-text (dm-text--selected-text)))
    (kill-region (mark) (point))
    (insert (format "%s%s%s" char selected-text char))))

(defun dm-text--latex-wrap-in-cmd (cmd)
  "Wrap the selected text in LaTeX command CMD."
  (let ((selected-text (dm-text--selected-text)))
    (kill-region (mark) (point))
    (insert (format "\\%s{%s}" cmd selected-text))))

(defun dm-text-latex-wrap-as-math (displaymode-p)
  "Wrap selected text, or text around point, in LaTeX math delimiters.
With DISPLAYMODE-P, use display math delimiters."
  (interactive "P")
  (if (or (dm-text-point-on-empty-line-p)
          (evil-insert-state-p))
      (if displaymode-p
          (progn
            (insert "\\[\n\n\\]")
            (goto-char (- (point) 3))
            (insert "\t")
            (evil-insert 1))
        (insert "\\(  \\)")
        (goto-char (- (point) 3))
        (evil-insert 1))
    (let* ((selected-text (dm-text--selected-text))
           (wrapped-text
            (if displaymode-p
                (format "\\[%s\\]" selected-text)
              (format "\\(%s\\)" selected-text))))
      (kill-region (mark) (point))
      (insert wrapped-text))))

(defun dm-text-latex-wrap-as-math-display ()
  "Wrap selected text, or text around point, in LaTeX display math delimiters."
  (interactive)
  (dm-text-latex-wrap-as-math t))

(defun dm-text-latex-wrap-as-frac ()
  "Wrap selected text, or text around point, in a LaTeX fraction command."
  (interactive)
  (let* ((selected-text (dm-text--selected-text))
	 (split-pos (string-match "/" selected-text))
	 (numerator (if split-pos
			(string-trim (substring selected-text 0 split-pos))
		      selected-text))
	 (denominator (if split-pos
			 (string-trim (substring selected-text (1+ split-pos)))
		       "1"))
	 (formatted-string (format "\\frac{%s}{%s}" numerator denominator)))
    (kill-region (mark) (point))
    (insert formatted-string)))

(defun dm-text-latex-wrap-as-boxed ()
  "Wrap selected text, or text around point, in a LaTeX boxed command."
  (interactive)
  (dm-text--latex-wrap-in-cmd "boxed"))

(defun dm-text-latex-wrap-as-si ()
  "Format the selected text as a LaTeX SI unit expression."
  (interactive)
  (let* ((selection (buffer-substring-no-properties (region-beginning) (region-end)))
         (split-pos (string-match " " selection))
         (formatted-string
          (if split-pos
              (let ((value (substring selection 0 split-pos))
                    (unit (substring selection (1+ split-pos))))
                (format "\\SI{%s}{\\%s}" value unit))
            (format "\\SI{}{\\%s}" selection))))
    (delete-region (region-beginning) (region-end))
    (insert formatted-string)))

(defun dm-text-latex-evaluate-selection ()
  "Evaluate selected LaTeX-flavored math and replace it with the result."
  (interactive)
  (let* ((selected-text (string-trim (buffer-substring (mark) (point))))
         (replaced-text (replace-regexp-in-string "\\\\cdot" "*" selected-text))
         (replaced-text (replace-regexp-in-string "\\\\ln" "ln" replaced-text))
         (replaced-text (replace-regexp-in-string "\\\\pi" "3.14159" replaced-text))
         (replaced-text (replace-regexp-in-string "\\\\exp" "exp" replaced-text))
         (replaced-text (replace-regexp-in-string "\\\\L" "" replaced-text))
         (replaced-text (replace-regexp-in-string "\\\\R" "" replaced-text))
         (replaced-text (replace-regexp-in-string "\\\\SI{\\([^}]+\\)}{[^}]*}" "\\1" replaced-text))
         (replaced-text (replace-regexp-in-string "\\\\p{\\([^}]+\\)}" "(\\1)" replaced-text))
         (replaced-text (replace-regexp-in-string "\\\\frac{\\([^}]+\\)}{\\([^}]+\\)}" "((\\1)/(\\2))" replaced-text))
         (replaced-text (replace-regexp-in-string "\\\\dfrac{\\([^}]+\\)}{\\([^}]+\\)}" "((\\1)/(\\2))" replaced-text))
         (replaced-text (replace-regexp-in-string "\\\\sfrac{\\([^}]+\\)}{\\([^}]+\\)}" "((\\1)/(\\2))" replaced-text))
         (replaced-text (replace-regexp-in-string "{" "(" replaced-text))
         (replaced-text (replace-regexp-in-string "}" ")" replaced-text))
         (replaced-text (replace-regexp-in-string "\\[" "(" replaced-text))
         (replaced-text (replace-regexp-in-string "\\]" ")" replaced-text))
         (result (calc-eval replaced-text)))
    (message "Evaluating: %s = %s" replaced-text result)
    (kill-region (mark) (point))
    (insert (format "%s" result))))

(defun dm-text-make-bold ()
  "Format selected text, or text around point, as bold."
  (interactive)
  (pcase major-mode
    ((or 'latex-mode 'LaTeX-mode)
     (dm-text--latex-wrap-in-cmd "textbf"))
    ('org-mode
     (dm-text--delimit-with "*"))
    ((or 'markdown-mode 'gfm-mode)
     (dm-text--delimit-with "**"))
    (_
     (message "Unrecognized mode: %s" major-mode))))

(defun dm-text-make-italic ()
  "Format selected text, or text around point, as italic."
  (interactive)
  (pcase major-mode
    ((or 'latex-mode 'LaTeX-mode)
     (dm-text--latex-wrap-in-cmd "textit"))
    ('org-mode
     (dm-text--delimit-with "/"))
    ((or 'markdown-mode 'gfm-mode)
     (dm-text--delimit-with "*"))
    (_
     (message "Unrecognized mode: %s" major-mode))))

(defun dm-text-make-underlined ()
  "Format selected text, or text around point, as underlined."
  (interactive)
  (pcase major-mode
    ((or 'latex-mode 'LaTeX-mode)
     (dm-text--latex-wrap-in-cmd "underline"))
    ('org-mode
     (dm-text--delimit-with "_"))
    ((or 'markdown-mode 'gfm-mode)
     (dm-text--delimit-with "_"))
    (_
     (message "Unrecognized mode: %s" major-mode))))

(defun dm-text-make-strikethrough ()
  "Format selected text, or text around point, as strikethrough."
  (interactive)
  (pcase major-mode
    ((or 'latex-mode 'LaTeX-mode)
     (dm-text--latex-wrap-in-cmd "sout"))
    ('org-mode
     (dm-text--delimit-with "+"))
    ((or 'markdown-mode 'gfm-mode)
     (dm-text--delimit-with "~~"))
    (_
     (message "Unrecognized mode: %s" major-mode))))

(provide 'dm-text)
;;; dm-text.el ends here
