#!/bin/bash

# Creating VPC security group, start instace "ec2", install "Nginx" deploy castom start page abd get public IP instance



# Step 1: Create a VPC and subnets
# Create a VPC with a 10.0.0.0/16 CIDR block and name "My-VPC"

#aws ec2 create-vpc --tag-specifications My-VPC --cidr-block 10.0.0.0/16

VPC_ID=$(aws ec2 create-vpc --cidr-block 10.0.0.0/16 \
--query 'Vpc.{VpcId:VpcId}' --output text)
aws ec2 create-tags --resources $VPC_ID --tags Key=Name,Value=My-vpc

echo "
Created VPC, ID: $VPC_ID"

# Using the VPC ID from the previous step, create two subnet with a 10.0.10.0/24 and 10.0.20.0/24 CIDR block 
PUB_SUB=$(aws ec2 create-subnet \
--vpc-id $VPC_ID --cidr-block 10.0.10.0/24 \
--query 'Subnet.{SubnetId:SubnetId}' \
--output text)
aws ec2 create-tags --resources $PUB_SUB --tags Key=Name,Value=Public
PRIV_SUB=$(aws ec2 create-subnet \
--vpc-id $VPC_ID --cidr-block 10.0.20.0/24 \
--query 'Subnet.{SubnetId:SubnetId}' \
--output text)
aws ec2 create-tags --resources $PRIV_SUB --tags Key=Name,Value=Privat

echo "
Created Public Subnet, ID: $PUB_SUB
Created Privat Subnet, ID: $PRIV_SUB"

# Step 2: Make subnet public

# Enable Auto-assign Public IP on Public Subnet
aws ec2 modify-subnet-attribute \
--subnet-id $PUB_SUB \
--map-public-ip-on-launch

# Create an Internet gateway.
IGW=$(aws ec2 create-internet-gateway \
--query 'InternetGateway.{InternetGatewayId:InternetGatewayId}' \
--output text)
echo "
Internet gateway ID: $IGW"

# attach the Internet gateway to "My-vpc"
aws ec2 attach-internet-gateway --vpc-id $VPC_ID --internet-gateway-id $IGW

# Add a tag to the Internet-Gateway
aws ec2 create-tags \
--resources $IGW \
--tags "Key=Name,Value=My-vpc-IGW"

# Create a custom route table for VPC.
RTB=$(aws ec2 create-route-table \
--vpc-id $VPC_ID \
--query 'RouteTable.{RouteTableId:RouteTableId}' \
--output text)
echo "
Route Table ID: $RTB"
aws ec2 create-tags --resources $RTB --tags Key=Name,Value=Castom-RT

# Add a tag to the default route table
DEFAULT_RTB=$(aws ec2 describe-route-tables \
--filters "Name=vpc-id,Values=$VPC_ID" \
--query 'RouteTables[?Associations[0].Main != `flase`].RouteTableId' \
--output text) &&
aws ec2 create-tags \
--resources $DEFAULT_RTB \
--tags "Key=Name,Value=local-route-table"

# Create a route in the route table that points all traffic (0.0.0.0/0) to the Internet gateway.
aws ec2 create-route --route-table-id $RTB --destination-cidr-block 0.0.0.0/0 --gateway-id $IGW

# To confirm that your route has been created and is active, you can describe the route table and view the results.        !!!!!!!
aws ec2 describe-route-tables --route-table-id $RTB

# choose subnet to associate with the custom route table. This subnet will be public subnet.
aws ec2 associate-route-table  --subnet-id $PUB_SUB --route-table-id $RTB

#Step 3: security groups.

echo "
Create a custom security group"

#Create a custom security group
aws ec2 create-security-group \
--vpc-id $VPC_ID \
--group-name my-sec-group \
--description 'My VPC non default security group'

#Get security group ID’s.
DEFAULT_SG_ID=$(aws ec2 describe-security-groups \
--filters "Name=vpc-id,Values=$VPC_ID" \
--query 'SecurityGroups[?GroupName == `default`].GroupId' \
--output text) &&
CUSTOM_SG_ID=$(aws ec2 describe-security-groups \
--filters "Name=vpc-id,Values=$VPC_ID" \
--query 'SecurityGroups[?GroupName == `my-sec-group`].GroupId' \
--output text)

