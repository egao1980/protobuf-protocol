(defpackage #:protobuf-protocol
  (:use #:cl)
  (:nicknames #:stack-protobuf)
  (:export #:protobuf-error
           #:protobuf-error-message
           #:protobuf-backend
           #:*protobuf-backend*
           #:encode-message
           #:decode-message
           #:load-schema
           #:backend-encode-message
           #:backend-decode-message
           #:backend-load-schema))

(in-package #:protobuf-protocol)
