locals {

  access_policies = [
    for policy in var.access_policies : merge({
      azure_ad_user_principal_names    = []
      azure_ad_group_names             = []
      azure_ad_service_principal_names = []
      object_ids                       = []
      certificate_permissions          = []
      key_permissions                  = []
      secret_permissions               = []
      storage_permissions              = []
    }, policy)
  ]

  azure_ad_user_principal_names = distinct(flatten(local.access_policies[*].azure_ad_user_principal_names))
  azure_ad_user_object_ids      = { for obj in data.azuread_user.ad_users : lower(obj.user_principal_name) => obj.id }

  azure_ad_group_names      = distinct(flatten(local.access_policies[*].azure_ad_group_names))
  azure_ad_group_object_ids = { for obj in data.azuread_group.ad_groups : lower(obj.display_name) => obj.id }

  azure_ad_service_principal_names      = distinct(flatten(local.access_policies[*].azure_ad_service_principal_names))
  azure_ad_service_principal_object_ids = { for obj in data.azuread_service_principal.ad_service_principals : lower(obj.display_name) => obj.id }

  access_policies_flatten = concat(
    flatten([
      for policy in local.access_policies : flatten([
        for record in policy.object_ids : {
          object_id               = record
          certificate_permissions = policy.certificate_permissions
          key_permissions         = policy.key_permissions
          secret_permissions      = policy.secret_permissions
          storage_permissions     = policy.storage_permissions
        }
      ])
    ]),
    flatten([
      for policy in local.access_policies : flatten([
        for record in policy.azure_ad_user_principal_names : {
          object_id               = local.azure_ad_user_object_ids[lower(record)]
          certificate_permissions = policy.certificate_permissions
          key_permissions         = policy.key_permissions
          secret_permissions      = policy.secret_permissions
          storage_permissions     = policy.storage_permissions
        }
      ])
    ]),
    flatten([
      for policy in local.access_policies : flatten([
        for record in policy.azure_ad_group_names : {
          object_id               = local.azure_ad_group_object_ids[lower(record)]
          certificate_permissions = policy.certificate_permissions
          key_permissions         = policy.key_permissions
          secret_permissions      = policy.secret_permissions
          storage_permissions     = policy.storage_permissions
        }
      ])
    ]),
    flatten([
      for policy in local.access_policies : flatten([
        for record in policy.azure_ad_service_principal_names : {
          object_id               = local.azure_ad_service_principal_object_ids[lower(record)]
          certificate_permissions = policy.certificate_permissions
          key_permissions         = policy.key_permissions
          secret_permissions      = policy.secret_permissions
          storage_permissions     = policy.storage_permissions
        }
      ])
    ])
  )

  access_policies_key_value_pairs = { for policy in local.access_policies_flatten : policy.object_id => policy... }

  access_policies_distinct = [
    for key, value in local.access_policies_key_value_pairs : {
      object_id               = key
      certificate_permissions = distinct(flatten(value[*].certificate_permissions))
      key_permissions         = distinct(flatten(value[*].key_permissions))
      secret_permissions      = distinct(flatten(value[*].secret_permissions))
      storage_permissions     = distinct(flatten(value[*].storage_permissions))
    }
  ]

}