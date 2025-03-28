# OpenMP ve MPI ile Dağıtık Veri İşleme Sistemi

Bu proje, OpenMP ve MPI kullanarak dağıtık bir sistemde veri işleme uygulamasını gerçekleştirir. Docker konteynerları kullanılarak master ve worker düğümleri oluşturulur.

## 🚀 Özellikler

- Docker konteynerları ile izole edilmiş çalışma ortamı
- MPI ile düğümler arası iletişim
- OpenMP ile çoklu iş parçacığı desteği
- SSH ile güvenli düğümler arası iletişim
- Otomatik yapılandırma ve kurulum

## 🛠️ Gereksinimler

- Docker Desktop
- Windows 10 veya üzeri
- PowerShell

## 📝 Sunum Adımları

1. Docker Desktop'ın çalıştığından emin olun.

2. PowerShell'i açın ve projenin bulunduğu dizine gidin:
   ```powershell
   cd C:\OpenMP-MPI
   ```

3. Konteynerleri başlatın:
   ```powershell
   docker-compose up -d
   ```

4. Programı derleyin:
   ```powershell
   docker exec mpi_master mpicc -o /mpi_workspace/data_processor /mpi_workspace/data_processing.c -fopenmp
   ```

5. SSH anahtarlarını oluşturun:
   ```powershell
   docker exec mpi_master bash -c "ssh-keygen -t rsa -f /root/.ssh/id_rsa -N '' && cat /root/.ssh/id_rsa.pub > /root/.ssh/authorized_keys"
   ```

6. SSH anahtarlarını worker düğümlerine kopyalayın:
   ```powershell
   docker exec mpi_worker1 mkdir -p /root/.ssh
   docker exec mpi_worker2 mkdir -p /root/.ssh
   docker exec mpi_worker3 mkdir -p /root/.ssh

   docker cp mpi_master:/root/.ssh/id_rsa.pub ./id_rsa.pub
   docker cp ./id_rsa.pub mpi_worker1:/root/.ssh/authorized_keys
   docker cp ./id_rsa.pub mpi_worker2:/root/.ssh/authorized_keys
   docker cp ./id_rsa.pub mpi_worker3:/root/.ssh/authorized_keys
   ```

7. Derlenmiş programı worker düğümlerine kopyalayın:
   ```powershell
   docker cp mpi_master:/mpi_workspace/data_processor ./data_processor
   docker cp ./data_processor mpi_worker1:/mpi_workspace/data_processor
   docker cp ./data_processor mpi_worker2:/mpi_workspace/data_processor
   docker cp ./data_processor mpi_worker3:/mpi_workspace/data_processor
   ```

8. SSH bağlantılarını test edin:
   ```powershell
   docker exec mpi_master bash -c "ssh -o StrictHostKeyChecking=no worker1 'hostname' && ssh -o StrictHostKeyChecking=no worker2 'hostname' && ssh -o StrictHostKeyChecking=no worker3 'hostname'"
   ```

9. MPI programını çalıştırın:
   ```powershell
   docker exec mpi_master mpirun --allow-run-as-root -np 4 -H master,worker1,worker2,worker3 /mpi_workspace/data_processor
   ```

10. Sunum bittikten sonra konteynerleri kapatmak için:
    ```powershell
    docker-compose down
    ```

## 🔧 Sistem Yapısı

- 1 master düğüm ve 3 worker düğüm
- Her düğümde 4 OpenMP thread'i
- Toplam 16 paralel işlem kapasitesi
- Ubuntu 20.04 tabanlı konteynerler
- OpenMPI ve OpenMP ile paralel işlem desteği

## 🤝 Katkıda Bulunma

1. Bu depoyu fork edin
2. Yeni bir branch oluşturun (`git checkout -b feature/yeniOzellik`)
3. Değişikliklerinizi commit edin (`git commit -am 'Yeni özellik eklendi'`)
4. Branch'inizi push edin (`git push origin feature/yeniOzellik`)
5. Pull Request oluşturun

## 📋 Sistem Gereksinimleri

