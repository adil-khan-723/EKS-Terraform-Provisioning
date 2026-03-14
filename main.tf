module "vpc" {
    source = "./VPC"
    azs = ["ap-south-1b", "ap-south-1c"]
    eks-name = "oggy-eks"
    env = "staging"
}

module "eks" {
    source = "./Cluster"
    subnet_ids = module.vpc.private_subnet_ids
    env = "staging"
    eks-name = "oggy-eks"
}