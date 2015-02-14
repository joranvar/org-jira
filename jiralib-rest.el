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

;;; jiralib-rest.el ends here
