docker run -d -p 4445:4444 selenium/standalone-firefox:2.53.1

docker stop $(docker ps -a -q)
docker rm $(docker ps -a -q)