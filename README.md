# protobuf-protocol

CLOS protobuf / serdes `:protobuf` and `:wkt` protocol for cl-stack.

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

JSON-shaped Lisp (hash-tables, vectors, strings, numbers, `:null`) is
`google.protobuf.Value` via `lisp-to-wkt` / `wkt-to-lisp`. serdes `:wkt`
encodes that Value; stream encode is the same big-endian uint32 length
prefix as `:protobuf`. Decode of `:wkt` does not need
`*protobuf-message-class*`.

`load-schema` takes a generated `.lisp` or ASDF system name. It does **not**
shell out to protoc — schema compile stays in the backend / `cl-protobufs.asdf`.

```
sbcl --load scripts/roundtrip.lisp
```

CI: canned [`cl-repository`](https://github.com/egao1980/cl-repository) (`test-system.yml` / `setup-client` + `ci`). Deps from `ghcr.io/egao1980/cl-systems`.

## License

MIT
