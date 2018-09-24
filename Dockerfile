#FROM docker.bsm.utility.valapp.com/terraform/terraform:0.10.7
FROM hashicorp/terraform:0.10.7

ADD cluster /cluster
ADD scripts /scripts
RUN /bin/terraform init /cluster

ENTRYPOINT ["/scripts/launch.sh"]

