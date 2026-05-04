;;; dm-evil-text.el --- Daymacs Evil text objects and sorting -*- lexical-binding: t; -*-

(require 'cl-lib)
(require 'evil)

;;; Code:

(defmacro dm-evil-text--define-and-bind-text-object (name key start-regex end-regex)
  "Define inner and outer Evil text objects named NAME on KEY.
START-REGEX and END-REGEX are passed to `evil-select-paren'."
  (let ((inner-name (intern (concat "evil-inner-" name)))
        (outer-name (intern (concat "evil-a-" name))))
    `(progn
       (evil-define-text-object ,inner-name (count &optional beg end type)
         (evil-select-paren ,start-regex ,end-regex beg end type count nil))
       (evil-define-text-object ,outer-name (count &optional beg end type)
         (evil-select-paren ,start-regex ,end-regex beg end type count t))
       (define-key evil-inner-text-objects-map ,key #',inner-name)
       (define-key evil-outer-text-objects-map ,key #',outer-name))))

(defun dm-evil-text-sort-inner (textobj &optional desc)
  "Sort inside the TEXTOBJ surrounding point.
When DESC is non-nil, sort in descending order.  TEXTOBJ should
name the suffix of an `evil-inner-*' text object."
  (let ((evil-textobj (intern (format "evil-inner-%s" textobj)))
        (start-pos (point)))
    (save-excursion
      (let* ((bounds (call-interactively evil-textobj))
             (beg (cl-first bounds))
             (end (cl-second bounds)))
        (sort-lines desc beg end)))
    (goto-char start-pos)))

(defun dm-evil-text-sort-inner-paragraph (desc)
  "Sort inside the paragraph under point.
With prefix argument DESC, sort in descending order."
  (interactive "P")
  (dm-evil-text-sort-inner 'paragraph desc))

(defun dm-evil-text-sort-inner-buffer (desc)
  "Sort inside the current buffer.
With prefix argument DESC, sort in descending order."
  (interactive "P")
  (dm-evil-text-sort-inner 'buffer desc))

(defun dm-evil-text-sort-inner-curly (desc)
  "Sort inside the current curly braces.
With prefix argument DESC, sort in descending order."
  (interactive "P")
  (dm-evil-text-sort-inner 'curly desc))

(defun dm-evil-text-sort-inner-paren (desc)
  "Sort inside the current parentheses.
With prefix argument DESC, sort in descending order."
  (interactive "P")
  (dm-evil-text-sort-inner 'paren desc))

(defun dm-evil-text-sort-inner-bracket (desc)
  "Sort inside the current brackets.
With prefix argument DESC, sort in descending order."
  (interactive "P")
  (dm-evil-text-sort-inner 'bracket desc))

(defun dm-evil-text-setup ()
  "Install Daymacs Evil text objects and sort bindings."
  (dm-evil-text--define-and-bind-text-object "bracket" "[" "\\[" "\\]")
  (dm-evil-text--define-and-bind-text-object "dash" "-" "-" "-")
  (dm-evil-text--define-and-bind-text-object "dollar" "$" "\\$" "\\$")
  (dm-evil-text--define-and-bind-text-object "pipe" "|" "|" "|")
  (dm-evil-text--define-and-bind-text-object "slash" "/" "/" "/")
  (dm-evil-text--define-and-bind-text-object "underscore" "_" "_" "_")
  (evil-define-text-object evil-inner-buffer (count &optional beg end type)
    "Select inner buffer."
    :type line
    (evil-select-inner-object 'buffer beg end type count t))
  (evil-define-key* 'normal 'global
    (kbd "g s i p") #'dm-evil-text-sort-inner-paragraph
    (kbd "g s i g") #'dm-evil-text-sort-inner-buffer
    (kbd "g s i {") #'dm-evil-text-sort-inner-curly
    (kbd "g s i }") #'dm-evil-text-sort-inner-curly
    (kbd "g s i [") #'dm-evil-text-sort-inner-bracket
    (kbd "g s i ]") #'dm-evil-text-sort-inner-bracket
    (kbd "g s i (") #'dm-evil-text-sort-inner-paren
    (kbd "g s i )") #'dm-evil-text-sort-inner-paren))

(provide 'dm-evil-text)
;;; dm-evil-text.el ends here
