docker stop $(docker ps -aq)
docker rm $(docker ps -aq)
docker rmi $(docker image ls -q)
docker volume rm $(docker volume ls -q)
