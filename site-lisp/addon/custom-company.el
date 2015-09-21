;;; -*- coding: utf-8; lexical-binding: t -*-

;;------------------------------------------------------------------------------
;; company
;; 補完システム
;; from package
;;------------------------------------------------------------------------------

(with-eval-after-load 'company
  ;; 基本設定
  (defvar company-idle-delay)  ;; 遅延
  (setq company-idle-delay 0.2)
  (defvar company-minimum-prefix-length) ;; 補完開始文字長
  (setq company-minimum-prefix-length 3)
  (defvar company-selection-wrap-around)  ;; 最下時に↓で最初に戻る
  (setq company-selection-wrap-around t))
