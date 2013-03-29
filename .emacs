;; PATH
(add-to-list 'load-path "~/.emacs.d/")

;; GENERIC
(setq backup-directory-alist    '((".*" . "~/.trash"))) ; Avoid clutter

;; THEMES (https://github.com/zellio/emacs-config/blob/master/config/theme.el)
(let ((theme-dir "~/.emacs.d/themes"))
  (let ((themes (directory-files theme-dir)))
    (dolist (theme themes)
      (unless (string= "." (substring theme 0 1))
        (add-to-list 'custom-theme-load-path (concat theme-dir "/" theme))))))
;;
(load-theme 'solarized-dark)


;; CONFIGURATION
(load "utf-8")
