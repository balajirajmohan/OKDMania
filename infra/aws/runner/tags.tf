locals {
  # Provider default_tags merge onto every taggable AWS resource.
  # Resource-level `tags` (usually just Name) are merged on top; same key → resource wins.
  aws_default_tags = merge(
    {
      Project   = "OKD-Project"
      Component = "github-runner"
      ManagedBy = "terraform"
      Decision  = "D034"
    },
    var.additional_tags,
    {
      Purpose = "okdmania"
    },
  )
}
