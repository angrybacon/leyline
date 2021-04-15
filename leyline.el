;;; leyline.el --- Yet another mode-line package for Emacs -*- lexical-binding: t; -*-

;; Copyright (C) 2021 Mathieu Marques

;; Author: Mathieu Marques <mathieumarques78@gmail.com>
;; Created: April 1, 2021
;; Homepage: https://github.com/angrybacon/leyline

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

;; A minimal mode-line with extensible segments.
;;
;; Heavily inspired by https://github.com/seagle0128/doom-modeline.

;;; Code:

(defvar leyline--function-alist ())

(defvar leyline--variable-alist ())

(defmacro leyline-define-segment (name &rest body)
  "Define a segment NAME with BODY and compile it."
  (declare (indent defun) (doc-string 2))
  (let ((segment (intern (format "leyline--segment-%s" name)))
        (docstring (if (stringp (car body))
                       (pop body)
                     (format "Leyline segment '%s'" name))))
    (cond
     ((and (symbolp (car body)) (not (cdr body)))
      (add-to-list 'leyline--variable-alist (cons name (car body)))
      `(add-to-list 'leyline--variable-alist (cons ',name ',(car body))))
     (t
      (add-to-list 'leyline--function-alist (cons name segment))
      `(progn
         (fset ',segment (lambda () ,docstring ,@body))
         (add-to-list 'leyline--function-alist (cons ',name ',segment))
         ,(unless (bound-and-true-p byte-compile-current-file)
            `(let (byte-compile-warnings)
               (byte-compile #',segment))))))))

(defun leyline--make-segments (segments)
  "Make and/or evaluate SEGMENTS."
  (let (forms form)
    (dolist (segment segments)
      (cond
       ((stringp segment)
        (push segment forms))
       ((symbolp segment)
        (cond ((setq form (cdr (assq segment leyline--function-alist)))
               (push (list :eval (list form)) forms))
              ((setq form (cdr (assq segment leyline--variable-alist)))
               (push form forms))
              ((error "Leyline: segment '%s' does not exist" segment))))
       ((error "Leyline: segment '%s' is not valid" segment))))
    (nreverse forms)))

(defvar leyline--font-width-cache nil "Keep a cached value for the font width.")

(defun leyline--font-width ()
  "Get the current font width."
  (let ((attributes (face-all-attributes 'mode-line)))
    (or (cdr (assoc attributes leyline--font-width-cache))
        (let ((width (window-font-width nil 'mode-line)))
          (push (cons attributes width) leyline--font-width-cache)
          width))))

(defun leyline-define (name left2 &optional right2)
  "Define a mode-line format NAME and compile it.
LEFT and RIGHT are lists specifying which segments to put in either side of the
mode-line. See `leyline-define-segment'."
  (declare (indent defun))
  (let ((f (intern (format "leyline--format-%s" name)))
        (left-segments (leyline--make-segments left2))
        (right-segments (leyline--make-segments right2)))
    (defalias f
      (lambda ()
        (list left-segments
              (propertize
               " "
               'display `((space
                           :align-to
                           (- (+ right right-fringe right-margin)
                              ,(* (let ((width (leyline--font-width)))
                                    (or (and (= width 1) 1)
                                        (/ width (frame-char-width) 1.0)))
                                  (string-width
                                   (format-mode-line (cons "" right-segments))))))))
              right-segments))
      (format "Left segments:\n  %s\nRight segments:\n  %s"
              (prin1-to-string left2)
              (prin1-to-string right2)))))

(defun leyline-get (kind)
  "Get a mode-line configuration according to KIND."
  (let ((f (intern-soft (format "leyline--format-%s" kind))))
    (when (functionp f)
      `(:eval (,f)))))

;;;###autoload
(defun leyline-set (&optional kind default)
  "Set the mode-line format according to KIND in the current buffer.
Set the main mode-line if KIND is not specified.
With DEFAULT non-nil, set the mode-line in all buffers instead."
  (when-let ((line (leyline-get (or kind 'main))))
    (setf (if default
              (default-value 'mode-line-format)
            (buffer-local-value 'mode-line-format (current-buffer)))
          (list "%e" line))))

(leyline-define 'main
  '(buffer buffer-position)
  '(mode))

(defvar leyline--default-format mode-line-format
  "Keep the original value of `mode-line-format' for restoring purposes.")

;;;###autoload
(define-minor-mode leyline-mode
  "Toggle the leyline mode-line on or off."
  :global t
  :lighter nil
  (if leyline-mode
      (progn
        (leyline-set 'main)
        (leyline-set 'main t))
    (setq mode-line-format leyline--default-format)
    (setq-default mode-line-format leyline--default-format)))

(provide 'leyline)

;;; leyline.el ends here
