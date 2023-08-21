# votingApp-helmChart
docker sample voting app Helm Charts for on-premises Kubernetes
# example-voting-app-kubernetes-v2

This is based on the original [example-voting-app](https://github.com/dockersamples/example-voting-app) from docker-examples(https://github.com/dockersamples)

modified to work on Kubernetes

1) install rke2 master and create some alias in .bashrc
alias kget='kubectl get'
alias kdes='kubectl describe'
alias kapp='kubectl apply -f'
alias kdel='kubectl delete -f'

2) run nexus on docker 
	docker run -d --name nexus -p 8081-8082:8081-8082 -v nexus_data:/nexus-data sonatype/nexus3
	docker volume inspect nexus_data | grep -i mountpoint
	cat /var/lib/docker/volumes/nexus_data/_data/admin.password
	
3) create repository for docker (hosted) on 8082 with annonymous access for download
	1) go to the login page 	http://192.168.56.106:8081/
	2) change the admin password
	3) enable the annonymouse access
	4) create two file blob stroes for helm and docker repositories
	5) create docker hosted repository with http port 8082 in docker blob- allow annonymous download
	6) create helm repository in helm blob 
	7) configure realm - Activate docker bearer token realm and move it to top of list
4) tag the images and push it to nexus

[root@nexus ~]# docker tag dockersamples/examplevotingapp_result nexus.repo:8082/dockersamples/examplevotingapp_result:latest
[root@nexus ~]# docker tag dockersamples/examplevotingapp_vote nexus.repo:8082/dockersamples/examplevotingapp_vote:latest
[root@nexus ~]# docker tag dockersamples/examplevotingapp_worker nexus.repo:8082/dockersamples/examplevotingapp_worker:latest
[root@nexus ~]# docker tag redis:alpine nexus.repo:8082/redis:alpine
[root@nexus ~]# docker tag postgres:15-alpine nexus.repo:8082/postgres:15-alpine

5) configure docker to login to unsecure repository

[root@nexus ~]# cat /etc/docker/daemon.json
{
  "insecure-registries" : ["nexus.repo:8082"]
}

[root@nexus ~]# systemctl restart docker
[root@nexus ~]# docker start nexus
[root@nexus ~]# docker login nexus.repo:8082

6) push the images into the registry
7) define default registry for rke2 on all nodes
[root@docker1 ~]# cat /etc/rancher/rke2/registries.yaml
mirrors:
  docker.io:
    endpoint:
      - "http://nexus.repo:8082"
  nexus.repo:8082:
    endpoint:
      - "http://nexus.repo:8082"

[root@docker1 ~]# systemctl restart rke2-server|rke2-agent

8) create a new context and change the defualt namespace
	kubectl config set-context context-voteApp --cluster default --user default --namespace vote-ns
  	kubectl create ns vote-ns
	kubectl config use-context context-voteApp
9) from nexus web console create a helm hosted repository and obtian its link
10) add the helm repository to your helm client 
	[root@docker1 helmChart]# helm repo add myhelm http://192.168.56.106:8081/repository/helm/

11) push the helm charts to the myhelm repo using curl eg:
	 curl -u admin:admin@123 http://192.168.56.106:8081/repository/helm/ --upload-file voting-app-0.1.0.tgz  -v
12) update the repo
helm repo update

13) search the repo to confirm:
[root@docker1 ~]# helm search repo myhelm
NAME                    CHART VERSION   APP VERSION     DESCRIPTION
myhelm/postgres         0.1.0           1.16.0          A Helm chart for Kubernetes
myhelm/redis            0.1.0           1.16.0          A Helm chart for Kubernetes
myhelm/result-app       0.1.0           1.16.0          A Helm chart for Kubernetes
myhelm/voting-app       0.1.1           1.16.0          A Helm chart for Kubernetes
myhelm/worker-app       0.1.0           1.16.0          A Helm chart for Kubernetes

12) install the charts:
[root@docker1 ~]# helm install voting-app myhelm/voting-app
[root@docker1 ~]# helm install redis myhelm/redis
[root@docker1 ~]# helm install worker-app myhelm/worker-app
[root@docker1 ~]# helm install postgres myhelm/postgres
[root@docker1 ~]# helm install result-app myhelm/result-app

13) confirm the helm chart installation
[root@docker1 ~]# helm ls
NAME            NAMESPACE       REVISION        UPDATED                                 STATUS          CHART                   APP VERSION
postgres        vote-helm-ns    1               2023-08-16 17:07:02.928459078 -0400 EDT deployed        postgres-0.1.0          1.16.0 
redis           vote-helm-ns    1               2023-08-16 17:06:00.689919293 -0400 EDT deployed        redis-0.1.0             1.16.0 
result-app      vote-helm-ns    1               2023-08-16 17:07:33.736205424 -0400 EDT deployed        result-app-0.1.0        1.16.0 
voting-app      vote-helm-ns    1               2023-08-16 16:55:58.428811455 -0400 EDT deployed        voting-app-0.1.0        1.16.0 
worker-app      vote-helm-ns    1               2023-08-16 17:06:29.502333417 -0400 EDT deployed        worker-app-0.1.0        1.16.0 

14) confirm the kubernets status:
[root@docker1 helmChart]# kget all
NAME                 READY   STATUS    RESTARTS   AGE
pod/postgres-pod     1/1     Running   0          9m8s
pod/redis-pod        1/1     Running   0          10m
pod/result-app-pod   1/1     Running   0          8m37s
pod/voting-app-pod   1/1     Running   0          20m
pod/worker-app-pod   1/1     Running   0          2s

NAME                         TYPE        CLUSTER-IP     EXTERNAL-IP   PORT(S)        AGE
service/db                   ClusterIP   10.43.138.54   <none>        5432/TCP       9m9s
service/redis-service        ClusterIP   10.43.169.40   <none>        6379/TCP       10m
service/result-app-service   NodePort    10.43.228.51   <none>        80:30020/TCP   8m38s
service/voting-app-service   NodePort    10.43.181.65   <none>        80:30010/TCP   20m

15) confirm the app via browser
http://node-ip:30007
http://node-ip:30008


