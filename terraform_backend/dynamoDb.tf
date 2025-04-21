
resource "aws_dynamodb_table" "almacen_estado" {
  name           = "almacen_estado" 
  billing_mode   = "PAY_PER_REQUEST"            
  hash_key       = "LockID"                    

  attribute {
    name = "LockID"
    type = "S" 
  }
}

