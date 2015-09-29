;;; -*- coding: utf-8; lexical-binding: t -*-

;;------------------------------------------------------------------------------
;; magit
;; git クライアント
;; from package
;;------------------------------------------------------------------------------

(when (eq system-type 'windows-nt)
  (defun ad-magit-read-repository (orig-fun &rest args)
    (let ((ret_val (apply orig-fun args)))
      (if (file-directory-p ret_val) (file-truename ret_val))))
  (advice-add 'magit-read-repository :around 'ad-magit-read-repository)

  (defun ad-magit-git-str|ing (orig-fun &rest args)
    (if (and (string= (nth 1 args) "--show-toplevel") (fboundp 'cygpath))
        (cygpath "-am" (apply orig-fun args))
      (apply orig-fun args)))
  (advice-add 'magit-git-str :around 'ad-magit-git-str|ing)
  (advice-add 'magit-git-string :around 'ad-magit-git-str|ing))
