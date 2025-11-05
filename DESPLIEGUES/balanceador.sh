#!/bin/bash
clear

# Creación VPC con salida de la ID.
VPC_ID=$(aws ec2 create-vpc --cidr-block 192.168.0.0/24 \
     --tag-specifications 'ResourceType=vpc,Tags=[{Key=Name,Value=Hector-VPC}]' \
     --query Vpc.VpcId --output text)

# En caso de estar en un entorno Lab y querer coger la VPC por defecto.
# VPC_ID=$(aws ec2 describe-vpcs --query Vpcs[0].VpcId --output text)
# SUB_ID=$(aws ec2 describe-subnets --filters "Name=availability-zone,Values=us-east-1a" --query Subnets[].SubnetId --output text)

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

## Autorización de abrir el puerto<<<<<<<<0 22 para el grupo de seguridad
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

# Almacenamos las IDs de las Instancias para no tardar más.
ID_MAQ_1="i-03c8921d92768ea35"
ID_MAQ_2="i-04e4a183325f03859"

# Añadimos ID de subred y del grupo de seguridad
aws elbv2 create-load-balancer \
   --name lb-dehector \
   --type network \
   --scheme internet-facing \
   --subnets $SUB_ID \
   --security-groups $SG_ID \
   --output text

aws elbv2 register-targets \
    --target-group-arn $SG_ID_ARN \
    --targets Id=$ID_MAQ_1 Id=$ID_MAQ_2

LIST_ARN=$(aws elbv2 create-listener \
    --load-balancer-arn $SG_ID_ARN \
    --protocol TCP \
    --port 80 \
    --default-actions Type=forward,TargetGroupArn=$SG_ID \
    --query 'Listeners[0].DNSName' --output text)