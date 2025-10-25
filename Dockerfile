# --- 阶段一：构建器 (Builder) ---
# 使用 Go 官方镜像来编译代码
FROM golang:alpine AS builder

# 在容器中设置编译的工作目录
WORKDIR /src

# 复制 Go 模块依赖文件，并下载依赖
# 这一步可以利用 Docker 缓存，加快后续构建速度
COPY go.mod go.sum ./
RUN go mod download

# 复制所有源代码 (包括 api 文件夹和 main.go)
COPY . .

# 编译应用程序，生成静态链接的二进制文件
# -ldflags "-s -w" 减小二进制文件体积
# -o /ikuai-bypass 将二进制文件输出到容器根目录，方便下一阶段复制
RUN go build -ldflags "-s -w" -o /ikuai-bypass ./main.go 

# --- 阶段二：最终运行环境 (Final Runtime) ---
# 使用轻量级的 Alpine 镜像作为最终基础镜像
FROM alpine:latest

# 安装时区数据并设置时区（优化您的 RUN 命令）
RUN apk add --no-cache tzdata && \
    ln -sf /usr/share/zoneinfo/Asia/Shanghai /etc/localtime && \
    echo "Asia/Shanghai" > /etc/timezone && \
    rm -rf /var/cache/apk/* # 设置工作目录，与您原先的 Dockerfile 保持一致
WORKDIR /build

# 从构建器阶段复制编译好的二进制文件
COPY --from=builder /ikuai-bypass .

# 最终启动命令
# 注意：/etc/ikuai-bypass/config.yml 文件需要您在容器运行时确保存在，或通过 volume 挂载。
CMD ["./ikuai-bypass", "-c", "/etc/ikuai-bypass/config.yml"]
