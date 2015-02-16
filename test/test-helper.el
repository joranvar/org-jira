(require 'f)
(require 'jiralib-rest (f-expand "jiralib-rest.el" (f-parent (f-dirname (f-this-file)))))

;;; Code:
(defmacro using-fake-call (fsymbol new-body &rest body)
  "Redirects calls to FSYMBOL to the NEW-BODY throughout BODY."
  (declare (indent 2))
  `(let ((old-call))
    (fset old-call ,fsymbol)
    (fset ,fsymbol (lambda (&rest args) ,@new-body))
    (let ((result (progn ,@body)))
      (fset ,fsymbol old-call)
      result)))

(provide 'test-helper)
;;; test-helper.el ends here
