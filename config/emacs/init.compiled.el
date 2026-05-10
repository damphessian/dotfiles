;;; ————————————————————————————
;;; Preamble for compiling (for debugging)
;;; ————————————————————————————
;; For enabling flymake checking:

(eval-and-compile
  (defconst dm-config-home (file-name-as-directory (file-truename "~/.config/emacs")))
  ;; Trust config directory
  (add-to-list 'trusted-content (abbreviate-file-name dm-config-home))
  ;; Add submodule directory to load path
  (add-to-list 'load-path (expand-file-name "config/" dm-config-home))
  ;; For Flymake: Add straight.el build directories to load path at compile time
  (let ((build-dir (expand-file-name "straight/build/" dm-config-home)))
    (when (file-directory-p build-dir)
      (dolist (dir (directory-files build-dir t "\\`[^.]"))
        (when (file-directory-p dir)
          (add-to-list 'load-path dir))))))
