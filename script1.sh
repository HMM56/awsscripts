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


