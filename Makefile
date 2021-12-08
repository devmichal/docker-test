remove:
	docker stop docker_nginx
	docker rm docker_nginx

build:
	docker build -t docker_nginx:1.0.15 .
	docker run --name docker_nginx -itd -p 8080:8080 docker_nginx:1.0.15