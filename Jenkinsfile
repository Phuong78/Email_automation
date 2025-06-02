// Jenkinsfile
pipeline {
    agent any // Jenkins local, image tùy chỉnh đã có Terraform, Ansible, AWS CLI

    environment {
        // === ID CỦA AWS CREDENTIALS ĐÃ TẠO TRONG JENKINS ===
        AWS_CREDENTIALS_ID                   = 'my-aws-account-creds' // QUAN TRỌNG: Phải khớp với ID credential trong Jenkins

        // === Các thông tin chung ===
        AWS_DEFAULT_REGION                   = 'us-east-1' // Vùng AWS chính của bạn
        AWS_REGION                           = 'us-east-1' // Dùng cho nhất quán
        PROJECT_NAME_TAG                     = 'CustomerEmailVM' // Tag cho VM khách hàng
        TERRAFORM_CUSTOMER_TEMPLATE_DIR_NAME = 'terraform_customer_mail_vm' // Tên thư mục template trong repo Git
        ANSIBLE_PLAYBOOKS_DIR_NAME           = 'ansible_playbooks'            // Tên thư mục playbook trong repo Git

        // === CÁC GIÁ TRỊ NÀY LẤY TỪ OUTPUT CỦA VIỆC CHẠY TERRAFORM_AWS_INFRA ===
        // Hãy kiểm tra lại các giá trị này với output mới nhất của bạn
        NAGIOS_SERVER_PRIVATE_IP             = "10.10.1.236"
        NFS_SERVER_PRIVATE_IP_AWS            = "10.10.101.68"
        NFS_EXPORT_PATH_AWS                  = "/srv/nfs_share"
        CUSTOMER_VM_SUBNET_ID                = "subnet-0606eeccb7dbc5b94" // Chọn một public subnet từ output của bạn
        VPC_ID_FOR_CUSTOMER_SG               = "vpc-05289181f27f39c5c"
        CUSTOMER_MAIL_SERVER_INSTANCE_PROFILE_NAME = "EmailInfraProd-CustomerMail-Profile"
        // =======================================================================

        // === Cấu hình cho máy chủ mail của khách hàng ===
        // QUAN TRỌNG: Xác nhận lại các giá trị này!
        CUSTOMER_VM_AMI_ID                   = 'ami-084568db4383264d4' // AMI Ubuntu 22.04 LTS (amd64) mới nhất cho vùng AWS_REGION
        CUSTOMER_VM_INSTANCE_TYPE            = 't3.micro'
        CUSTOMER_VM_KEY_PAIR_NAME            = 'nguyenp-key-pair'      // Key Pair cho VM khách hàng (phải có private key trong Jenkins credentials)

        // === ID CỦA SSH CREDENTIALS ĐÃ TẠO TRONG JENKINS ===
        SSH_CREDENTIALS_ID                   = 'customer-vm-ssh-key'
    }

    parameters {
        string(name: 'CUSTOMER_NAME', defaultValue: '', description: 'Tên định danh khách hàng (vd: KhachHangA, không dấu, không cách, không ký tự đặc biệt)')
        string(name: 'CUSTOMER_DOMAIN', defaultValue: '', description: 'Tên miền của khách hàng (vd: khachhanga.com)')
        string(name: 'CUSTOMER_EMAIL_USER', defaultValue: 'admin', description: 'Tên user email đầu tiên (vd: admin)')
        password(name: 'CUSTOMER_EMAIL_PASSWORD', defaultValue: '', description: 'Mật khẩu cho user email đầu tiên')
    }

    stages {
        stage('1. Checkout SCM & Prepare Absolute Paths') {
            steps {
                checkout scm
                script {
                    env.TERRAFORM_CUSTOMER_TEMPLATE_PATH_ABS = "${env.WORKSPACE}/${env.TERRAFORM_CUSTOMER_TEMPLATE_DIR_NAME}"
                    env.ANSIBLE_PLAYBOOKS_PATH_ABS = "${env.WORKSPACE}/${env.ANSIBLE_PLAYBOOKS_DIR_NAME}"
                    echo "Terraform Customer Template Path (Absolute): ${env.TERRAFORM_CUSTOMER_TEMPLATE_PATH_ABS}"
                    echo "Ansible Playbooks Path (Absolute): ${env.ANSIBLE_PLAYBOOKS_PATH_ABS}"
                }
            }
        }

        stage('2. Prepare Customer Terraform Workspace') {
            steps {
                script {
                    def customerTerraformWorkspace = "${env.WORKSPACE}/tf_work_${params.CUSTOMER_NAME.toLowerCase().replaceAll('[^a-z0-9]+', '')}"
                    sh "rm -rf ${customerTerraformWorkspace}"
                    sh "mkdir -p ${customerTerraformWorkspace}"
                    sh "cp -R ${env.TERRAFORM_CUSTOMER_TEMPLATE_PATH_ABS}/* ${customerTerraformWorkspace}/"

                    writeFile file: "${customerTerraformWorkspace}/terraform.tfvars", text: """
                    aws_region                               = "${env.AWS_REGION}"
                    customer_name                            = "${params.CUSTOMER_NAME}"
                    customer_vm_ami_id                       = "${env.CUSTOMER_VM_AMI_ID}"
                    customer_vm_instance_type                = "${env.CUSTOMER_VM_INSTANCE_TYPE}"
                    key_pair_name                            = "${env.CUSTOMER_VM_KEY_PAIR_NAME}"
                    subnet_id                                = "${env.CUSTOMER_VM_SUBNET_ID}"
                    vpc_id                                   = "${env.VPC_ID_FOR_CUSTOMER_SG}"
                    project_name_tag                         = "${env.PROJECT_NAME_TAG}"
                    customer_mail_server_instance_profile_name = "${env.CUSTOMER_MAIL_SERVER_INSTANCE_PROFILE_NAME}"
                    nagios_server_private_ip                 = "${env.NAGIOS_SERVER_PRIVATE_IP}"
                    """
                    echo "Đã chuẩn bị workspace và file terraform.tfvars cho khách hàng ${params.CUSTOMER_NAME} tại ${customerTerraformWorkspace}"
                }
            }
        }

        stage('3. Provision Customer VM (Terraform)') {
            steps {
                // Sử dụng withAWS để cung cấp credentials cho các lệnh Terraform
                withAWS(credentials: env.AWS_CREDENTIALS_ID, region: env.AWS_REGION) {
                    script {
                        def customerTerraformWorkspace = "${env.WORKSPACE}/tf_work_${params.CUSTOMER_NAME.toLowerCase().replaceAll('[^a-z0-9]+', '')}"
                        dir(customerTerraformWorkspace) {
                            sh "echo '--- Checking Terraform version ---'"
                            sh "terraform --version"
                            sh "echo '--- Checking AWS identity ---'"
                            sh "aws sts get-caller-identity" // Kiểm tra xem Jenkins đang dùng IAM user nào
                            
                            sh "echo '--- Running terraform init ---'"
                            sh "terraform init -input=false"
                            sh "echo '--- Running terraform validate ---'"
                            sh "terraform validate"
                            sh "echo '--- Running terraform plan ---'"
                            sh "terraform plan -out=tfplan -input=false"
                            
                            // Cân nhắc thêm bước input thủ công cho production:
                            // input message: "Xác nhận tạo máy chủ cho ${params.CUSTOMER_NAME}?", submitter: "admins"
                            sh "echo '--- Running terraform apply ---'"
                            sh "terraform apply -auto-approve -input=false tfplan"

                            sh "echo '--- Getting terraform output ---'"
                            def terraformOutput = sh(script: "terraform output -json", returnStdout: true).trim()
                            if (terraformOutput) {
                                try {
                                    def jsonOutput = readJSON text: terraformOutput // Cần plugin "Pipeline Utility Steps"
                                    env.CUSTOMER_VM_PUBLIC_IP = jsonOutput.customer_vm_public_ip.value
                                    env.CUSTOMER_VM_PRIVATE_IP = jsonOutput.customer_vm_private_ip.value
                                    echo "Máy chủ ${params.CUSTOMER_NAME} - IP Public: ${env.CUSTOMER_VM_PUBLIC_IP}, IP Private: ${env.CUSTOMER_VM_PRIVATE_IP}"
                                } catch (e) {
                                    echo "Lỗi khi đọc Terraform output: ${e.getMessage()}"
                                    currentBuild.result = 'FAILURE'
                                    error("Không thể đọc output từ Terraform.")
                                }
                            } else {
                                currentBuild.result = 'FAILURE'
                                error("Terraform output rỗng. Kiểm tra lại file outputs.tf của template khách hàng.")
                            }
                        } // Đóng dir
                    } // Đóng script
                } // Đóng withAWS
            } // Đóng steps
        } // Đóng stage 3

        stage('4. Configure Customer VM (Ansible)') {
            when {
                expression { env.CUSTOMER_VM_PUBLIC_IP != null && env.CUSTOMER_VM_PUBLIC_IP != "" }
            }
            steps {
                withCredentials([sshUserPrivateKey(credentialsId: env.SSH_CREDENTIALS_ID, keyFileVariable: 'ANSIBLE_SSH_KEY_FILE_PATH')]) {
                    script {
                        echo "Bắt đầu cấu hình Ansible cho ${params.CUSTOMER_NAME} (IP: ${env.CUSTOMER_VM_PUBLIC_IP})"
                        echo "Sử dụng key file từ Jenkins credentials được lưu tại: ${ANSIBLE_SSH_KEY_FILE_PATH}"
                        
                        sleep(60) // Đợi SSH sẵn sàng

                        def inventoryContent = """
                        [mail_server_customer]
                        ${env.CUSTOMER_VM_PUBLIC_IP} ansible_user=ubuntu ansible_ssh_private_key_file=${ANSIBLE_SSH_KEY_FILE_PATH} ansible_ssh_common_args='-o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null -o ServerAliveInterval=60'
                        """
                        def ansibleInventoryFile = "${env.WORKSPACE}/inventory_${params.CUSTOMER_NAME.toLowerCase().replaceAll('[^a-z0-9]+', '')}.ini"
                        writeFile file: ansibleInventoryFile, text: inventoryContent
                        echo "Đã tạo file inventory tạm thời cho Ansible: ${ansibleInventoryFile}"

                        dir(env.ANSIBLE_PLAYBOOKS_PATH_ABS) {
                           sh """
                           echo '--- Checking Ansible version ---'
                           ansible --version
                           echo '--- Running Ansible playbook ---'
                           ansible-playbook -i "${ansibleInventoryFile}" setup_mail_server.yml \\
                               -e "customer_domain=${params.CUSTOMER_DOMAIN}" \\
                               -e "customer_email_user=${params.CUSTOMER_EMAIL_USER}" \\
                               -e "customer_email_password='${params.CUSTOMER_EMAIL_PASSWORD}'" \\
                               -e "nfs_server_private_ip_aws=${env.NFS_SERVER_PRIVATE_IP_AWS}" \\
                               -e "nfs_export_path_aws=${env.NFS_EXPORT_PATH_AWS}" \\
                               -e "nagios_server_private_ip=${env.NAGIOS_SERVER_PRIVATE_IP}" \\
                               -e "target_host_private_ip=${env.CUSTOMER_VM_PRIVATE_IP}" \\
                               -e "target_host_public_ip=${env.CUSTOMER_VM_PUBLIC_IP}" \\
                               -e "aws_region=${env.AWS_REGION}"
                           """
                        }
                        echo "Đã cấu hình máy chủ cho ${params.CUSTOMER_NAME} bằng Ansible."
                    } // Đóng script
                } // Đóng withCredentials
            } // Đóng steps
        } // Đóng stage 4

        // stage('5. Cập nhật Nagios Server') { ... }
        // stage('6. Thông báo Kết quả cho n8n') { ... }
    } // Đóng stages

    post {
        always {
            echo 'Hoàn thành pipeline onboarding khách hàng.'
            cleanWs() // Dọn dẹp workspace sau khi chạy
        }
        success {
            echo "THÀNH CÔNG: Pipeline cho ${params.CUSTOMER_NAME} đã hoàn tất. IP Public của VM: ${env.CUSTOMER_VM_PUBLIC_IP}"
        }
        failure {
            echo "THẤT BẠI: Pipeline cho ${params.CUSTOMER_NAME} đã gặp lỗi."
            script {
                if (env.CUSTOMER_VM_PUBLIC_IP != null && env.CUSTOMER_VM_PUBLIC_IP != "") {
                    echo "Có lỗi xảy ra. Đang thử destroy VM đã tạo cho ${params.CUSTOMER_NAME}..."
                    def customerTerraformWorkspace = "${env.WORKSPACE}/tf_work_${params.CUSTOMER_NAME.toLowerCase().replaceAll('[^a-z0-9]+', '')}"
                    if (fileExists("${customerTerraformWorkspace}/terraform.tfstate")) {
                       dir(customerTerraformWorkspace) {
                           // Bọc lệnh destroy bằng withAWS
                           withAWS(credentials: env.AWS_CREDENTIALS_ID, region: env.AWS_REGION) {
                               sh "terraform destroy -auto-approve -input=false"
                           }
                       }
                       echo "Đã destroy VM cho ${params.CUSTOMER_NAME} do lỗi trong pipeline."
                    } else {
                        echo "Không tìm thấy file terraform.tfstate cho ${params.CUSTOMER_NAME}, không thể destroy tự động."
                    }
                }
            }
        } // Đóng failure
    } // Đóng post
} // Đóng pipeline