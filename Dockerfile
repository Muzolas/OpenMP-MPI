# MPI ve OpenMP için Ubuntu tabanlı Docker imajı
# Bu imaj, dağıtık veri işleme için gerekli tüm araçları içerir

# Ubuntu'nun en son sürümünü temel al
FROM ubuntu:20.04

# Etkileşimli olmayan kurulum için
ENV DEBIAN_FRONTEND=noninteractive

# Proxy ayarlarını devre dışı bırak
RUN echo 'Acquire::http::Proxy "false";' > /etc/apt/apt.conf.d/99proxy

# Paketleri yükle
RUN apt-get update && \
    apt-get install -y \
    build-essential \
    openssh-server \
    openssh-client \
    openmpi-bin \
    openmpi-common \
    libopenmpi-dev \
    && rm -rf /var/lib/apt/lists/*

# SSH yapılandırması
RUN mkdir /var/run/sshd
RUN echo 'root:root' | chpasswd
RUN sed -i 's/#PermitRootLogin prohibit-password/PermitRootLogin yes/' /etc/ssh/sshd_config

# SSH servisi için port aç
EXPOSE 22

# Çalışma dizini oluştur
RUN mkdir -p /mpi_workspace
WORKDIR /mpi_workspace

# SSH servisini başlat
CMD ["/usr/sbin/sshd", "-D"] 