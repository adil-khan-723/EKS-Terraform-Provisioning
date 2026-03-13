module "vpc" {
    source = "./VPC"
    azs = ["ap-south-1b", "ap-south-1c"]
    eks-name = "oggy-eks"
    env = "staging"
}