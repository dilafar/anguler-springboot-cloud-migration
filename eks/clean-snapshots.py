import boto3
from operator import itemgetter

client = boto3.client('ec2', region_name="us-east-1")

volumes = client.describe_volumes(
        Filters=[
            {
                'Name': 'tag:Name',
                'Values': ['eksdemo-eksdemo-ng-private-Node']
            }
        ]
    )
for volume in volumes['Volumes']:

    snapshots = client.describe_snapshots(
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

    sorted_by_date = sorted(snapshots['Snapshots'], key=itemgetter('StartTime'),reverse=True)

    for snap in sorted_by_date[2:]:
        response = client.delete_snapshot(
            SnapshotId=snap['SnapshotId']
        )
        print(response)

