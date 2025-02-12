docker stop $(docker ps -aq)
docker rm $(docker ps -aq)
docker rmi $(docker image ls -q)
docker volume rm $(docker volume ls -q)
# docker container prune
# docker image prune 
# docker volume prune
