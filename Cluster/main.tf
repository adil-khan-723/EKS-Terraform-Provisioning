#EKS ROLES AND CLUSTER

resource "aws_iam_role" "eks-role" {
  name = "${var.env}-${var.eks-name}-eks-cluster"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "eks.amazonaws.com"
        }
      }
    ]
  })
}

resource "aws_iam_role_policy_attachment" "eks" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKSClusterPolicy"
  role       = aws_iam_role.eks-role.name
}

resource "aws_eks_cluster" "oggy-eks" {
  name     = "${var.env}-${var.eks-name}"
  role_arn = aws_iam_role.eks-role.arn

  vpc_config {
    endpoint_private_access = false
    endpoint_public_access  = true

    subnet_ids = var.subnet_ids
  }

  access_config {
    authentication_mode                         = "API"
    bootstrap_cluster_creator_admin_permissions = true
  }

  depends_on = [aws_iam_role_policy_attachment.eks]
}

# EKS NODES AND ROLES

resource "aws_iam_role" "eks-nodes-role" {
  name = "${var.env}-${var.eks-name}-eks-node-role"
  assume_role_policy = jsonencode({
  Version = "2012-10-17"
  Statement = [
    {
      Action = "sts:AssumeRole"
      Effect = "Allow"
      Principal = {
        Service = "ec2.amazonaws.com"
      }
    }
  ]
})
}

resource "aws_iam_role_policy_attachment" "worker-node-policy" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKSWorkerNodePolicy"
  role       = aws_iam_role.eks-nodes-role.name
}

resource "aws_iam_role_policy_attachment" "eks-cni-policy" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKS_CNI_Policy"
  role       = aws_iam_role.eks-nodes-role.name
}

resource "aws_iam_role_policy_attachment" "ecrReadonly" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonEC2ContainerRegistryReadOnly"
  role       = aws_iam_role.eks-nodes-role.name
}

resource "aws_eks_node_group" "nodes" {
  cluster_name    = aws_eks_cluster.oggy-eks.name
  node_group_name = "oggy"
  node_role_arn   = aws_iam_role.eks-nodes-role.arn

  subnet_ids     = var.subnet_ids
  capacity_type  = "SPOT"
  instance_types = ["t3.medium"]

  scaling_config {
    desired_size = 1
    max_size     = 10
    min_size     = 0
  }

  update_config {
    max_unavailable = 1
  }

  depends_on = [
    aws_iam_role_policy_attachment.ecrReadonly,
    aws_iam_role_policy_attachment.worker-node-policy,
    aws_iam_role_policy_attachment.eks-cni-policy
  ]
  lifecycle {
    ignore_changes = [scaling_config[0].desired_size]
  }
}
