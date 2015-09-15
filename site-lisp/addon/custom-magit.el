;;; -*- coding: utf-8; lexical-binding: t -*-

;;------------------------------------------------------------------------------
;; magit
;; git クライアント
;; from package
;;------------------------------------------------------------------------------

(defun ad-magit-read-repository (orig-fun &rest args)
  (let ((ret_val (apply orig-fun args)))
	(if (file-directory-p ret_val) (file-truename ret_val))))
(advice-add 'magit-read-repository :around 'ad-magit-read-repository)

(defun ad-magit-process-git-arguments (orig-fun &rest args)
  (mapcar (lambda (x) (replace-regexp-in-string "\\^\\({.*}\\)" "^'\\1'" x))
   (apply orig-fun args)))
(advice-add 'magit-process-git-arguments :around 'ad-magit-process-git-arguments)

(defun ad-magit-git-str|ing (orig-fun &rest args)
  (let ((ret_val (apply orig-fun args)))
	(if (and (string= (nth 1 args) "--show-toplevel") ret_val)
		(cygpath "-am" ret_val)
	  ret_val)))
(advice-add 'magit-git-str :around 'ad-magit-git-str|ing)
(advice-add 'magit-git-string :around 'ad-magit-git-str|ing)
