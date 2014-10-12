;;; c-align-operands.el --- Support for aligned operands in C-like languages

;; Copyright (C) 1997-2007,2014 Anders Lindgren.

;; Author: Anders Lindgren
;; Version: 0.0.1
;; Created: 1997-??-??
;; URL: https://github.com/Lindydancer/c-align-operands

;;; Commentary:

;; Support for aligning operands when placing operators first on line,
;; for C-like languages.

;; Introduction:
;;
;; *Operator first on line* style means that long expressions are
;; broken into several lines, with the operator at the beginning of
;; the line. *Aligned operands* mean that the all operands start in
;; the same column, including the first one.
;;
;;  For example:
;;
;;     if (   alpha
;;         && (   beta
;;             || gamma))
;;
;; Personally, for complex expressions, I consider this style far more
;; readble than any other style I have seen.
;;
;; This package provides:
;;
;; * Indentation support for major modes based on `cc-mode', for
;;   example C, C++, Objective-C, and Java.
;;
;; * Electric minor mode -- when inserting an operator (like `&&')
;;   first on a line, the operand preceeding it will automatically be
;;   aligned.
;;
;; Emacs versions:
;;
;; This package requires at least Emacs 22.

;; Electric mode:
;;
;; When `c-align-operands-electric-mode' is enabled, you don't have to
;; space out `alpha' yourself. For example, assume that the buffer
;; contains:
;;
;;     if (alpha
;;
;; When & is typed, and the point is on the line following the `if', some
;; space is inserted before `alpha':
;;
;;     if (  alpha
;;         &
;;
;; When typing the second `&', the first line is indented even more:
;;
;;     if (   beta
;;         &&
;;
;; Of course, this is not limited to small expressions like this, it
;; works equally well on a multi line expression.

;; Usage:
;;
;; Place the source file in a directory in the load path. Add the
;; following to an appropriate init file:
;;
;;     (autoload 'c-align-operands-electric-mode
;;               "c-align-operands" nil t)
;;     (autoload 'c-align-operands-lineup-arglist-operators
;;               "c-align-operands" nil t)
;;
;; Indentation:
;;
;; To enable indentation, define a custom language style. This package
;; is useful in conjunction with the `c-lineup-arglist' cc-mode
;; indentation rule, since lines beginning with an operator is
;; indented differently than other lines. For example:
;;
;;   (defconst my-c-style
;;    '(;; Other configuration settings goes here.
;;      (c-offsets-alist
;;       . (;; Other offset settings goes here.
;;          (arglist-cont-nonempty . (c-align-operands-lineup-arglist-operators
;;                                    c-lineup-arglist)))))
;;     "My indentation style, align operands when operator is first on line.")
;;
;;   (defun my-c-mode-common-hook ()
;;     "My settings for cc-mode modes (C, C++, Java etc.)."
;;     (c-add-style "my" my-c-style t))
;;   (add-hook 'c-mode-common-hook 'my-c-mode-common-hook)
;;
;; Electric operators:
;;
;; If you are using Emacs 24 or newer, the electric mode can be, for
;; example, enabled in all modes based on `cc-mode' (C, C++,
;; Objective-C, Java etc) using:
;;
;;   (add-hook 'c-mode-common-hook 'c-align-operands-electric-mode)
;;
;; If you are using older Emacs versions, define a function that can
;; be added to a hook:
;;
;;   (defun my-c-mode-common-hook ()
;;     "Personal settings for cc-mode modes (C, C++, Java etc.)."
;;     (c-align-operands-electric-mode 1))
;;
;;   (add-hook 'c-mode-common-hook 'my-c-mode-common-hook)
;;

;;; Code:


;; -------------------------------------------------------------------
;; Indentation
;;


(defvar c-align-operands-operators '(?: ?? ?! ?- ?+ ?| ?& ?* ?% ?< ?> ?= ?/)
  "List of first character of operators in C-like languages.")


(defun c-align-operands-patched-c-lineup-arglist-operators (langelem)
  "Like `c-lineup-arglist-operators' but handles `!=', `?', and `:' aswell."
  (save-excursion
    (back-to-indentation)
    (let ((ch (following-char)))
      (when (and (memq ch c-align-operands-operators)
                 ;; Not comment start.
                 (not (and (eq ch ?/)
                           (memq (char-after (+ (point) 1))
                                 '(?* ?/)))))
        (c-lineup-arglist-close-under-paren langelem)))))


;;;###autoload
(defun c-align-operands-lineup-arglist-operators (langelem)
  "Indent operators to the right of the start parenthesis."
  (let ((res (c-align-operands-patched-c-lineup-arglist-operators langelem)))
    (if (vectorp res)
        (vector (+ 1 (aref res 0)))
      res)))


;; -------------------------------------------------------------------
;; Electric operands
;;

(defun c-align-operands-get-start-of-statement ()
  ;; context: ((arglist-cont-nonempty 56 59))
  (nth 1 (car (c-guess-basic-syntax))))


(defun c-align-operands-electric-operator (arg)
  "Insert operator, when first on line, align the previous operand.

This is intended to be used to create code that like:

  if (   alpha
      && beta)

For example, assume that this function is bound to, say, &, and the
buffer contains:

  if (alpha

When & is typed, and the point is on the line following the `if', some
space is inserted before `alpha':

  if (  alpha
      &

This function also features automatic re-indentation when typing
the operator. This is useful in conjunction with the
`c-lineup-arglist' cc-mode indentation rule, since lines
beginning with an operator is indented differently than other
lines.

The operator is inserted using the command the key the operator
would have been bound to, if `c-align-operands-electric-mode'
would not be enabled."
  (interactive "P")
  ;; Call the original function to insert the actual operator character.
  (let ((c-align-operands-electric-mode nil))
    (let ((cmd (key-binding (make-string 1 last-command-event))))
      (if (and cmd
               (not (eq cmd 'c-align-operands-electric-operator)))
          (call-interactively cmd)
        (self-insert-command (prefix-numeric-value arg)))))
  ;; Maybe indent the line and adjust operands.
  (let* ((lim (c-most-enclosing-brace (c-parse-state)))
         (literal (c-in-literal lim))
         (c-echo-syntactic-information-p nil))
    (unless (or (null lim)                  ; Top-level (outside function).
                literal                     ; In literal.
                arg                         ; Universal argument.
                (save-excursion             ; Not beginning of line.
                  (skip-syntax-backward ".")
                  (skip-chars-backward " \t")
                  (not (bolp)))
                ;; statement starts after opening parenthesis.
                (>= (c-align-operands-get-start-of-statement) lim)
                ;; Check if we're a function argument. (Typically, this
                ;; occurs when using "&" as "address of".
                ;;
                ;; alpha(bar
                ;;       <p>     // Indent.
                ;;
                ;; alpha(bar,    // Don't indent.
                ;;       <p>
                (save-excursion
                  (skip-syntax-backward ".") ; The char(s) we just typed.
                  (c-backward-syntactic-ws)
                  (or (bobp)
                      (eq (char-before) ?,))))
      ;; Indent current line.
      (c-indent-line)
      (save-excursion
        ;; Insert space in all other lines in the same expression.
        (let ((column (+ 1 (current-column)))
              (here (point)))
          (goto-char lim)
          (if (memq (following-char) '(?{ ?\( ))
              (forward-char 1))
          (skip-chars-forward " \t")
          (unless (eolp)
            ;; Insert space before the first argument to the operator.
            ;; (Keep `here' opdated.)
            (setq here (- here (current-column)))
            (setq here (+ here (indent-to column)))
            ;; Indent all lines in a multi-line expression.
            (forward-line)
            (c-indent-region (point) here)))))))


(defvar c-align-operands-electric-mode-map
  (let ((map (make-sparse-keymap)))
    (dolist (ch c-align-operands-operators)
      (define-key map (make-string 1 ch) 'c-align-operands-electric-operator))

    ;; And don't forget to "return" map.
    map))


;;;###autoload
(define-minor-mode c-align-operands-electric-mode
  "Operators automatically aligns previous operand when first on line.

\\{c-align-operands-electric-mode-map}."
  :keymap c-align-operands-electric-mode-map)


(provide 'c-align-operands)

;;; c-align-operands.el ends here
