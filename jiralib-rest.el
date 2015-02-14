;;; jiralib-rest -- JIRA functions over their REST API

;;; Commentary:

(require 'request)
(require 'json)

;;; Code:
(defun rest-json-sync-call (base-url resource &optional method data)
  "Call the REST method on BASE-URL/RESOURCE.

The http method METHOD is used, defaulting to GET.
If given, the plist DATA is encoded to json and sent along.

Returns a cons of the response status code and the response data,
also encoded as a plist.

Example:

  (rest-json-sync-call \"http://rest.example.com\" \"/thing\"
                       \"POST\"
                       '(:name \"myThing\" :color \"blue\"))

  ⇒ (200 :thing (:id 1 :name \"myThing\" :color \"blue\"))"
  (let ((request (request
		  (concat base-url resource)
		  :type (or method "GET")
		  :data (and data (json-encode data))
		  :headers (and data '(("Content-Type" . "application/json")))
		  :parser (lambda () (let ((json-object-type 'plist)) (json-read)))
		  :sync t)))
    (cons (request-response-status-code request)
	  (request-response-data request))))


;; JIRA methods
(defun jira-session-create (username password)
  "Create a session for user USERNAME, identified by PASSWORD."
  (rest-json-sync-call "https://example.com/jira/rest" "/auth/1/session" "POST"
	     (list :username username
		   :password password)))

(defun jira-session-delete ()
  "Destroy the current session, aka logout."
  (rest-json-sync-call "https://example.com/jira/rest" "/auth/1/session" "DELETE"))

(defun jira-project-get ()
  "Get all visible projects on JIRA."
  (rest-json-sync-call "https://example.com/jira/rest" "/api/2/project"))

(defun jira-project-get-by-id (id)
  "Get specific project on JIRA by ID."
  (rest-json-sync-call "https://example.com/jira/rest" (format "/api/2/project/%s" id)))

;;; jiralib-rest.el ends here
