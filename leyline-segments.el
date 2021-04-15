;;; leyline-segments.el --- Leyline segments -*- lexical-binding: t; -*-

;; Copyright (C) 2021 Mathieu Marques

;; Author: Mathieu Marques <mathieumarques78@gmail.com>
;; Created: April 1, 2021

;; This program is free software. You can redistribute it and/or modify it under
;; the terms of the Do What The Fuck You Want To Public License, version 2 as
;; published by Sam Hocevar.
;;
;; This program is distributed in the hope that it will be useful, but WITHOUT
;; ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS
;; FOR A PARTICULAR PURPOSE.
;;
;; You should have received a copy of the Do What The Fuck You Want To Public
;; License along with this program. If not, see http://www.wtfpl.net/.

;;; Commentary:

;; Definitions for leyline segments.

;;; Code:

(defsubst leyline-space ()
  "Whitespace to use as segment separator."
  " ")

(leyline-define-segment buffer
  "The buffer name and details."
  (let ((face (if (buffer-modified-p) 'error 'mode-line-buffer-id)))
    (concat
     (leyline-space)
     (propertize "%b" 'face face)
     (leyline-space))))

(leyline-define-segment buffer-position
  "The buffer position."
  (when (or column-number-mode line-number-mode)
    (concat
     (leyline-space)
     (format-mode-line '(line-number-mode
                         (column-number-mode "%l:%c" "%l")
                         (column-number-mode ":%c")))
     (leyline-space))))

(leyline-define-segment mode
  "The major mode for the current buffer."
  (concat
   (leyline-space)
   (format-mode-line mode-name)
   (leyline-space)))

(provide 'leyline-segments)

;;; leyline-segments.el ends here
