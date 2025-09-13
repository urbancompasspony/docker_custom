OBS: DWSERVICE É ROOT POR PADRÃO!

docker buildx create --name mybuilder

docker buildx use mybuilder

docker login

docker buildx build --push --platform linux/amd64,linux/arm64 --tag urbancompasspony/ssh-dw .
