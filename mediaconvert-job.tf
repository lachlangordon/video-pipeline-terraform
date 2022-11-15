variable "mediaconvert_job_name" {
  default = "sanity-video-job"
}

data "aws_iam_policy_document" "mediaconvert_role_policy_document" {
  statement {
    sid     = "AllowAssumeRole"
    actions = ["sts:AssumeRole"]
    principals {
      type        = "Service"
      identifiers = ["mediaconvert.amazonaws.com"]
    }
  }
}

resource "aws_iam_role" "mediaconvert_role" {
  name               = "${var.mediaconvert_job_name}-role"
  description        = "Enables MediaConvert jobs to access input and output buckets for Sanity video"
  assume_role_policy = data.aws_iam_policy_document.mediaconvert_role_policy_document.json
}

data "aws_iam_policy_document" "mediaconvert_role_s3_policy_document" {
  statement {
    sid       = "GetObjectsFromSource"
    actions   = ["s3:Get*", "s3:List*"]
    resources = ["${aws_s3_bucket.source.arn}/*"]
  }
  statement {
    sid       = "PutObjectsInDestination"
    actions   = ["s3:Put*"]
    resources = ["${aws_s3_bucket.destination.arn}/*"]
  }
}

resource "aws_iam_policy" "mediaconvert_s3_policy" {
  name   = "${var.mediaconvert_job_name}-s3-policy"
  policy = data.aws_iam_policy_document.mediaconvert_role_s3_policy_document.json
}

resource "aws_iam_role_policy_attachment" "mediaconvert_s3_policy_attachment" {
  role       = aws_iam_role.mediaconvert_role.name
  policy_arn = aws_iam_policy.mediaconvert_s3_policy.arn
}

resource "aws_media_convert_queue" "queue" {
  name   = "${var.mediaconvert_job_name}-queue"
  status = "ACTIVE"
}