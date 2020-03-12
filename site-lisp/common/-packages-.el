;;; -*- coding: utf-8; lexical-binding: t -*-

;;==============================================================================
;; emacs built in package
;;==============================================================================
;;------------------------------------------------------------------------------
;; auto-insert
;; ファイルの種類に応じたテンプレートの挿入
;;------------------------------------------------------------------------------
(eval-when-compile (require 'autoinsert))
(with-eval-after-load 'autoinsert
  ;; テンプレートのディレクトリ
  (setq-default auto-insert-directory (eval-when-compile (expand-file-name (concat user-emacs-directory "auto-insert"))))

  ;; テンプレート中で展開してほしいテンプレート変数を定義
  (setq-default template-replacements-alists
                `(("%file%"             . ,(lambda () (file-name-nondirectory (buffer-file-name))))
                  ("%file-without-ext%" . ,(lambda () (file-name-sans-extension (file-name-nondirectory (buffer-file-name)))))
                  ("%include-guard%"    . ,(lambda () (format "INCLUDE_%s_H" (upcase (file-name-sans-extension (file-name-nondirectory (buffer-file-name)))))))))

  (fset 'my-template
        (lambda ()
          (time-stamp)
          (dolist (c (default-value 'template-replacements-alists))
            (goto-char (point-min))
            (while (search-forward (car c) nil t)
              (replace-match (funcall (cdr c)))))
          (goto-char (point-max))
          (message "done.")))

  ;; 各ファイルによってテンプレートを切り替える
  (add-to-list 'auto-insert-alist '("\\.cpp$"   . ["template.cpp" my-template]))
  (add-to-list 'auto-insert-alist '("\\.h$"     . ["template.h" my-template]))
  (add-to-list 'auto-insert-alist '("Makefile$" . ["template.make" my-template])))

(add-hook 'find-file-not-found-hooks #'auto-insert)

;;------------------------------------------------------------------------------
;; cua-mode
;; C-Ret で矩形選択
;;------------------------------------------------------------------------------
;; 詳しいキーバインド操作：http://dev.ariel-networks.com/articles/emacs/part5/
;; (with-eval-after-load 'cua-base
;;   (setq-default cua-enable-cua-keys nil))
(global-set-key (kbd "C-<return>") 'cua-rectangle-mark-mode)

;;------------------------------------------------------------------------------
;; display-line-numbers-mode
;; 行番号の表示
;;------------------------------------------------------------------------------
(with-eval-after-load 'display-line-numbers
  (set-face-attribute 'line-number nil :background "gray10")
  (set-face-attribute 'line-number-current-line nil :background "gray40"))

;;------------------------------------------------------------------------------
;; display-time
;; 時刻の表示
;;------------------------------------------------------------------------------
;; (setq-default display-time-string-forms
;;       '((format "%s/%s/%s(%s) %s:%s " year month day dayname 24-hours minutes)
;;         load))
;; (setq-default display-time-24hr-format t)
;; (display-time)

;;------------------------------------------------------------------------------
;; ediff
;;------------------------------------------------------------------------------
(setq-default ediff-window-setup-function 'ediff-setup-windows-plain)

;;------------------------------------------------------------------------------
;; eldoc
;;------------------------------------------------------------------------------
(with-eval-after-load 'eldoc
  (setq-default eldoc-idle-delay 0.5)) ;; eldoc 遅延

;;------------------------------------------------------------------------------
;; GDB
;; デバッガ
;;------------------------------------------------------------------------------
;; ;;; 有用なバッファを開くモード
;; (setq-default gdb-many-windows t)

;; ;;; 変数の上にマウスカーソルを置くと値を表示
;; (add-hook 'gdb-mode-hook 'gud-tooltip-mode)

;; ;;; I/O バッファを表示
;; (setq-default gdb-use-separate-io-buffer t)

;; ;;; t にすると mini buffer に値が表示される
;; (setq-default gud-tooltip-echo-area nil)

;;------------------------------------------------------------------------------
;; TRAMP(TransparentRemoteAccessMultipleProtocol)
;; edit remoto file from local emacs
;;------------------------------------------------------------------------------
(with-eval-after-load 'tramp
  (declare-function tramp-change-syntax "tramp")
  (tramp-change-syntax 'simplified) ;; Emacs 26.1 or later
  (setq-default tramp-encoding-shell "bash")

  ;; リモートサーバで shell を開いた時に日本語が文字化けしないよう、LC_ALL の設定を無効にする
  ;; http://www.gnu.org/software/emacs/manual/html_node/tramp/Remote-processes.html#Running%20a%20debugger%20on%20a%20remote%20host
  (let ((process-environment (default-value 'tramp-remote-process-environment)))
    (setenv "LC_ALL" nil)
    (setq-default tramp-remote-process-environment process-environment)))

;;------------------------------------------------------------------------------
;; uniquify
;; 同一ファイル名を区別する
;;------------------------------------------------------------------------------
;; 表示形式指定(default: 'post-forward-angle-brackets)
;; (setq-default uniquify-buffer-name-style 'post-forward-angle-brackets)

;; 無視するバッファ名
(setq-default uniquify-ignore-buffers-re "*[^*]+*")

;;------------------------------------------------------------------------------
;; whitespace-mode
;; 不可視文字の可視化
;;------------------------------------------------------------------------------
(with-eval-after-load 'whitespace
  ;; 保存時に行末の空白を削除する
  (add-hook 'before-save-hook #'delete-trailing-whitespace)

  ;; 可視化する不可視文字のリスト
  (setq-default whitespace-style '(face tabs tab-mark newline newline-mark spaces space-mark trailing))

  ;; 表示の変更
  (setq-default whitespace-display-mappings
        '(;; space → " "
          (space-mark   ?\xA0   [?\u00A4]     [?_])
          (space-mark   ?\x8A0  [?\x8A4]      [?_])
          (space-mark   ?\x920  [?\x924]      [?_])
          (space-mark   ?\xE20  [?\xE24]      [?_])
          (space-mark   ?\xF20  [?\xF24]      [?_])
          ;; full-width-space → "□"
          (space-mark   ?\u3000 [?\u25a1]     [?_ ?_])
          ;; tab → "»" with underline
          (tab-mark     ?\t     [?\xBB ?\t]   [?\\ ?\t])
          ;; newline → "｣"
          (newline-mark ?\n     [?\uFF63 ?\n] [?$ ?\n])))

  ;; 以下の正規表現にマッチするものを"space"と認識
  (setq-default whitespace-space-regexp "\\(\u3000+\\)")

  ;; face
  (set-face-attribute 'whitespace-space nil :foreground "GreenYellow" :background "black")
  (set-face-attribute 'whitespace-tab nil :foreground "LightSkyBlue" :background "black" :underline t)
  (set-face-attribute 'whitespace-newline nil :foreground "DeepSkyBlue")
  (set-face-attribute 'whitespace-trailing nil :background "DeepPink"))

;;------------------------------------------------------------------------------
;; windmove
;; Emacsの分割ウィンドウを modifier-key + 矢印キー で移動
;;------------------------------------------------------------------------------
(fset 'activate-windmove
      (lambda ()
        (unless (boundp 'windmove-wrap-around)
          (windmove-default-keybindings 'meta) ;; modifier-key = Alt
          (setq-default windmove-wrap-around t) ;; wrap-around を有効化
          (remove-hook 'window-configuration-change-hook 'activate-windmove) ;; 呼出し後 hook から削除
          (fmakunbound 'activate-windmove)))) ;; 呼出し後シンボルの関数ポインタを "void" にする
(add-hook 'window-configuration-change-hook 'activate-windmove)

;;------------------------------------------------------------------------------
;; vc-mode
;; バージョン管理
;;------------------------------------------------------------------------------
;; vcを起動しない
(setq-default vc-handled-backends nil)

;; vc 関係の hook 削除
(remove-hook 'find-file-hook 'vc-find-file-hook)
(remove-hook 'kill-buffer-hook 'vc-kill-buffer-hook)

;;==============================================================================
;; from package
;;==============================================================================
;;------------------------------------------------------------------------------
;; company
;; 補完システム
;;------------------------------------------------------------------------------
(with-eval-after-load 'company
  (setq-default company-idle-delay nil) ;; 遅延
  (setq-default company-minimum-prefix-length 3) ;; 補完開始文字長
  (setq-default company-selection-wrap-around t) ;; 最下時に↓で最初に戻る
  (define-key (default-value 'company-mode-map) (kbd "C-<tab>") 'company-complete))

;;------------------------------------------------------------------------------
;; company-box
;; A company front-end with icons.
;;------------------------------------------------------------------------------
(with-eval-after-load 'company
  (add-hook 'company-mode-hook 'company-box-mode)
  (setq-default company-box-enable-icon nil)
  ;;(setq-default company-box-icons-alist 'company-box-icons-all-the-icons)
  ;;(setq-default company-box-doc-enable nil)
  (set-face-attribute 'company-tooltip-selection nil :foreground "wheat" :background "steelblue")
  (set-face-attribute 'company-tooltip nil :background "midnight blue")
  )

;;------------------------------------------------------------------------------
;; elscreen
;; ウィンドウ構成管理
;;------------------------------------------------------------------------------
(with-eval-after-load 'elscreen
  (setq-default elscreen-display-tab t) ;; tabの表示および幅の設定
  (setq-default elscreen-display-screen-number nil) ;; modelineへの番号表示
  (setq-default elscreen-tab-display-kill-screen nil) ;; タブの先頭に[X]を表示しない
  (setq-default elscreen-tab-display-control nil) ;; header-lineの先頭に[<->]を表示しない

  ;; face
  ;; tab-background (header-line)
  (set-face-attribute 'elscreen-tab-background-face nil :background "black" :underline nil)
  ;; tab-current-screen (current-screen)
  (set-face-attribute 'elscreen-tab-current-screen-face nil :foreground "yellow" :background "black" :underline nil)
  ;; tab-other-screen (other-screen)
  (set-face-attribute 'elscreen-tab-other-screen-face nil :foreground "Gray72" :background "black" :underline nil)
  )

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
    (cons 'progn (mapcar (lambda (x) `(setenv ,x ,(getenv x))) (eval env-var-lst))))

  (defmacro copy-envs-settings ()
    (when (string-match ".el$" (or (locate-library "-packages-") ""))
      ;; sync emacs environment variable with shell's one
      (exec-path-from-shell-initialize))

    `(cond ((time-less-p ',(nth 5 (file-attributes (file-truename "~/.bash_profile")))
                         (nth 5 (file-attributes ,(file-truename "~/.bash_profile"))))
            ;; sync emacs environment variable with shell's one
            (exec-path-from-shell-copy-envs ',exec-path-from-shell-variables)
            (add-hook 'after-init-hook (lambda () (byte-compile-file (locate-library "-packages-.el")))))
           (t ;; else
            ;; setenv cached environment variables
            (setenv_cached-env-var exec-path-from-shell-variables)
            (setq exec-path ',exec-path)))))

(when (string= "0" (getenv "SHLVL"))
  (copy-envs-settings))

;;------------------------------------------------------------------------------
;; elscreen-separate-buffer-list
;; screenごとに独自のバッファリスト
;;------------------------------------------------------------------------------
;; (autoload 'elscreen-separate-buffer-list-mode "elscreen-separate-buffer-list" t)
;; (elscreen-separate-buffer-list-mode 1)

;;------------------------------------------------------------------------------
;; flycheck
;; エラーチェッカー
;;------------------------------------------------------------------------------
(with-eval-after-load 'flycheck
  (add-hook 'flycheck-mode-hook (lambda () (setq left-fringe-width 8))) ;; 左フリンジを有効化

  (setq-default flycheck-display-errors-delay 0.3) ;; 遅延
  (setq-default flycheck-disabled-checkers '(emacs-lisp-checkdoc)) ;; remove useless warnings
  (setq-default flycheck-emacs-lisp-load-path 'inherit) ;; use the `load-path' of the current Emacs session

  (declare-function flycheck-add-mode "flycheck")
  (flycheck-add-mode 'emacs-lisp 'elisp-mode))

