;;; -*- coding: utf-8; lexical-binding: t -*-

;;------------------------------------------------------------------------------
;; site-lisp 設定
;;------------------------------------------------------------------------------
;; shell-pop 設定
(global-set-key [f8] 'shell-pop)

(with-eval-after-load 'shell-pop
  (defvar shell-pop-internal-mode)
  (setq shell-pop-internal-mode "shell")

  (defvar shell-pop-internal-mode-buffer)
  (setq shell-pop-internal-mode-buffer "*shell-pop: shell*")

  (defvar shell-pop-internal-mode-func)
  (setq shell-pop-internal-mode-func (lambda () (shell)))

  (defvar shell-pop-window-size)
  (setq shell-pop-window-size 30)

  (defvar shell-pop-full-span)
  (setq shell-pop-full-span t)

  (defvar shell-pop-window-position)
  (setq shell-pop-window-position "bottom"))