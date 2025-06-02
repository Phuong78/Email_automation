#!/bin/bash
set -e # Thoát ngay nếu có lỗi
exec > >(tee /var/log/user-data.log|logger -t user-data -s 2>/dev/console) 2>&1 # Ghi log user-data

echo "--- Starting user_data script for NFS Server ---"

sudo apt-get update -y
sudo apt-get install -y nfs-kernel-server xfsprogs util-linux parted

echo "Waiting for EBS volume to attach..."
sleep 20 # Chờ EBS volume được attach và OS nhận diện

TARGET_DEVICE_NAME=""
DEVICES=$(lsblk -ndo NAME,TYPE,MOUNTPOINT | awk '$2=="disk" {print $1}' | sort)
ROOT_DEVICE_NAME=$(lsblk -ndo NAME,TYPE,MOUNTPOINT | awk '$3=="/" {gsub("p[0-9]+$", "", $1); print $1; exit}')

echo "Available disk devices: $DEVICES"
echo "Identified root device name: $ROOT_DEVICE_NAME"

for d_name in $DEVICES; do
  if [ "$d_name" != "$ROOT_DEVICE_NAME" ]; then
    TARGET_DEVICE_NAME="/dev/$d_name"
    echo "Selected candidate EBS device: $TARGET_DEVICE_NAME"
    break
  fi
done

if [ -z "$TARGET_DEVICE_NAME" ]; then
  echo "ERROR: Could not reliably determine the target EBS device. Trying /dev/xvdf as fallback."
  TARGET_DEVICE_NAME="/dev/xvdf" # Fallback, CẨN THẬN
fi

echo "Final target EBS device: $TARGET_DEVICE_NAME"

if [ ! -b "$TARGET_DEVICE_NAME" ]; then
  echo "ERROR: Target device $TARGET_DEVICE_NAME does not exist or is not a block device."
  exit 1
fi

if ! sudo blkid -s TYPE -o value "$TARGET_DEVICE_NAME"; then
  echo "Formatting $TARGET_DEVICE_NAME with XFS..."
  sudo mkfs.xfs -f "$TARGET_DEVICE_NAME"
else
  echo "Device $TARGET_DEVICE_NAME already has a filesystem."
fi

sudo mkdir -p /srv/nfs_share

EBS_UUID=$(sudo blkid -s UUID -o value "$TARGET_DEVICE_NAME")
if [ -n "$EBS_UUID" ]; then
  echo "UUID=$EBS_UUID  /srv/nfs_share  xfs  defaults,nofail,x-systemd.device-timeout=30s  0  2" | sudo tee -a /etc/fstab
  echo "Mounting all fstab entries..."
  sudo mount -a
  if ! mountpoint -q /srv/nfs_share; then
    echo "ERROR: Failed to mount /srv/nfs_share. Check /etc/fstab and device $TARGET_DEVICE_NAME."
  else
    echo "/srv/nfs_share mounted successfully."
  fi
else
  echo "ERROR: Could not get UUID for $TARGET_DEVICE_NAME. Manual mount of /srv/nfs_share is needed."
fi

sudo chown nobody:nogroup /srv/nfs_share
sudo chmod 777 /srv/nfs_share

# Bạn sẽ cần truyền giá trị VPC CIDR vào đây, ví dụ qua biến môi trường khi khởi tạo instance
# Hoặc nếu Terraform có thể render file này, bạn có thể dùng biến Terraform.
# Hiện tại, chúng ta hardcode tạm, BẠN CẦN SỬA CHO ĐÚNG VPC CIDR CỦA MÌNH.
VPC_CIDR_FOR_NFS_EXPORT="10.10.0.0/16" # << THAY THẾ BẰNG GIÁ TRỊ var.vpc_cidr_block CỦA BẠN

echo "/srv/nfs_share    ${VPC_CIDR_FOR_NFS_EXPORT}(rw,sync,no_subtree_check,no_root_squash)" | sudo tee /etc/exports

sudo exportfs -ar
sudo systemctl restart nfs-kernel-server
sudo systemctl enable nfs-kernel-server

echo "--- NFS Server setup completed ---"