;;------------------------------------------------------------------------------
;; helm
;; emacsに統一的なある”操作方式”を提供するフレームワーク
;;------------------------------------------------------------------------------
(with-eval-after-load 'helm
  ;; helm-migemo を有効化
  ;; (or (featurep 'migemo) (require 'cmigemo))
  ;; (declare-function helm-migemo-mode "helm-multi-match")
  ;; (helm-migemo-mode)

  ;; http://fukuyama.co/nonexpansion
  ;; 自動補完を無効にする
  (setq-default helm-ff-auto-update-initial-value nil))

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
  ;; (setq-default highlight-indent-guides-method 'character)
  ;; (setq-default highlight-indent-guides-auto-character-face-perc 100)
  ;; (setq-default highlight-indent-guides-character ?\|)
  ;; (setq-default highlight-indent-guides-method 'column)
  (setq-default highlight-indent-guides-auto-odd-face-perc 40)
  (setq-default highlight-indent-guides-auto-even-face-perc 25))

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
(with-eval-after-load 'magit
  (setq-default git-commit-summary-max-length 999))

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

;;------------------------------------------------------------------------------
;; plantuml-mode
;;------------------------------------------------------------------------------
;; (with-eval-after-load 'plantuml-mode
;;   (setq-default plantuml-jar-path "c:/msys64/usr/local/share/plantuml/plantuml.jar")

;;   ;; javaにオプションを渡したい場合はここにかく
;;   (setq-default plantuml-java-options "")

;;   ;; plantumlのプレビュー出力形式(svg,png,txt,utxt)
;;   ;; (setq-default plantuml-output-type "txt")

;;   ;; 日本語を含むUMLを書く場合はUTF-8を指定
;;   (setq-default plantuml-options "-charset UTF-8")

;;   (add-to-list 'smart-compile-alist '("\\.puml$" . "plantuml -charset UTF-8 -tsvg %f") t))

;; ;; 拡張子による major-mode の関連付け
;; (add-to-list 'auto-mode-alist '("\\.puml$" . plantuml-mode))

;;------------------------------------------------------------------------------
;; shell-pop
;; シェルバッファをポップアップ
;;------------------------------------------------------------------------------
;; (global-set-key [f8] 'shell-pop)

;;------------------------------------------------------------------------------
;; smert compile
;;------------------------------------------------------------------------------
(eval-when-compile (require 'smart-compile))
(with-eval-after-load 'smart-compile
  (add-to-list 'smart-compile-alist '(elisp-mode emacs-lisp-byte-compile)))
(global-set-key (kbd "C-x c") #'smart-compile)

;;------------------------------------------------------------------------------
;; vs-set-c-style
;; Visual Studio スタイルのインデント設定
;; http://yohshiy.blog.fc2.com/blog-entry-264.html
;;------------------------------------------------------------------------------
;; (autoload 'vs-set-c-style "vs-set-c-style")
