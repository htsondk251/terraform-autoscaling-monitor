//dashboard
resource "aws_cloudwatch_dashboard" "monitor-ASG" {
  dashboard_name = "monitor-ASG"

  dashboard_body = jsonencode({
    widgets = [
      {
        type   = "metric"
        x      = 0
        y      = 0
        width  = 12
        height = 6

        properties = {
          metrics = [
            [
              "AWS/EC2",
              "CPUUtilization",
              "AutoScalingGroupName",
              aws_autoscaling_group.example.id
            ]
          ]
          period = 60
          stat   = "Average"
          region = var.region
          title  = "ASG Average CPUUtilization"
        }
      },
      {
        type   = "metric"
        x      = 12
        y      = 0
        width  = 12
        height = 6

        properties = {
          metrics = [
            [
              "AWS/AutoScaling",
              "GroupInServiceInstances",
              "AutoScalingGroupName",
              aws_autoscaling_group.example.id
            ]
          ]
          period = 60
          stat   = "Average"
          region = var.region
          title  = "ASG Average Instances"
        }
      }
    ]
  })
}