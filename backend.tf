terraform {
  backend "s3" {
    bucket         = "myiacsandbox"
    region         = "us-east-1"
    profile        = "default"
    key            = "backend.tfstate"
    dynamodb_table = "myiacsandbox"
  }
}