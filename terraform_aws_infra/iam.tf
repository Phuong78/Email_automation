# --- IAM Role cho Nagios Server ---
resource "aws_iam_role" "nagios_server_role" {
  name = "${var.project_name}-Nagios-Role"
  assume_role_policy = jsonencode({
    Version   = "2012-10-17",
    Statement = [{
      Action    = "sts:AssumeRole",
      Effect    = "Allow",
      Principal = { Service = "ec2.amazonaws.com" }
    }]
  })
  tags = { Name = "${var.project_name}-Nagios-Role" }
}

resource "aws_iam_role_policy_attachment" "nagios_ssm" {
  role       = aws_iam_role.nagios_server_role.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore"
}

resource "aws_iam_instance_profile" "nagios_profile" {
  name = "${var.project_name}-Nagios-Profile"
  role = aws_iam_role.nagios_server_role.name
}

# --- IAM Role cho NFS Server ---
resource "aws_iam_role" "nfs_server_role" {
  name = "${var.project_name}-NFS-Role"
  assume_role_policy = jsonencode({
    Version   = "2012-10-17",
    Statement = [{
      Action    = "sts:AssumeRole",
      Effect    = "Allow",
      Principal = { Service = "ec2.amazonaws.com" }
    }]
  })
  tags = { Name = "${var.project_name}-NFS-Role" }
}

resource "aws_iam_role_policy_attachment" "nfs_ssm" {
  role       = aws_iam_role.nfs_server_role.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore"
}

resource "aws_iam_instance_profile" "nfs_profile" {
  name = "${var.project_name}-NFS-Profile"
  role = aws_iam_role.nfs_server_role.name
}

# --- IAM Role cho EC2 Máy chủ Mail của Khách hàng ---
resource "aws_iam_role" "customer_mail_server_role" {
  name = "${var.project_name}-CustomerMail-Role"
  assume_role_policy = jsonencode({
    Version   = "2012-10-17",
    Statement = [{
      Action    = "sts:AssumeRole",
      Effect    = "Allow",
      Principal = { Service = "ec2.amazonaws.com" }
    }]
  })
  tags = { Name = "${var.project_name}-CustomerMail-Role" }
}

resource "aws_iam_role_policy_attachment" "customer_ssm" {
  role       = aws_iam_role.customer_mail_server_role.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore"
}

resource "aws_iam_role_policy_attachment" "customer_cloudwatch" {
  role       = aws_iam_role.customer_mail_server_role.name
  policy_arn = "arn:aws:iam::aws:policy/CloudWatchLogsFullAccess" # Cân nhắc giới hạn policy này
}

resource "aws_iam_instance_profile" "customer_mail_profile" {
  name = "${var.project_name}-CustomerMail-Profile"
  role = aws_iam_role.customer_mail_server_role.name
}