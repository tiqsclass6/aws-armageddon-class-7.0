# WAF A1 (top actions)
resource "aws_cloudwatch_query_definition" "bonus_g_waf_a1_top_actions" {
  count = var.enable_bonus_g_logs_insights_queries ? 1 : 0

  name            = "${var.project_name}-waf-a1-top-actions"
  log_group_names = [local.waf_log_group]

  query_string = <<-EOT
    fields @timestamp, action
    | stats count() as hits by action
    | sort hits desc
  EOT
}

# WAF A2 (top client IPs)
resource "aws_cloudwatch_query_definition" "bonus_g_waf_a2_top_client_ips" {
  count = var.enable_bonus_g_logs_insights_queries ? 1 : 0

  name            = "${var.project_name}-waf-a2-top-client-ips"
  log_group_names = [local.waf_log_group]

  query_string = <<-EOT
    fields @timestamp, httpRequest.clientIp as clientIp
    | stats count() as hits by clientIp
    | sort hits desc
    | limit 25
  EOT
}

# WAF A3 (top URIs)
resource "aws_cloudwatch_query_definition" "bonus_g_waf_a3_top_uris" {
  count = var.enable_bonus_g_logs_insights_queries ? 1 : 0

  name            = "${var.project_name}-waf-a3-top-uris"
  log_group_names = [local.waf_log_group]

  query_string = <<-EOT
    fields @timestamp, httpRequest.uri as uri
    | stats count() as hits by uri
    | sort hits desc
    | limit 25
  EOT
}

# WAF A4 (blocked only)
resource "aws_cloudwatch_query_definition" "bonus_g_waf_a4_blocked_only" {
  count = var.enable_bonus_g_logs_insights_queries ? 1 : 0

  name            = "${var.project_name}-waf-a4-blocked-only"
  log_group_names = [local.waf_log_group]

  query_string = <<-EOT
    fields @timestamp, action, httpRequest.clientIp as clientIp, httpRequest.uri as uri
    | filter action = "BLOCK"
    | stats count() as blocks by clientIp, uri
    | sort blocks desc
    | limit 25
  EOT
}

# WAF A5 (blocking rule)
resource "aws_cloudwatch_query_definition" "bonus_g_waf_a5_blocking_rule" {
  count = var.enable_bonus_g_logs_insights_queries ? 1 : 0

  name            = "${var.project_name}-waf-a5-blocking-rule"
  log_group_names = [local.waf_log_group]

  query_string = <<-EOT
    fields @timestamp, action, terminatingRuleId, terminatingRuleType
    | filter action = "BLOCK"
    | stats count() as blocks by terminatingRuleId, terminatingRuleType
    | sort blocks desc
    | limit 25
  EOT
}

# WAF A6/A7 (suspicious scanners - URIs commonly targeted by bots/scanners, with option to filter for blocked only)
resource "aws_cloudwatch_query_definition" "bonus_g_waf_a6_suspicious_scanners" {
  count = var.enable_bonus_g_logs_insights_queries ? 1 : 0

  name            = "${var.project_name}-waf-a6-suspicious-scanners"
  log_group_names = [local.waf_log_group]

  query_string = <<-EOT
    fields @timestamp, httpRequest.clientIp as clientIp, httpRequest.uri as uri
    | filter uri =~ /wp-login|xmlrpc|\\.env|admin|phpmyadmin|\\.git|login/
    | stats count() as hits by clientIp, uri
    | sort hits desc
    | limit 50
  EOT
}

# WAF A8 (country of origin)
resource "aws_cloudwatch_query_definition" "bonus_g_waf_a8_country" {
  count = var.enable_bonus_g_logs_insights_queries ? 1 : 0

  name            = "${var.project_name}-waf-a8-country"
  log_group_names = [local.waf_log_group]

  query_string = <<-EOT
    fields @timestamp, httpRequest.country as country
    | stats count() as hits by country
    | sort hits desc
    | limit 25
  EOT
}

# APP B1 (errors over time)
resource "aws_cloudwatch_query_definition" "bonus_g_app_b1_errors_over_time" {
  count = var.enable_bonus_g_logs_insights_queries ? 1 : 0

  name            = "${var.project_name}-app-b1-errors-over-time"
  log_group_names = [local.app_log_group]

  query_string = <<-EOT
    fields @timestamp, @message
    | filter @message like /(?i)\b(ERROR|Exception|Traceback|timeout|refused)\b/
    | stats count() as error_count by bin(1m)
    | sort @timestamp asc
  EOT
}

# APP B2 (recent DB failures)
resource "aws_cloudwatch_query_definition" "bonus_g_app_b2_recent_db_failures" {
  count = var.enable_bonus_g_logs_insights_queries ? 1 : 0

  name            = "${var.project_name}-app-b2-recent-db-failures"
  log_group_names = [local.app_log_group]

  query_string = <<-EOT
    fields @timestamp, @message
    | filter @message like /(?i)DB|mysql|timeout|refused|Access denied|could not connect/
    | sort @timestamp desc
    | limit 50
  EOT
}

# APP B3 (classifier)
resource "aws_cloudwatch_query_definition" "bonus_g_app_b3_classifier" {
  count = var.enable_bonus_g_logs_insights_queries ? 1 : 0

  name            = "${var.project_name}-app-b3-creds-vs-network"
  log_group_names = [local.app_log_group]

  query_string = <<-EOT
    fields @timestamp, @message
    | filter @message like /(?i)Access denied|authentication failed|timeout|refused|no route|could not connect/
    | stats count() as hits by
        case(
          @message like /(?i)Access denied|authentication failed/, "Creds/Auth",
          @message like /(?i)timeout|no route/, "Network/Route",
          @message like /(?i)refused/, "Port/SG/ServiceRefused",
          true, "Other"
        )
    | sort hits desc
  EOT
}

# APP B4 (JSON logs)
resource "aws_cloudwatch_query_definition" "bonus_g_app_b4_json_error_fields" {
  count = var.enable_bonus_g_logs_insights_queries ? 1 : 0

  name            = "${var.project_name}-app-b4-json-error-fields"
  log_group_names = [local.app_log_group]

  query_string = <<-EOT
    fields @timestamp, level, event, reason
    | filter level="ERROR"
    | stats count() as n by event, reason
    | sort n desc
  EOT
}