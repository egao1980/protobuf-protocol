(in-package #:protobuf-protocol)

;;; serdes-protocol implementor for :protobuf. Octets ↔ proto message.

(defclass protobuf-serdes-backend (serdes-protocol:serdes-backend) ())

(defclass protobuf-binary-input-stream (serdes-protocol:serdes-binary-input-stream) ())

(defclass protobuf-binary-output-stream (serdes-protocol:serdes-binary-output-stream) ())

(defun make-protobuf-serdes-backend ()
  (make-instance 'protobuf-serdes-backend))

(defun %coerce-octets (source)
  (etypecase source
    ((vector (unsigned-byte 8)) source)
    (array
     (if (and (not (stringp source))
              (every (lambda (b) (typep b '(unsigned-byte 8))) source))
         (coerce source '(vector (unsigned-byte 8)))
         (error 'protobuf-decode-error
                :message "serdes :protobuf decode needs octets")))
    (stream source)))

(defun %message-class-for-decode (source)
  (or *protobuf-message-class*
      (when (and (consp source) (keywordp (car source)))
        (getf source :class))
      (error 'protobuf-decode-error
             :message "*protobuf-message-class* is nil — bind it or pass (:class TYPE :octets OCTETS)")))

(defun %payload-for-decode (source)
  (if (and (consp source) (keywordp (car source)))
      (or (getf source :octets) (getf source :data))
      source))

(defmethod serdes-protocol:backend-encode ((backend protobuf-serdes-backend) value &key stream)
  (declare (ignore backend))
  (encode-message value :stream stream))

(defmethod serdes-protocol:backend-decode ((backend protobuf-serdes-backend) source &key)
  (declare (ignore backend))
  (decode-message (%coerce-octets (%payload-for-decode source))
                  (%message-class-for-decode source)))

(defmethod serdes-protocol:backend-make-input-stream ((backend protobuf-serdes-backend)
                                                      underlying
                                                      &key (element-type '(unsigned-byte 8)))
  (unless (equal element-type '(unsigned-byte 8))
    (error 'protobuf-error
           :message (format nil "protobuf streams are binary, got ~S" element-type)))
  (make-instance 'protobuf-binary-input-stream
                 :underlying underlying
                 :backend backend))

(defmethod serdes-protocol:backend-make-output-stream ((backend protobuf-serdes-backend)
                                                       underlying
                                                       &key (element-type '(unsigned-byte 8)))
  (unless (equal element-type '(unsigned-byte 8))
    (error 'protobuf-error
           :message (format nil "protobuf streams are binary, got ~S" element-type)))
  (make-instance 'protobuf-binary-output-stream
                 :underlying underlying
                 :backend backend))

(defun %write-u32be (stream n)
  (write-byte (ldb (byte 8 24) n) stream)
  (write-byte (ldb (byte 8 16) n) stream)
  (write-byte (ldb (byte 8 8) n) stream)
  (write-byte (ldb (byte 8 0) n) stream))

(defun %read-u32be (stream)
  (let ((b0 (read-byte stream nil :eof)))
    (when (eq b0 :eof)
      (return-from %read-u32be :eof))
    (let ((b1 (read-byte stream nil :eof))
          (b2 (read-byte stream nil :eof))
          (b3 (read-byte stream nil :eof)))
      (when (or (eq b1 :eof) (eq b2 :eof) (eq b3 :eof))
        (error 'protobuf-decode-error :message "truncated length prefix"))
      (logior (ash b0 24) (ash b1 16) (ash b2 8) b3))))

(defmethod serdes-protocol:stream-encode-value ((stream protobuf-binary-output-stream) value &key)
  (let* ((octets (encode-message value))
         (out (serdes-protocol:underlying-stream stream)))
    (%write-u32be out (length octets))
    (write-sequence octets out)
    value))

(defmethod serdes-protocol:stream-decode-value ((stream protobuf-binary-input-stream) &key)
  (let* ((in (serdes-protocol:underlying-stream stream))
         (len (%read-u32be in)))
    (when (eq len :eof)
      (return-from serdes-protocol:stream-decode-value :eof))
    (let ((buf (make-array len :element-type '(unsigned-byte 8))))
      (let ((n (read-sequence buf in)))
        (unless (= n len)
          (error 'protobuf-decode-error :message "truncated length-delimited message")))
      (decode-message buf (%message-class-for-decode nil)))))

(defun use-protobuf-serdes-backend ()
  "Register :protobuf with serdes-protocol. Does not change *SERDES-FORMAT*."
  (let ((backend (make-protobuf-serdes-backend)))
    (serdes-protocol:register-format :protobuf backend)
    backend))

;;; :wkt — JSON document as google.protobuf.Value. Same length-prefixed
;;; framing as :protobuf; the payload is always a Value, so decode does not
;;; need *protobuf-message-class*.

(defclass wkt-serdes-backend (protobuf-serdes-backend) ())

(defclass wkt-binary-input-stream (protobuf-binary-input-stream) ())

(defclass wkt-binary-output-stream (protobuf-binary-output-stream) ())

(defun make-wkt-serdes-backend ()
  (make-instance 'wkt-serdes-backend))

(defmethod serdes-protocol:backend-encode ((backend wkt-serdes-backend) value &key stream)
  (declare (ignore backend))
  (encode-wkt value :stream stream))

(defmethod serdes-protocol:backend-decode ((backend wkt-serdes-backend) source &key)
  (declare (ignore backend))
  (decode-wkt (%coerce-octets (%payload-for-decode source))))

(defmethod serdes-protocol:backend-make-input-stream ((backend wkt-serdes-backend)
                                                      underlying
                                                      &key (element-type '(unsigned-byte 8)))
  (unless (equal element-type '(unsigned-byte 8))
    (error 'protobuf-error
           :message (format nil "wkt streams are binary, got ~S" element-type)))
  (make-instance 'wkt-binary-input-stream
                 :underlying underlying
                 :backend backend))

(defmethod serdes-protocol:backend-make-output-stream ((backend wkt-serdes-backend)
                                                       underlying
                                                       &key (element-type '(unsigned-byte 8)))
  (unless (equal element-type '(unsigned-byte 8))
    (error 'protobuf-error
           :message (format nil "wkt streams are binary, got ~S" element-type)))
  (make-instance 'wkt-binary-output-stream
                 :underlying underlying
                 :backend backend))

(defmethod serdes-protocol:stream-encode-value ((stream wkt-binary-output-stream) value &key)
  (let* ((octets (encode-wkt value))
         (out (serdes-protocol:underlying-stream stream)))
    (%write-u32be out (length octets))
    (write-sequence octets out)
    value))

(defmethod serdes-protocol:stream-decode-value ((stream wkt-binary-input-stream) &key)
  (let* ((in (serdes-protocol:underlying-stream stream))
         (len (%read-u32be in)))
    (when (eq len :eof)
      (return-from serdes-protocol:stream-decode-value :eof))
    (let ((buf (make-array len :element-type '(unsigned-byte 8))))
      (let ((n (read-sequence buf in)))
        (unless (= n len)
          (error 'protobuf-decode-error :message "truncated length-delimited message")))
      (decode-wkt buf))))

(defun use-wkt-serdes-backend ()
  "Register :wkt with serdes-protocol. Does not change *SERDES-FORMAT*."
  (let ((backend (make-wkt-serdes-backend)))
    (serdes-protocol:register-format :wkt backend)
    backend))

(use-protobuf-serdes-backend)
(use-wkt-serdes-backend)
