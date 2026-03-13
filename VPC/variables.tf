variable "env" {
    description = "environment type"
    type = string
}

variable "azs" {
    description = "availability zones"
    type = list(string)
}

variable "eks-name" {
    description = "name of the eks cluster"
    type = string
}
