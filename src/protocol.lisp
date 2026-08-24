(in-package #:protobuf-protocol)

;;; CLOS protobuf message GFs. Values are backend proto classes (cl-protobufs),
;;; not a parallel DOM. Octets first — SSE/gRPC want bytes.

(defclass protobuf-backend (serdes-protocol:serdes-backend) ())

(defvar *protobuf-backend* nil
  "Current protobuf backend. Load protobuf-backend-cl-protobufs to bind.")

(defvar *protobuf-message-class* nil
  "Default message class for serdes:decode / stream-decode-value when :format :protobuf.")

(defgeneric backend-encode-message (backend message &key stream)
  (:documentation "Encode MESSAGE to octets, or write octets to STREAM."))

(defgeneric backend-decode-message (backend source message-class &key)
  (:documentation "Decode SOURCE (octets or binary stream) as MESSAGE-CLASS."))

(defgeneric backend-load-schema (backend source &key)
  (:documentation "Load a compiled schema (generated .lisp or ASDF system).
   Does not shell out to protoc."))

(defmethod backend-encode-message ((backend protobuf-backend) message &key stream)
  (declare (ignore message stream))
  (error 'protobuf-encode-error
         :message "backend-encode-message not implemented"))

(defmethod backend-decode-message ((backend protobuf-backend) source message-class &key)
  (declare (ignore source message-class))
  (error 'protobuf-decode-error
         :message "backend-decode-message not implemented"))

(defmethod backend-load-schema ((backend protobuf-backend) source &key)
  (declare (ignore source))
  (error 'protobuf-schema-error
         :message "backend-load-schema not implemented"))

(defun %ensure-backend (&optional (backend *protobuf-backend*))
  (or backend
      (error 'protobuf-error
             :message "*protobuf-backend* is nil — load protobuf-backend-cl-protobufs")))

(defun encode-message (message &key stream (backend *protobuf-backend*))
  "Encode MESSAGE via BACKEND. Returns octets unless STREAM is given."
  (backend-encode-message (%ensure-backend backend) message :stream stream))

(defun decode-message (source message-class &key (backend *protobuf-backend*))
  "Decode SOURCE (octets or binary stream) as MESSAGE-CLASS."
  (backend-decode-message (%ensure-backend backend) source message-class))

(defun encode-to-octets (message &key (backend *protobuf-backend*))
  "Encode MESSAGE to an (unsigned-byte 8) vector."
  (let ((encoded (encode-message message :backend backend)))
    (if (and (vectorp encoded) (not (stringp encoded)))
        encoded
        (error 'protobuf-encode-error
               :message "backend did not return octets"))))

(defun decode-octets (octets message-class &key (backend *protobuf-backend*))
  "Decode OCTETS as MESSAGE-CLASS."
  (decode-message octets message-class :backend backend))

(defun load-schema (source &key (backend *protobuf-backend*))
  "Load a compiled schema. SOURCE = generated .lisp pathname or ASDF system name."
  (backend-load-schema (%ensure-backend backend) source))
