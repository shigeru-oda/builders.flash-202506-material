resource "aws_iam_role" "ecs_task_execution_role" {
  name = "${var.project_name}-ecs-execution-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "ecs-tasks.amazonaws.com"
        }
      }
    ]
  })

  tags = {
    Name    = "${var.project_name}-ecs-execution-role"
    Project = var.project_name
  }
}

resource "aws_iam_role_policy_attachment" "ecs_task_execution_role_policy" {
  role       = aws_iam_role.ecs_task_execution_role.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonECSTaskExecutionRolePolicy"
}

resource "aws_iam_role" "ecs_task_role" {
  name = "${var.project_name}-ecs-task-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "ecs-tasks.amazonaws.com"
        }
      }
    ]
  })

  tags = {
    Name    = "${var.project_name}-ecs-task-role"
    Project = var.project_name
  }
}

resource "aws_iam_policy" "task_policy" {
  name        = "${var.project_name}-task-policy"
  description = "Policy for ECS tasks to access CloudWatch Logs"

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = [
          "logs:CreateLogStream",
          "logs:PutLogEvents",
          "logs:CreateLogGroup"
        ]
        Effect   = "Allow"
        Resource = "*"
      }
    ]
  })
}

resource "aws_iam_role_policy_attachment" "task_policy_attachment" {
  role       = aws_iam_role.ecs_task_role.name
  policy_arn = aws_iam_policy.task_policy.arn
}

resource "aws_iam_role" "firehose_role" {
  name = "builders-flash-firehose-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = [
        "sts:AssumeRole"],
        Effect = "Allow"
        Principal = {
          Service = [
            "firehose.amazonaws.com"
          ]
        }
      }
    ]
  })

  tags = {
    Name    = "builders-flash-firehose-role"
    Project = var.project_name
  }
}

resource "aws_iam_policy" "firehose_policy" {
  name        = "builders-flash-firehose-policy"
  description = "Policy for Kinesis Firehose"

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "s3:AbortMultipartUpload",
          "s3:GetBucketLocation",
          "s3:GetObject",
          "s3:ListBucket",
          "s3:ListBucketMultipartUploads",
          "s3:PutObject"
        ]
        Resource = [
          aws_s3_bucket.api_logs_json.arn,
          "${aws_s3_bucket.api_logs_json.arn}/*",
          aws_s3_bucket.api_logs_parquet.arn,
          "${aws_s3_bucket.api_logs_parquet.arn}/*",
          aws_s3_directory_bucket.api_logs_json_express.arn,
          "${aws_s3_directory_bucket.api_logs_json_express.arn}/*",
          aws_s3_directory_bucket.api_logs_parquet_express.arn,
          "${aws_s3_directory_bucket.api_logs_parquet_express.arn}/*",
        ]
      },
      {
        Effect = "Allow"
        Action = [
          "glue:GetTable",
          "glue:GetTableVersion",
          "glue:GetTableVersions",
          "glue:GetDatabase",
          "glue:GetDatabases",
          "glue:CreateTable",
          "glue:UpdateTable",
          "glue:GetSchemaVersion",
        ]
        Resource = [
          "*"
        ]
      },
      {
        Effect = "Allow"
        Action = [
          "logs:PutLogEvents"
        ]
        Resource = [
          "arn:aws:logs:${var.aws_region}:*:log-group:/aws/kinesisfirehose/*:log-stream:*"
        ]
      }
    ]
  })
}

resource "aws_iam_role_policy_attachment" "firehose_policy_attachment" {
  role       = aws_iam_role.firehose_role.name
  policy_arn = aws_iam_policy.firehose_policy.arn
}

resource "aws_iam_policy" "ecs_kinesis_policy" {
  name        = "builders-flash-ecs-kinesis-policy"
  description = "Policy for ECS tasks to send logs to Kinesis Firehose"

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "firehose:PutRecord",
          "firehose:PutRecordBatch"
        ]
        Resource = [
          aws_kinesis_firehose_delivery_stream.api_logs_parquet.arn,
          aws_kinesis_firehose_delivery_stream.api_logs_json.arn,
        ]
      }
    ]
  })
}

resource "aws_iam_role_policy_attachment" "ecs_kinesis_policy_attachment" {
  role       = aws_iam_role.ecs_task_role.name
  policy_arn = aws_iam_policy.ecs_kinesis_policy.arn
}

