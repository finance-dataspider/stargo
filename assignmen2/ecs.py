from aws_cdk import (
    aws_ecs as ecs,
    aws_ec2 as ec2,
    core
)
import json



class ServiceStack(core.Stack):

    def __init__(self, scope: core.Construct, id: str, cluster: ecs.Cluster, service_name: str, **kwargs) -> None:
        super().__init__(scope, id, **kwargs)

        # Load environment variables from JSON file
        with open(f"{service_name}_env.json") as json_file:
            env_vars = json.load(json_file)

        # Create ECS Task Definition
        task_definition = ecs.FargateTaskDefinition(self, f"{service_name}TaskDef")

        # Add container to the task definition
        container = task_definition.add_container(
            f"{service_name}Container",
            image=ecs.ContainerImage.from_registry("nginx:latest"),
            environment=env_vars
        )

        # Create ECS Service
        service = ecs.FargateService(self, f"{service_name}Service",
                                     cluster=cluster,
                                     task_definition=task_definition)

class ECSClusterStack(core.Stack):

    def __init__(self, scope: core.Construct, id: str, **kwargs) -> None:
        super().__init__(scope, id, **kwargs)

        # create vpc
        vpc = ec2.Vpc(self, "MyVPC", max_azs=2)
        # Create ECS Cluster
        cluster = ecs.Cluster(self, "MyECSCluster", vpc=vpc)

        # Create Service 1
        service1_stack = ServiceStack(self, "Service1Stack", cluster=cluster, service_name="Service1")

        # Create Service 2
        service2_stack = ServiceStack(self, "Service2Stack", cluster=cluster, service_name="Service2")
