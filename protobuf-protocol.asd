(defsystem "protobuf-protocol"
  :version "0.1.0"
  :description "CLOS protobuf / serdes :protobuf protocol for cl-stack"
  :author "egao1980"
  :license "MIT"
  :depends-on ("serdes-protocol")
  :serial t
  :pathname "src"
  :components ((:file "package")
               (:file "conditions")
               (:file "protocol")
               (:file "serdes"))
  :in-order-to ((test-op (test-op "protobuf-protocol/tests"))))

(defsystem "protobuf-protocol/tests"
  :depends-on ("protobuf-protocol" "rove")
  :pathname "tests"
  :serial t
  :components ((:file "package")
               (:file "protocol-test"))
  :perform (test-op (o c)
             (unless (symbol-call :rove :run c)
               (error "tests failed for ~A" (component-name c)))))
