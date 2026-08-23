(in-package #:protobuf-protocol)

(defclass protobuf-backend () ())

(defvar *protobuf-backend* nil)

(defgeneric backend-encode-message (backend message &key))
(defgeneric backend-decode-message (backend octets message-class &key))
(defgeneric backend-load-schema (backend source &key))

(defun %ensure-backend (&optional (backend *protobuf-backend*))
  (or backend
      (error 'protobuf-error
             :message "*protobuf-backend* is nil — load protobuf-backend-cl-protobufs")))

(defun encode-message (message &key (backend *protobuf-backend*))
  (backend-encode-message (%ensure-backend backend) message))

(defun decode-message (octets message-class &key (backend *protobuf-backend*))
  (backend-decode-message (%ensure-backend backend) octets message-class))

(defun load-schema (source &key (backend *protobuf-backend*))
  (backend-load-schema (%ensure-backend backend) source))
