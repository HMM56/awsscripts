#!/bin/bash
clear

# Creación VPC con salida de la ID.
VPC_ID=$(aws ec2 create-vpc --cidr-block 192.168.0.0/24 \
     --tag-specifications 'ResourceType=vpc,Tags=[{Key=Name,Value=Hector-VPC}]' \
     --query Vpc.VpcId --output text)

### Mostrar el ID de la VPC creada.
echo $VPC_ID

# Creación de la GW
 GW_ID=$(aws ec2 create-internet-gateway \
     --tag-specifications 'ResourceType=internet-gateway,Tags=[{Key=Name,Value=Hector-GW}]' \
     --query InternetGateway.InternetGatewayId --output text)

echo $GW_ID

## Enlazamos la puerta de enlace a la VPC que hemos creado
 aws ec2 attach-internet-gateway --internet-gateway-id $GW_ID --vpc-id $VPC_ID

## Habilitar el DNS en la VPC.
aws ec2 modify-vpc-attribute \
    --vpc-id $VPC_ID \
    --enable-dns-hostnames "{\"Value\":true}"

# Creación de la subred. Le damos 4 bits para subred.
SUB_ID=$(aws ec2 create-subnet \
    --vpc-id $VPC_ID \
    --cidr-block 192.168.0.0/28 \
    --tag-specifications 'ResourceType=subnet,Tags=[{Key=Name,Value=Hector-Subred}]' \
    --query Subnet.SubnetId --output text)

## Mostrar el ID de la Subred.
echo $SUB_ID

# Creación del grupo de seguridad
SG_ID=$(aws ec2 create-security-group --group-name My-SG \
    --description "Mi grupito de seguridad - 22P" \
    --vpc-id $VPC_ID \
    --output text)

SG_ID_ARN=$(echo $SG_ID | cut -d' ' -f2)
SG_ID=$(echo $SG_ID | cut -d' ' -f1)

## Autorización de abrir el puerto 22 para el grupo de seguridad
aws ec2 authorize-security-group-ingress \
    --group-id $SG_ID \
    --protocol tcp \
    --port 22 \
    --cidr 0.0.0.0/0 > /dev/null

aws ec2 authorize-security-group-ingress \
    --group-id $SG_ID \
    --protocol tcp \
    --port 80 \
    --cidr 0.0.0.0/0 > /dev/null

aws ec2 authorize-security-group-ingress \
    --group-id $SG_ID \
    --protocol tcp \
    --port 443 \
    --cidr 0.0.0.0/0 > /dev/null

echo $SG_ID

### Habilitar la asginación de IPv4 Pública en la subred
aws ec2 modify-subnet-attribute --subnet-id $SUB_ID --map-public-ip-on-launch 

EC2_ID=$(aws ec2 run-instances \
    --image-id ami-0ecb62995f68bb549 \
    --instance-type t3.micro \
    --subnet-id $SUB_ID \
    --security-group-ids $SG_ID \
    --associate-public-ip-address \
    --count 1 \
    --key-name vockey \
    --tag-specifications 'ResourceType=instance,Tags=[{Key=Name,Value=Hector-Instance}]' \
    --query Instances.InstanceId --output text)

sleep 10m

echo $EC2_ID

# En caso de NO indicar el grupo de seguridad se haría de la siguiente manera:
# aws ec2 modify-instance-attribute --instance-id $EC2_ID --groups $SG_ID
