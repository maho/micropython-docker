FROM python:3

RUN apt-get update && apt-get install -y httpie jq sudo 
#     && rm -rf /var/lib/apt/lists/*

RUN pip3 install yq pyserial

COPY scripts/run-from-travis.sh /run-from-travis.sh

RUN git clone https://github.com/pfalcon/pycopy

RUN cd /pycopy && /run-from-travis.sh


CMD ["/bin/bash"]
