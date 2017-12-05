;;; counsel-notmuch.el --- Search emails in Notmuch asynchronously with Ivy  -*- lexical-binding: t; -*-

;; Copyright (C) 2017-2018  Alexander Fu Xi

;; Author: Alexander Fu Xi <fuxialexander@gmail.com>
;; URL: https://github.com/fuxialexander/counsel-notmuch
;; Keywords: mail
;; Version: 1.0
;; Package-Requires: ((swiper "0.10.0") (notmuch "0.21"))

;; This program is free software; you can redistribute it and/or modify
;; it under the terms of the GNU General Public License as published by
;; the Free Software Foundation, either version 3 of the License, or
;; (at your option) any later version.

;; This program is distributed in the hope that it will be useful,
;; but WITHOUT ANY WARRANTY; without even the implied warranty of
;; MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
;; GNU General Public License for more details.

;; You should have received a copy of the GNU General Public License
;; along with this program.  If not, see <http://www.gnu.org/licenses/>.

;;; Commentary:

;; This package provides `counsel-notmuch' function which is inspired by
;; `helm-notmuch'.
;; Simply call `counsel-notmuch' function and input your notmuch query.

;; News:
;; -2017-12-05 Initial release

;;; Code:
;;; License: GPLv3
;;
;;
;;; Code:
;;

(require 'ivy)

(defcustom counsel-notmuch-path "/usr/local/bin/notmuch" "path to notmuch executable"
  :group 'notmuch
  :group 'counsel-notmuch)

(defvar counsel-notmuch-history nil
  "History for `counsel-notmuch'.")

(defun counsel-notmuch-cmd (input)
  "Return mail"
  (counsel-require-program counsel-notmuch-path)
  (format "notmuch search %s" input)
  )

(defun counsel-notmuch-function (input)
  "helper function"
  (setq counsel-notmuch-base-command (concat counsel-notmuch-path " search"))
  (if (< (length input) 3)
      (counsel-more-chars 3)
    (counsel--async-command
     (counsel-notmuch-cmd input)) '("" "working...")))

(defun counsel-notmuch-action-tree (thread)
  "open search result in tree view"
  (setq thread-id (car (split-string thread "\\ +")))
  (notmuch-tree thread-id initial-input nil)
  )


(defun counsel-notmuch-action-show (thread)
  "open search result in show view"
  (let ((title (concat "*counsel-notmuch-show*" (substring thread 24)))
        (thread-id (car (split-string thread "\\ +"))))
    (notmuch-show-reuse-buffer thread-id nil nil nil title)))

(defun counsel-notmuch-transformer (str)
  "search notmuch asynchronously through ivy"
  (when (string-match "thread:" str)
    (let* ((mid (substring str 24))
           (date (propertize (substring str 24 37) 'face 'notmuch-search-date))
           (mat (propertize
                 (substring mid (string-match "[[]" mid) (+ (string-match "[]]" mid) 1))
                 'face
                 'notmuch-search-count))
           (people
            (propertize
             (truncate-string-to-width (s-trim (nth 1 (split-string mid "[];]"))) 20)
             'face
             'notmuch-search-matching-authors))
           (subject
            (propertize
             (truncate-string-to-width (s-trim (nth 1 (split-string mid "[;]"))) (- (window-width) 32))
             'face
             'notmuch-search-subject))
           (str (format "%s\t%10s\t%20s\t%s" date mat people subject)))
      str)))

;;;###autoload
(defun counsel-notmuch (&optional initial-input)
  "search for your email in notmuch"
  (interactive)
  (ivy-set-prompt 'counsel-notmuch counsel-prompt-function)
  (ivy-read "Notmuch Search"
            #'counsel-notmuch-function
            :initial-input initial-input
            :dynamic-collection t
            ;; :keymap counsel-notmuch-map
            :history 'counsel-notmuch-history
            :action '(1
                      ("o" counsel-notmuch-action-show "Show")
                      ("t" counsel-notmuch-action-tree "Tree View")
                      )
            :unwind (lambda ()
                      (counsel-delete-process)
                      (swiper--cleanup))
            :caller 'counsel-notmuch))

(ivy-set-display-transformer 'counsel-notmuch 'counsel-notmuch-transformer)

(provide 'counsel-notmuch)

;;; counsel-notmuch.el ends here
