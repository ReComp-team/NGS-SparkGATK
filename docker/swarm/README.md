(credits to: https://github.com/big-data-europe/docker-hadoop-spark-workbench)
# Running Hadoop and Spark in Swarm cluster


Initialize the Swarm:
```
sudo docker swarm init
```
and use generated output to join other nodes to the Swarm.

Create an overlay network:
```
sudo docker network create -d overlay --attachable workbench
```

Create traefik service:
```
sudo docker service create \
    --name traefik \
    --constraint=node.role==manager \
    --publish 80:80 \
    --publish 8080:8080 \
    --mount type=bind,source=/var/run/docker.sock,target=/var/run/docker.sock \
    --network workbench \
    traefik:v1.1.0 \
    --docker \
    --docker.swarmmode \
    --docker.domain=traefik \
    --docker.watch \
    --web
```


If it is the first time that you are going to execute the `docker-compose-spark.yml` (images are not cached in the file system and will be dowloaded from the Docker-Hub), you may be interested to the download progress, so first execute this pull command:
```
sudo docker-compose -f docker-compose-spark.yml pull
```
To deploy hadoop run:
```
sudo docker stack deploy -c docker-compose-spark.yml spark

As earlier for Hadoop:
```
sudo docker-compose -f docker-compose-hadoop.yml pull
```
To deploy Hadoop run:
```
sudo docker stack deploy -c docker-compose-hadoop.yml hadoop
```
