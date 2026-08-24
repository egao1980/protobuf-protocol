(in-package #:protobuf-protocol)

(define-condition protobuf-error (error)
  ((message :initarg :message :reader protobuf-error-message :initform nil))
  (:report (lambda (c s)
             (format s "protobuf error~@[: ~a~]" (protobuf-error-message c)))))

(define-condition protobuf-encode-error (protobuf-error) ())

(define-condition protobuf-decode-error (protobuf-error) ())

(define-condition protobuf-schema-error (protobuf-error) ())
