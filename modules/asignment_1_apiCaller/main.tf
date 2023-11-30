# API GW AND KEYS
resource "aws_api_gateway_rest_api" "stargo_api" {
  name        = "stargo-api"
  description = "stargo API created with Terraform"
}

resource "aws_api_gateway_resource" "stargo_resource" {
  rest_api_id = aws_api_gateway_rest_api.stargo_api.id
  parent_id   = aws_api_gateway_rest_api.stargo_api.root_resource_id
  path_part   = "stargo"
}

resource "aws_api_gateway_method" "stargo_method" {
  rest_api_id   = aws_api_gateway_rest_api.stargo_api.id
  resource_id   = aws_api_gateway_resource.stargo_resource.id
  http_method   = "GET"
  authorization = "AWS_IAM"
}

resource "aws_api_gateway_integration" "stargo_integration" {
  rest_api_id             = aws_api_gateway_rest_api.stargo_api.id
  resource_id             = aws_api_gateway_resource.stargo_resource.id
  http_method             = aws_api_gateway_method.stargo_method.http_method
  integration_http_method = "GET"
  type                    = "MOCK"
  request_templates = {
    "application/json" = jsonencode(
      {
        statusCode = 200
      }
    )
  }
}

resource "aws_api_gateway_integration_response" "stargo_integration_response" {
  rest_api_id = aws_api_gateway_rest_api.stargo_api.id
  resource_id = aws_api_gateway_resource.stargo_resource.id
  http_method = aws_api_gateway_method.stargo_method.http_method
  status_code = 200
  response_templates = {
    "application/json" = jsonencode({
      statusCode = 200
    })
  }
  depends_on = [
    aws_api_gateway_integration.stargo_integration
  ]
}



resource "aws_api_gateway_method_response" "stargo_method_response" {
  rest_api_id = aws_api_gateway_rest_api.stargo_api.id
  resource_id = aws_api_gateway_resource.stargo_resource.id
  http_method = aws_api_gateway_method.stargo_method.http_method
  status_code = 200
}

resource "aws_api_gateway_deployment" "stargo_deployment" {
  depends_on = [
    aws_api_gateway_method.stargo_method,
    aws_api_gateway_method_response.stargo_method_response,
    aws_api_gateway_integration.stargo_integration,
    aws_api_gateway_integration_response.stargo_integration_response
    ]
  rest_api_id = aws_api_gateway_rest_api.stargo_api.id
  stage_name  = "prod"

}

resource "aws_api_gateway_api_key" "stargo_api_key" {
  name = "stargo-api-key"
}

resource "aws_api_gateway_usage_plan" "stargo_usage_plan" {
  name = "stargo-usage-plan"
  api_stages {
    api_id  = aws_api_gateway_rest_api.stargo_api.id
    stage   = aws_api_gateway_deployment.stargo_deployment.stage_name
  }
  quota_settings {
    limit = 1000
    offset = 2
    period = "MONTH"
  }
  throttle_settings {
    burst_limit = 5
    rate_limit  = 2
  }
}

resource "aws_api_gateway_usage_plan_key" "stargo_key_association" {
  key_id        = aws_api_gateway_api_key.stargo_api_key.id
  usage_plan_id = aws_api_gateway_usage_plan.stargo_usage_plan.id
  key_type      = "API_KEY"  
}

#LAMBDA

# IAM Role for Lambda
resource "aws_iam_role" "lambda_execution_role" {
  name = "lambda_execution_role"
  assume_role_policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        Action = "sts:AssumeRole",
        Effect = "Allow",
        Principal = {
          Service = "lambda.amazonaws.com",
        },
      },
    ],
  })
}

resource "aws_iam_policy_attachment" "lambda_execution_attachment" {
  name        = "lambda_execution_attachment"
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSLambdaBasicExecutionRole"
  roles      = [aws_iam_role.lambda_execution_role.name]
}

# Policy for Lambda to interact with API Gateway
resource "aws_iam_policy" "lambda_api_gateway_policy" {
  name        = "lambda_api_gateway_policy"
  description = "Policy for Lambda to interact with API Gateway"

  policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        Action   = "execute-api:Invoke",
        Effect   = "Allow",
        Resource = "arn:aws:execute-api:${var.aws_region}:${var.aws_account_id}:${aws_api_gateway_rest_api.stargo_api.id}/*/GET/stargo",
        
      },
    ],
  })
}

resource "aws_iam_policy_attachment" "lambda_api_gateway_attachment" {
  name        = "lambda_api_gateway_attachment"
  policy_arn = aws_iam_policy.lambda_api_gateway_policy.arn
  roles      = [aws_iam_role.lambda_execution_role.name]
}

data "archive_file" "python_lambda_package" {  
  type = "zip"  
  source_dir = "./modules/asignment_1_apiCaller/src" 
  output_path = "./modules/asignment_1_apiCaller/lambda.zip"
}

# Lambda Function
resource "aws_lambda_function" "stargo_lambda" {
  function_name    = "stargo_lambda"
  handler          = "lambda_function.lambda_handler"  # Change this to your actual Python file and handler
  runtime          = "python3.8"
  role             = aws_iam_role.lambda_execution_role.arn
  filename         = "./modules/asignment_1_apiCaller/lambda.zip"  # Update with your actual Lambda deployment package
  environment {
    variables = {
      API_URL = "${aws_api_gateway_deployment.stargo_deployment.invoke_url}${aws_api_gateway_resource.stargo_resource.path}",
      API_KEY = aws_api_gateway_api_key.stargo_api_key.value,
    }
  }
}