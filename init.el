;;; init.el --- -*- coding: utf-8; lexical-binding: t -*-
;;; Commentary:
;;; Code:

;;==============================================================================
;; from package
;;==============================================================================
;;------------------------------------------------------------------------------
;; cygwin-mount
;; teach EMACS about cygwin styles and mount points
;; https://www.emacswiki.org/emacs/cygwin-mount.el
;;------------------------------------------------------------------------------
;; fakecygpty
;; cygwin's pty feature for NTEmacs
;; https://github.com/d5884/fakecygpty
;;------------------------------------------------------------------------------
(with-eval-after-load 'shell
  (require 'my-package))

;;------------------------------------------------------------------------------
;; IME
;;------------------------------------------------------------------------------
(eval-when-compile
  (defmacro set-my-ime ()
    (cond ((eq system-type 'windows-nt)
           (declare-function tr-ime-hook-check "tr-ime-hook")

           `(progn
              ;; 無変換キーで tr-ime & w32-ime を有効化
              (global-set-key (kbd "<non-convert>")
                              (lambda ()
                                (interactive)
                                (global-unset-key (kbd "<non-convert>"))

                                ;; tr-imeの有効化
                                ;; (tr-ime-advanced-install)
                                (tr-ime-advanced-initialize)
                                (tr-ime-hook-check)

                                (require 'my-package)))))

          ((eq system-type 'gnu/linux)
           `(progn
              (setq default-input-method "japanese-mozc")
              (global-set-key (kbd "<zenkaku-hankaku>") 'toggle-input-method)
              (global-set-key (kbd "<henkan>") (lambda () (interactive) (activate-input-method default-input-method)))
              (global-set-key (kbd "<hiragana-katakana>") (lambda () (interactive) (activate-input-method default-input-method)))
              (global-set-key (kbd "<muhenkan>") (lambda () (interactive) (deactivate-input-method)))

              (with-eval-after-load 'mozc
                (require 'my-package))))
          )))
(set-my-ime)

;;------------------------------------------------------------------------------
;; helm
;; an Emacs incremental and narrowing framework
;;------------------------------------------------------------------------------
(global-set-key (kbd "M-x") #'helm-M-x)
(global-set-key (kbd "C-x C-f") #'helm-find-files)
(global-set-key (kbd "C-x C-r") #'helm-recentf)
(global-set-key (kbd "M-y") #'helm-show-kill-ring)
(global-set-key (kbd "C-c i") #'helm-imenu)
(global-set-key (kbd "C-x C-b") #'helm-buffers-list)

;;------------------------------------------------------------------------------
;; migemo
;; Japanese incremental search through dynamic pattern expansion
;;------------------------------------------------------------------------------
(add-hook 'isearch-mode-hook (lambda () (require 'shell) (require 'cmigemo)))

;;==============================================================================
;; major-mode
;;==============================================================================
;;------------------------------------------------------------------------------
;; markdown-mode
;;------------------------------------------------------------------------------
(with-eval-after-load 'markdown-mode
  (eval-when-compile (require 'markdown-mode))
  (setq markdown-fontify-code-blocks-natively t)
  (setq markdown-content-type "application/xhtml+xml")
  (setq markdown-css-paths '("https://cdn.jsdelivr.net/npm/github-markdown-css/github-markdown.min.css"))
  (setq markdown-xhtml-header-content "
<style>
body {
  box-sizing: border-box;
  width: 100%;
  margin: 40px auto;
  padding: 0 10px;
}
</style>
<script>
document.addEventListener('DOMContentLoaded', () => {
  document.body.classList.add('markdown-body');
});
</script>
" ))

;;------------------------------------------------------------------------------
;; plantuml-mode
;;------------------------------------------------------------------------------
(with-eval-after-load 'plantuml-mode
  (eval-when-compile (require 'plantuml-mode))

  (setq plantuml-jar-path
        (eval-when-compile (locate-file "plantuml" exec-path '(".jar"))))

  ;; specify the desired output type to use for generated diagrams(svg,png,txt)
  (setq plantuml-output-type "png")
  (setq plantuml-default-exec-mode 'jar))

;;------------------------------------------------------------------------------
;; web-mode
;;------------------------------------------------------------------------------
(with-eval-after-load 'web-mode
  (eval-when-compile (require 'web-mode))

  (setq web-mode-engines-alist '(("php" . "\\.phtml\\'")))

  (setq web-mode-content-types-alist '(("js" . "\\.\\(js[x]\\|vue\\)?\\'")))
  (add-to-list 'web-mode-comment-formats '("javascript" . "//" ))

  (setq indent-tabs-mode nil)
  (setq web-mode-enable-current-element-highlight t)
  )

;;------------------------------------------------------------------------------
;; auto-mode-alist
;;------------------------------------------------------------------------------
(add-to-list 'auto-mode-alist '("\\.elc\\'" . fundamental-mode))
(add-to-list 'auto-mode-alist '("\\.\\(html?\\|ptml?\\|php?\\|tpl?\\|js\\(on\\)?\\|vue?\\)\\'" . web-mode))
(add-to-list 'auto-mode-alist '("\\.puml?\\'" . plantuml-mode))
(add-to-list 'auto-mode-alist '("\\.md\\'" . gfm-mode))

;;------------------------------------------------------------------------------
;; major-mode-hook
;;------------------------------------------------------------------------------
(eval-when-compile
  (require 'cc-mode)
  (require 'python))

;; 共通
(eval-when-compile
  (declare-function my-mode-setup "init.el"))

(fset 'my-mode-setup
      (lambda ()
        (require 'my-package)
        (display-line-numbers-mode)
        (whitespace-mode) ;; whitespace
        ))

;; プログラミング言語共通
(eval-when-compile
  (declare-function my-prog-mode-setup "init.el"))

(fset 'my-prog-mode-setup
      (lambda (tab-w)
        (my-mode-setup)

        (setq tab-width tab-w) ;; tab 幅
        (setq truncate-lines t) ;; 画面外文字の切り詰め
        (setq truncate-partial-width-windows t) ;; 縦分割時の画面外文字の切り詰め
        ;; (show-paren-mode) ; default on
        (company-mode) ;; 補完
        ))

;; c/c++-mode共通
(eval-when-compile
  (declare-function my-c/c++-mode-setup "init.el"))

(fset 'my-c/c++-mode-setup
      (lambda (irony-option)
        ;; (eldoc-mode)
        (flycheck-mode)
        (flycheck-irony-setup)
        (ggtags-mode)
        (irony-mode)
        (google-set-c-style)
        (google-make-newline-indent)
        (setq c-basic-offset 4)
        (add-to-list (make-local-variable 'company-backends) '(company-irony))

        ;; irony 追加のコンパイルオプションを設定
        (setq irony-additional-clang-options irony-option)
        ))

;;; built-in
;; text-mode
(add-hook 'text-mode-hook #'my-mode-setup)

;; emacs-lisp-mode
(add-hook 'emacs-lisp-mode-hook
          (lambda ()
            (my-prog-mode-setup 4)
            (flycheck-mode)
            ))

;; c-mode-common
(add-hook 'c-mode-common-hook
          (lambda ()
            (my-prog-mode-setup 4)
            ))

;; c-mode
(add-hook 'c-mode-hook
          (lambda ()
            (my-c/c++-mode-setup '("-std=c99"))
            ))

;; c++-mode
(add-hook 'c++-mode-hook
          (lambda ()
            (my-c/c++-mode-setup '("-std=c++14"))
            ))

;; sh-mode
(add-hook 'sh-mode-hook
          (lambda ()
            (my-prog-mode-setup 4)
            (flycheck-mode)
            ))

;; python-mode
(add-hook 'python-mode-hook
          (lambda ()
            (my-prog-mode-setup 4)
            ;; (ggtags-mode)
            ;; (setq flycheck-disabled-checkers '(python-mypy))
            (highlight-indent-guides-mode)
            (setq python-indent-offset 4)
            ))

;;; from package
;; plantuml-mode
(add-hook 'plantuml-mode-hook
          (lambda ()
            (my-prog-mode-setup 2)
            (flycheck-mode)
            (flycheck-plantuml-setup)
            (setq plantuml-indent-level 2)
            ))

;; web mode
(add-hook 'web-mode-hook
          (lambda ()
            (my-prog-mode-setup 2)
            ;; (highlight-indent-guides-mode)

            (setq web-mode-markup-indent-offset 2)
            (setq web-mode-css-indent-offset 2)
            (setq web-mode-code-indent-offset 2)
            ))

;;; init.el ends here
