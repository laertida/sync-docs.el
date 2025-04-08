;;; sync-docs.el --- Description -*- lexical-binding: t; -*-
;;
;; Copyright (C) 2025
;;
;; Author:  <laertida>
;; Maintainer:  <laertida>
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
  "Host to make requests on sync-docs operation."
  :type 'string
  :group 'sync-docs)

(defcustom sync-docs-user ""
  "Username to authenticate sync-docs operations."
  :type 'string
  :group 'sync-docs)

(defcustom sync-docs-token ""
  "Token to authenticate sync-docs operations."
  :type 'string
  :group 'sync-docs)

(defcustom sync-docs-space-id ""
  "Space Id where sync-docs will create documents."
  :type 'string
  :group 'sync-docs)

(defcustom sync-docs-default-parent-id ""
  "Default value for parent-id page."
  :type 'string
  :group 'sync-docs)


(defun sync-docs-generate-auth (user pass)
  "This function helps to create the base64 encodign for basic auth in api use.
USER is the user or email for confluence API.
PASS is the Token for API usage"
  (format "%s" (concat "Basic " (base64-encode-string (format "%s:%s" user pass) t))))

(defun sync-docs-get-html-export ()
  "This function helps to export the current buffer to html.

This function returns the html created only the content
inside <body></body> tags."
  (with-current-buffer
      ;; this let is for set variables for execution on
      ;; org-html-export-as-html
      (let((async nil)
           (subtreep nil)
           (visible-only nil)
           (body-only t)
           (ext-plist nil))
        (org-html-export-as-html async subtreep visible-only body-only ext-plist))
    (buffer-string)))


(defun sync-docs-get-page (page)
  "This function helps to get the page id from the space.
PAGE is the pageId parameter to the app"
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
  "This functions gets the sync id if needed or creates a new one."
  (assoc-default "SYNC_DOCS_ID" (org-entry-properties (point-min))))

(defun sync-docs-get-site-id ()
  "This functions gets the siteId if needed or creates a new one."
  (assoc-default "SYNC_DOCS_SITE_ID" (org-entry-properties (point-min))))

(defun sync-docs-get-parent-id ()
  "This functions gets the siteId if needed or creates a new one."
  (assoc-default "SYNC_DOCS_PARENT_ID" (org-entry-properties (point-min))))

(defun sync-docs-get-new-version()
  "This function increase automatically the version number in the property."
  (+ 1 (string-to-number (assoc-default "SYNC_DOCS_VERSION"
                                        (org-entry-properties (point-min))))))

(defun sync-docs-create-page (space-id parent-id status)
  "This function helps to create a new page.
SPACE-ID is the space where the page will be created.
PARENT-ID is the parent page where this page is created.
STATUS this is the status of the publication it could be
`draft` or `current`."
  (request
    (concat sync-docs-host "/wiki/api/v2/pages")
    :type "POST"
    :headers `(("Content-Type" . "application/json")
               ("Authorization" . ,(sync-docs-generate-auth sync-docs-user sync-docs-token)))
    :data (json-encode `( ("spaceId" . ,space-id)
                          ("parentId" . ,parent-id)
                          ("status" . ,status)
                          ("title" . ,(org-get-title))
                          ("body" . (("representation" . "storage")
                                     ("value" . ,(sync-docs-get-html-export) )))))
    :parser 'json-read
    :success (cl-function
              (lambda (&key data &allow-other-keys)
                (message "I sent: %S" (assoc-default 'parentId data))
                (org-entry-put (point-min) "SYNC_DOCS_ID" (assoc-default 'id data))
                (org-entry-put (point-min) "SYNC_DOCS_VERSION" 1)))))

(defun sync-docs-update-page (pageId status message &optional spaceId parentId)
  "This functioh helps to update an already created page.
PAGEID refers to the page Id of the created page.
STATUS refers to the status of the document, it could be `draft` or `current`.
MESSAGE is the message of the updated version.
SPACEID is the space where the page will be updated.
PARENTID is the parent id of the page where this page will be published."
  (request
    (concat sync-docs-host "/wiki/api/v2/pages/" (sync-docs-get-sync-id))
    :type "PUT"
    :headers `(("Content-Type" . "application/json")
               ("Authorization" . ,(sync-docs-generate-auth sync-docs-user sync-docs-token)))
    :data (json-encode `( ("spaceId" . ,sync-docs-space-id)
                          ("id" . ,pageId)
                          ("parentId" . ,sync-docs-default-parent-id)
                          ("status" . ,status)
                          ("title" . ,(org-get-title))
                          ("body" . (("representation" . "storage")
                                     ("value" . ,(sync-docs-format-for-confluence) )))
                          ("version" . ( ("number" . ,(sync-docs-get-new-version)) ("message". ,message)))))
    :parser 'json-read
    :success (cl-function
              (lambda (&key data &allow-other-keys)
                (message "Page updated with id: %S!" (assoc-default 'id data))
                (org-entry-put (point-min) "SYNC_DOCS_ID" (assoc-default 'id data))
                (org-entry-put (point-min) "SYNC_DOCS_VERSION" (number-to-string(assoc-default 'number (assoc-default 'version data))))))))


(defun sync-docs-create-or-update-attachments (image-path)
  "This function helps to create an attachment.
IMAGE-PATH is the path where the image exists."
  (shell-command (concat "curl -v " "-u " (concat "'" sync-docs-user ":" sync-docs-token "' ")
                         "-X PUT " "-H 'X-Atlassian-Token: nocheck' "
                         "-F 'file=@"
                         image-path
                         "' '"
                         (concat sync-docs-host "/wiki/rest/api/content/")
                         (sync-docs-get-sync-id)

                         "/child/attachment'"
                         ))
  )


(defun sync-docs-get-images ()
  "This function helps to get a list in the current buffer."
  (org-element-map (org-element-parse-buffer) 'link
    (lambda (link)
      (let ((type (org-element-property :type link))
            (path (org-element-property :path link)))
        (when (member type '("file" "attachment"))
          path)))))

(defun sync-docs-upgrade-all-images ()
  "This function helps to upgrade all images."
  (mapc #'sync-docs-create-or-update-attachments (sync-docs-get-images)))

(defun sync-docs-format-for-confluence ()
  "This function helps to replace masively the img for confluence img format."
  (let ((html-buffer (sync-docs-get-html-export)))
    (replace-regexp-in-string "alt=\"[a-z0-9]*.png\"\s\/>\n<\/p>" "/></ac:image>"
                              (replace-regexp-in-string "<p><img src=\".\/images\/" "<ac:image><ri:attachment ri:filename=\"" html-buffer))))

(defun sync-docs (status message upgrade-images)
  "This function helps to update docs remotely.
STATUS is the status of the document, it could be `draft` or `current`
MESSAGE is the message for to comment the version
UPGRADE-IMAGES is a flag that indicates if the images will be updated or not."
  (interactive (list
                (completing-read "Which is the status of this page? " '("draft" "current"))
                (read-string "Please write a message for this version: ")
                (let* ((upgrade '(("yes" . t)
                                  ("no" . nil)))
                       (selected-option (completing-read "Do you want to publish images" (mapcar #'car upgrade))))
                  (cdr (assoc selected-option upgrade)))))
  (if (sync-docs-get-sync-id)
      (progn (sync-docs-update-page (sync-docs-get-sync-id) status message)
             (sync-docs-upgrade-all-images))
    (progn (sync-docs-create-page (or (sync-docs-get-site-id) sync-docs-space-id)
                                  (or (sync-docs-get-parent-id) sync-docs-default-parent-id)
                                  status)
           (if upgrade-images
               (sync-docs-upgrade-all-images)))))

(provide 'sync-docs)
;;; sync-docs.el ends here