# Add a tags to security groups
aws ec2 create-tags --resources $DEFAULT_SG_ID --tags Key=Name,Value=My-vpc-default-SG
aws ec2 create-tags --resources $CUSTOM_SG_ID --tags Key=Name,Value=My-vpc-castom-SG

echo "
Default security group ID: $DEFAULT_SG_ID
Castom security group ID: $CUSTOM_SG_ID"

# reading my public IP
 MY_IP=$(wget -qO- checkip.amazonaws.com)

# Create ingress rules for custom security group.
aws ec2 authorize-security-group-ingress --group-id $CUSTOM_SG_ID --protocol tcp --port 22 --cidr $MY_IP/32
aws ec2 authorize-security-group-ingress --group-id $CUSTOM_SG_ID --protocol tcp --port 80 --cidr $MY_IP/32

#aws ec2 authorize-security-group-ingress \
#--group-id $CUSTOM_SG_ID \
#--ip-permissions '[{"IpProtocol": "tcp", "FromPort": 22, "ToPort": 22, "IpRanges": [{"CidrIp": "0.0.0.0/0", "Description": "Allow SSH"}]}]' &&
#aws ec2 authorize-security-group-ingress \
#--group-id $CUSTOM_SG_ID \
#--ip-permissions '[{"IpProtocol": "tcp", "FromPort": 80, "ToPort": 80, "IpRanges": [{"CidrIp": "0.0.0.0/0", "Description": "Allow HTTP"}]}]'

echo "
VPC_ID: $VPC_ID
PUB_SUB: $PUB_SUB
PRIV_SUB: $PRIV_SUB
IGW: $IGW
RTB: $RTB
DEFAULT_SG_ID: $DEFAULT_SG_ID
CUSTOM_SG_ID: $CUSTOM_SG_ID"


#Step 5: Create NAT gateways

aws ec2 allocate-address --domain vpc
EL_IP=$(aws ec2 describe-addresses --query 'Addresses[*].AllocationId' --output text)

aws ec2 create-nat-gateway --subnet-id $PUB_SUB --allocation-id $EL_IP


#Step 5: Create instances.

echo "
Create instance."

aws ec2 run-instances --image-id ami-0767046d1677be5a0 --count 1 --instance-type t2.micro \
--key-name aws-test --security-group-ids $CUSTOM_SG_ID --subnet-id $PUB_SUB

# create instance Tag
#BASTION=$(aws ec2 describe-instances --query 'Reservations[*].Instances[*].InstanceId' --output text)
#aws ec2 create-tags --resources $DEFAULT_SG_ID --tags Key=Name,Value=My-vpc-default-SG

aws ec2 run-instances --image-id ami-0767046d1677be5a0 --count 1 --instance-type t2.micro \
--key-name aws-test --security-group-ids $DEFAULT_SG_ID --subnet-id $PRIV_SUB

#PublicIpAddress
echo "
Public IP address:"
aws ec2 describe-instances --query 'Reservations[*].Instances[*].PublicIpAddress' --output text 

echo "
VPC_ID: $VPC_ID
PUB_SUB: $PUB_SUB
PRIV_SUB: $PRIV_SUB
IGW: $IGW
RTB: $RTB
DEFAULT_SG_ID: $DEFAULT_SG_ID
CUSTOM_SG_ID: $CUSTOM_SG_ID"

# Step 6: create script for delete all
echo "
VPC_ID=$VPC_ID
PUB_SUB=$PUB_SUB
PRIV_SUB=$PRIV_SUB
IGW=$IGW
RTB=$RTB
DEFAULT_SG_ID=$DEFAULT_SG_ID
CUSTOM_SG_ID=$CUSTOM_SG_ID

aws ec2 delete-security-group \
--group-id $CUSTOM_SG_ID
 
## Delete internet gateway
aws ec2 detach-internet-gateway \
--internet-gateway-id $IGW \
--vpc-id $VPC_ID &&
aws ec2 delete-internet-gateway \
--internet-gateway-id $IGW
 
## Delete the custom route table
aws ec2 disassociate-route-table \
--association-id $VPC_ID &&
aws ec2 delete-route-table \
--route-table-id $RTB
 
## Delete the public subnet
aws ec2 delete-subnet \
--subnet-id $PUB_SUB

## Delete the privat subnet
aws ec2 delete-subnet \
--subnet-id $PRIV_SUB
 
## Delete the vpc
aws ec2 delete-vpc \
--vpc-id $VPC_ID" > delete.sh
