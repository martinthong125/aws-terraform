# aws-terraform
Using terraform as IaC in AWS


After using terraform apply to create the infrastructure, 

## 1) open terminal to run terraform commands

\# list all the resources

\> terraform state list

\# show the details of a particular resource

\> terraform state show \<resource\>

\# display your output

\> terraform output

\> terraform refresh

\# destroy one resource

\> terraform destroy -target \<resource\>

\# create one resource

\> terraform apply -target \<resource\>

## 2) open terminal to access the ubuntu server.

$ chmod 400 \<ssh-key\>.pem

$ sudo -i \<ssh-key\>.pem ubuntu@\<IP\>

$ systemctl status apache2


