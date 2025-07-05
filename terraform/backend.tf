terraform {
  backend "s3" {
    bucket         = "tcb-devops-mod3-state-12233"
    key            = "terraform.tfstate"
    region         = "us-east-1"
    encrypt        = true
    dynamodb_table = "humangov-terraform-state-lock-table"
  }

}
