;;; -*- coding: utf-8; lexical-binding: t -*-

;;==============================================================================
;; from package
;;==============================================================================
;;------------------------------------------------------------------------------
;; fakecygpty
;; NTEmacs の仮想端末偽装
;; https://github.com/d5884/fakecygpty
;;------------------------------------------------------------------------------
(eval-when-compile
  (defmacro fakecygpty-nt ()
    (when (eq system-type 'windows-nt)
      `(progn
         (autoload 'fakecygpty-activate "fakecygpty" t nil)
         (add-hook 'after-init-hook #'fakecygpty-activate)
         ))))
(fakecygpty-nt)

;;------------------------------------------------------------------------------
;; cygwin-mount
;; Teach EMACS about cygwin styles and mount points.
;; https://www.emacswiki.org/emacs/cygwin-mount.el
;;------------------------------------------------------------------------------
(eval-when-compile
  (when (eq system-type 'windows-nt)
    (require 'cygwin-mount)
    (defvar msys-bin (file-name-directory shell-file-name))

    (setq-default cygwin-mount-program (concat msys-bin "mount.exe"))
    (setq-default cygwin-mount-uname-program (concat msys-bin "uname.exe"))
    (cygwin-mount-build-table-internal))

  (defmacro cygwin-mount-nt ()
    (when (eq system-type 'windows-nt)
      `(progn
         (autoload 'cygwin-mount-activate "cygwin-mount" t nil)
         (add-hook 'after-init-hook #'cygwin-mount-activate)

         (with-eval-after-load 'cygwin-mount
           (setq cygwin-mount-table ',cygwin-mount-table--internal)
           (fset 'cygwin-mount-get-cygdrive-prefix (lambda () ,(cygwin-mount-get-cygdrive-prefix))))
         ))))
(cygwin-mount-nt)

;;------------------------------------------------------------------------------
;; exec-path-from-shell
;; シェルと環境変数を同期
;;------------------------------------------------------------------------------
(eval-when-compile
  (require 'exec-path-from-shell)

  (let ((add-env-vars '()))
    (when (eq system-type 'windows-nt)
      (setq add-env-vars (append add-env-vars '("LANG" "PKG_CONFIG_PATH" "http_proxy" "https_proxy"))))
    (mapc (lambda (x) (add-to-list 'exec-path-from-shell-variables x t)) add-env-vars))

  (defmacro setenv_cached-env-var (env-var-lst)
    (mapcar (lambda (x) `(setenv ,x ,(getenv x))) (eval env-var-lst)))

  (defmacro copy-envs-settings ()
    (when (and (eq system-type 'windows-nt) (fboundp 'cygpath))
      (fset 'ad-exec-path-from-shell-setenv
            (lambda (args)
              (and (string= (car args) "PATH")
                   (setf (nth 1 args) (cygpath "-amp" (nth 1 args))))
              args))
      (advice-add 'exec-path-from-shell-setenv :filter-args 'ad-exec-path-from-shell-setenv))

    ;; sync emacs environment variable with shell's one
    (exec-path-from-shell-initialize)
    `(progn
       ,@(macroexpand '(setenv_cached-env-var exec-path-from-shell-variables))
       (setq exec-path (append (split-string (getenv "PATH") path-separator) ',(last exec-path)))
  )))

(when (string= "0" (getenv "SHLVL"))
  (copy-envs-settings))

;;------------------------------------------------------------------------------
;; IME
;;------------------------------------------------------------------------------
(eval-when-compile
  (cond ((eq system-type 'windows-nt)
         (defvar w32-ime-mode-line-state-indicator)
         (defvar w32-ime-mode-line-state-indicator-list)
         (declare-function tr-ime-hook-check "tr-ime-hook")
         (declare-function w32-ime-wrap-function-to-control-ime "w32-ime")
         (declare-function tr-ime-font-reflect-frame-parameter "tr-ime-font")
         )
        ((eq system-type 'gnu/linux)
         nil
         )
        )

  (defmacro ime-settings ()
    (cond ((eq system-type 'windows-nt)
           `(progn
              ;; 無変換キーで tr-ime & w32-ime を有効化
              (global-set-key (kbd "<non-convert>")
                              (lambda ()
                                (interactive)
                                (global-unset-key (kbd "<non-convert>"))

                                ;; tr-imeの有効化
                                ;; (tr-ime-advanced-install)
                                (tr-ime-advanced-initialize)
                                (tr-ime-hook-check)))

              (with-eval-after-load 'w32-ime
                ;; 標準IMEの設定
                (setq default-input-method "W32-IME")

                ;; Windows IME の ON:[あ]/OFF:[Aa] をモードラインに表示
                (setq w32-ime-mode-line-state-indicator "[Aa]")
                (setq w32-ime-mode-line-state-indicator-list '("[Aa]" "[あ]" "[Aa]"))

                ;; IME の初期化
                (w32-ime-initialize)

                ;; IME ON/OFF時のカーソルカラー
                (add-hook 'w32-ime-on-hook (lambda () (set-cursor-color "yellow")))
                (add-hook 'w32-ime-off-hook (lambda () (set-cursor-color "thistle")))

                ;; IMEの制御(yes/noをタイプするところでは IME をオフにする)
                (w32-ime-wrap-function-to-control-ime #'universal-argument)
                (w32-ime-wrap-function-to-control-ime #'read-string)
                (w32-ime-wrap-function-to-control-ime #'read-char)
                (w32-ime-wrap-function-to-control-ime #'read-from-minibuffer)
                (w32-ime-wrap-function-to-control-ime #'y-or-n-p)
                (w32-ime-wrap-function-to-control-ime #'yes-or-no-p)
                (w32-ime-wrap-function-to-control-ime #'map-y-or-n-p)

                ;; frame font
                (modify-all-frames-parameters `((ime-font . ,(frame-parameter nil 'font))))
                (tr-ime-font-reflect-frame-parameter))
              ))
          ((eq system-type 'gnu/linux)
           `(progn
              (setq default-input-method "japanese-mozc")

              (with-eval-after-load 'mozc
                ;; (setq mozc-candidate-style 'overlay)
                ;; (require 'mozc-popup)
                ;; (setq mozc-candidate-style 'popup)
                (require 'mozc-cand-posframe)
                (setq mozc-candidate-style 'posframe)

                ;; 無変換キーのキーイベントを横取りする
                (fset 'ad-mozc-intercept-keys
                      (lambda (f event)
                        (cond
                         ((member event '(muhenkan))
                          ;; (message "%s" event) ;debug
                          (mozc-clean-up-changes-on-buffer)
                          (mozc-fall-back-on-default-binding event))
                         (t ; else
                          ;; (message "%s" event) ;debug
                          (funcall f event)))))
                (advice-add 'mozc-handle-event :around 'ad-mozc-intercept-keys))

              (global-set-key (kbd "<zenkaku-hankaku>") 'toggle-input-method)
              (global-set-key (kbd "<henkan>") (lambda () (interactive) (activate-input-method default-input-method)))
              (global-set-key (kbd "<hiragana-katakana>") (lambda () (interactive) (activate-input-method default-input-method)))
              (global-set-key (kbd "<muhenkan>") (lambda () (interactive) (deactivate-input-method)))

              ;; IME ON/OFF時のカーソルカラー
              (add-hook 'input-method-activate-hook (lambda () (set-cursor-color "yellow")))
              (add-hook 'input-method-deactivate-hook (lambda () (set-cursor-color "thistle")))
              ))
          )))
(ime-settings)

;;------------------------------------------------------------------------------
;; company
;; 補完システム
;;------------------------------------------------------------------------------
(with-eval-after-load 'company
  (eval-when-compile (require 'company))
  (setq company-idle-delay nil) ;; 遅延
  (setq company-minimum-prefix-length 3) ;; 補完開始文字長
  (setq company-selection-wrap-around t) ;; 最下時に↓で最初に戻る
  (define-key (default-value 'company-mode-map) (kbd "C-<tab>") 'company-complete))

;;------------------------------------------------------------------------------
;; company-box
;; A company front-end with icons.
;;------------------------------------------------------------------------------
(with-eval-after-load 'company
  (eval-when-compile (defvar company-box-enable-icon))
  (add-hook 'company-mode-hook 'company-box-mode)
  (setq company-box-enable-icon nil)
  ;;(setq company-box-icons-alist 'company-box-icons-all-the-icons)
  ;;(setq company-box-doc-enable nil)
  (set-face-attribute 'company-tooltip-selection nil :foreground "wheat" :background "steelblue")
  (set-face-attribute 'company-tooltip nil :background "midnight blue")
  )

;;------------------------------------------------------------------------------
;; flycheck
;; エラーチェッカー
;;------------------------------------------------------------------------------
(with-eval-after-load 'flycheck
  (eval-when-compile (require 'flycheck))
  (add-hook 'flycheck-mode-hook (lambda () (setq left-fringe-width 8))) ;; 左フリンジを有効化

  (setq flycheck-display-errors-delay 0.3) ;; 遅延
  (setq flycheck-disabled-checkers '(emacs-lisp-checkdoc)) ;; remove useless warnings
  (setq flycheck-emacs-lisp-load-path 'inherit) ;; use the `load-path' of the current Emacs session

  (declare-function flycheck-add-mode "flycheck")
  ;; (flycheck-add-mode 'emacs-lisp 'elisp-mode)
  )

;;------------------------------------------------------------------------------
;; helm
;; emacsに統一的なある”操作方式”を提供するフレームワーク
;;------------------------------------------------------------------------------
(with-eval-after-load 'helm
  (eval-when-compile (require 'helm-files))
  ;; helm-migemo を有効化
  ;; (or (featurep 'migemo) (require 'cmigemo))
  ;; (declare-function helm-migemo-mode "helm-multi-match")
  ;; (helm-migemo-mode)

  ;; http://fukuyama.co/nonexpansion
  ;; 自動補完を無効にする
  (setq helm-ff-auto-update-initial-value nil))

;; key-bind
(global-set-key (kbd "M-x") #'helm-M-x)
(global-set-key (kbd "C-x C-f") #'helm-find-files)
(global-set-key (kbd "C-x C-r") #'helm-recentf)
(global-set-key (kbd "M-y") #'helm-show-kill-ring)
(global-set-key (kbd "C-c i") #'helm-imenu)
(global-set-key (kbd "C-x C-b") #'helm-buffers-list)

;;------------------------------------------------------------------------------
;; highlight-indent-guides
;; A minor mode highlights indentation levels via font-lock.
;;------------------------------------------------------------------------------
(with-eval-after-load 'highlight-indent-guides
  (eval-when-compile (require 'highlight-indent-guides))
  ;; (setq-default highlight-indent-guides-method 'character)
  ;; (setq-default highlight-indent-guides-auto-character-face-perc 100)
  ;; (setq-default highlight-indent-guides-character ?\|)
  ;; (setq-default highlight-indent-guides-method 'column)
  (setq highlight-indent-guides-auto-odd-face-perc 40)
  (setq highlight-indent-guides-auto-even-face-perc 25))

;;------------------------------------------------------------------------------
;; irony
;; A C/C++ minor mode powered by libclang
;;------------------------------------------------------------------------------
(eval-when-compile
  (require 'irony)
  (defmacro irony-nt ()
    (when (eq system-type 'windows-nt)
      `(progn
         (with-eval-after-load 'irony
           ;; Windows Subsystem for Linux(WSL) の irony-server と共存するための設定
           ;; (setq-default irony-server-install-prefix (concat (default-value 'irony-server-install-prefix) "win-nt/"))

           ;; Set the buffer size to 64K on Windows (from the original 4K)
           (setq irony-server-w32-pipe-buffer-size (* 64 1024))

           ;; irony-server-install に失敗する問題の修正
           ;; コンパイラに clang を指定
           (fset 'ad-irony--install-server-read-command
                 (lambda (args)
                   "modify irony--install-server-read-command"
                   (setenv "CC" "clang") (setenv "CXX" "clang++")
                   `(,(replace-regexp-in-string
                       (format "^\\(%s\\)" (shell-quote-argument (default-value 'irony-cmake-executable)))
                       "\\1 -G'MSYS Makefiles'"
                       (car args)))))
           (advice-add 'irony--install-server-read-command :filter-args 'ad-irony--install-server-read-command)
           (add-hook 'irony-mode-hook #'irony-cdb-autosetup-compile-options))
         ))))
(irony-nt)

;;------------------------------------------------------------------------------
;; irony-eldoc
;; irony-mode support for eldoc-mode
;; from https://github.com/josteink/irony-eldoc
;; 本家の更新がないのでフォーク版を使用
;;------------------------------------------------------------------------------
;; (autoload 'irony-eldoc "irony-eldoc")
;; (add-hook 'irony-mode-hook 'irony-eldoc)

;; ;; 文字化け対処
;; (defun ad-irony-eldoc--strip-underscores (string)
;;   (if (or (not string) (not (default-value 'irony-eldoc-strip-underscores)))
;;       string
;;     (let ((new-string string)
;;           (regexps '(("\\_<_+" . ""))))
;;       (dolist (r regexps)
;;         (setq new-string
;;               (replace-regexp-in-string (car r) (cdr r) new-string)))
;;       new-string)))
;; (advice-add 'irony-eldoc--strip-underscores :override 'ad-irony-eldoc--strip-underscores)

;;------------------------------------------------------------------------------
;; magit
;; git クライアント
;;------------------------------------------------------------------------------
;; (eval-when-compile
;;   (defmacro magit-nt ()
;;     (when (eq system-type 'windows-nt)
;;       `(progn
;;          (with-eval-after-load 'magit-utils
;;            (unless (get-process "my-bash-process")
;;              (start-process "my-bash-process" "my-bash" "bash")
;;              (set-process-query-on-exit-flag (get-process "my-bash-process") nil)))
;;          ))))
;; (magit-nt)

(with-eval-after-load 'magit
  (eval-when-compile (defvar git-commit-summary-max-length))
  (setq git-commit-summary-max-length 999))

;;------------------------------------------------------------------------------
;; migemo
;; ローマ字入力で日本語文字列を検索
;;------------------------------------------------------------------------------
(fset 'ad-migemo-register-isearch-keybinding
      (lambda ()
        (define-key isearch-mode-map (kbd "C-M-y") 'migemo-isearch-yank-char)
        (define-key isearch-mode-map (kbd "C-w") 'migemo-isearch-yank-word)
        (define-key isearch-mode-map (kbd "M-s C-e") 'migemo-isearch-yank-line)
        (define-key isearch-mode-map (kbd "M-m") 'migemo-isearch-toggle-migemo)
        (define-key isearch-mode-map (kbd "C-y") 'isearch-yank-kill)))
(advice-add 'migemo-register-isearch-keybinding :override 'ad-migemo-register-isearch-keybinding)
(add-hook 'isearch-mode-hook (lambda () (require 'cmigemo)))

;; ------------------------------------------------------------------------------
;; plantuml-mode
;; ------------------------------------------------------------------------------
;; (eval-when-compile (require 'plantuml-mode)
;;                    (require 'smart-compile))
;; (with-eval-after-load 'plantuml-mode
;;   (setq-default plantuml-jar-path "c:/msys64/usr/local/bin/plantuml.jar")

;;   ;; javaにオプションを渡したい場合はここにかく
;;   (setq-default plantuml-java-options "")

;;   ;; plantumlのプレビュー出力形式(svg,png,txt,utxt)
;;   ;; (setq-default plantuml-output-type "txt")

;;   (setq-default plantuml-default-exec-mode 'jar)

;;   (with-eval-after-load 'smart-compile
;;     (let ((sc-cmd (concat "java -jar " plantuml-jar-path " -charset UTF-8 -tsvg %f")))
;;       (add-to-list 'smart-compile-alist `("\\.pum$" . ,sc-cmd) t)
;;       )))

;;------------------------------------------------------------------------------
;; smert compile
;;------------------------------------------------------------------------------
(with-eval-after-load 'smart-compile
  (eval-when-compile (require 'smart-compile))
  (add-to-list 'smart-compile-alist '(elisp-mode emacs-lisp-byte-compile)))
(global-set-key (kbd "C-c c") #'smart-compile)

;;------------------------------------------------------------------------------
;; vs-set-c-style
;; Visual Studio スタイルのインデント設定
;; http://yohshiy.blog.fc2.com/blog-entry-264.html
;;------------------------------------------------------------------------------
;; (autoload 'vs-set-c-style "vs-set-c-style")
