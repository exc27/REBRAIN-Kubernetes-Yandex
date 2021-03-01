# KUB-35

#### Installation requirements:

Для успешной установки неодходимо чтобы в Yandex.Cloud был развернут экземпляр кластера PostgreSQL как сервис [Managed Service for PostgreSQL](https://cloud.yandex.ru/services/managed-postgresql), т.к. это коррелирует с курсом обучения Kubernetes в Яндекс Облаке и наличее внешней управляемой базы данных как сервис является лучшей практикой.

Так же, должны быть созданы kubernetes namespaces `prod` и `stage`.

Установить RabbitMQ (пока его нет у Яндекс.Облако, только клон AWS SQS, но в этом сервисе хранятся не критичные для потери данные, поэтому не страшно), можно взять от bitnami, это довольно надежный поставщик:
```
    helm repo add bitnami https://charts.bitnami.com/bitnami
    helm repo update
    helm install -n prod rabbit-mq --set auth.username=prod-user,auth.password=XNR628qr2koN2Qf bitnami/rabbitmq
    helm install -n stage rabbit-mq --set auth.username=stage-user,auth.password=hBB2KanRTzFoBYf bitnami/rabbitmq  
```
*(Доступы показаны в учебных целях чтобы соотсветвовать шифрованным вариантам в файлах для воспроизведения и проверки).*

**Только для учебных целей:**

Содержимое секретных файлов, чтобы не расшифровывать их вручную и показать что они разные для разных окружений.
*В идеале это должны быть разные кластера БД, но в учебных целях имеет смысл экономии, поэтому это один физический хост с разными логическими базами.*

```                                                                                           
    sops -d secrets.prod.yaml
    private_env_variables:
        API_KEY: dgsCCz6Gmoio2ksibNHQmb4sUBo7LWZ2
        PGSQL_URI: postgresql://prod-user:8rxEzJns4gPaOeY@rc1a-sq6egbgs78aqx04t.mdb.yandexcloud.net:6432/prod-db?sslmode=verify-full&sslrootcert=/root/.postgresql/root.crt
        RABBIT_URI: amqp://prod-user:XNR628qr2koN2Qf@rabbit-mq-rabbitmq:5672

    sops -d secrets.stage.yaml
    private_env_variables:
        API_KEY: ydkCDI0SyMOQhydVtUgsthZWgeEYNQTv
        PGSQL_URI: postgresql://stage-user:dHCFRO6TfLdtFkR@rc1a-sq6egbgs78aqx04t.mdb.yandexcloud.net:6432/stage-db?sslmode=verify-full&sslrootcert=/root/.postgresql/root.crt
        RABBIT_URI: amqp://stage-user:hBB2KanRTzFoBYf@rabbit-mq-rabbitmq:5672
```

#### Прверка работоспособности:

```                                                                                                      
    kubectl -n prod get pods
    NAME                                    READY   STATUS    RESTARTS   AGE
    rebrain-kub-35-chart-78d69d8d85-hmwlt   1/1     Running   0          66s

    kubectl -n prod logsrebrain-kub-35-chart-78d69d8d85-hmwlt
    2021/01/30 15:58:31 INFO: Getting environment variables
    2021/01/30 15:58:31 INFO: Connecting to database
```
```
    kubectl -n stage get pods 
    NAME                                    READY   STATUS    RESTARTS   AGE
    rebrain-kub-35-chart-7c77b4d7cd-v9vl5   1/1     Running   0          2m14s


    kubectl -n stage logs rebrain-kub-35-chart-7c77b4d7cd-v9vl5                                     
    2021/01/30 16:28:23 INFO: Getting environment variables
    2021/01/30 16:28:23 INFO: Connecting to database
```

```
    helm list -n stage                                                                               
    NAME          	NAMESPACE	REVISION	UPDATED                                	STATUS  	CHART      	APP VERSION
    rebrain-kub-35	stage    	1       	2021-01-30 16:26:01.669941508 +0000 UTC	deployed	chart-0.1.0	1.0        

    helm list -n prod                                                   
    NAME          	NAMESPACE	REVISION	UPDATED                                	STATUS  	CHART      	APP VERSION
    rebrain-kub-35	prod     	1       	2021-01-30 15:58:16.864631832 +0000 UTC	deployed	chart-0.1.0	1.0        
```

**Проверки API:**
*(В этом премере указан мой конкретный IP для проверки в учебных целях, кокретный ip стоит узнать командой kubectl -n {prod/stage} get ingress rebrain-kub-35-chart) или использовать доменное имя если оно принадлежит вам и создана А/CNAME-запись.*

Для тестирования используется утилита https://httpie.io/

**addRequest:**

```
echo '{                                 
        "name": "TestName1",
        "description": "Test Description",
        "processed": true,
        "video_url": "http://test.com/test",
        "text_url": "Test Url"
}' |  \
  http --follow -v POST http://178.154.228.156/requests \
  Content-Type:application/json \
  Host:default.dev.kis.im \
  X-API-KEY:804b95f13b714ee9912b19861faf3d25
```

**Response:**

```
POST /requests/ HTTP/1.1
Accept: application/json, */*;q=0.5
Accept-Encoding: gzip, deflate
Connection: keep-alive
Content-Length: 212
Content-Type: application/json
Host: default.dev.kis.im
User-Agent: HTTPie/2.3.0
X-API-KEY: 804b95f13b714ee9912b19861faf3d25

{
    "description": "Test Description",
    "name": "TestName1",
    "processed": true,
    "text_url": "Test Url",
    "video_url": "http://test.com/test"
}


HTTP/1.1 301 Moved Permanently
Connection: keep-alive
Content-Length: 0
Date: Sun, 31 Jan 2021 10:47:12 GMT
Location: /requests



GET /requests HTTP/1.1
Accept: application/json, */*;q=0.5
Accept-Encoding: gzip, deflate
Connection: keep-alive
Host: default.dev.kis.im
User-Agent: HTTPie/2.3.0
X-API-KEY: 804b95f13b714ee9912b19861faf3d25



HTTP/1.1 200 OK
Connection: keep-alive
Content-Length: 75
Content-Type: application/json
Date: Sun, 31 Jan 2021 10:47:12 GMT

{
  "success": true,
  "message": "Successfully added new request",
  "data": null
}
```

**getRequests:**

```
http --follow -v GET http://178.154.228.156/requests/ \
  Host:default.dev.kis.im \
  X-API-KEY:804b95f13b714ee9912b19861faf3d25
```

**Response:**

```
GET /requests/ HTTP/1.1
Accept: */*
Accept-Encoding: gzip, deflate
Connection: keep-alive
Host: default.dev.kis.im
User-Agent: HTTPie/2.3.0
X-API-KEY: 804b95f13b714ee9912b19861faf3d25



HTTP/1.1 301 Moved Permanently
Connection: keep-alive
Content-Length: 44
Content-Type: text/html; charset=utf-8
Date: Sun, 31 Jan 2021 10:49:11 GMT
Location: /requests

<a href="/requests">Moved Permanently</a>.


GET /requests HTTP/1.1
Accept: */*
Accept-Encoding: gzip, deflate
Connection: keep-alive
Host: default.dev.kis.im
User-Agent: HTTPie/2.3.0
X-API-KEY: 804b95f13b714ee9912b19861faf3d25



HTTP/1.1 200 OK
Connection: keep-alive
Content-Length: 251
Content-Type: application/json
Date: Sun, 31 Jan 2021 10:49:11 GMT

{
    "data": [
        {
            "archived": false,
            "created_at": "2021-01-31T13:48:26.823975Z",
            "description": "Test Description",
            "name": "TestName1",
            "processed": false,
            "text_url": "",
            "updated_at": null,
            "video_url": ""
        }
    ],
    "message": "Successfully got all the requests",
    "success": true
}
```

**getRequest:**

```
http --follow -v GET http://178.154.228.156/requests/TestName1 \
  Host:default.dev.kis.im \
  X-API-KEY:804b95f13b714ee9912b19861faf3d25
```

**Response:**

```
GET /requests/TestName1 HTTP/1.1
Accept: */*
Accept-Encoding: gzip, deflate
Connection: keep-alive
Host: default.dev.kis.im
User-Agent: HTTPie/2.3.0
X-API-KEY: 804b95f13b714ee9912b19861faf3d25



HTTP/1.1 200 OK
Connection: keep-alive
Content-Length: 276
Content-Type: application/json
Date: Sun, 31 Jan 2021 10:50:44 GMT

{
    "data": {
        "archived": false,
        "created_at": "2021-01-31T13:48:26.823975Z",
        "description": "Test Description",
        "name": "TestName1",
        "processed": true,
        "text_url": "Test Url",
        "updated_at": null,
        "video_url": "http://test.com/test"
    },
    "message": "Successfully got the request info",
    "success": true
}
```

**updRequest:**

```
echo '{
        "name": "TestName1",
        "description": "Test Description 2",
        "processed": true,
        "video_url": "http://test.com/test",
        "text_url": "Test Url"
}' |  \
  http --follow -v PUT http://178.154.228.156/requests/TestName1 \  
  Content-Type:application/json \
  Host:default.dev.kis.im \
  X-API-KEY:804b95f13b714ee9912b19861faf3d25
```

**Response:**

```
PUT /requests/TestName1 HTTP/1.1
Accept: application/json, */*;q=0.5
Accept-Encoding: gzip, deflate
Connection: keep-alive
Content-Length: 146
Content-Type: application/json
Host: default.dev.kis.im
User-Agent: HTTPie/2.3.0
X-API-KEY: 804b95f13b714ee9912b19861faf3d25

{
    "description": "Test Description 2",
    "name": "TestName1",
    "processed": true,
    "text_url": "Test Url",
    "video_url": "http://test.com/test"
}


HTTP/1.1 200 OK
Connection: keep-alive
Content-Length: 70
Content-Type: application/json
Date: Sun, 31 Jan 2021 10:53:27 GMT

{
    "data": null,
    "message": "Successfully updated request",
    "success": true
}
```

**delRequest:**

```
http --follow -v DELETE http://178.154.228.156/requests/TestName1 \
  Host:default.dev.kis.im \
  X-API-KEY:804b95f13b714ee9912b19861faf3d25
```

**Response:**

```
DELETE /requests/TestName1 HTTP/1.1
Accept: */*
Accept-Encoding: gzip, deflate
Connection: keep-alive
Content-Length: 0
Host: default.dev.kis.im
User-Agent: HTTPie/2.3.0
X-API-KEY: 804b95f13b714ee9912b19861faf3d25



HTTP/1.1 200 OK
Connection: keep-alive
Content-Length: 70
Content-Type: application/json
Date: Sun, 31 Jan 2021 10:55:34 GMT

{
    "data": null,
    "message": "Successfully deleted request",
    "success": true
}
```

