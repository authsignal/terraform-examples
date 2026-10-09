resource "authsignal_flow" "sign_in" {
  action_code = "sign-in"
  flow = jsonencode({
    actionNodes = [
      {
        nodeId        = "evaluate-risk"
        nodeType      = "RULE"
        parentNodeIds = []
        ruleChildNodeIds = [
          [
            "anonymous-ip",
            "block-request"
          ],
          [
            "new-device",
            "verify-identity"
          ]
        ]
        elseChildNodeId = "complete-sign-in"
      },
      {
        nodeId   = "verify-identity"
        nodeType = "VERIFICATION"
        parentNodeIds = [
          "evaluate-risk"
        ]
        name = "Confirm it is you signing in"
        methodConfigurations = {
          PASSKEY = {
            isEnabled = true
          }
        }
        childNodeId = "complete-sign-in"
      },
      {
        nodeId   = "block-request"
        nodeType = "BLOCK"
        parentNodeIds = [
          "evaluate-risk"
        ]
      },
      {
        nodeId   = "complete-sign-in"
        nodeType = "COMPLETE"
        parentNodeIds = [
          "evaluate-risk",
          "verify-identity"
        ]
      }
    ]
    rules = [
      {
        ruleId = "anonymous-ip"
        name   = "Anonymous IP"
        conditions = {
          and = [
            {
              "==" = [
                {
                  var = "ip.isAnonymous"
                },
                true
              ]
            }
          ]
        }
      },
      {
        ruleId = "new-device"
        name   = "New device"
        conditions = {
          and = [
            {
              "==" = [
                {
                  var = "device.isNew"
                },
                true
              ]
            }
          ]
        }
      }
    ]
  })

  depends_on = [authsignal_passkey_authenticator_configuration.passkey]
}
