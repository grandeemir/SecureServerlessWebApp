output "lambda_function" {
  value = aws_lambda_function.example.arn
}

output "lambda_function_name" {
  value = aws_lambda_function.example.function_name
}