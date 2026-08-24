;;;; Dogfood protocol façade + serdes :protobuf with a mock backend.
;;;;   sbcl --load scripts/roundtrip.lisp

(setf *debugger-hook*
      (lambda (c h)
        (declare (ignore h))
        (format *error-output* "~&roundtrip failed: ~a~%" c)
        (uiop:quit 1)))

(defun %here ()
  (uiop:pathname-directory-pathname
   (or *load-truename* *compile-file-truename* (uiop:getcwd))))

(defun %root ()
  (uiop:pathname-parent-directory-pathname (%here)))

(pushnew (%root) asdf:*central-registry* :test #'equal)
(let ((serdes (merge-pathnames "serdes-protocol/"
                               (uiop:pathname-parent-directory-pathname (%root)))))
  (when (probe-file serdes)
    (pushnew serdes asdf:*central-registry* :test #'equal)))

(asdf:load-system "protobuf-protocol")

(defclass mock-backend (protobuf-protocol:protobuf-backend) ())

(defmethod protobuf-protocol:backend-encode-message ((backend mock-backend) message &key stream)
  (let ((octets (babel:string-to-octets message :encoding :utf-8)))
    (if stream
        (progn (write-sequence octets stream) (values))
        octets)))

(defmethod protobuf-protocol:backend-decode-message ((backend mock-backend) source message-class &key)
  (declare (ignore message-class))
  (babel:octets-to-string source :encoding :utf-8))

(defun fail (fmt &rest args)
  (apply #'format *error-output* (concatenate 'string "~&FAIL: " fmt "~%") args)
  (uiop:quit 1))

(let ((protobuf-protocol:*protobuf-backend* (make-instance 'mock-backend))
      (protobuf-protocol:*protobuf-message-class* 'string))
  (let ((octets (protobuf-protocol:encode-to-octets "ping")))
    (unless (equalp octets (babel:string-to-octets "ping" :encoding :utf-8))
      (fail "encode-to-octets"))
    (unless (equal "ping" (protobuf-protocol:decode-octets octets 'string))
      (fail "decode-octets"))
    (unless (equal "ping" (serdes-protocol:decode
                           (serdes-protocol:encode "ping" :format :protobuf)
                           :format :protobuf))
      (fail "serdes :protobuf")))
  (format t "~&; protobuf-protocol roundtrip ok~%")
  (uiop:quit 0))
