;; Thanks, @zellio.
(setq-default
 inhibit-startup-message        t
 default-tab-width              2
 c-basic-offset                 4
 kill-whole-line                t
 truncate-partial-width-windows nil
 fill-column                    80
 indicate-empty-lines           t
 line-number-mode               t
 column-number-mode             t
 visible-bell                   t)

;; Make some room for generated files
(make-directory "~/.emacs.d/autosave/" t)
(make-directory "~/.emacs.d/backup/"   t)
(make-directory "~/.emacs.d/recovery/" t)

(setq
 auto-save-list-file-prefix     "~/.emacs.d/recovery/"
 auto-save-file-name-transforms '((".*" "~/.emacs.d/autosave/\\1" t)))

(setq
 backup-by-copying      t
 backup-directory-alist '((".*" . "~/.emacs.d/backup/"))
 delete-old-versions    t
 kept-new-versions      3
 kept-old-versions      2
 version-control        t)

;; Tidy up files
(add-hook 'before-save-hook (lambda () (delete-trailing-whitespace)))


;; TABS
(setq-default indent-tabs-mode nil)       ;; Turn off '\t' character
(setq-default standard-indent 2)          ;; Set indent to "  "
(setq-default tab-width 2)                ;; Set indent to "  "

(defun smart-indent ()
  "Indents region if mark is active, or current line otherwise."
  (interactive)
  (if mark-active
      (indent-region (region-beginning)
                     (region-end))
    (indent-for-tab-command)))

(global-set-key (kbd "TAB") 'smart-indent)

(global-linum-mode)
