# Implementação de uma Infraestrutura ‘SaaS’, ‘Multi-tenant’ e ‘Reutilizável’ na Aws, Usando Módulos do Terraform

# Parte 1: Automatizando sua Infraestrutura SaaS Multi-Tenant com Terraform 

Este tutorial guiará você pelos primeiros passos na configuração de uma infraestrutura multi-tenant na AWS usando Terraform, ideal para sua aplicação SaaS. Vamos focar na organização dos arquivos e na criação dos módulos essenciais.

## Pré-requisito

Antes de começar, certifique-se de ter uma **chave SSH** criada com o nome `humangov-ec2-key.pem`. Esta chave é fundamental para acessar as instâncias EC2 que o Terraform irá provisionar.

---

## Passo 01: Criando a Estrutura de Arquivos dos Módulos

Vamos organizar nosso projeto Terraform. Assumindo que você já criou e clonou seu repositório GitHub e o sincronizou com sua IDE. Neste caso usaremos um chamado `human-gov-infrastructure` e usaremos o CloudShell como ambiente de trabalho. Usando o CloudShell, você pode gerenciar, explorar e interagir com segurança com seus recursos da AWS a partir de um navegador. Ao efetuar login no seu console, o CloudShell autentica você, então você não precisa se preocupar com a chave de acesso/chave secreta. O CloudShell pode ser acessado diretamente do seu navegador e é gratuito.

Caso queira criar uma Amazon linux e precise saber como configurar VS Code para acessar a instância:

