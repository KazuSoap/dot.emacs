;;; -*- coding: utf-8; lexical-binding: t -*-

;;------------------------------------------------------------------------------
;; site-lisp 設定
;;------------------------------------------------------------------------------
;; auto-async-byte-compile 設定
(let ((loadfile "auto-async-byte-compile"))
  (cond ((autoload-if-found 'enable-auto-async-byte-compile-mode loadfile t)
		 (add-hook 'emacs-lisp-mode-hook 'enable-auto-async-byte-compile-mode)
		 (with-eval-after-load 'auto-async-byte-compile
		   (defvar auto-async-byte-compile-init-file)
		   (setq auto-async-byte-compile-init-file "~/.emacs.d/init.elc")
		   (defvar auto-async-byte-compile-exclude-files-regexp)
		   (setq auto-async-byte-compile-exclude-files-regexp "/elpa/*/*")))
		(t (display-loading-error-message loadfile))))
