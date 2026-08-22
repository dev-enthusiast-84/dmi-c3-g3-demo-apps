#!/usr/bin/env python3
"""
AWS EC2 Instance Launcher with User Data
Launches an EC2 instance with the web application user data script
"""

import argparse
import base64
import time
import sys
from pathlib import Path
import boto3
from botocore.exceptions import ClientError


def read_user_data_script():
    """Read the user data script from file"""
    script_path = Path(__file__).parent / "userdata-for-console.sh"
    if not script_path.exists():
        print(f"Error: User data script not found at {script_path}")
        sys.exit(1)

    with open(script_path, 'r') as f:
        return f.read()


def create_security_group(ec2_client, group_name, vpc_id=None):
    """Create a security group for the web server"""
    try:
        sg_params = {
            'GroupName': group_name,
            'Description': 'Security group for web application with database access'
        }
        if vpc_id:
            sg_params['VpcId'] = vpc_id

        response = ec2_client.create_security_group(**sg_params)
        sg_id = response['GroupId']
        print(f"✓ Created security group: {sg_id}")

        # Add ingress rules
        ec2_client.authorize_security_group_ingress(
            GroupId=sg_id,
            IpPermissions=[
                {
                    'IpProtocol': 'tcp',
                    'FromPort': 80,
                    'ToPort': 80,
                    'IpRanges': [{'CidrIp': '0.0.0.0/0', 'Description': 'HTTP'}]
                },
                {
                    'IpProtocol': 'tcp',
                    'FromPort': 443,
                    'ToPort': 443,
                    'IpRanges': [{'CidrIp': '0.0.0.0/0', 'Description': 'HTTPS'}]
                },
                {
                    'IpProtocol': 'tcp',
                    'FromPort': 22,
                    'ToPort': 22,
                    'IpRanges': [{'CidrIp': '0.0.0.0/0', 'Description': 'SSH'}]
                }
            ]
        )
        print(f"✓ Added ingress rules to security group")
        return sg_id

    except ClientError as e:
        if 'InvalidGroup.Duplicate' in str(e):
            print(f"Security group '{group_name}' already exists")
            sgs = ec2_client.describe_security_groups(GroupNames=[group_name])
            return sgs['SecurityGroups'][0]['GroupId']
        else:
            raise


