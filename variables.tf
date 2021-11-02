variable "account_ids" {
  type        = list(string)
  description = "An AWS account identifier, typically a 10-12 digit string."
}
variable "description" {
  type        = string
  description = "The description of the Permission Set."
}
variable "inline_policy" {
  type        = string
  description = "Inline policy as JSON. LIMIT 1 per permission set."
  default     = ""
}
variable "managed_policies" {
  type        = list(string)
  description = "List of AWS managed policies."
  default     = []
}
variable "permission_set_name" {
  type        = string
  description = "Descriptive name of permission set."
}
variable "principal_group_id" {
  type        = list(string)
  description = "The Active Directory group the permission set will be applied to."
  default     = []
}
variable "principal_user_id" {
  type        = list(string)
  description = "The Active Directory user the permission set will be applied to."
  default     = []
}
variable "relay_state" {
  type        = string
  description = "The relay state URL used to redirect users within the application during the federation authentication process."
  default     = null
}
variable "session_duration" {
  type        = string
  description = "The lenght of the session. ISO-8601 standard."
}
variable "tags" {
  default     = {}
  description = "Resource tags"
  type        = map(string)
}
