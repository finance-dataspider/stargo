# Output for API Gateway URL

output "api_gateway_resource_path" {
  value = aws_api_gateway_deployment.stargo_deployment.invoke_url

}

# Output for API Key
output "api_key" {
  value = aws_api_gateway_api_key.stargo_api_key.value
}

# Output for Lambda Function ARN
output "lambda_function_arn" {
  value = aws_lambda_function.stargo_lambda.arn
}

output "lambda_api_gateway_policy_arn" {
  value = aws_iam_policy.lambda_api_gateway_policy.arn
}