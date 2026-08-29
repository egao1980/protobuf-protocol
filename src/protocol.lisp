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

;;; JSON-shaped Lisp ↔ google.protobuf.Value. The protocol owns the GF; the
;;; backend that has the WKT classes implements it. Decode of :wkt never needs
;;; *protobuf-message-class* — the class is always Value.

(defgeneric backend-wkt-value-class (backend)
  (:documentation "Lisp class of google.protobuf.Value for BACKEND.")
  (:method ((backend protobuf-backend))
    (declare (ignore backend))
    (error 'protobuf-error
           :message "backend does not implement WKT Value")))

(defgeneric backend-lisp-to-wkt (backend value)
  (:documentation "JSON-shaped Lisp VALUE → a WKT Value message.")
  (:method ((backend protobuf-backend) value)
    (declare (ignore value))
    (error 'protobuf-encode-error
           :message "backend-lisp-to-wkt not implemented")))

(defgeneric backend-wkt-to-lisp (backend message)
  (:documentation "WKT Value MESSAGE → JSON-shaped Lisp.")
  (:method ((backend protobuf-backend) message)
    (declare (ignore message))
    (error 'protobuf-decode-error
           :message "backend-wkt-to-lisp not implemented")))

(defun lisp-to-wkt (value &key (backend *protobuf-backend*))
  "JSON-shaped Lisp → WKT Value message."
  (backend-lisp-to-wkt (%ensure-backend backend) value))

(defun wkt-to-lisp (message &key (backend *protobuf-backend*))
  "WKT Value message → JSON-shaped Lisp."
  (backend-wkt-to-lisp (%ensure-backend backend) message))

(defun encode-wkt (value &key stream (backend *protobuf-backend*))
  "JSON-shaped Lisp → protobuf octets of a WKT Value (or write STREAM)."
  (encode-message (lisp-to-wkt value :backend backend)
                  :stream stream :backend backend))

(defun decode-wkt (source &key (backend *protobuf-backend*))
  "Protobuf octets (or stream) of a WKT Value → JSON-shaped Lisp."
  (let ((b (%ensure-backend backend)))
    (wkt-to-lisp (decode-message source (backend-wkt-value-class b) :backend b)
                 :backend b)))
