FROM jenkins/jenkins:lts-jdk17

USER root
ENV DEBIAN_FRONTEND=noninteractive

# --- Phần 1: Chẩn đoán Mạng và DNS ---
RUN echo "--- [PHẦN 1 - ROOT] Bắt đầu Chẩn đoán Mạng và DNS ---" && \
    echo ">>> Nội dung file /etc/resolv.conf (DNS servers container đang dùng):" && \
    cat /etc/resolv.conf && \
    echo ">>> Ping đến deb.debian.org (Debian Repo Host):" && \
    (ping -c 3 deb.debian.org || echo "CẢNH BÁO: Ping đến deb.debian.org THẤT BẠI") && \
    echo ">>> Ping đến pypi.org (Python Package Index Host):" && \
    (ping -c 3 pypi.org || echo "CẢNH BÁO: Ping đến pypi.org THẤT BẠI") && \
    echo "--- [PHẦN 1 - ROOT] Kết thúc Chẩn đoán Mạng và DNS ---"

# --- Phần 2: Cập nhật Hệ thống Gói và Cài đặt Dependencies ---
RUN echo "--- [PHẦN 2 - ROOT] Đang cập nhật danh sách gói (apt-get update) ---" && \
    apt-get update -y \
      -o Debug::Acquire::http=true \
      -o Debug::Acquire::https=true \
      -o Debug::APT::Update::SourceList=true \
    || ( \
      echo "!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!" && \
      echo "!!! [ROOT] LỖI NGHIÊM TRỌNG: apt-get update THẤT BẠI !!!" && \
      # ... (phần hiển thị sources.list giữ nguyên) ...
      exit 100 \
    )
RUN echo "--- [PHẦN 2 - ROOT] apt-get update hoàn thành ---"

RUN echo "--- [PHẦN 2 - ROOT] Đang cài đặt các gói thiết yếu và Python build dependencies ---" && \
    apt-get install -y --no-install-recommends \
    sudo \
    apt-transport-https \
    ca-certificates \
    curl \
    gnupg \
    lsb-release \
    software-properties-common \
    wget \
    unzip \
    python3 \
    python3-pip \
    python3-setuptools \
    python3-wheel \
    build-essential \
    libssl-dev \
    libffi-dev \
    python3-dev && \
    rm -rf /var/lib/apt/lists/*
RUN echo "--- [PHẦN 2 - ROOT] Cài đặt các gói thiết yếu hoàn thành ---"

# --- Phần 3: Cài đặt Terraform ---
ARG TERRAFORM_VERSION="1.8.3"
RUN echo "--- [PHẦN 3 - ROOT] Đang cài đặt Terraform v${TERRAFORM_VERSION} ---" && \
    wget https://releases.hashicorp.com/terraform/${TERRAFORM_VERSION}/terraform_${TERRAFORM_VERSION}_linux_amd64.zip && \
    unzip terraform_${TERRAFORM_VERSION}_linux_amd64.zip -d /usr/local/bin/ && \
    rm terraform_${TERRAFORM_VERSION}_linux_amd64.zip
RUN echo "--- [PHẦN 3 - ROOT] Cài đặt Terraform hoàn thành ---"

# --- Phần 4: Nâng cấp pip và Cài đặt Ansible ---
RUN echo "--- [PHẦN 4 - ROOT] Kiểm tra phiên bản Python3 và pip3 hiện tại ---" && \
    python3 --version && \
    pip3 --version

RUN echo "--- [PHẦN 4 - ROOT] Đang thử nâng cấp pip (thêm --break-system-packages) ---" && \
    pip3 install -vvv --no-cache-dir --upgrade pip --default-timeout=100 --break-system-packages
RUN echo "--- [PHẦN 4 - ROOT] Nâng cấp pip hoàn thành ---"

RUN echo "--- [PHẦN 4 - ROOT] Đang thử cài đặt Ansible (thêm --break-system-packages) ---" && \
    pip3 install -vvv --no-cache-dir ansible --default-timeout=100 --break-system-packages
RUN echo "--- [PHẦN 4 - ROOT] Cài đặt Ansible hoàn thành ---"

# --- Phần 5: Cài đặt AWS CLI v2 ---
RUN echo "--- [PHẦN 5 - ROOT] Đang cài đặt AWS CLI v2 ---" && \
    curl "https://awscli.amazonaws.com/awscli-exe-linux-x86_64.zip" -o "awscliv2.zip" && \
    unzip awscliv2.zip && \
    ./aws/install && \
    rm -rf awscliv2.zip ./aws
RUN echo "--- [PHẦN 5 - ROOT] Cài đặt AWS CLI v2 hoàn thành ---"

# --- Phần 6: Cấu hình sudo cho user jenkins ---
RUN echo "--- [PHẦN 6 - ROOT] Đang cấu hình sudo cho user jenkins ---" && \
    echo "jenkins ALL=(ALL) NOPASSWD:ALL" > /etc/sudoers.d/jenkins && \
    chmod 0440 /etc/sudoers.d/jenkins
RUN echo "--- [PHẦN 6 - ROOT] Cấu hình sudo cho user jenkins hoàn thành ---"

USER jenkins
RUN echo "--- [JENKINS USER] Quá trình build Dockerfile hoàn tất ---"