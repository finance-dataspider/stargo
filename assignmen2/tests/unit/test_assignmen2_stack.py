import aws_cdk as core
import aws_cdk.assertions as assertions

from assignmen2.assignmen2_stack import Assignmen2Stack

# example tests. To run these tests, uncomment this file along with the example
# resource in assignmen2/assignmen2_stack.py
def test_sqs_queue_created():
    app = core.App()
    stack = Assignmen2Stack(app, "assignmen2")
    template = assertions.Template.from_stack(stack)

#     template.has_resource_properties("AWS::SQS::Queue", {
#         "VisibilityTimeout": 300
#     })
