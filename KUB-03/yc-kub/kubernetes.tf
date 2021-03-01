# Создаем кластер кубернетес
  resource "yandex_kubernetes_cluster" "kuber-cluster" {
  # Указываем его имя
    name        = "kub-test"

  # Указываем, к какой сети он будет подключен
    network_id = yandex_vpc_network.internal.id

  # Указываем, что мастера располагаются в регионе ru-central и какие subnets использовать для каждой зоны
    master {
    zonal {
        zone      = var.yc_region
        #subnet_id = yandex_vpc_network.internal.id
        subnet_id = "e9bq3c7cnnvd8j98447s"
    }

  # Указываем версию Kubernetes
    version   = "1.18"
  # Назначаем внешний ip master нодам, чтобы мы могли подключаться к ним извне
    public_ip = true
    }

  # Указываем канал обновлений
    release_channel = "RAPID"
  # Включить сетевые политики
    network_policy_provider = "CALICO"

  # Указываем сервисный аккаунт, который будут использовать ноды, и кластер для управления нодами
    node_service_account_id = yandex_iam_service_account.docker-registry.id
    service_account_id      = yandex_iam_service_account.instances-editor.id
}

  # Создаем группу узлов
    resource "yandex_kubernetes_node_group" "node-group-0" {
  # Указываем, к какому кластеру они принадлежат
    cluster_id  = yandex_kubernetes_cluster.kuber-cluster.id
  # Указываем название группы узлов
    name        = "test-group-auto"
  # И версию
    version     = "1.18"

  # Настраиваем шаблон виртуальной машины
    instance_template {
    platform_id = "standard-v2"
    nat         = true

    resources {
    core_fraction = 20 # Данный параметр позволяет уменьшить производительность CPU и сильно уменьшить затраты на инфраструктуру
    memory        = 2
    cores         = 2
    }

    boot_disk {
    type = "network-hdd"
    size = 64
    }

    scheduling_policy {
    preemptible = false
    }
    }

  # Настраиваем политику масштабирования — в данном случае у нас группа фиксирована и в ней находятся 2 узла
    scale_policy {
    auto_scale {
    min = 2
    max = 3
    initial = 2
    }
    }

  # В каких зонах можно создавать машинки — указываем все зоны
    allocation_policy {
    location {
    zone = "ru-central1-a"
    }
    }

  # Отключаем автоматический апгрейд
    maintenance_policy {
    auto_upgrade = false
    auto_repair  = true
    }
}