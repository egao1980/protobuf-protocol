(in-package #:protobuf-protocol/tests)

(defclass mock-backend (protobuf-protocol:protobuf-backend) ())

(defmethod protobuf-protocol:backend-encode-message ((backend mock-backend) message &key stream)
  (let ((octets (babel:string-to-octets (etypecase message
                                          (string message)
                                          (symbol (string message)))
                                        :encoding :utf-8)))
    (if stream
        (progn (write-sequence octets stream) (values))
        octets)))

(defmethod protobuf-protocol:backend-decode-message ((backend mock-backend) source message-class &key)
  (declare (ignore message-class))
  (let ((octets (etypecase source
                  ((vector (unsigned-byte 8)) source)
                  (stream
                   (let ((out (make-array 0 :element-type '(unsigned-byte 8)
                                            :adjustable t :fill-pointer 0)))
                     (loop for b = (read-byte source nil :eof)
                           until (eq b :eof)
                           do (vector-push-extend b out))
                     out)))))
    (babel:octets-to-string octets :encoding :utf-8)))

(defmethod protobuf-protocol:backend-load-schema ((backend mock-backend) source &key)
  (list :loaded source))

(defun with-mock (fn)
  (let ((protobuf-protocol:*protobuf-backend* (make-instance 'mock-backend)))
    (funcall fn)))

(defun slurp-octets (path)
  (with-open-file (in path :direction :input :element-type '(unsigned-byte 8))
    (let ((buf (make-array (file-length in) :element-type '(unsigned-byte 8))))
      (read-sequence buf in)
      buf)))

(deftest no-backend-signals
  (let ((protobuf-protocol:*protobuf-backend* nil))
    (ok (signals (protobuf-protocol:encode-message "x")
                 'protobuf-protocol:protobuf-error))))

(deftest encode-decode-octets
  (with-mock
    (lambda ()
      (let ((octets (protobuf-protocol:encode-to-octets "hello")))
        (ok (typep octets '(vector (unsigned-byte 8))))
        (ok (equal "hello" (protobuf-protocol:decode-octets octets 'string)))))))

(deftest encode-to-stream
  (with-mock
    (lambda ()
      (uiop:with-temporary-file (:pathname path :prefix "pb-enc-")
        (with-open-file (out path :direction :output
                                  :element-type '(unsigned-byte 8)
                                  :if-exists :supersede)
          (protobuf-protocol:encode-message "ab" :stream out))
        (ok (equalp #(97 98) (slurp-octets path)))))))

(deftest load-schema-delegates
  (with-mock
    (lambda ()
      (ok (equal '(:loaded "ping.lisp")
                 (protobuf-protocol:load-schema "ping.lisp"))))))

(deftest serdes-register
  (ok (serdes-protocol:find-backend :protobuf))
  (ok (serdes-protocol:find-backend :wkt)))

(deftest wkt-without-backend-signals
  (let ((protobuf-protocol:*protobuf-backend* nil))
    (ok (signals (protobuf-protocol:lisp-to-wkt (make-hash-table))
                 'protobuf-protocol:protobuf-error))
    (ok (signals (protobuf-protocol:encode-wkt "x")
                 'protobuf-protocol:protobuf-error))))

(deftest serdes-roundtrip
  (with-mock
    (lambda ()
      (let ((protobuf-protocol:*protobuf-message-class* 'string))
        (let ((octets (serdes-protocol:encode "hi" :format :protobuf)))
          (ok (typep octets '(vector (unsigned-byte 8))))
          (ok (equal "hi" (serdes-protocol:decode octets :format :protobuf))))))))

(deftest serdes-decode-needs-class
  (with-mock
    (lambda ()
      (let ((protobuf-protocol:*protobuf-message-class* nil))
        (ok (signals (serdes-protocol:decode #(104 105) :format :protobuf)
                     'serdes-protocol:serdes-decode-error))))))

(deftest serdes-decode-plist
  (with-mock
    (lambda ()
      (let ((octets (protobuf-protocol:encode-to-octets "z")))
        (ok (equal "z" (serdes-protocol:decode (list :class 'string :octets octets)
                                               :format :protobuf)))))))

(deftest length-delimited-stream
  (with-mock
    (lambda ()
      (let ((protobuf-protocol:*protobuf-message-class* 'string))
        (uiop:with-temporary-file (:pathname path :prefix "pb-ld-")
          (with-open-file (out path :direction :output
                                    :element-type '(unsigned-byte 8)
                                    :if-exists :supersede)
            (let ((s (serdes-protocol:make-output-stream
                      out :format :protobuf :element-type '(unsigned-byte 8))))
              (serdes-protocol:stream-encode-value s "abc")
              (serdes-protocol:stream-encode-value s "xy")))
          (with-open-file (in path :direction :input :element-type '(unsigned-byte 8))
            (let ((s (serdes-protocol:make-input-stream
                      in :format :protobuf :element-type '(unsigned-byte 8))))
              (ok (equal "abc" (serdes-protocol:stream-decode-value s)))
              (ok (equal "xy" (serdes-protocol:stream-decode-value s)))
              (ok (eq :eof (serdes-protocol:stream-decode-value s))))))))))
