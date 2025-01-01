import boto3
import schedule

client = boto3.client('ec2', region_name="us-east-1")


def create_volume_snapshot():
    volumes = client.describe_volumes(
        Filters=[
            {
                'Name': 'tag:Name',
                'Values': ['eksdemo-eksdemo-ng-private-Node']
            }
        ]
    )
    for volume in volumes['Volumes']:
        snapshot = client.create_snapshot(
            VolumeId=volume['VolumeId']
        )
        print(snapshot)

schedule.every(20).seconds.do(create_volume_snapshot)

while True:
    schedule.run_pending()