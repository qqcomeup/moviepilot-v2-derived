# MoviePilot v2 Derived Image

This image follows `jxxghp/moviepilot-v2` and fixes `/app/app/plugins`
ownership during image build for `PUID=1000` and `PGID=1001`, avoiding
runtime recursive `chown` over `/app`.

Image:

```text
ghcr.io/qqcomeup/moviepilot-v2-derived
```

Tags:

- `latest`
- upstream version, for example `2.14.1`

The workflow only builds `linux/amd64`, matching the current deployment host.

Manual build:

```bash
gh workflow run build.yml -f mp_tag=2.14.1
```
