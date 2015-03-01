(require 'f)
(require 'test-helper (f-expand "test-helper.el" (f-dirname (f-this-file))))

;;; Code:
(defconst root-node
  "\n* JIRA root\n  :PROPERTIES:\n  :COLUMNS:  %140ITEM %8ORG-JIRA-ID(id)\n  :ORG-JIRA-NODE: root\n  :ORG-JIRA-REST-URL: http://example.com/jira/rest\n  :END:\n")

(defvar root-node-only
  (concat root-node org-jira-default-root-text))

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
             (buffer-substring-no-properties (point-min) (point-max))
             root-node-only))))

(ert-deftest fetch-projects--in-an-empty-buffer--fails-with-message ()
  (with-temp-buffer
    (should (equal
             (nth 1 (should-error (org-jira-fetch-projects)
                                  :type 'error))
             "No root node found, please call org-jira-create-org-tree first"))))

(ert-deftest fetch-projects--in-a-root-node--fetches-all-projects-on-associated-server ()
  (with-temp-buffer
    (insert root-node-only)
    (using-fake-call 'rest-json-sync-call
        ((should (equal (car args) "http://example.com/jira/rest"))
         nil)
      (org-jira-fetch-projects))))

(defconst first-fake-return-of-fetch-projects
  (cons 200
        [((projectCategory
           (name . "CRD")
           (description . "")
           (id . "10701")
           (self . "http://example.com/jira/rest/api/2/projectCategory/10701"))
          (avatarUrls
           (32x32 . "http://example.com/jira/secure/projectavatar?size=medium&pid=12603&avatarId=10011")
           (16x16 . "http://example.com/jira/secure/projectavatar?size=xsmall&pid=12603&avatarId=10011")
           (24x24 . "http://example.com/jira/secure/projectavatar?size=small&pid=12603&avatarId=10011")
           (48x48 . "http://example.com/jira/secure/projectavatar?pid=12603&avatarId=10011"))
          (name . "Base Components Request")
          (key . "BASREQ")
          (id . "12603")
          (self . "http://example.com/jira/rest/api/2/project/12603"))
         ((projectCategory
           (name . "CID")
           (description . "Internal Projects by Central IT Development")
           (id . "10101")
           (self . "http://example.com/jira/rest/api/2/projectCategory/10101"))
          (avatarUrls
           (32x32 . "http://example.com/jira/secure/projectavatar?size=medium&pid=14507&avatarId=15162")
           (16x16 . "http://example.com/jira/secure/projectavatar?size=xsmall&pid=14507&avatarId=15162")
           (24x24 . "http://example.com/jira/secure/projectavatar?size=small&pid=14507&avatarId=15162")
           (48x48 . "http://example.com/jira/secure/projectavatar?pid=14507&avatarId=15162"))
          (name . "Central Development Systems")
          (key . "DEVSYS")
          (id . "14507")
          (self . "http://example.com/jira/rest/api/2/project/14507"))]
        ))

(defconst second-fake-return-of-fetch-projects
  (cons 200
        [((projectCategory
           (name . "CRD")
           (description . "")
           (id . "10701")
           (self . "http://example.com/jira/rest/api/2/projectCategory/10701"))
          (avatarUrls
           (32x32 . "http://example.com/jira/secure/projectavatar?size=medium&pid=12603&avatarId=10011")
           (16x16 . "http://example.com/jira/secure/projectavatar?size=xsmall&pid=12603&avatarId=10011")
           (24x24 . "http://example.com/jira/secure/projectavatar?size=small&pid=12603&avatarId=10011")
           (48x48 . "http://example.com/jira/secure/projectavatar?pid=12603&avatarId=10011"))
          (name . "Base Components Request Changed Name")
          (key . "BASREQ")
          (id . "12603")
          (self . "http://example.com/jira/rest/api/2/project/12603"))
         ((projectCategory
           (name . "CID")
           (description . "Internal Projects by Central IT Development")
           (id . "10101")
           (self . "http://example.com/jira/rest/api/2/projectCategory/10101"))
          (avatarUrls
           (32x32 . "http://example.com/jira/secure/projectavatar?size=medium&pid=14507&avatarId=15162")
           (16x16 . "http://example.com/jira/secure/projectavatar?size=xsmall&pid=14507&avatarId=15162")
           (24x24 . "http://example.com/jira/secure/projectavatar?size=small&pid=14507&avatarId=15162")
           (48x48 . "http://example.com/jira/secure/projectavatar?pid=14507&avatarId=15162"))
          (name . "Central Development Systems")
          (key . "DEVSYS")
          (id . "14507")
          (self . "http://example.com/jira/rest/api/2/project/14507"))]
        ))

(ert-deftest fetch-projects--in-a-sub-node--fetches-all-projects-on-associated-server ()
  (with-temp-buffer
    (insert root-node-only)
    (using-fake-call 'rest-json-sync-call
        (first-fake-return-of-fetch-projects)
      (org-jira-fetch-projects))
    (should (equal
             (buffer-substring-no-properties (point-min) (point-max))
             (concat root-node-only "\n** Base Components Request :BASREQ:\n   :PROPERTIES:\n   :ORG-JIRA-NODE: project 12603\n   :ORG-JIRA-NAME: Base Components Request\n   :ORG-JIRA-KEY: BASREQ\n   :ORG-JIRA-ID: 12603\n   :END:\n\n** Central Development Systems :DEVSYS:\n   :PROPERTIES:\n   :ORG-JIRA-NODE: project 14507\n   :ORG-JIRA-NAME: Central Development Systems\n   :ORG-JIRA-KEY: DEVSYS\n   :ORG-JIRA-ID: 14507\n   :END:\n")))))

(ert-deftest fetch-projects--twice--inserts-all-projects-only-once ()
  (with-temp-buffer
    (insert root-node-only)
    (using-fake-call 'rest-json-sync-call
        (first-fake-return-of-fetch-projects)
      (org-jira-fetch-projects)
      (org-jira-fetch-projects))
    (should (equal
             (buffer-substring-no-properties (point-min) (point-max))
             (concat root-node-only "\n** Base Components Request :BASREQ:\n   :PROPERTIES:\n   :ORG-JIRA-NODE: project 12603\n   :ORG-JIRA-NAME: Base Components Request\n   :ORG-JIRA-KEY: BASREQ\n   :ORG-JIRA-ID: 12603\n   :END:\n\n** Central Development Systems :DEVSYS:\n   :PROPERTIES:\n   :ORG-JIRA-NODE: project 14507\n   :ORG-JIRA-NAME: Central Development Systems\n   :ORG-JIRA-KEY: DEVSYS\n   :ORG-JIRA-ID: 14507\n   :END:\n")))))

(ert-deftest fetch-projects--twice--updates-all-changed-projects ()
  (with-temp-buffer
    (insert root-node-only)
    (using-fake-call 'rest-json-sync-call
        (first-fake-return-of-fetch-projects)
      (org-jira-fetch-projects))
    (using-fake-call 'rest-json-sync-call
        (second-fake-return-of-fetch-projects)
      (org-jira-fetch-projects))
    (should (equal
             (buffer-substring-no-properties (point-min) (point-max))
             (concat root-node-only "\n** Base Components Request :BASREQ:\n   :PROPERTIES:\n   :ORG-JIRA-NODE: project 12603\n   :ORG-JIRA-NAME: Base Components Request Changed Name\n   :ORG-JIRA-KEY: BASREQ\n   :ORG-JIRA-ID: 12603\n   :END:\n\n** Central Development Systems :DEVSYS:\n   :PROPERTIES:\n   :ORG-JIRA-NODE: project 14507\n   :ORG-JIRA-NAME: Central Development Systems\n   :ORG-JIRA-KEY: DEVSYS\n   :ORG-JIRA-ID: 14507\n   :END:\n")))))

;;; org-jira-test.el ends here