resource "aws_iam_policy" "firelens_policy" {
  name        = "${var.project_name}-firelens-policy"
  description = "Policy for FireLens (Fluent Bit) to send logs to Firehose and S3"

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "firehose:PutRecord",
          "firehose:PutRecordBatch"
        ]
        Resource = [
          aws_kinesis_firehose_delivery_stream.api_logs_parquet.arn,
          aws_kinesis_firehose_delivery_stream.api_logs_json.arn,
        ]
      },
      {
        Effect = "Allow"
        Action = [
          "s3:PutObject",
          "s3:GetObject",
          "s3:ListBucket"
        ]
        Resource = [
          aws_s3_bucket.api_logs_json.arn,
          "${aws_s3_bucket.api_logs_json.arn}/*",
          aws_s3_bucket.api_logs_parquet.arn,
          "${aws_s3_bucket.api_logs_parquet.arn}/*",
          aws_s3_directory_bucket.api_logs_json_express.arn,
          "${aws_s3_directory_bucket.api_logs_json_express.arn}/*",
          aws_s3_directory_bucket.api_logs_parquet_express.arn,
          "${aws_s3_directory_bucket.api_logs_parquet_express.arn}/*",
        ]
      }
    ]
  })
}

resource "aws_iam_role_policy_attachment" "firelens_policy_attachment" {
  role       = aws_iam_role.ecs_task_role.name
  policy_arn = aws_iam_policy.firelens_policy.arn
}

resource "aws_iam_role" "glue_service_role" {
  name = "${var.project_name}-glue-service-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "glue.amazonaws.com"
        }
      }
    ]
  })

  tags = {
    Name    = "${var.project_name}-glue-service-role"
    Project = var.project_name
  }
}

resource "aws_iam_role_policy_attachment" "glue_service_role_attachment" {
  role       = aws_iam_role.glue_service_role.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSGlueServiceRole"
}

resource "aws_iam_policy" "glue_s3_policy" {
  name        = "${var.project_name}-glue-s3-policy"
  description = "Policy for Glue to access S3 buckets"

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "s3:GetObject",
          "s3:PutObject",
          "s3:DeleteObject",
          "s3:ListBucket"
        ]
        Resource = [
          aws_s3_bucket.api_logs_parquet.arn,
          "${aws_s3_bucket.api_logs_parquet.arn}/*",
          aws_s3_bucket.api_logs_json.arn,
          "${aws_s3_bucket.api_logs_json.arn}/*",
          aws_s3_directory_bucket.api_logs_parquet_express.arn,
          "${aws_s3_directory_bucket.api_logs_parquet_express.arn}/*",
          aws_s3_directory_bucket.api_logs_json_express.arn,
          "${aws_s3_directory_bucket.api_logs_json_express.arn}/*",
          aws_s3_bucket.athena_query_results.arn,
          "${aws_s3_bucket.athena_query_results.arn}/*"
        ]
      }
    ]
  })
}

resource "aws_iam_role_policy_attachment" "glue_s3_policy_attachment" {
  role       = aws_iam_role.glue_service_role.name
  policy_arn = aws_iam_policy.glue_s3_policy.arn
}

resource "aws_iam_policy" "athena_policy" {
  name        = "${var.project_name}-athena-policy"
  description = "Policy for Athena to query S3 buckets and Glue tables"

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "athena:*"
        ]
        Resource = [
          "arn:aws:athena:${var.aws_region}:*:workgroup/${aws_athena_workgroup.api_logs.name}"
        ]
      },
      {
        Effect = "Allow"
        Action = [
          "glue:GetDatabase",
          "glue:GetDatabases",
          "glue:GetTable",
          "glue:GetTables",
          "glue:GetPartition",
          "glue:GetPartitions",
          "glue:BatchGetPartition"
        ]
        Resource = [
          "arn:aws:glue:${var.aws_region}:*:catalog",
          "arn:aws:glue:${var.aws_region}:*:database/builders_flash_logs",
          "arn:aws:glue:${var.aws_region}:*:table/builders_flash_logs/*"
        ]
      }
    ]
  })
}

resource "aws_iam_role_policy_attachment" "firehose_athena_policy_attachment" {
  role       = aws_iam_role.firehose_role.name
  policy_arn = aws_iam_policy.athena_policy.arn
}
