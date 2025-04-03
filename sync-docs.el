;;; sync-docs.el --- Description -*- lexical-binding: t; -*-
;;
;; Copyright (C) 2025
;;
;; Author:  <laertida@nostromo>
;; Maintainer:  <laertida@nostromo>
;; Created: abril 02, 2025
;; Modified: abril 02, 2025
;; Version: 0.0.1
;; Keywords: abbrev bib c calendar comm convenience data docs emulations extensions faces files frames games hardware help hypermedia i18n internal languages lisp local maint mail matching mouse multimedia news outlines processes terminals tex tools unix vc wp
;; Homepage: https://github.com/laertida/sync-docs
;; Package-Requires: ((emacs "24.3"))
;;
;; This file is not part of GNU Emacs.
;;
;;; Commentary:
;;
;;  Description
;;
;;; Code:




(require 'org)
(require 'request)


(defcustom sync-docs-host ""
  "Host to make requests on sync-docs operation"
  :type 'string
  :group 'sync-docs)

(defcustom sync-docs-user ""
  "Username to authenticate sync-docs operations"
  :type 'string
  :group 'sync-docs)

(defcustom sync-docs-token ""
  "Token to authenticate sync-docs operations"
  :type 'string
  :group 'sync-docs
  )

(defcustom sync-docs-space-id ""
  "Space Id where sync-docs will create documents"
  :type 'string
  :group 'sync-docs)

(defcustom sync-docs-default-parent-id ""
  "If no parent id is defined in the document, then
sync-docs will use this value"
  :type 'string
  :group 'sync-docs)


(defun sync-docs-generate-auth (user pass)
  "This function helps to create the base64 encodign
for basic auth in api use"
  (format "%s" (concat "Basic " (base64-encode-string (format "%s:%s" user pass) t))))

(defun sync-docs-get-html-export ()
  "This function helps to export the current buffer to html.

This function returns the html created only the content
inside <body></body> tags.
   "
  (with-current-buffer
      ;; this let is for set variables for execution on
      ;; org-html-export-as-html
      (let ((org-export-show-temporary-export-buffer nil)
            (async nil)
            (subtreep nil)
            (visible-only nil)
            (body-only t)
            (ext-plist nil))
        (org-html-export-as-html async subtreep visible-only body-only ext-plist))
    (buffer-string)))

(defun sync-docs-jsonify-html (html-doc)
  "This function helps to transform the html into json format"
  (json-encode html-doc))

(defun sync-docs-get-page (page)
  "This function helps to get the page id from the space"
  (request
    (concat sync-docs-host "/wiki/api/v2/pages/" page)
    :type "GET"
    :params '(("body-format" . "editor"))
    :headers `(("Content-Type" . "application/json")
               ("Authorization" . ,(sync-docs-generate-auth sync-docs-user sync-docs-token)))
    :parser 'json-read
    :success (cl-function
              (lambda (&key data &allow-other-keys)
                (message "I sent: %S" (assoc-default 'parentId data))))))

(defun sync-docs-get-sync-id ()
  "This functions gets the sync id if needed or creates a new one"
  (assoc-default "SYNC_DOCS_ID" (org-entry-properties (point-min))))

(defun sync-docs-get-site-id ()
  "This functions gets the siteId if needed or creates a new one"
  (assoc-default "SYNC_DOCS_SITE_ID" (org-entry-properties (point-min))))

(defun sync-docs-get-parent-id ()
  "This functions gets the siteId if needed or creates a new one"
  (assoc-default "SYNC_DOCS_PARENT_ID" (org-entry-properties (point-min)))
  )


(defun sync-docs-create-page (space-id parent-id)
  (request
    (concat sync-docs-host "/wiki/api/v2/pages")
    :type "POST"
    :headers `(("Content-Type" . "application/json")
               ("Authorization" . ,(sync-docs-generate-auth sync-docs-user sync-docs-token)))
    :data (json-encode `( ("spaceId" . ,space-id)
                          ("parentId" . ,parent-id)
                          ("status" . "draft")
                          ("title" . ,(org-get-title))
                          ("body" . (("representation" . "storage")
                                     ("value" . ,(sync-docs-get-html-export) ))
                           )
                          ))
    :parser 'json-read
    :success (cl-function
              (lambda (&key data &allow-other-keys)
                (message "I sent: %S" (assoc-default 'parentId data))
                (org-entry-put (point-min) "SYNC_DOCS_ID" (assoc-default 'id data))))))

(defun sync-docs-update-page (page-id &optional space-id parent-id)
  "This functioh helps to update an already created
page, with the defined PAGE-ID "
  (request
    (concat sync-docs-host "/wiki/api/v2/pages/" (sync-docs-get-sync-id))
    :type "PUT"
    :headers `(("Content-Type" . "application/json")
               ("Authorization" . ,(sync-docs-generate-auth sync-docs-user sync-docs-token)))
    :data (json-encode `( ("spaceId" . ,space-id)
                          ("id" . ,page-id)
                          ("parentId" . ,parent-id)
                          ("status" . "draft")
                          ("title" . ,(org-get-title))
                          ("body" . (("representation" . "storage")
                                     ("value" . ,(sync-docs-get-html-export) ))
                           )
                          ("version" . ( ("number" . 1) ("message". "test")) )
                          ))
    :parser 'json-read
    :success (cl-function
              (lambda (&key data &allow-other-keys)
                (message "Page updated with id: %S!" (assoc-default 'id data))
                (org-entry-put (point-min) "SYNC_DOCS_ID" (assoc-default 'id data))
                ))))

(defun sync-docs ()
  "This function helps to update "
  (interactive)
  (let ((site-id (sync-docs-get-site-id))
        (parent-id (if (sync-docs-get-parent-id) (sync-docs-get-parent-id) (format "%s" sync-docs-default-parent-id)))
        (page-id (sync-docs-get-sync-id)))
    (if (sync-docs-get-sync-id)
        (sync-docs-update-page page-id parent-id)
      (sync-docs-create-page site-id parent-id))
    (message "Site %s updated on %s with page id: %s" site-id parent-id page-id)))

(provide 'sync-docs)
;;; sync-docs.el ends here
