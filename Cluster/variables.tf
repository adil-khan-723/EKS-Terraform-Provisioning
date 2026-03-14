variable "env" {
    description = "evironment type"
    type = string
}

variable "eks-name" {
    description = "name of the cluster"
    type = string
}

variable "subnet_ids" {
    description = "list of subnets"
    type = list(string)
}