Leia este artigo [Conectando seu VS Code ao Poder da AWS: Desenvolvimento Python na Nuvem](https://medium.com/@phillrsouza/conectando-seu-vs-code-ao-poder-da-aws-desenvolvimento-python-na-nuvem-4e731c673f6b)




1.  **Navegue até a pasta do seu projeto:**

    ```bash
    cd human-gov-infrastructure
    ```

2.  **Crie um diretório raiz para os arquivos Terraform:**

    ```bash
    mkdir terraform
    ```

3.  **Crie a estrutura de diretórios para o seu módulo dentro da pasta `terraform`:**

    ```bash
    cd terraform
    mkdir -p modules/aws_humangov_infrastructure
    ls
    ```
    > **Observação:** `mkdir -p` cria o diretório pai (`modules`) se ele não existir, e depois o subdiretório (`aws_humangov_infrastructure`).

4.  **Dentro do diretório `modules/aws_humangov_infrastructure`, crie os arquivos vazios necessários para o módulo:**

    ```bash
    cd modules/aws_humangov_infrastructure
    touch variables.tf main.tf outputs.tf
    ```
    > **Observação:** `touch` cria arquivos vazios. Estes serão os pilares do seu módulo Terraform.

---

## Passo 02: Criando Arquivos de Configuração do Módulo

Agora, vamos preencher os arquivos que você acabou de criar dentro de `modules/aws_humangov_infrastructure/`.

1.  **Edite o arquivo `variables.tf`:**

    ```hcl
    variable "state_name" {
       description = "The name of the US State"
    }
    ```
    > **Observação:** Esta variável tornará seu módulo reutilizável, permitindo que você especifique o nome do estado (ou cliente/região) ao instanciá-lo neste projeto será estado. Ex: 'São Paulo, Bahia, Rio de Janeiro, etc...'.

2.  **Edite o arquivo `main.tf`:**

    ```hcl
    resource "aws_security_group" "state_ec2_sg" {
      name        = "humangov-${var.state_name}-ec2-sg"
      description = "Allow traffic on ports 22 and 80"

      ingress {
        from_port   = 22
        to_port     = 22
        protocol    = "tcp"
        cidr_blocks = ["0.0.0.0/0"] # Cuidado: 0.0.0.0/0 permite acesso de qualquer IP. Em produção, restrinja!
      }

      ingress {
        from_port   = 80
        to_port     = 80
        protocol     = "tcp"
        cidr_blocks = ["0.0.0.0/0"] # Cuidado: 0.0.0.0/0 permite acesso de qualquer IP. Em produção, restrinja!
      }

      tags = {
        Name = "humangov-${var.state_name}"
      }
    }

    resource "aws_instance" "state_ec2" {
      ami           = "ami-05ffe3c48a9991133" # AMI validada: Use AMIs específicas para sua região e atualize periodicamente.
      instance_type = "t2.micro"
      key_name = "humangov-ec2-key" # Certifique-se de que a chave SSH existe na sua conta AWS.
      vpc_security_group_ids = [aws_security_group.state_ec2_sg.id]

      tags = {
        Name = "humangov-${var.state_name}"
      }
    }

    resource "aws_dynamodb_table" "state_dynamodb" {
      name           = "humangov-${var.state_name}-dynamodb"
      billing_mode   = "PAY_PER_REQUEST" # Bom para cargas de trabalho variáveis.
      hash_key       = "id"   # Chave primária.

      attribute {           # Definição das colunas/atributos.
        name = "id"
        type = "S"  # String
      }

      tags = {
        Name = "humangov-${var.state_name}"
      }
    }

    resource "random_string" "bucket_suffix" {
      length  = 4
      special = false
      upper = false
    }

    resource "aws_s3_bucket" "state_s3" {
      bucket = "humangov-${var.state_name}-s3-${random_string.bucket_suffix.result}" # Nomes de bucket S3 devem ser globalmente únicos. O sufixo random_string ajuda nisso.

      tags = {
        Name = "humangov-${var.state_name}"
      }
    }
    ```
    > **Observação:** Este arquivo define os recursos essenciais para cada instância : um Security Group, uma EC2, uma tabela DynamoDB e um bucket S3.

3.  **Edite o arquivo `outputs.tf`:**

    ```hcl
    output "state_ec2_public_dns" {
      value = aws_instance.state_ec2.public_dns
    }

    output "state_dynamodb_table" {
      value = aws_dynamodb_table.state_dynamodb.name
    }

    output "state_s3_bucket" {
      value = aws_s3_bucket.state_s3.bucket
    }
    ```
    > **Observação:** Os outputs permitem que você acesse informações importantes dos recursos criados pelo módulo a partir do módulo pai ou da linha de comando.

---

## Passo 03: Criando Arquivos de Configuração da Pasta Raiz

Agora, mova-se para a pasta raiz do seu projeto Terraform (`terraform/`) para criar os arquivos que farão a orquestração e o consumo do módulo que você acabou de definir.

1.  **Certifique-se de estar no diretório `terraform`:**

    ```bash
    cd ../.. # Se você seguiu os passos anteriores, isso te levará para terraform/
    pwd # Verifique se a saída é algo como .../human-gov-infrastructure/terraform
    ```

2.  **No diretório raiz (`terraform/`), crie e edite o arquivo `variables.tf`:**

    ```hcl
    variable "states" {
      description = "A list of state names"
      default = ["sao-paulo", "bahia", "rio-de-janeiro"]
    }
    ```
    > **Observação:** Esta variável `states` é a chave para o multi-tenancy. Ela define para quais "clientes" (estados/regiões) a infraestrutura será criada.

3.  **No diretório raiz (`terraform/`), crie e edite o arquivo `main.tf`:**

    ```hcl
    provider "aws" {
      region = "us-east-1" # Defina a região AWS onde seus recursos serão provisionados.
    }

    module "aws_humangov_infrastructure" {
      source     = "./modules/aws_humangov_infrastructure"
      for_each   = toset(var.states) # Isso cria uma instância do módulo para cada valor em 'states'.
      state_name = each.value # O nome do estado atual do loop é passado para o módulo.
    }
    ```
    > **Observação:** O bloco `module` referencia o módulo que você criou. O `for_each` é fundamental aqui, pois ele instrui o Terraform a criar uma instância completa dos recursos definidos no módulo (`aws_humangov_infrastructure`) para cada item na lista `var.states` (neste caso, "sao-paulo", "bahia", "rio-de-janeiro").
    > * `for_each = toset(var.states)`: A função `toset` converte a lista `var.states` em um conjunto. O Terraform itera sobre cada item único neste conjunto, criando um conjunto separado de recursos para cada um.
    > * `state_name = each.value`: Dentro do loop `for_each`, `each.value` representa o item atual da iteração (por exemplo, "sao-paulo"). Este valor é passado para a variável `state_name` dentro do módulo, personalizando os nomes dos recursos criados.

4.  **No diretório raiz (`terraform/`), crie e edite o arquivo `outputs.tf`:**

    ```hcl
    output "state_infrastructure_outputs" {
      value = {
        for state, infrastructure in module.aws_humangov_infrastructure : # Itera sobre cada instância do módulo criada.
        state => { # Cria um mapa onde a chave é o nome do estado (cliente/região)...
          ec2_public_dns   = infrastructure.state_ec2_public_dns # ...e o valor é um mapa com os outputs de cada recurso.
          dynamodb_table   = infrastructure.state_dynamodb_table
          s3_bucket        = infrastructure.state_s3_bucket
        }
      }
    }
    ```
    > **Observação:** Este `output` organiza todas as informações de saída de cada instância do módulo (para cada estado/cliente) em um único mapa, facilitando a consulta após a aplicação do Terraform.
    > * `for state, infrastructure in module.aws_humangov_infrastructure`: Este loop itera sobre todas as instâncias do módulo criadas pelo `for_each`. `state` captura a chave do conjunto (`"sao-paulo"`, `"bahia"`, etc.), e `infrastructure` representa os outputs daquela instância específica do módulo.
    > * `state => { ... }`: Para cada iteração, ele cria uma entrada no mapa final onde a chave é o nome do `state` e o valor é outro mapa contendo os outputs individuais (DNS da EC2, nome da tabela DynamoDB, nome do bucket S3) daquela infraestrutura específica.

---

## Passo 04: Instalar terraform

No cloudshell execute:

```bash
sudo yum install -y yum-utils shadow-utils
sudo yum-config-manager --add-repo https://rpm.releases.hashicorp.com/AmazonLinux/hashicorp.repo
sudo yum -y install terraform
```

## Passo 05: Executando Terraform

Agora que os arquivos de configuração estão prontos, vamos inicializar, validar e aplicar as mudanças. Certifique-se de estar na pasta raiz do Terraform (`terraform/`).

1.  **Formate seus arquivos Terraform:**

    ```bash
    terraform fmt
    ```
    > **Observação:** `terraform fmt` formata automaticamente seus arquivos `.tf` para um estilo consistente, melhorando a legibilidade.

2.  **Inicialize o diretório de trabalho do Terraform:**

    ```bash
    terraform init
    ```
    > **Observação:** `terraform init` baixa os provedores AWS necessários e configura o backend para gerenciar o estado do Terraform.

3.  **Valide suas configurações do Terraform:**

    ```bash
    terraform validate
    ```
    > **Observação:** `terraform validate` verifica a sintaxe e a consistência da sua configuração, ajudando a pegar erros antes da aplicação.

4.  **Crie um plano de execução:**

    ```bash
    terraform plan
    ```
    > **Observação:** `terraform plan` mostra exatamente quais recursos o Terraform irá criar, modificar ou destruir. Você deve ver "15 to add" (3 estados x 5 recursos por estado = 15 recursos no total). Sempre revise o plano cuidadosamente!

5.  **Aplique as configurações para provisionar os recursos:**

    ```bash
    terraform apply
    ```
    > **Observação:** `terraform apply` executa o plano, criando os recursos na sua conta AWS. Ele pedirá confirmação. Digite `yes` para prosseguir.

6.  **Valide os recursos criados na AWS:**

    Após a aplicação bem-sucedida, acesse o console da AWS (EC2 | DynamoDB | Bucket S3) e verifique se as instâncias EC2, as tabelas DynamoDB e os buckets S3 foram criados para `sao-paulo`, `bahia` e `rio-de-janeiro`, conforme esperado.

---

## Passo 06: Excluindo Recursos

Quando você não precisar mais da infraestrutura provisionada, é essencial destruí-la para evitar custos desnecessários.

1.  **Destrua todos os recursos provisionados pelo Terraform:**

    ```bash
    terraform destroy
    ```
    > **Observação:** `terraform destroy` remove todos os recursos gerenciados pela sua configuração Terraform. Use com extrema cautela em ambientes de produção! Ele também pedirá confirmação.

---


# Parte 2: Automatizando sua Infraestrutura SaaS Multi-Tenant com Terraform

Nesta etapa crucial, vamos elevar a segurança e a colaboração da sua gestão de infraestrutura. Vamos configurar o **backend remoto do Terraform** em um bucket S3 e uma tabela DynamoDB na AWS, garantindo que o arquivo de estado seja armazenado de forma segura e que as operações sejam controladas para evitar conflitos.

---

## Passo 01: Criando o Bucket para Armazenar o Estado do Terraform

O arquivo de estado (`terraform.tfstate`) é vital para o Terraform, pois ele mapeia seus recursos reais na AWS. Armazená-lo localmente é arriscado e inviabiliza a colaboração. Vamos criar um bucket S3 para esse propósito.

1.  **Crie um novo bucket S3 para armazenar o estado do Terraform remotamente:**

    ```bash
    aws s3api create-bucket --bucket devops-mod3-state-hsp --region us-east-1
    ```
    > **Observação:** Substitua `devops-mod3-state-hsp` por um **nome de bucket S3 que seja globalmente único**. Você também pode usar `--create-bucket-configuration LocationConstraint=us-east-1` se o bucket for criado fora de `us-east-1` e você quiser especificá-la.

2.  **Valide que o bucket foi criado:**

    ```bash
    aws s3 ls
    ```
    > **Observação:** Este comando lista todos os seus buckets S3. Procure pelo nome do bucket que você acabou de criar.

    Ou, para listar o conteúdo específico do seu novo bucket (que deve estar vazio por enquanto):

    ```bash
    aws s3 ls s3://devops-mod3-state-hsp
    ```
    > **Observação:** Confirme se o bucket aparece na lista, indicando que foi criado com sucesso.

---

## Passo 02: Criando Tabela DynamoDB para Controle de Concorrência

Para evitar que múltiplos engenheiros tentem aplicar mudanças na mesma infraestrutura simultaneamente, o Terraform precisa de um mecanismo de bloqueio de estado (state locking). O DynamoDB é perfeito para isso.

1.  **Crie uma Tabela DynamoDB para controle de concorrência:**

    ```bash
    aws dynamodb create-table \
    --table-name humangov-terraform-state-lock-table \
    --attribute-definitions AttributeName=LockID,AttributeType=S \
    --key-schema AttributeName=LockID,KeyType=HASH \
    --provisioned-throughput ReadCapacityUnits=5,WriteCapacityUnits=5 \
    --region us-east-1
    ```
    > **Observação:** Esta tabela terá uma única chave primária (`LockID`) do tipo String, ideal para o propósito de bloqueio. `PAY_PER_REQUEST` é geralmente mais econômico para este tipo de uso, mas aqui estamos usando provisioned throughput para demonstração.

2.  **Valide que a tabela foi criada:**

    ```bash
    aws dynamodb list-tables
    ```
    > **Observação:** Verifique se `humangov-terraform-state-lock-table` aparece na lista de tabelas.

---

## Passo 03: Criando o Arquivo "Backend"

Agora, vamos instruir o Terraform a usar o S3 e o DynamoDB para gerenciar seu estado.

1.  **No seu diretório raiz do projeto Terraform (`terraform/`), crie um arquivo `backend.tf`:**

    ```bash
    pwd   # /home/ec2-user/human-gov-infrastructure/terraform
    touch backend.tf
    ```
    > **Observação:** É crucial criar este arquivo na pasta raiz do seu projeto Terraform (`terraform/`), não dentro do módulo.

2.  **Edite o arquivo `backend.tf` com o seguinte conteúdo:**

    ```hcl
    terraform {
      backend "s3" {
        bucket         = "devops-mod3-state-hsp" # SUBSTITUA pelo nome do SEU bucket S3 criado no Passo 01.
        key            = "terraform.tfstate" # Nome do arquivo de estado dentro do bucket.
        region         = "us-east-1" # A mesma região do seu bucket S3 e outros recursos.
        encrypt        = true # Criptografa o arquivo de estado no S3. BOA PRÁTICA!
        dynamodb_table = "humangov-terraform-state-lock-table" # A tabela DynamoDB criada no Passo 02.
      }
    }
    ```
    > **Observação:** Este bloco `backend "s3"` configura o Terraform para armazenar seu arquivo de estado neste bucket S3 e usar a tabela DynamoDB para bloqueio de estado. Isso é fundamental para um fluxo de trabalho colaborativo e seguro.

---

## Passo 04: Inicializando o Terraform com o Novo Backend

Após configurar o `backend.tf`, você precisa inicializar o Terraform novamente para que ele reconheça e configure o backend remoto.

1.  **Inicialize o Terraform:**

    ```bash
    terraform init
    ```
    Você deve ver uma saída similar a esta:

    ```
    Initializing the backend...

    Successfully configured the backend "s3"! Terraform will automatically
    use this backend unless the backend configuration changes.
    ```
    > **Observação:** Se for a primeira vez que você está executando `terraform init` com um backend remoto, o Terraform tentará migrar qualquer estado local existente para o S3. Se não houver estado local (como no nosso caso, pois o `terraform destroy` foi executado na parte 1), ele simplesmente configurará o backend.

    > **Observação:** Nenhuma confirmação foi requisitada pelo fato de não haver nenhum recurso criado ou arquivo de estado local neste momento.

---

## Passo 05: Aplicando as Alterações

Agora que o backend está configurado, podemos aplicar a infraestrutura. Para esta parte do tutorial, vamos aplicar para apenas um cliente (estado) para agilizar o processo e validar a funcionalidade do backend.

1.  **Edite temporariamente seu arquivo `variables.tf` na pasta raiz (`terraform/`) para incluir apenas um estado:**

    ```hcl
    # temporariamente para o Passo 05
    variable "states" {
      description = "A list of state names"
      default     = ["sao-paulo"] # Alterado de ["sao-paulo", "bahia", "rio-de-janeiro"] para apenas "sao-paulo"
    }
    ```
    > **Observação:** Essa mudança é apenas para este teste específico. Você pode reverter para a lista completa após validar.

2.  **Crie um plano de execução e aplique as configurações do Terraform:**

    ```bash
    terraform plan
    terraform apply
    ```
    > **Observação:** O Terraform agora criará os recursos para a `sao-paulo` e armazenará o estado dessa infraestrutura no bucket S3 configurado. Verifique no console da AWS se os recursos (EC2, DynamoDB, S3) para "sao-paulo" foram criados.

---

## Passo 06: Validando a Criação do Arquivo de Estado no Bucket

Vamos confirmar se o arquivo de estado (`terraform.tfstate`) foi realmente armazenado no seu bucket S3.

1.  **Liste o conteúdo do seu bucket S3:**

    ```bash
    aws s3 ls s3://tcb-devops-mod3-state-hsp # Substitua pelo nome do SEU bucket
    ```
    Você deve ver o arquivo `terraform.tfstate` listado.

    ```bash
    # Exemplo de saída:
    # 2025-06-28 17:30:00        1234 terraform.tfstate
    ```
    > **Observação:** A presença do arquivo `terraform.tfstate` confirma que o backend S3 está funcionando corretamente.

---

## Passo 07: Excluindo Recursos

Para manter seu ambiente limpo e evitar custos, vamos destruir os recursos criados.

1.  **Destrua os recursos provisionados:**

    ```bash
    terraform destroy
    ```
    > **Observação:** O Terraform usará o estado armazenado no S3 para identificar e remover os recursos. Confirme a exclusão digitando `yes` quando solicitado.

---

# Parte 3: Automatizando sua Infraestrutura SaaS Multi-Tenant com Terraform

Nesta etapa final, vamos integrar o trabalho que fizemos no Terraform com seu repositório remoto no GitHub. Abordaremos como gerenciar arquivos sensíveis com `.gitignore`, como configurar seu ambiente Git para commits seguros, e como sincronizar seu código para o GitHub, garantindo que seu projeto esteja versionado e pronto para colaboração.

---

## Passo 01: Configurando o Git no CloudShell (Configurações Globais e Autenticação)

Antes de enviar seus arquivos para o GitHub, é fundamental configurar sua identidade no Git e como você se autentica. Quando você executa um comando `git commit` pela primeira vez no **CloudShell**, ele pode solicitar suas configurações globais.

1.  **Configure seu nome de usuário global do Git:**

    ```bash
    git config --global user.name "Seu Nome Completo"
    ```
    > **Observação:** Substitua `"Seu Nome Completo"` pelo seu nome. Esta informação será associada a todos os seus commits.

2.  **Configure seu e-mail global do Git:**

    ```bash
    git config --global user.email "ID_NUMERICO+SEU_USUARIO@users.noreply.github.com"
    ```
    > **Observação:** **É altamente recomendável usar o e-mail "no-reply" do GitHub para commits.** Para encontrar o seu, vá em `https://github.com/settings/emails` no seu navegador. O GitHub fornece um e-mail no formato `ID_NUMERICO+SEU_USUARIO@users.noreply.github.com` (ex: `12345678+username@users.noreply.github.com`). Usar este e-mail evita expor seu e-mail pessoal e ainda assim vincula o commit à sua conta GitHub.

3.  **Configurando a autenticação com GitHub (Token de Acesso Pessoal - PAT):**
    Ao executar `git push` para um repositório privado, o GitHub não aceita mais sua senha da conta para autenticação via HTTPS. Você precisará usar um **Personal Access Token (PAT)**.

    * **Crie um Personal Access Token (PAT) no GitHub:**
        * Acesse `https://github.com/settings/personal-access-tokens/new` no seu navegador.
        * Dê um nome descritivo ao token (ex: "terraform-cloudshell").
        * Defina um prazo de validade (ex: 90 dias, 1 ano, ou sem expiração se for para uso pessoal em ambiente controlado).
        * **Marque os escopos necessários:** Para push e pull em repositórios, os escopos `repo` (que inclui `repo:status`, `repo_deployment`, `public_repo`, `repo:invite`) são geralmente suficientes. Se você precisar de acesso a Gists ou outras funcionalidades, marque-as.
        * Clique em "Generate token".
        * **COPIE O TOKEN GERADO IMEDIATAMENTE!** Ele só será exibido uma vez. Se você perdê-lo, terá que gerar um novo.

    * **Use o PAT no CloudShell:**
        Quando você executar `git push` pela primeira vez, o Git solicitará seu nome de usuário e senha.
        * **Username:** Digite seu **nome de usuário do GitHub**.
        * **Password:** Cole o **Personal Access Token (PAT)** que você acabou de gerar.

    > **Importante:** O PAT é como uma senha, mas para automações. Mantenha-o seguro e nunca o exponha em códigos ou logs. Em ambientes de produção, use métodos mais seguros como roles IAM em conjunto com repositórios privados ou Secrets Managers.

---

## Passo 02: Criando o Arquivo `.gitignore`

É essencial evitar que arquivos temporários, sensíveis ou gerados pelo Terraform sejam versionados no seu repositório Git. O arquivo `.gitignore` faz exatamente isso.

1.  **Acesse o Diretório de Trabalho do Git:**

    ```bash
    cd human-gov-infrastructure
    ```

2.  **Analise os arquivos na pasta `terraform/` (raiz do seu projeto Terraform):**

    ```bash
    ls -la terraform/
    ```
    > **Observação:** Você verá arquivos como `.terraform/`, `terraform.tfstate`, `terraform.tfstate.backup`, etc. Estes são arquivos de estado e cache que não devem ser versionados.

3.  **Experimente os comandos Git para entender o que seria adicionado antes de usar o `.gitignore`:**

    ```bash
    git status
    git add .
    git status
    git rm -r --cached . # Remove tudo do "stage" (área de preparação), desfazendo o 'git add .'
    git status
    ```
    > **Observação:** `git status` mostra o estado atual do seu repositório. Após `git add .`, você verá muitos arquivos (incluindo os de estado do Terraform) como "new file". `git rm -r --cached .` é um comando útil para "desfazer" um `git add .` sem excluir os arquivos do seu sistema de arquivos local.

4.  **Crie o arquivo `.gitignore` no diretório raiz do seu repositório (`human-gov-infrastructure/`):**

    ```bash
    touch .gitignore
    ```
    > **Observação:** Este arquivo deve estar no mesmo nível que a pasta `terraform/` e `.git/`.

5.  **Adicione os arquivos/folders para serem ignorados no arquivo `.gitignore`:**

    Edite o arquivo `.gitignore` e adicione o seguinte conteúdo:

    ```
    .terraform/
    *.tfstate
    *.tfstate.backup
    *.tfvars
    *.tfplan
    *.tfstate.lock.info
    # Adicionais comuns para Terraform:
    .terraform.lock.hcl
    crash.log
    override.tf
    override.tf.json
    *.tfvars.json
    ```
    > **Observação:**
    > * `.terraform/`: Ignora o diretório de trabalho do Terraform (módulos baixados, plugins, etc.).
    > * `*.tfstate`, `*.tfstate.backup`, `*.tfstate.lock.info`: Ignora os arquivos de estado do Terraform, que são gerenciados no S3 (conforme Parte 2) e não devem estar no Git.
    > * `*.tfvars`: Ignora arquivos que contêm variáveis sensíveis (senhas, chaves de API). Nunca comite isso!
    > * `*.tfplan`: Ignora os planos de execução gerados pelo `terraform plan`.
    > * O `git add .` agora irá **ignorar automaticamente** os arquivos e pastas especificados no `.gitignore`.

---

## Passo 03: Sincronizando Repositórios (Commit e Push)

Com o Git configurado e o `.gitignore` pronto, você pode adicionar seus arquivos Terraform ao repositório local e enviá-los para o GitHub.

1.  **Verifique novamente o status do Git para ver o que será adicionado:**

    ```bash
    git status
    ```
    > **Observação:** Agora, você deve ver apenas os arquivos Terraform `.tf`, `.gitignore`, e `backend.tf` listados como "untracked files" ou "modified". Os arquivos ignorados não aparecerão.

2.  **Adicione todos os arquivos rastreáveis ao "stage" (área de preparação):**

    ```bash
    git add .
    ```
    > **Observação:** O ponto (`.`) significa adicionar todos os arquivos e diretórios no diretório atual (e subdiretórios) que não são ignorados pelo `.gitignore`.

3.  **Confirme o que está na área de preparação:**

    ```bash
    git status
    ```
    > **Observação:** Todos os arquivos que você deseja commitar devem aparecer como "changes to be committed".

4.  **Crie um commit com uma mensagem descritiva:**

    ```bash
    git commit -m "AWS Infrastructure Terraform Configuration - first commit"
    ```
    > **Observação:** A mensagem de commit deve ser clara e concisa, descrevendo as mudanças.

5.  **Envie seus commits do repositório local para o repositório remoto no GitHub:**

    ```bash
    git push -u origin main
    ```
    > **Observação:**
    > * `git push`: Envia os commits.
    > * `-u origin main`: Define o branch `main` no repositório remoto (`origin`) como o branch upstream padrão para o seu branch local atual. Isso significa que nas próximas vezes, você pode usar apenas `git push` e `git pull`.
    > * Se for a primeira vez, será solicitada sua autenticação (nome de usuário GitHub e o PAT que você gerou no Passo 01).

    Após o `git push` ser bem-sucedido, seus arquivos Terraform estarão visíveis no seu repositório GitHub, prontos para colaboração e versionamento!

---

# Resultado

![devops-mod3-prova](https://github.com/user-attachments/assets/617c51f8-5a8f-415d-94ad-2173265fa459)
