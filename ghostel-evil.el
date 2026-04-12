;;; ghostel-evil.el --- Obsolete compatibility shim  -*- lexical-binding: t; -*-

;; Copyright (c) 2026 Daniel Kraus <daniel@kraus.my>

;; Author: Daniel Kraus <daniel@kraus.my>
;; SPDX-License-Identifier: GPL-3.0-or-later

;; This file is NOT part of GNU Emacs.

;;; Commentary:

;; This package has been renamed to `evil-ghostel'.
;; This file exists so that existing (require 'ghostel-evil) and
;; (use-package ghostel-evil ...) configurations keep working.
;; It will be removed in a future release.

;;; Code:

(require 'evil-ghostel)

(define-obsolete-function-alias 'ghostel-evil-mode #'evil-ghostel-mode "0.13.0")
(define-obsolete-variable-alias 'ghostel-evil-mode 'evil-ghostel-mode "0.13.0")

(provide 'ghostel-evil)
;;; ghostel-evil.el ends here