def launch_instance(
    region,
    db_endpoint,
    db_user,
    db_password,
    db_name,
    key_pair,
    instance_type='t3.micro',
    security_group_id=None,
    create_sg=True,
    wait_for_running=True
):
    """Launch an EC2 instance with user data"""

    # Initialize EC2 client
    ec2 = boto3.client('ec2', region_name=region)
    ec2_resource = boto3.resource('ec2', region_name=region)

    print(f"\n{'='*60}")
    print("AWS EC2 Instance Launcher")
    print(f"{'='*60}\n")

    print(f"Configuration:")
    print(f"  Region: {region}")
    print(f"  Instance Type: {instance_type}")
    print(f"  Database Endpoint: {db_endpoint}")
    print(f"  Database Name: {db_name}")
    print(f"  Key Pair: {key_pair}")

    # Verify key pair exists
    try:
        ec2.describe_key_pairs(KeyNames=[key_pair])
        print(f"✓ Key pair '{key_pair}' found")
    except ClientError:
        print(f"✗ Key pair '{key_pair}' not found in region {region}")
        print(f"  Create a key pair first: aws ec2 create-key-pair --key-name {key_pair}")
        sys.exit(1)

    # Get or create security group
    if not security_group_id and create_sg:
        sg_name = 'web-app-sg'
        security_group_id = create_security_group(ec2, sg_name)

    if not security_group_id:
        print("✗ No security group specified and auto-create disabled")
        sys.exit(1)

    # Get Ubuntu 22.04 LTS AMI for the region
    ami_response = ec2.describe_images(
        Owners=['099720109477'],  # Canonical owner
        Filters=[
            {'Name': 'name', 'Values': ['ubuntu/images/hvm-ssd/ubuntu-jammy-22.04-amd64-server-*']},
            {'Name': 'state', 'Values': ['available']},
            {'Name': 'root-device-type', 'Values': ['ebs']}
        ]
    )

    if not ami_response['Images']:
        print("✗ No Ubuntu 22.04 LTS AMI found for this region")
        sys.exit(1)

    ami_id = sorted(ami_response['Images'], key=lambda x: x['CreationDate'])[-1]['ImageId']
    print(f"✓ Found Ubuntu 22.04 LTS AMI: {ami_id}")

    # Prepare user data
    user_data_script = read_user_data_script()

    # Inject database configuration into user data
    user_data_with_config = (
        f"#!/bin/bash\n"
        f"DB_ENDPOINT='{db_endpoint}'\n"
        f"DB_USER='{db_user}'\n"
        f"DB_PASSWORD='{db_password}'\n"
        f"DB_NAME='{db_name}'\n"
        f"DB_PORT='3306'\n"
    ) + user_data_script.split('\n', 1)[1]  # Skip the original shebang

    print(f"\n{'='*60}")
    print("Launching Instance...")
    print(f"{'='*60}\n")

    # Launch instance
    response = ec2.run_instances(
        ImageId=ami_id,
        MinCount=1,
        MaxCount=1,
        InstanceType=instance_type,
        KeyName=key_pair,
        SecurityGroupIds=[security_group_id],
        UserData=user_data_with_config,
        TagSpecifications=[
            {
                'ResourceType': 'instance',
                'Tags': [
                    {'Key': 'Name', 'Value': 'web-app-instance'},
                    {'Key': 'Application', 'Value': 'hit-counter'},
                    {'Key': 'LaunchedBy', 'Value': 'launch-instance.py'}
                ]
            }
        ]
    )

    instance_id = response['Instances'][0]['InstanceId']
    print(f"✓ Instance launched: {instance_id}")

    if not wait_for_running:
        print(f"\nInstance is launching. Check AWS Console for status.")
        print(f"Instance ID: {instance_id}")
        return instance_id

    # Wait for instance to be running
    print("\nWaiting for instance to start (this may take 1-2 minutes)...")

    instance = ec2_resource.Instance(instance_id)
    instance.wait_until_running()
    instance.reload()

    public_ip = instance.public_ip_address
    private_ip = instance.private_ip_address

    print(f"✓ Instance is running")
    print(f"\nInstance Details:")
    print(f"  Instance ID: {instance_id}")
    print(f"  Public IP: {public_ip}")
    print(f"  Private IP: {private_ip}")
    print(f"  Security Group: {security_group_id}")

    # Wait for status checks
    print(f"\nWaiting for system status checks (this may take 3-5 minutes)...")
    waiter = ec2.get_waiter('instance_status_ok')
    waiter.wait(InstanceIds=[instance_id])

    print(f"✓ Instance status checks passed")

    print(f"\n{'='*60}")
    print("Instance Successfully Launched!")
    print(f"{'='*60}\n")

    print(f"Access your application at:")
    print(f"  http://{public_ip}")
    print(f"\nSSH into the instance:")
    print(f"  ssh -i /path/to/{key_pair}.pem ubuntu@{public_ip}")
    print(f"\nView application logs:")
    print(f"  ssh -i /path/to/{key_pair}.pem ubuntu@{public_ip} 'sudo journalctl -u app -f'")
    print(f"\nView user data logs:")
    print(f"  ssh -i /path/to/{key_pair}.pem ubuntu@{public_ip} 'sudo tail -f /var/log/user-data.log'")

    print(f"\nNote: The application may take 2-3 minutes to fully initialize.")
    print(f"      If you get a 502 error, wait a bit and refresh.")

    print(f"\nWhen done, terminate the instance:")
    print(f"  aws ec2 terminate-instances --instance-ids {instance_id} --region {region}")

    return instance_id, public_ip


def main():
    parser = argparse.ArgumentParser(
        description='Launch an EC2 instance with web application and database'
    )

    parser.add_argument(
        '--region',
        default='us-east-1',
        help='AWS region (default: us-east-1)'
    )

    parser.add_argument(
        '--db-endpoint',
        required=True,
        help='RDS database endpoint (e.g., mydb.xxxxx.us-east-1.rds.amazonaws.com)'
    )

    parser.add_argument(
        '--db-user',
        default='admin',
        help='Database username (default: admin)'
    )

    parser.add_argument(
        '--db-password',
        required=True,
        help='Database password (use strong password!)'
    )

    parser.add_argument(
        '--db-name',
        default='hitcounter',
        help='Database name (default: hitcounter)'
    )

    parser.add_argument(
        '--key-pair',
        required=True,
        help='EC2 key pair name'
    )

    parser.add_argument(
        '--instance-type',
        default='t3.micro',
        help='EC2 instance type (default: t3.micro)'
    )

    parser.add_argument(
        '--security-group-id',
        help='Security group ID (creates one if not provided)'
    )

    parser.add_argument(
        '--no-wait',
        action='store_true',
        help='Do not wait for instance to be running'
    )

    args = parser.parse_args()

    # Warn about password in command line
    print("⚠️  Warning: Passing password via command line is not secure.")
    print("   For production, use AWS Secrets Manager or environment variables.")
    print()

    launch_instance(
        region=args.region,
        db_endpoint=args.db_endpoint,
        db_user=args.db_user,
        db_password=args.db_password,
        db_name=args.db_name,
        key_pair=args.key_pair,
        instance_type=args.instance_type,
        security_group_id=args.security_group_id,
        wait_for_running=not args.no_wait
    )


if __name__ == '__main__':
    main()
