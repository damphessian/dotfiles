;;; dm-autoload.el --- -*- lexical-binding: t; -*-

;;; Commentary:

;; Lazy-load `dm-*' modules via a generated `loaddefs.el'. The generator picks
;; up `;;;###autoload' cookies in `config/*.el' and writes one file with all
;; the `(autoload ...)' forms. We rebuild it whenever any source file is newer
;; than the cache, so adding a new module or cookie just works on next boot.

;;; Code:

(let* ((loaddefs (expand-file-name "loaddefs.el" dm-modules-dir))
       (sources (and (file-directory-p dm-modules-dir)
                     (directory-files dm-modules-dir t "\\`dm-.*\\.el\\'")))
       (stale (or (not (file-exists-p loaddefs))
                  (let ((cached (file-attribute-modification-time
                                 (file-attributes loaddefs))))
                    (seq-some (lambda (f)
                                (time-less-p
                                 cached
                                 (file-attribute-modification-time
                                  (file-attributes f))))
                              sources)))))
  (when stale
    (require 'loaddefs-gen)
    ;; `loaddefs-generate' reports each scrape pass with INFO messages. Keep
    ;; startup quiet while preserving the automatic autoload refresh.
    (let ((inhibit-message t)
          (message-log-max nil))
      (loaddefs-generate dm-modules-dir loaddefs)))
  (load loaddefs nil 'nomessage))

(provide 'dm-autoload)
;;; dm-autoload.el ends here
