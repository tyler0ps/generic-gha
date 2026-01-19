variable "repositories" {
  description = "Map of ECR repositories to create"
  type = map(object({
    name                 = string
    image_tag_mutability = optional(string, "MUTABLE")
    scan_on_push         = optional(bool, true)
  }))
}

variable "force_delete" {
  description = "Allow deleting repositories with images (for easy destruction)"
  type        = bool
  default     = true
}

variable "images_to_keep" {
  description = "Number of images to keep per repository"
  type        = number
  default     = 10
}

variable "tags" {
  description = "Tags to apply to all resources"
  type        = map(string)
  default     = {}
}
