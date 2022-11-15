variable "destination_bucket_name" {
  default = "ph-sanity-generated-video"
}

resource "aws_s3_bucket" "destination" {
  bucket = var.destination_bucket_name
}