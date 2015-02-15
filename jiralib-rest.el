;;; jiralib-rest -- JIRA functions over their REST API

;;; Commentary:

(require 'request)
(require 'json)
(require 'dash)
(require 'org)

;;; Code:
(defun rest-json-sync-call (base-url resource &optional method &rest data)
  "Call the REST method on BASE-URL/RESOURCE.

The http method METHOD is used, defaulting to GET.  If present,
the extra DATA (as a plist) is encoded to json and sent along.

Returns a cons of the response status code and the response data,
encoded as a alist.

Example:

  (rest-json-sync-call \"http://rest.example.com\" \"/thing\"
		       \"POST\"
		       :name \"myThing\" :color \"blue\")

  ⇒ (200 . (thing (id . 1) (name . \"myThing\") (color . \"blue\")))"
  (let ((request (request
		  (concat base-url resource)
		  :type (or method "GET")
		  :data (and data (json-encode data))
		  :headers (and data '(("Content-Type" . "application/json")))
		  :parser (lambda () (let ((json-object-type 'alist)) (json-read)))
		  :sync t)))
    (cons (request-response-status-code request)
	  (request-response-data request))))

;; Partial function pointer
(declare-function
 jira-call t
 "The function to call to get a REST result from JIRA.")

(defun jira-set-rest-url (url)
  "Set the base url of the JIRA REST interface to URL."
  (fset #'jira-call (-partial #'rest-json-sync-call url)))

;; JIRA methods
(defun jira-session-create (username password)
  "Create a session for user USERNAME, identified by PASSWORD."
  (jira-call "/auth/1/session" "POST"
	     :username username
	     :password password))

(defun jira-session-delete ()
  "Destroy the current session, aka logout."
  (jira-call "/auth/1/session" "DELETE"))

(defun jira-project-get ()
  "Get all visible projects on JIRA."
  (jira-call "/api/2/project"))

(defun jira-project-get-by-id (id)
  "Get specific project by ID."
  (jira-call (format "/api/2/project/%s" id)))

(defun jira-component-get-by-id (id)
  "Get specific component by ID."
  (jira-call (format "/api/2/component/%s" id)))

(defun jira-issue-get-by-id (id)
  "Get specific issue by ID."
  (jira-call (format "/api/2/issue/%s" id)))

(defun jira-issue-search (jql)
  "Execute a JQL search and return the found issues."
  (jira-call "/api/2/search" "POST"
	     :jql jql
	     :startAt 0
	     :maxResults 50))

;; ORG-JIRA
(defconst org-jira-default-root-text
  "You can adjust the title and text, and even the properties of this
node (perhaps you'd like to customize the columns).  The only thing
that is important to org-jira is the property \"ORG-JIRA-NODE\", which
is used to track the state of this node, and find it when updates are
needed.\n")

(defun org-jira-create-org-tree ()
  "Create a root element for JIRA querying."
  (interactive)
  (unless (eq major-mode 'org-mode) (org-mode))
  (org-insert-heading-respect-content)
  (insert "JIRA root\n")
  (org-entry-put (point) "ORG-JIRA-NODE" "root")
  (org-entry-put (point) "ORG-JIRA-REST-URL" "http://example.com/jira/rest")
  (insert org-jira-default-root-text))

(defmacro org-jira-ensure-in-jira-node (point &rest body)
  "Ensure POINT is in an org node with ORG-JIRA-NODE set, before executing BODY.

Sets org-jira-rest-url accordingly."
  (declare (indent defun))
  `(save-excursion
    (goto-char ,point)
    (while (and (not (equal (org-entry-get (point) "ORG-JIRA-NODE") "root"))
		(condition-case nil ((outline-up-heading 1) t) (error nil))))
    (let ((org-jira-rest-url (org-entry-get (point) "ORG-JIRA-REST-URL")))
      (unless org-jira-rest-url
	(error "No root node found, please call org-jira-create-org-tree first"))
      ,@body)))

(defun org-jira-fetch-projects ()
  "Fetch all projects on the JIRA server for the root node in this buffer."
  (interactive)
  (unless (eq major-mode 'org-mode) (org-mode))
  (org-jira-ensure-in-jira-node (point)
    (jira-set-rest-url org-jira-rest-url)
    (jira-project-get)))

(provide 'jiralib-rest)
;;; jiralib-rest.el ends here
