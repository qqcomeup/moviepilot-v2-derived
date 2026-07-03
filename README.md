# MoviePilot v2 派生镜像

这是一个基于官方 `jxxghp/moviepilot-v2` 的轻量派生镜像，不修改
MoviePilot 源码，只把部分启动时反复执行的权限处理前移到镜像构建阶段。

当前镜像适配的运行用户：

```text
PUID=1000
PGID=1001
```

镜像地址：

```text
ghcr.io/qqcomeup/moviepilot-v2-derived
```

## 解决的问题

官方镜像启动时会递归处理 `/app`、`/public` 等路径权限。文件数量较多时，即使是
SSD/NVMe，也可能因为 overlayfs 和大量 inode 元数据写入导致启动前长时间无日志。

本镜像在构建阶段完成：

```dockerfile
groupmod -o -g 1001 moviepilot
usermod -o -u 1000 moviepilot
chown -R 1000:1001 /app /public
```

配合自定义 `entrypoint.sh` 跳过运行时的 `/app`、`/public` 权限修复后，可以把启动时
`chown` 阶段从几十秒降到毫秒级。

## 实测数据

测试环境中，官方运行时权限处理耗时：

```text
chown /app:     31858 ms
chown /public:  20397 ms
chown 总耗时:   52892 ms
```

使用派生镜像并跳过运行时 `/app`、`/public` 后：

```text
groupmod/usermod 已跳过
chown /app/app/plugins 已跳过: 5 ms
chown /public 已跳过: 2 ms
chown 总耗时: 322 ms
```

## 自动跟随上游

GitHub Actions 每 5 分钟检查一次上游最新版：

1. 读取 `jxxghp/MoviePilot` 最新 GitHub Release，例如 `v2.14.1`
2. 转换为 Docker Hub tag，例如 `2.14.1`
3. 等待 `jxxghp/moviepilot-v2:2.14.1` 在 Docker Hub 可用
4. 构建并推送：

```text
ghcr.io/qqcomeup/moviepilot-v2-derived:2.14.1
ghcr.io/qqcomeup/moviepilot-v2-derived:latest
```

如果对应版本已经构建过，workflow 会跳过。

## 手动触发构建

```bash
gh workflow run build.yml -f mp_tag=2.14.1
```

## docker-compose 示例

```yaml
services:
  moviepilot:
    image: ghcr.io/qqcomeup/moviepilot-v2-derived:2.14.1
    environment:
      - PUID=1000
      - PGID=1001
```

如果仍然使用官方 `entrypoint.sh`，它可能还是会执行运行时 `groupmod/usermod` 和
`chown`。需要同步调整启动脚本，跳过已经在镜像构建阶段处理过的步骤。

## 适用范围

适合：

- 固定使用 `PUID=1000`、`PGID=1001` 的部署环境
- 不想把 `/app` 映射到宿主机
- 希望减少容器重建时的启动空窗期

不适合：

- 经常更换 `PUID` 或 `PGID`
- 希望一个镜像同时适配多台不同 UID/GID 的机器
- 不想维护自定义 `entrypoint.sh`

如果你的 UID/GID 不是 `1000:1001`，需要修改 workflow 的 build args 后重新构建。
