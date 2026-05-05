;;; dm-test-toggle --- Summary: Daymacs test toggle helpers

;;; Commentary:

;;; Code:

(require 'project)
(require 'seq)
(require 'subr-x)

(defvar dm-test-toggle-rules
  '((:impl-dir "app/"  :test-dir "spec/" :test-suffix "_spec")
    (:impl-dir "lib/"  :test-dir "test/" :test-suffix "_test")
    (:impl-dir "src/"  :test-dir "test/" :test-suffix "_test")
    (:impl-dir "src/"  :test-dir "__tests__/" :test-suffix ".test"))
  "Rules for toggling between implementation and test files.")

(defun dm-project-files ()
  "Return project files for the current project."
  (let ((project (project-current t)))
    (project-files project)))

(defun dm-project-root ()
  "Return current project root."
  (project-root (project-current t)))

(defun dm-file-in-dir-p (file dir)
  "Return non-nil if FILE is under DIR."
  (string-prefix-p dir file))

(defun dm-test-toggle-same-file-p (a b root)
  "Return non-nil if A and B name the same file under ROOT."
  (string= (file-truename (expand-file-name a root))
           (file-truename (expand-file-name b root))))

(defun dm-replace-prefix (s old new)
  "Replace OLD prefix in S with NEW."
  (concat new (string-remove-prefix old s)))

(defun dm-test-file-p (relfile)
  "Return non-nil if RELFILE looks like a test file."
  (or (string-match-p "\\(_spec\\|_test\\|\\.test\\|\\.spec\\)\\." relfile)
      (string-match-p "\\`\\(test\\|spec\\|__tests__\\)/" relfile)))

(defun dm-possible-related-test-files (relfile)
  "Return configured candidate relatives for RELFILE."
  (let ((ext (file-name-extension relfile t))
        (base (file-name-sans-extension relfile)))
    (seq-mapcat
     (lambda (rule)
       (let ((impl-dir (plist-get rule :impl-dir))
             (test-dir (plist-get rule :test-dir))
             (suffix (plist-get rule :test-suffix)))
         (when (string-prefix-p impl-dir relfile)
           (list
            (concat test-dir
                    (file-name-sans-extension
                     (string-remove-prefix impl-dir relfile))
                    suffix
                    ext)))))
     dm-test-toggle-rules)))

(defun dm-possible-related-impl-files (relfile)
  "Return configured candidate implementation relatives for RELFILE."
  (let ((ext (file-name-extension relfile t)))
    (seq-mapcat
     (lambda (rule)
       (let* ((impl-dir (plist-get rule :impl-dir))
              (test-dir (plist-get rule :test-dir))
              (suffix (plist-get rule :test-suffix))
              (without-test-dir
               (and (string-prefix-p test-dir relfile)
                    (string-remove-prefix test-dir relfile)))
              (without-ext
               (and without-test-dir
                    (file-name-sans-extension without-test-dir))))
         (when (and without-ext
                    (string-suffix-p suffix without-ext))
           (list
            (concat impl-dir
                    (string-remove-suffix suffix without-ext)
                    ext)))))
     dm-test-toggle-rules)))

(defun dm-related-file-candidates (relfile project-files root)
  "Return candidate related files for RELFILE from PROJECT-FILES."
  (let* ((configured
          (if (dm-test-file-p relfile)
              (dm-possible-related-impl-files relfile)
            (dm-possible-related-test-files relfile)))
         (existing-configured
          (seq-filter
           (lambda (f)
             (and (member f project-files)
                  (not (dm-test-toggle-same-file-p f relfile root))))
           configured)))
    (if existing-configured
        existing-configured
      (dm-test-toggle-discover-candidates relfile project-files root))))

(defun dm-test-toggle-normalized-base (file)
  "Return FILE basename with common test affixes removed."
  (let ((base (file-name-base file)))
    (setq base (string-remove-prefix "test_" base))
    (setq base (string-remove-prefix "spec_" base))
    (setq base (replace-regexp-in-string "\\(_test\\|_spec\\|\\.test\\|\\.spec\\)\\'" "" base))
    base))

(defun dm-test-toggle-file-score (needle file)
  "Return a similarity score for NEEDLE against FILE, or nil."
  (let* ((base (file-name-base file))
         (normalized (dm-test-toggle-normalized-base file)))
    (cond
     ;; Best: exact normalized basename match.
     ((string= needle normalized) 100)
     ;; Good: exact raw basename match.
     ((string= needle base) 90)
     ;; Decent: basename contains the normalized target.
     ((string-match-p (regexp-quote needle) normalized) 70)
     ;; Weak: full path contains the normalized target.
     ((string-match-p (regexp-quote needle) file) 40)
     ;; Fail
     (t nil))))

(defun dm-test-toggle-discover-candidates (relfile project-files root)
  "Find fallback related files for RELFILE among PROJECT-FILES."
  (let* ((needle (dm-test-toggle-normalized-base relfile))
         (current-ext (file-name-extension relfile t))
         (scored
          (delq nil
                (mapcar
                 (lambda (file)
                   (unless (dm-test-toggle-same-file-p file relfile root)
                     (let ((score (dm-test-toggle-file-score needle file)))
                       (when score
                         ;; Prefer same extension a little.
                         (when (string= current-ext
                                        (file-name-extension file t))
                           (setq score (+ score 5)))
                         ;; Prefer src/lib/app over test/spec when coming from a test.
                         (when (and (dm-test-file-p relfile)
                                    (string-match-p "\\`\\(src\\|lib\\|app\\)/" file))
                           (setq score (+ score 10)))
                         ;; Prefer test/spec when coming from implementation.
                         (when (and (not (dm-test-file-p relfile))
                                    (dm-test-file-p file))
                           (setq score (+ score 10)))
                         (cons score file)))))
                 project-files))))
    (mapcar #'cdr
            (sort scored
                  (lambda (a b)
                    (> (car a) (car b)))))))

(defun dm-toggle-test-implementation ()
  "Toggle between implementation and test file using project.el."
  (interactive)
  (unless buffer-file-name
    (user-error "Current buffer is not visiting a file"))
  (let* ((root (dm-project-root))
         (relfile (file-relative-name buffer-file-name root))
         (files (dm-project-files))
         (candidates (dm-related-file-candidates relfile files root)))
    (cond
     ((null candidates)
      (user-error "No related test/implementation file found"))
     ((= (length candidates) 1)
      (find-file (expand-file-name (car candidates) root)))
     (t
      (find-file
       (expand-file-name
        (completing-read "Related file: " candidates nil t)
        root))))))

(provide 'dm-test-toggle)
;;; dm-test-toggle.el ends here
