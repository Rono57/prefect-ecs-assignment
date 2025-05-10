resource "aws_secretsmanager_secret" "prefect_api_key" {
  name = "prefect-api-key"
  tags = {
    Name = "prefect-ecs"
  }
}

resource "aws_secretsmanager_secret_version" "prefect_api_key_version" {
  secret_id     = aws_secretsmanager_secret.prefect_api_key.id
  secret_string = var.prefect_api_key
}