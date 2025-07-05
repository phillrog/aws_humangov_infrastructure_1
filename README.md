# Automatizando sua Infraestrutura SaaS Multi-Tenant com Terraform 

Este tutorial guiará você pelos primeiros passos na configuração de uma infraestrutura multi-tenant na AWS usando Terraform, ideal para sua aplicação SaaS. Vamos focar na organização dos arquivos e na criação dos módulos essenciais.

## Pré-requisito

Antes de começar, certifique-se de ter uma **chave SSH** criada com o nome `humangov-ec2-key.pem`. Esta chave é fundamental para acessar as instâncias EC2 que o Terraform irá provisionar.

Crie um s3 e e um dynamodb com um table LockID:


    ```bash
    aws dynamodb create-table \
    --table-name humangov-terraform-state-lock-table \
    --attribute-definitions AttributeName=LockID,AttributeType=S \
    --key-schema AttributeName=LockID,KeyType=HASH \
    --provisioned-throughput ReadCapacityUnits=5,WriteCapacityUnits=5 \
    --region us-east-1
    ```

E altere o nome do s3 e do dynamodb table no no arquivo backend.tf

![image](https://github.com/user-attachments/assets/223f7fb1-7734-4267-9c7b-ab58d6b6229f)


Crie um ec2 e Instale terraform, ansible em seguida configure o acesso remoto explore.

Caso queira criar uma Amazon linux e precise saber como configurar VS Code para acessar a instância:

Leia este artigo [Conectando seu VS Code ao Poder da AWS: Desenvolvimento Python na Nuvem](https://medium.com/@phillrsouza/conectando-seu-vs-code-ao-poder-da-aws-desenvolvimento-python-na-nuvem-4e731c673f6b)

No terminal VSCode , conecte-se ao EC2

**Navegue até a pasta do seu projeto:**

    ```bash
    cd human-gov-infrastructure
    ```

Crie um usuário chamado terraform e dê permissão "AdministratorAccess" para ele criar rules e outras recursos.

![image](https://github.com/user-attachments/assets/b07019fe-1715-4d2d-b018-8e10f2b08858)

Por último configure crie um access key para este usuário e no terminal do VSCode execute:

```bash
    export AWS_ACCESS_KEY_ID=Accesskey
    export AWS_SECRET_ACCESS_KEY=Secretkey
```

Teste

```bash
    terraform init
    terraform plan
    terraform apply
```
