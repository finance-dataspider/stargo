from aws_cdk import core
from ecs import ECSClusterStack

app = core.App()
ECSClusterStack(app, "ECSClusterStack")
app.synth()
