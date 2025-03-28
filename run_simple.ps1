# MPI ve OpenMP Dağıtık Sistem Kurulum ve Çalıştırma Betiği
# Bu betik, Docker konteynerlerini başlatır, SSH yapılandırmasını yapar
# ve MPI programını çalıştırır.

# Docker konteynerlerini temizle ve yeniden oluştur
Write-Host "Docker konteynerleri temizleniyor..."
docker-compose down
docker-compose build --no-cache
docker-compose up -d

# Konteynerlerin başlamasını bekle
Write-Host "Konteynerler başlatılıyor, lütfen bekleyin..."
Start-Sleep -Seconds 15

# Her düğüm için IP adreslerini ayarla
Write-Host "IP adresleri yapılandırılıyor..."
$nodes = @("master", "worker1", "worker2", "worker3")
foreach ($node in $nodes) {
    docker exec "mpi_$node" bash -c "echo '172.28.1.1 master' >> /etc/hosts"
    docker exec "mpi_$node" bash -c "echo '172.28.1.2 worker1' >> /etc/hosts"
    docker exec "mpi_$node" bash -c "echo '172.28.1.3 worker2' >> /etc/hosts"
    docker exec "mpi_$node" bash -c "echo '172.28.1.4 worker3' >> /etc/hosts"
}

# SSH yapılandırması
Write-Host "SSH yapılandırması yapılıyor..."
foreach ($node in $nodes) {
    docker exec "mpi_$node" bash -c "mkdir -p /root/.ssh && chmod 700 /root/.ssh"
    docker exec "mpi_$node" bash -c "echo 'StrictHostKeyChecking no' > /root/.ssh/config"
    docker exec "mpi_$node" bash -c "echo 'UserKnownHostsFile /dev/null' >> /root/.ssh/config"
    docker exec "mpi_$node" bash -c "chmod 600 /root/.ssh/config"
}

# SSH anahtarlarını oluştur ve paylaş
Write-Host "SSH anahtarları oluşturuluyor..."
docker exec mpi_master bash -c "ssh-keygen -t rsa -N '' -f /root/.ssh/id_rsa"
$sshKey = docker exec mpi_master bash -c "cat /root/.ssh/id_rsa.pub"

# Tüm düğümlere SSH anahtarını ekle
Write-Host "SSH anahtarları düğümlere dağıtılıyor..."
foreach ($node in $nodes) {
    docker exec "mpi_$node" bash -c "echo '$sshKey' > /root/.ssh/authorized_keys"
    docker exec "mpi_$node" bash -c "chmod 600 /root/.ssh/authorized_keys"
}

# Master'ın özel anahtarını diğer düğümlere kopyala
Write-Host "Özel anahtarlar kopyalanıyor..."
$workers = @("worker1", "worker2", "worker3")
foreach ($worker in $workers) {
    $privateKey = docker exec mpi_master bash -c "cat /root/.ssh/id_rsa"
    docker exec "mpi_$worker" bash -c "echo '$privateKey' > /root/.ssh/id_rsa"
    docker exec "mpi_$worker" bash -c "chmod 600 /root/.ssh/id_rsa"
}

# SSH bağlantılarını test et
Write-Host "SSH bağlantıları test ediliyor..."
foreach ($worker in $workers) {
    docker exec mpi_master bash -c "ssh -o StrictHostKeyChecking=no $worker 'echo SSH bağlantısı başarılı'"
}

# Programı derle ve kopyala
Write-Host "Program derleniyor ve kopyalanıyor..."
docker cp data_processing.c mpi_master:/app/
docker exec mpi_master bash -c "cd /app && mpicc -fopenmp -o data_processor data_processing.c -lm"
docker cp mpi_master:/app/data_processor .

# Programı worker'lara kopyala ve izinleri ayarla
Write-Host "Program worker'lara kopyalanıyor..."
foreach ($worker in $workers) {
    docker cp data_processor "mpi_$worker`:/app/"
    docker exec "mpi_$worker" bash -c "chmod +x /app/data_processor"
}
docker exec mpi_master bash -c "chmod +x /app/data_processor"

# MPI programını çalıştır
Write-Host "MPI programı çalıştırılıyor..."
docker exec -e OMPI_ALLOW_RUN_AS_ROOT=1 -e OMPI_ALLOW_RUN_AS_ROOT_CONFIRM=1 mpi_master bash -c "mpirun --allow-run-as-root -mca btl_tcp_if_include eth0 -n 4 --host master,worker1,worker2,worker3 /app/data_processor"

Write-Host "İşlem tamamlandı!" 