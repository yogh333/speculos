## How to use the Docker image

Pull the latest image from
[Docker Hub](https://hub.docker.com/r/ledgerhq/speculos):

```shell
docker pull ledgerhq/speculos
```

And launch the Docker image:

- With X11: `./scripts/docker_x11.sh apps/btc.elf`
- With VNC: `./scripts/docker_vnc.sh apps/btc.elf`

The image can obviously run an interactive shell by adding
`--entrypoint /bin/bash` to the Docker command-line.
