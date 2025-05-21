FROM swift:5.9 as builder
RUN apt-get update -y && apt-get install libgd-dev -y
WORKDIR /app
COPY . .
RUN swift build -c release
# aarch64-unknown-linux-gnu for raspberry pi
# x86_64-unknown-linux-gnu for intel based architectures
RUN mkdir output
RUN cp -R $(swift build --show-bin-path -c release)/FolderWatch output/App

FROM swift:5.9-slim
RUN apt-get update -y && apt-get install libgd-dev -y
WORKDIR /app
COPY --from=builder /app/output/App .
COPY .env /app/.env
COPY local.env /app/local.env
CMD ["./App"]