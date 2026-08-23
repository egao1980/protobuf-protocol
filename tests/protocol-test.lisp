(in-package #:protobuf-protocol/tests)

(deftest no-backend-signals
  (let ((protobuf-protocol:*protobuf-backend* nil))
    (ok (signals (protobuf-protocol:encode-message nil)
                 'protobuf-protocol:protobuf-error))))
