;; PATH
(add-to-list 'load-path "~/.emacs.d/config")
(load "vendor")

;; THEMES (https://github.com/zellio/emacs-config/blob/master/config/theme.el)
(unless (boundp 'custom-theme-load-path)
  (defvaralias 'custom-theme-load-path 'load-path))

(unless (boundp 'custom-safe-themes)
  (setq custom-safe-themes '()))

(let ((theme-dir "~/.emacs.d/themes"))
  (let ((themes (directory-files theme-dir)))
    (dolist (theme themes)
      (unless (string= "." (substring theme 0 1))
        (add-to-list 'custom-theme-load-path (concat theme-dir "/" theme))))))

;; SHA256 for "safe" theme load
(dolist (hash '(
  ;; Solarized Dark
  "fc5fcb6f1f1c1bc01305694c59a1a861b008c534cae8d0e48e4d5e81ad718bc6"
  ;; Solarized Light
  "1e7e097ec8cb1f8c3a912d7e1e0331caeed49fef6cff220be63bd2a6ba4cc365"))
  (add-to-list 'custom-safe-themes hash))

(load-theme 'solarized-dark)


;; CONFIGURATION
(load "env") ; Global environment settings

(vendor 'yasnippet) ; Snippets
(yas-global-mode 1)

(vendor 'inf-ruby) ; Ruby
(vendor 'ruby-mode)
(vendor 'rinari)

(vendor 'ido-mode) ; IDO
(ido-mode t)

(vendor 'lua-mode) ; Lua
(load "utf-8")
