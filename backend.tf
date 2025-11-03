terraform {
  backend "s3" {
    bucket         = "terraform-states-utn-demo"
    key            = "terraform-lab/terraform.tfstate"
    region         = "us-east-1"
    dynamodb_table = "terraform-state-locks"
    encrypt        = true
    # profile        = "zlab"
    # test
  }
}
