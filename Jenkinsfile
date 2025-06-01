// Jenkinsfile
pipeline {
    agent any // Jenkins local, đã map Terraform & Ansible CLI từ máy Mac host

    environment {
        // === AWS Credentials - Jenkins sẽ dùng credentials từ ~/.aws trên máy Mac ===
        // Đảm bảo AWS CLI đã được 'aws configure' trên máy Mac host và Docker Desktop File Sharing
        // đã cho phép Jenkins container truy cập ~/.aws
        AWS_DEFAULT_REGION                   = 'us-east-1' // Hoặc var.aws_region từ TF chính
        AWS_REGION                           = 'us-east-1' // Dùng cho cohẻence, một số tool dùng biến này

        // === Các thông tin cố định hoặc lấy từ nguồn khác ===
        PROJECT_NAME_TAG                     = 'CustomerEmailVM' // Tag cho VM khách hàng
        TERRAFORM_CUSTOMER_TEMPLATE_DIR_NAME = 'terraform_customer_mail_vm'
        ANSIBLE_PLAYBOOKS_DIR_NAME           = 'ansible_playbooks'

        // === THAY THẾ CÁC GIÁ TRỊ NÀY BẰNG OUTPUT TỪ TERRAFORM_AWS_INFRA SAU KHI CHẠY LẦN ĐẦU ===
        NAGIOS_SERVER_PRIVATE_IP             = "10.10.1.231"
        NFS_SERVER_PRIVATE_IP_AWS            = "10.10.101.10" 
        NFS_EXPORT_PATH_AWS                  = '/srv/nfs_share' // Đường dẫn export trên NFS Server AWS
        CUSTOMER_VM_SUBNET_ID                = "subnet-0606eeccb7dbc5b94" // Ví dụ: một trong các public_subnet_ids
        VPC_ID_FOR_CUSTOMER_SG               = "vpc-05289181f27f39c5c"
        CUSTOMER_MAIL_SERVER_INSTANCE_PROFILE_NAME = "EmailInfraProd-CustomerMail-Profile"
        // =======================================================================================

        // === Cấu hình mặc định cho máy chủ mail của khách hàng (có thể ghi đè bằng parameters nếu muốn) ===
        CUSTOMER_VM_AMI_ID                   = 'ami-053b0d53c279acc90'        // THAY THẾ: AMI Ubuntu 22.04 LTS mới nhất cho vùng AWS_REGION
        CUSTOMER_VM_INSTANCE_TYPE            = 't3.micro'
        CUSTOMER_VM_KEY_PAIR_NAME            = 'nguyenp-key-pair' // THAY THẾ: Key Pair dùng cho VM khách hàng

        // === SSH Credentials ID (đã tạo trong Jenkins UI) ===
        SSH_CREDENTIALS_ID                   = 'customer-vm-ssh-key' // ID của credential SSH trong Jenkins
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
                    // Thiết lập đường dẫn tuyệt đối trong workspace cho các thư mục template và playbook
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
                    // Tạo thư mục làm việc Terraform riêng cho khách hàng này trong workspace của job
                    def customerTerraformWorkspace = "${env.WORKSPACE}/tf_work_${params.CUSTOMER_NAME.toLowerCase().replaceAll('[^a-z0-9]+', '')}" // Tên thư mục an toàn
                    sh "rm -rf ${customerTerraformWorkspace}"
                    sh "mkdir -p ${customerTerraformWorkspace}"
                    // Copy code Terraform template vào workspace của khách hàng
                    sh "cp -R ${env.TERRAFORM_CUSTOMER_TEMPLATE_PATH_ABS}/* ${customerTerraformWorkspace}/"

                    // Tạo file biến terraform.tfvars
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
                script {
                    def customerTerraformWorkspace = "${env.WORKSPACE}/tf_work_${params.CUSTOMER_NAME.toLowerCase().replaceAll('[^a-z0-9]+', '')}"
                    dir(customerTerraformWorkspace) {
                        sh "terraform --version" // Kiểm tra version Terraform mà Jenkins đang dùng
                        sh "terraform init -input=false"
                        sh "terraform validate"
                        sh "terraform plan -out=tfplan -input=false"
                        // Cân nhắc thêm bước input thủ công ở đây cho production
                        // input message: "Xác nhận tạo máy chủ cho ${params.CUSTOMER_NAME}?", submitter: "admins"
                        sh "terraform apply -auto-approve -input=false tfplan"

                        // Lấy IP của máy chủ vừa tạo
                        def terraformOutput = sh(script: "terraform output -json", returnStdout: true).trim()
                        if (terraformOutput) {
                            try {
                                def jsonOutput = readJSON text: terraformOutput // Cần plugin "Pipeline Utility Steps"
                                env.CUSTOMER_VM_PUBLIC_IP = jsonOutput.customer_vm_public_ip.value
                                env.CUSTOMER_VM_PRIVATE_IP = jsonOutput.customer_vm_private_ip.value
                                echo "Máy chủ cho ${params.CUSTOMER_NAME} đã được tạo. IP Public: ${env.CUSTOMER_VM_PUBLIC_IP}, IP Private: ${env.CUSTOMER_VM_PRIVATE_IP}"
                            } catch (e) {
                                echo "Lỗi khi đọc Terraform output: ${e.getMessage()}"
                                currentBuild.result = 'FAILURE'
                                error("Không thể đọc output từ Terraform.")
                            }
                        } else {
                            currentBuild.result = 'FAILURE'
                            error("Terraform output rỗng. Kiểm tra lại file outputs.tf của template khách hàng.")
                        }
                    }
                }
            }
        }

        stage('4. Configure Customer VM (Ansible)') {
            // Chỉ chạy stage này nếu đã lấy được IP của VM khách hàng
            when {
                expression { env.CUSTOMER_VM_PUBLIC_IP != null && env.CUSTOMER_VM_PUBLIC_IP != "" }
            }
            steps {
                // Sử dụng Credentials Binding để lấy SSH key an toàn
                withCredentials([sshUserPrivateKey(credentialsId: env.SSH_CREDENTIALS_ID, keyFileVariable: 'ANSIBLE_SSH_KEY_FILE_PATH')]) {
                    script {
                        echo "Bắt đầu cấu hình Ansible cho ${params.CUSTOMER_NAME} (IP: ${env.CUSTOMER_VM_PUBLIC_IP})"
                        echo "Sử dụng key file từ Jenkins credentials được lưu tại: ${ANSIBLE_SSH_KEY_FILE_PATH}"
                        
                        // Đợi một chút để SSH trên máy chủ mới sẵn sàng hoàn toàn
                        sleep(60) // 60 giây

                        // Tạo file inventory tạm thời cho Ansible
                        def inventoryContent = """
                        [mail_server_customer]
                        ${env.CUSTOMER_VM_PUBLIC_IP} ansible_user=ubuntu ansible_ssh_private_key_file=${ANSIBLE_SSH_KEY_FILE_PATH} ansible_ssh_common_args='-o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null -o ServerAliveInterval=60'
                        """
                        def ansibleInventoryFile = "${env.WORKSPACE}/inventory_${params.CUSTOMER_NAME.toLowerCase().replaceAll('[^a-z0-9]+', '')}.ini"
                        writeFile file: ansibleInventoryFile, text: inventoryContent
                        echo "Đã tạo file inventory tạm thời cho Ansible: ${ansibleInventoryFile}"

                        // Chạy Ansible playbook
                        dir(env.ANSIBLE_PLAYBOOKS_PATH_ABS) { // Di chuyển vào thư mục chứa playbooks
                           sh """
                           ansible --version # Kiểm tra version Ansible mà Jenkins đang dùng
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
                    }
                } // Đóng withCredentials
            } // Đóng steps của stage 4
        } // Đóng stage 4

        // stage('5. Cập nhật Nagios Server') {
        //     // ... (Tương tự, gọi playbook Ansible để cập nhật Nagios)
        // }

        // stage('6. Thông báo Kết quả cho n8n') {
        //     // ... (Gọi webhook của n8n)
        // }
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
            // (Tùy chọn) Chạy Terraform destroy nếu có lỗi và VM đã được tạo một phần
            script {
                if (env.CUSTOMER_VM_PUBLIC_IP != null && env.CUSTOMER_VM_PUBLIC_IP != "") { // Chỉ destroy nếu VM đã có IP
                    echo "Có lỗi xảy ra. Đang thử destroy VM đã tạo cho ${params.CUSTOMER_NAME}..."
                    def customerTerraformWorkspace = "${env.WORKSPACE}/tf_work_${params.CUSTOMER_NAME.toLowerCase().replaceAll('[^a-z0-9]+', '')}"
                    // Kiểm tra xem tfstate có tồn tại không trước khi destroy
                    if (fileExists("${customerTerraformWorkspace}/terraform.tfstate")) {
                       dir(customerTerraformWorkspace) {
                           sh "terraform destroy -auto-approve -input=false"
                       }
                       echo "Đã destroy VM cho ${params.CUSTOMER_NAME} do lỗi trong pipeline."
                    } else {
                        echo "Không tìm thấy file terraform.tfstate cho ${params.CUSTOMER_NAME}, không thể destroy tự động."
                    }
                }
            }
        }
    } // Đóng post
} // Đóng pipeline