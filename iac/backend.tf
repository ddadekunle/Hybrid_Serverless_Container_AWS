terraform{
    backend "s3" {
        bucket = "tfstate-hybrid-serverless-container-dda"
        key = "hybrid-capstone/terraform.tfstate"
        region = "eu-west-1"
        dynamodb_table = "tfstate-locks"
        encrypt = true
    }
}