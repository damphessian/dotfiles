;;; dm-env.el --- Daymacs environment import  -*- lexical-binding: t; -*-

;;; Commentary:

;; Import shell environment variables needed by subprocesses. Deferred slightly
;; so the first frame can come up before shell startup work runs.

;;; Code:

(use-package exec-path-from-shell
  :if (memq window-system '(mac ns x))
  :defer 0.1
  :custom
  (exec-path-from-shell-variables
   '("DOCKER_HOST"
     "GIT_CG_PROVIDER"
     "GOPATH"
     "HEX_HOME"
     "IPYTHONDIR"
     "MANPATH"
     "MISE_DIR"
     "OLLAMA_API_KEY"
     "OPENAI_API_KEY"
     "OPENAI_API_KEY_GIT"
     "ORG_HOME"
     "PATH"
     "PERL_CPANM_HOME"
     "PNPM_HOME"
     "RUSTUP_HOME"
     "XDG_CACHE_HOME"
     "XDG_CONFIG_DIRS"
     "XDG_CONFIG_HOME"
     "XDG_DATA_HOME"
     "XDG_LOCALS_DIR"
     "XDG_RUNTIME_DIR"
     "XDG_SECURE_DIR"
     "XDG_STATE_HOME"))
  :config
  (exec-path-from-shell-initialize))

(provide 'dm-env)
;;; dm-env.el ends here
