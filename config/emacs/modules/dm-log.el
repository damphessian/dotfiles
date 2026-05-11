;;; dm-log --- Summary: Daymacs logging facilities  -*- lexical-binding: t; -*-

;;; Commentary:
;;
;; Basic logging facilities.
;;
;; Usage:
;; ```
;; (dm-log :debug "debug message")
;; (dm-log :info  "info message")
;; (dm-log :warn  "warn message")
;; (dm-log :error "error message")
;; ```
;;
;; ```
;; % DM_LOG_LEVEL=warn emacs -nw
;; # ...
;; # warn message
;; # error message
;; # ...
;; ```

;;; Code:

(defvar dm-log-level nil
  "Current logging level.
One of :debug, :info, :warn, :error. If nil, `dm-log-initialize' will initialize
it from env DM_LOG_LEVEL,falling back to :error.")

(defconst dm-log--levels
  '((:debug . 0)
    (:info  . 1)
    (:warn  . 2)
    (:error . 3))
  "Numeric severity ordering for DM logging levels.")

(defun dm-log-set-level (&optional level)
  "Set `dm-log-level`.

If LEVEL is nil, read from DM_LOG_LEVEL. Fall back to :error."
  (setq dm-log-level
        (or (dm-log--coerce-level level)
            (dm-log--coerce-level (getenv "DM_LOG_LEVEL"))
            :error)))

(defun dm-log-initialize ()
  "Initialize `dm-log-level' if it hasn't already been set."
  (unless dm-log-level
    (dm-log-set-level)))

(defun dm-log--valid-level-p (level)
  "Return non-nil if LEVEL is a valid DM log level."
  (assq level dm-log--levels))

(defun dm-log--coerce-level (value)
  "Convert VALUE to a DM log level keyword.

VALUE may be a keyword like :info or a string like \"info\"."
  (cond
   ((dm-log--valid-level-p value)
    value)
   ((stringp value)
    (let ((level (intern (concat ":" (downcase value)))))
      (when (dm-log--valid-level-p level)
        level)))
   (t nil)))

(defun dm-log--level-value (level)
  "Return numeric severity for LEVEL."
  (or (cdr (assq level dm-log--levels))
      (error "Unknown log level: %S" level)))

(defun dm-logp (level)
  "Return non-nil if LEVEL should be logged at `dm-log-level`."
  (>= (dm-log--level-value level)
      (dm-log--level-value dm-log-level)))

(defun dm-log (level fmt &rest args)
  "Log a message at LEVEL if it passes `dm-logp`."
  (when (dm-logp level)
    (apply #'message
           (concat "[dm:" (substring (symbol-name level) 1) "] " fmt)
           args)))

(provide 'dm-log)
;;; dm-log.el ends here
