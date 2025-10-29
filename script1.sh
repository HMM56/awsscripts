# Creación VPC con salida de la ID.
VPC_ID=$(aws ec2 create-vpc --cidr-block 192.168.0.0/24 \
    --tag-specifications 'ResourceType=vpc,Tags=[{Key=Name,Value=Hector-VPC}]' \
    --query Vpc.VpcId --output text)

# Mostrar el ID de la VPC creada.
echo $VPC_ID

# Habilitar el DNS en la VPC.
aws ec2 modify-vpc-attribute \
    --vpc-id $VPC_ID \
    --enable-dns-hostnames "{\"Value\":true}"


# Creación de la subred. Le damos 4 bits para subred.
SUB_ID=$(aws ec2 create-subnet \
    --vpc-id $VPC_ID \
    --cidr-block 192.168.0.0/28 \
    --tag-specifications 'ResourceType=subnet,Tags=[{Key=Name,Value=Hector-Subred}]' \
    --query Subnet.SubnetId --output text)

# Mostrar el ID de la Subred.
echo $SUB_ID

aws ec2 modify-subnet-attribute --subnet-id $SUB_ID --map-public-ip-on-launch 