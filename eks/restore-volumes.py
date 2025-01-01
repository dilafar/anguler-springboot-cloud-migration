import boto3
from operator import itemgetter

ec2_client = boto3.client('ec2', region_name="us-east-1")
ec2_resource = boto3.resource('ec2', region_name="us-east-1")

instances = ec2_client.describe_instances(
    Filters=[
            {
                'Name': 'tag:Name',
                'Values': ['eksdemo-eksdemo-ng-private-Node']
            }
        ]
)

for reservation in instances['Reservations']:
    for instance in reservation['Instances']:
        print(instance['InstanceId'])

        volumes = ec2_client.describe_volumes(
            Filters=[
                    {
                        'Name': 'attachment.instance-id',
                        'Values': [instance['InstanceId']]
                    }
                ]
        )
        for volume in volumes['Volumes']:
            print(volume['VolumeId'])
            snapshots = ec2_client.describe_snapshots(
                    OwnerIds=[
                        'self',
                    ],
                    Filters=[
                        {
                            'Name': 'volume-id',
                            'Values': [volume['VolumeId']]
                        }
                    ]
            )
            latest_snap_shot = sorted(snapshots['Snapshots'], key=itemgetter('StartTime'),reverse=True)[0]
            new_volume = ec2_client.create_volume(
                AvailabilityZone=volume['AvailabilityZone'],
                SnapshotId=latest_snap_shot['SnapshotId'],
                TagSpecifications=[
                        {
                            'ResourceType': 'volume',
                            'Tags': [
                                {
                                    'Key': 'Name',
                                    'Value': 'eksdemo-eksdemo-ng-private-Node'
                                },
                            ]
                        },
                    ]
            )
            while True:
                vol = ec2_resource.Volume(new_volume['VolumeId'])
                print(vol.state)
                if vol.state == 'available':
                    ec2_resource.Instance(instance['InstanceId']).attach_volume(
                        VolumeId=new_volume['VolumeId'],
                        Device='/dev/xvdb'
                    )
                    break
            print("######################################################")
            print("successfully restored ......")