FROM python:3

ARG branch=master
ARG repo=https://github.com/micropython/micropython

RUN apt-get update && apt-get install -y httpie jq sudo 
#     && rm -rf /var/lib/apt/lists/*

RUN pip3 install yq pyserial

COPY scripts/run-from-travis.sh /run-from-travis.sh

RUN echo git clone -b ${branch} ${repo} micropython
RUN git clone -b ${branch} ${repo} micropython

RUN cd /micropython && /run-from-travis.sh


CMD ["/bin/bash"]
