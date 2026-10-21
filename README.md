# MiniC container for ANTLR

Create the podman image with :
```bash
podman build -t compil .
```

Run a bash in your MiniC directory with 
```bash
podman run --mount=type=bind,source=.,target=/app -it --rm compil bash
```

You can directly run the makefile :
```bash
podman run --mount=type=bind,source=.,target=/app -it --rm compil bash -c "make test"
```
