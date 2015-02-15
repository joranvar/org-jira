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

;;; org-jira-test.el ends here
