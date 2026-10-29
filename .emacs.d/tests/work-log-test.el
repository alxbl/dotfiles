;;; work-log-test.el --- Tests for the Work Log API in settings.org -*- lexical-binding: t; -*-

;; Run from the repository root:
;;   emacs -Q --batch -l .emacs.d/tests/work-log-test.el -f ert-run-tests-batch-and-exit
;;
;; The API is evaluated straight from the "Work Log API" subtree of
;; settings.org. The tests exercise exactly what gets compiled into settings.el.

(require 'ert)
(require 'org)
(require 'org-capture)
(require 'subr-x)

(defvar work-file)

(defconst wl-test--dir
  (file-name-directory (or load-file-name buffer-file-name)))

(defun wl-test--load-api ()
  "Evaluate every emacs-lisp block under the Work Log API heading."
  (with-temp-buffer
    (insert-file-contents (expand-file-name "../settings.org" wl-test--dir))
    (org-mode)
    (goto-char (point-min))
    (re-search-forward "^\\*\\* Work Log API")
    (let ((end (save-excursion (org-end-of-subtree t t) (point))))
      (while (re-search-forward "^ *#\\+BEGIN_SRC emacs-lisp" end t)
        (let ((beg (line-beginning-position 2)))
          (re-search-forward "^ *#\\+END_SRC")
          (eval (read (concat "(progn "
                              (buffer-substring-no-properties
                               beg (line-beginning-position))
                              ")"))
                t))))))

(wl-test--load-api)

(defun wl-test--today-heading ()
  (format-time-string "%F %A"))

(defmacro wl-test--with-work-file (content &rest body)
  "Run BODY with `work-file' set to a temp file holding CONTENT.
The \"w\" capture template starts a day with an empty Work Log and Notes."
  (declare (indent 1))
  `(let* ((work-file (make-temp-file "work-" nil ".org" ,content))
          (tmpl (make-temp-file "workday-" nil ".org"
                                "***** Work Log\n***** Notes\n"))
          ;; Keep capture from touching the user's bookmarks and kill ring.
          (org-capture-bookmark nil)
          (kill-ring nil)
          (org-capture-templates
           `(("w" "Start work day" entry
              (file+olp+datetree ,work-file "Diary")
              (file ,tmpl) :tree-type week :immediate-finish t
              :jump-to-captured t))))
     (unwind-protect
         (progn ,@body)
       (when-let* ((buf (get-file-buffer work-file)))
         (with-current-buffer buf (set-buffer-modified-p nil))
         (kill-buffer buf))
       (delete-file work-file)
       (delete-file tmpl))))

(defun wl-test--file-text ()
  (with-temp-buffer
    (insert-file-contents work-file)
    (buffer-string)))

(defun wl-test--past-day ()
  "A work file with one past day (2026-03-02) and no entry for today."
  (concat "* Diary\n"
          "** 2026\n"
          "*** 2026-W10\n"
          "**** 2026-03-02 Monday\n"
          "***** Worfklow [/]\n"
          "      - [ ] Dust off workspace\n"
          "***** Work Log\n"
          "- [X] Project A - Fix the widget (#1234)\n"
          "- [ ] Project A - Other widget (#12345)\n"
          "- [X] Admin - Standup (Technical Planning, 1h)\n"
          "- [-] Project A - Ongoing task (#555)\n"
          "***** Notes\n"
          "Overtime +2h\n"
          "**** 2026-03-03 Tuesday\n"
          "***** Work Log\n"
          "***** Notes\n"))

(defun wl-test--today-day ()
  "A work file whose only day is today, with an empty Work Log."
  (concat "* Diary\n** 2026\n*** W\n**** " (wl-test--today-heading) "\n"
          "***** Work Log\n***** Notes\n"))

(ert-deftest wl-test-id-normalization ()
  (should (equal (alxbl/work-log--id 123) "123"))
  (should (equal (alxbl/work-log--id "#123") "123"))
  (should (equal (alxbl/work-log--id " 123 ") "123"))
  (should-error (alxbl/work-log--id "abc") :type 'user-error)
  (should-error (alxbl/work-log--id "") :type 'user-error))

(ert-deftest wl-test-item-matches-whole-id ()
  (wl-test--with-work-file (wl-test--past-day)
    (should (equal (alxbl/work-log-item 1234 "2026-03-02")
                   "- [X] Project A - Fix the widget (#1234)"))
    (should (equal (alxbl/work-log-item "#12345" "2026-03-02")
                   "- [ ] Project A - Other widget (#12345)"))
    (should-not (alxbl/work-log-item 123 "2026-03-02"))
    (should-not (alxbl/work-log-item 1234 "2026-03-03"))
    (should-error (alxbl/work-log-item 1234 "03/02/2026") :type 'user-error)))

(ert-deftest wl-test-workon-adds-then-finds-existing ()
  (wl-test--with-work-file (wl-test--today-day)
    (should (equal (alxbl/work-log-workon 42 "Fix the thing")
                   '(added . "- [ ] Fix the thing (#42)")))
    (should (equal (alxbl/work-log-workon "#42" "Another description")
                   '(existing . "- [ ] Fix the thing (#42)")))
    (should (= 1 (with-temp-buffer
                   (insert (wl-test--file-text))
                   (how-many "(#42)" (point-min)))))
    ;; The edit is persisted since the buffer was clean.
    (should (string-match-p "- \\[ \\] Fix the thing (#42)" (wl-test--file-text)))))

(ert-deftest wl-test-workon-does-not-duplicate-id-in-text ()
  (wl-test--with-work-file (wl-test--today-day)
    (should (equal (cdr (alxbl/work-log-workon 7 "Fix #7 now"))
                   "- [ ] Fix #7 now"))))

(ert-deftest wl-test-workon-rejects-blank-text ()
  (wl-test--with-work-file (wl-test--today-day)
    (should-error (alxbl/work-log-workon 7 "  ") :type 'user-error)))

(ert-deftest wl-test-workon-creates-missing-day ()
  (wl-test--with-work-file (wl-test--past-day)
    (should (alxbl/work-log-ensure-day))
    (should-not (alxbl/work-log-ensure-day))
    (should (string-match-p (regexp-quote (wl-test--today-heading))
                            (wl-test--file-text)))
    (should (equal (car (alxbl/work-log-workon 9 "New day"))
                   'added))))

(ert-deftest wl-test-ensure-day-needs-template ()
  (wl-test--with-work-file (wl-test--past-day)
    (let ((org-capture-templates nil))
      (should-error (alxbl/work-log-ensure-day) :type 'user-error))))

(ert-deftest wl-test-check-marks-done-and-is-idempotent ()
  (wl-test--with-work-file (wl-test--past-day)
    (should (equal (alxbl/work-log-check 12345 "2026-03-02")
                   "- [X] Project A - Other widget (#12345)"))
    (should (equal (alxbl/work-log-check 12345 "2026-03-02")
                   "- [X] Project A - Other widget (#12345)"))
    (should (string-match-p "- \\[X\\] Project A - Other widget (#12345)"
                            (wl-test--file-text)))
    ;; The neighbour with a shorter id is untouched.
    (should (string-match-p "- \\[X\\] Project A - Fix the widget (#1234)"
                            (wl-test--file-text)))
    (should-error (alxbl/work-log-check 999 "2026-03-02") :type 'user-error)))

(ert-deftest wl-test-check-keeps-pending-edits-unsaved ()
  (wl-test--with-work-file (wl-test--past-day)
    (with-current-buffer (find-file-noselect work-file)
      (goto-char (point-max))
      (insert "unsaved\n"))
    (alxbl/work-log-check 12345 "2026-03-02")
    (should-not (string-match-p "unsaved" (wl-test--file-text)))
    (should-not (string-match-p "\\[X\\] Project A - Other widget"
                                (wl-test--file-text)))))

(ert-deftest wl-test-open-items ()
  (wl-test--with-work-file (wl-test--past-day)
    (should (equal (alxbl/work-log-open-items "2026-03-02")
                   '("- [ ] Project A - Other widget (#12345)"
                     "- [-] Project A - Ongoing (#555)")))
    (should-not (alxbl/work-log-open-items "2026-03-03"))
    (alxbl/work-log-check 12345 "2026-03-02")
    (alxbl/work-log-check 555 "2026-03-02")
    (should-not (alxbl/work-log-open-items "2026-03-02"))))

(ert-deftest wl-test-check-completes-in-progress-item ()
  (wl-test--with-work-file (wl-test--past-day)
    (should (equal (alxbl/work-log-check 555 "2026-03-02")
                   "- [X] Project A - Ongoing (#555)"))))

(ert-deftest wl-test-diary-has-work-log-and-notes ()
  (wl-test--with-work-file (wl-test--past-day)
    (should (equal (alxbl/work-diary "2026-03-01" "2026-03-04")
                   (concat "* 2026-03-02\n"
                           "** Work Log\n"
                           "- [X] Project A - Fix the widget (#1234)\n"
                           "- [ ] Project A - Other widget (#12345)\n"
                           "- [X] Admin - Standup (Technical Planning, 1h)\n"
                           "- [-] Project A - Ongoing (#555)\n"
                           "** Notes\n"
                           "Overtime +2h\n")))
    (should (equal (alxbl/work-diary "2026-03-03" "2026-03-03") ""))))

(ert-deftest wl-test-work-log-still-reads-range ()
  (wl-test--with-work-file (wl-test--past-day)
    (should (string-prefix-p "* 2026-03-02\n- [X] Project A - Fix the widget"
                             (alxbl/work-log "2026-03-02" "2026-03-03")))))

;;; work-log-test.el ends here
