(require 'f)
(require 'test-helper (f-expand "test-helper.el" (f-dirname (f-this-file))))

;;; Code:
(ert-deftest using-fake-environment-works-fine ()
  "Exploratory test to make sure that real REST calls are not made."
  (should (equal
	   (using-fake-call 'jira-call
	       ("New return")
	     (jira-session-delete))
	   "New return")))

;; create-org-tree
(ert-deftest create-org-tree--in-an-empty-buffer--creates-root-element-for-jira-querying ()
  (with-temp-buffer
    (org-jira-create-org-tree)
    (should (equal
	     (buffer-string)
	     (concat "\n* JIRA root\n  :PROPERTIES:\n  :ORG-JIRA-NODE: root\n  :ORG-JIRA-REST-URL: http://example.com/jira/rest\n  :END:\n" org-jira-default-root-text)))))

(ert-deftest fetch-projects--in-an-empty-buffer--fails-with-message ()
  (with-temp-buffer
    (should (equal
	     (nth 1 (should-error (org-jira-fetch-projects)
				  :type 'error))
	     "No root node found, please call org-jira-create-org-tree first"))))

(ert-deftest fetch-projects--in-a-root-node--fetches-all-projects-on-associated-server ()
  (with-temp-buffer
    (insert (concat "\n* JIRA root\n  :PROPERTIES:\n  :ORG-JIRA-NODE: root\n  :ORG-JIRA-REST-URL: http://example.com/jira/rest\n  :END:\n" org-jira-default-root-text))
    (using-fake-call 'rest-json-sync-call
	((should (equal (car args) "http://example.com/jira/rest")))
      (org-jira-fetch-projects))))

;;; org-jira-test.el ends here
