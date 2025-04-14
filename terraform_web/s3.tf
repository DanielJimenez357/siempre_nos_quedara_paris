terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }

  backend "s3" {
    bucket         = "state-dani357"  
    key            = "web-simple/terraform.tfstate"    
    region         = "us-east-1"                     
    dynamodb_table = "almacen_estado"  
    encrypt        = true                              
  }

}

provider "aws" {
  region = "us-east-1"
}



resource "aws_s3_bucket" "servidor" {
  bucket  = "www.${var.nombre_bucket}"
}


resource "aws_s3_bucket_public_access_block" "permitir_acceso" {
  bucket = aws_s3_bucket.servidor.id

  block_public_acls       = false
  block_public_policy     = false
  ignore_public_acls      = false
  restrict_public_buckets = false
}

resource "aws_s3_bucket_policy" "acceso_publico" {
  bucket = aws_s3_bucket.servidor.id
  policy = jsonencode({
    Statement = [
      {
        Effect    = "Allow",
        Principal = "*",
        Action    = "s3:GetObject",
        Resource  = "${aws_s3_bucket.servidor.arn}/*"
      }
    ]
  })

  depends_on = [aws_s3_bucket_public_access_block.permitir_acceso]
}

resource "aws_s3_bucket_website_configuration" "configuracion_web" {
  bucket = aws_s3_bucket.servidor.id

  index_document {
    suffix = "index.html"
  }

  depends_on = [aws_s3_bucket_policy.acceso_publico]
}

resource "aws_s3_bucket_ownership_controls" "configuracion_acl" {
  bucket = aws_s3_bucket.servidor.id
  rule {
    object_ownership = "BucketOwnerPreferred"
  }
}

resource "aws_s3_bucket_acl" "s3_bucket_acl" {
  depends_on = [aws_s3_bucket_ownership_controls.configuracion_acl]
  bucket = aws_s3_bucket.servidor.id
  acl    = "public-read"
}

resource "aws_s3_object" "subir_html" {
    depends_on = [aws_s3_bucket_acl.s3_bucket_acl]
    for_each        = fileset("./web/", "*.html")
    bucket          = aws_s3_bucket.servidor.bucket
    key             = each.value
    source          = "./web/${each.value}"
    content_type    = "text/html"
    etag            = filemd5("./web/${each.value}")
    acl             = "public-read"
}

resource "aws_s3_object" "subir_css" {
    depends_on = [aws_s3_bucket_acl.s3_bucket_acl]
    for_each        = fileset("./web/", "*.css")
    bucket          = aws_s3_bucket.servidor.bucket
    key             = each.value
    source          = "./web/${each.value}"
    content_type    = "text/css"
    etag            = filemd5("./web/${each.value}")
    acl             = "public-read"
}

output "endpoint" {
  value = "http://${aws_s3_bucket.servidor.bucket}.s3-website-us-east-1.amazonaws.com"
}


