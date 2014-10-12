# c-align-operands - Support for aligned operands in C-like languages

*Author:* Anders Lindgren<br>
*Version:* 0.0.1<br>
*URL:* [https://github.com/Lindydancer/c-align-operands](https://github.com/Lindydancer/c-align-operands)<br>

Support for aligning operands when placing operators first on line,
for C-like languages.

## Introduction

*Operator first on line* style means that long expressions are
broken into several lines, with the operator at the beginning of
the line. *Aligned operands* mean that the all operands start in
the same column, including the first one.

 For example:

    if (   alpha
        && (   beta
            || gamma))

Personally, for complex expressions, I consider this style far more
readble than any other style I have seen.

This package provides:

* Indentation support for major modes based on `cc-mode`, for
  example C, C++, Objective-C, and Java.
* Electric minor mode -- when inserting an operator (like `&&`)
  first on a line, the operand preceeding it will automatically be
  aligned.

### Emacs versions

This package requires at least Emacs 22.

## Electric mode

When `c-align-operands-electric-mode` is enabled, you don't have to
space out `alpha` yourself. For example, assume that the buffer
contains:

    if (alpha

When & is typed, and the point is on the line following the `if`, some
space is inserted before `alpha`:

    if (  alpha
        &

When typing the second `&`, the first line is indented even more:

    if (   beta
        &&

Of course, this is not limited to small expressions like this, it
works equally well on a multi line expression.

## Usage

Place the source file in a directory in the load path. Add the
following to an appropriate init file:

        (autoload 'c-align-operands-electric-mode
                  "c-align-operands" nil t)
        (autoload 'c-align-operands-lineup-arglist-operators
                  "c-align-operands" nil t)

### Indentation

To enable indentation, define a custom language style. This package
is useful in conjunction with the `c-lineup-arglist` cc-mode
indentation rule, since lines beginning with an operator is
indented differently than other lines. For example:

      (defconst my-c-style
       '(;; Other configuration settings goes here.
         (c-offsets-alist
          . (;; Other offset settings goes here.
             (arglist-cont-nonempty . (c-align-operands-lineup-arglist-operators
                                       c-lineup-arglist)))))
        "My indentation style, align operands when operator is first on line.")

      (defun my-c-mode-common-hook ()
        "My settings for cc-mode modes (C, C++, Java etc.)."
        (c-add-style "my" my-c-style t))
      (add-hook 'c-mode-common-hook 'my-c-mode-common-hook)

### Electric operators

If you are using Emacs 24 or newer, the electric mode can be, for
example, enabled in all modes based on `cc-mode` (C, C++,
Objective-C, Java etc) using:

      (add-hook 'c-mode-common-hook 'c-align-operands-electric-mode)

If you are using older Emacs versions, define a function that can
be added to a hook:

      (defun my-c-mode-common-hook ()
        "Personal settings for cc-mode modes (C, C++, Java etc.)."
        (c-align-operands-electric-mode 1))

      (add-hook 'c-mode-common-hook 'my-c-mode-common-hook)



---
Converted from `c-align-operands.el` by [*el2markdown*](https://github.com/Lindydancer/el2markdown).
