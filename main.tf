locals {
  id_store_group_list = [
    for id_store_group in data.aws_identitystore_group.this : {
      group_id = id_store_group.group_id
    }
  ]
  id_store_user_list = [
    for id_store_user in data.aws_identitystore_user.this : {
      user_id = id_store_user.user_id
    }
  ]
  group_assignments_in_accounts = { for p in setproduct(local.id_store_group_list.*.group_id, var.account_ids) : "${p[0]}/${p[1]}" => {
    principal_group_id = p[0]
    account_ids        = p[1]
    }
  }
  user_assignments_in_accounts = { for p in setproduct(local.id_store_user_list.*.user_id, var.account_ids) : "${p[0]}/${p[1]}" => {
    principal_user_id = p[0]
    account_ids       = p[1]
    }
  }
}

# My understanding is that each AWS account has one 'instance' of
# SSO, so this is just pulling the data about its configuration.
data "aws_ssoadmin_instances" "organization_management_account" {}

resource "aws_ssoadmin_permission_set" "this" {
  name             = var.permission_set_name
  description      = var.description
  instance_arn     = tolist(data.aws_ssoadmin_instances.organization_management_account.arns)[0]
  relay_state      = var.relay_state
  session_duration = var.session_duration
  tags             = module.label.tags
}

resource "aws_ssoadmin_permission_set_inline_policy" "this" {
  count = var.inline_policy == "" ? 0 : 1

  instance_arn       = aws_ssoadmin_permission_set.this.instance_arn
  permission_set_arn = aws_ssoadmin_permission_set.this.arn
  inline_policy      = var.inline_policy
}

resource "aws_ssoadmin_managed_policy_attachment" "this" {
  for_each           = toset(var.managed_policies)
  instance_arn       = aws_ssoadmin_permission_set.this.instance_arn
  permission_set_arn = aws_ssoadmin_permission_set.this.arn
  managed_policy_arn = each.value
}

data "aws_identitystore_group" "this" {
  for_each          = toset(var.principal_group_id)
  identity_store_id = tolist(data.aws_ssoadmin_instances.organization_management_account.identity_store_ids)[0]

  filter {
    attribute_path  = "DisplayName"
    attribute_value = each.value
  }
}

data "aws_identitystore_user" "this" {
  for_each          = toset(var.principal_user_id)
  identity_store_id = tolist(data.aws_ssoadmin_instances.organization_management_account.identity_store_ids)[0]

  filter {
    attribute_path  = "UserName"
    attribute_value = each.value
  }
}

resource "aws_ssoadmin_account_assignment" "group" {
  for_each           = local.group_assignments_in_accounts
  instance_arn       = aws_ssoadmin_permission_set.this.instance_arn
  permission_set_arn = aws_ssoadmin_permission_set.this.arn
  principal_id       = each.value.principal_group_id
  principal_type     = "GROUP"
  target_id          = each.value.account_ids
  target_type        = "AWS_ACCOUNT"
}

resource "aws_ssoadmin_account_assignment" "user" {
  for_each           = local.user_assignments_in_accounts
  instance_arn       = aws_ssoadmin_permission_set.this.instance_arn
  permission_set_arn = aws_ssoadmin_permission_set.this.arn
  principal_id       = each.value.principal_user_id
  principal_type     = "USER"
  target_id          = each.value.account_ids
  target_type        = "AWS_ACCOUNT"
}

module "label" {
  source = "git::https://github.com/getwilbur/terraform-null-label.git?ref=tags/0.25.0"
  tags   = var.tags
}
