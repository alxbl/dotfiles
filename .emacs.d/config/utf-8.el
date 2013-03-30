;; Original: https://github.com/zellio/emacs-config/
;;; utf-8.el --- Unicode Configuration

;; Copyright (C) 2012,2013 Zachary Elliott
;; See LICENSE for more information

;; This file is not part of GNU Emacs.

;;; Commentary:

;;

;;; Code:

(require 'un-define "un-define" t)

(set-default-coding-systems 'utf-8)
(set-terminal-coding-system 'utf-8)
(set-keyboard-coding-system 'utf-8)

(setq-default
 buffer-file-coding-system         'utf-8-unix
 default-buffer-file-coding-system 'utf-8-unix
 x-select-request-type             '(UTF8_STRING COMPOUND_TEXT TEXT STRING))

(set-buffer-file-coding-system 'utf-8 'utf-8-unix)
(set-default-coding-systems 'utf-8-unix)

(prefer-coding-system 'utf-8-unix)

;; MS Windows clipboard is UTF-16LE
;(set-clipboard-coding-system 'utf-16le-dos)

;; end of utf-8.el