- **Docker Desktop** (en son versiyon)
- **Docker Compose** (en son versiyon)
- **Windows PowerShell** (Windows için)
- Minimum 8GB RAM
- Minimum 4 çekirdekli CPU
- En az 10GB boş disk alanı

## 🛠️ Kurulum

1. **Projeyi Klonlama**
   ```bash
   git clone [REPO_URL]
   cd [REPO_NAME]
   ```

2. **Docker Konteynerlerini Başlatma**
   ```bash
   # Windows PowerShell'de
   .\run_simple.ps1
   ```

## 📁 Proje Yapısı

```
.
├── data_processing.c     # Ana program kaynak kodu
├── Dockerfile           # Konteyner yapılandırması
├── docker-compose.yml   # Düğüm yapılandırması
├── run_simple.ps1      # Windows çalıştırma betiği
├── README.md           # Dokümantasyon
└── data/               # Veri dosyaları dizini
```

### 🔍 Bileşen Detayları

#### data_processing.c
- MPI ve OpenMP hibrit paralel işleme kodu
- Veri dağıtımı ve toplama işlemleri
- OpenMP iş parçacığı yönetimi
- Hata kontrolü ve raporlama

#### Dockerfile
- Ubuntu tabanlı konteyner
- MPI ve OpenMP geliştirme araçları
- SSH sunucu yapılandırması
- Güvenlik ayarları

#### docker-compose.yml
- Bir master ve üç worker düğüm
- Özel ağ yapılandırması
- Kaynak limitleri
- Servis bağımlılıkları

## 💻 Kullanım

1. **Sistemi Başlatma**
   ```powershell
   .\run_simple.ps1
   ```

2. **Çalışma Durumunu Kontrol**
   - Tüm düğümlerin çalıştığından emin olun
   - SSH bağlantılarını kontrol edin
   - MPI programının çalışmasını izleyin

3. **Sonuçları Görüntüleme**
   - İşlem süresini kontrol edin
   - Her düğümün performansını izleyin
   - Toplam sonucu değerlendirin

## 📊 Performans Analizi

### Sistem Konfigürasyonu
- **Düğüm Sayısı**: 4 (1 master + 3 worker)
- **İş Parçacığı Sayısı**: Her düğümde 4 OpenMP thread
- **Toplam İş Parçacığı**: 16 (4 düğüm × 4 thread)

### Test Sonuçları

| Veri Boyutu | Düğüm Sayısı | Thread Sayısı | İşlem Süresi (s) | Hızlanma |
|-------------|--------------|---------------|------------------|-----------|
| 1M          | 1           | 4             | 0.185           | 1x        |
| 1M          | 2           | 8             | 0.095           | 1.95x     |
| 1M          | 4           | 16            | 0.047           | 3.93x     |

## 🔧 Sorun Giderme

1. **Docker Hataları**
   - Docker servisinin çalıştığından emin olun
   - Konteyner loglarını kontrol edin
   - Ağ bağlantılarını test edin

2. **MPI Hataları**
   - SSH bağlantılarını kontrol edin
   - Host dosyası yapılandırmasını doğrulayın
   - MPI programının derlendiğinden emin olun

3. **Performans Sorunları**
   - Sistem kaynaklarını monitör edin
   - Network gecikmelerini kontrol edin
   - İş yükü dağılımını optimize edin

## 📈 Geliştirme Planı

- [ ] GPU desteği ekleme
- [ ] Dinamik yük dengeleme
- [ ] Web arayüzü
- [ ] Gerçek zamanlı monitörleme
- [ ] Otomatik ölçeklendirme

## 📚 Referanslar

- [MPI Forum](https://www.mpi-forum.org/)
- [OpenMP Specifications](https://www.openmp.org/)
- [Docker Documentation](https://docs.docker.com/)

## 📝 Lisans

Bu proje MIT lisansı altında lisanslanmıştır. Detaylar için [LICENSE](LICENSE) dosyasına bakınız.

## 👥 Katkıda Bulunma

1. Fork yapın
2. Feature branch oluşturun
3. Değişikliklerinizi commit edin
4. Branch'inizi push edin
5. Pull Request oluşturun 