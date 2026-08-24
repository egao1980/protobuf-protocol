# protobuf-protocol

CLOS protobuf / serdes `:protobuf` protocol for cl-stack.

Part of [cl-stack](https://github.com/egao1980/cl-stack) agent-wire
([brief](https://github.com/egao1980/cl-stack/blob/main/docs/capabilities/protobuf.md)).

Values are backend proto messages (cl-protobufs classes). Octets first.

```lisp
(asdf:load-system "protobuf-protocol")
(asdf:load-system "protobuf-backend-cl-protobufs")

(protobuf-protocol:encode-to-octets message)
(protobuf-protocol:decode-octets octets 'my-package:my-message)

(let ((protobuf-protocol:*protobuf-message-class* 'my-package:my-message))
  (serdes-protocol:encode message :format :protobuf)
  (serdes-protocol:decode octets :format :protobuf))
```

`load-schema` takes a generated `.lisp` or ASDF system name. It does **not**
shell out to protoc — schema compile stays in the backend / `cl-protobufs.asdf`.

```
sbcl --load scripts/roundtrip.lisp
```

CI: `setup-client` + `setup-roswell` + `scripts/ci-install.lisp` / `ci-test.lisp` (OCI only, no Quicklisp).

## License

MIT
