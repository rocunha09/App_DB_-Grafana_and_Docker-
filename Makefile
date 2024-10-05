# Comandos do Docker Compose para subir e gerenciar os containers
up:
	docker-compose up -d

down:
	docker-compose down

logs:
	docker-compose logs -f

restart:
	docker-compose down && docker-compose up -d

clean:
	docker-compose down -v && make clean-volumes

exec-mysql:
	docker exec -it mysql-oversee mysql -uroot -proot oversee

exec-app:
	docker exec -it oversee-php_app-1 /bin/bash

exec-grafana:
	docker exec -it grafana /bin/bash

clean-volumes:
	docker volume rm oversee_grafana-data oversee_mysql-data   
