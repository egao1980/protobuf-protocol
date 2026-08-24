(defpackage #:protobuf-protocol
  (:use #:cl)
  (:nicknames #:stack-protobuf)
  (:export #:protobuf-error
           #:protobuf-encode-error
           #:protobuf-decode-error
           #:protobuf-schema-error
           #:protobuf-error-message
           #:protobuf-backend
           #:*protobuf-backend*
           #:*protobuf-message-class*
           #:encode-message
           #:decode-message
           #:encode-to-octets
           #:decode-octets
           #:load-schema
           #:backend-encode-message
           #:backend-decode-message
           #:backend-load-schema
           #:protobuf-serdes-backend
           #:use-protobuf-serdes-backend))

(in-package #:protobuf-protocol)
