FROM nvidia/cuda:9.0-cudnn7-devel-ubuntu16.04

MAINTAINER from www.jecing.com by jecing (hu@jecing.com)

# sources.list
RUN mv /etc/apt/sources.list /etc/apt/sources.list.bak
RUN touch /etc/apt/sources.list
RUN echo "deb http://mirrors.tuna.tsinghua.edu.cn/ubuntu/ xenial main restricted" >> /etc/apt/sources.list
RUN echo "deb http://mirrors.tuna.tsinghua.edu.cn/ubuntu/ xenial-updates main restricted" >> /etc/apt/sources.list
RUN echo "deb http://mirrors.tuna.tsinghua.edu.cn/ubuntu/ xenial universe" >> /etc/apt/sources.list
RUN echo "deb http://mirrors.tuna.tsinghua.edu.cn/ubuntu/ xenial-updates universe" >> /etc/apt/sources.list
RUN echo "deb http://mirrors.tuna.tsinghua.edu.cn/ubuntu/ xenial multiverse" >> /etc/apt/sources.list
RUN echo "deb http://mirrors.tuna.tsinghua.edu.cn/ubuntu/ xenial-updates multiverse" >> /etc/apt/sources.list
RUN echo "deb http://mirrors.tuna.tsinghua.edu.cn/ubuntu/ xenial-backports main restricted universe multiverse" >> /etc/apt/sources.list
RUN echo "deb http://mirrors.tuna.tsinghua.edu.cn/ubuntu/ xenial-security main restricted" >> /etc/apt/sources.list
RUN echo "deb http://mirrors.tuna.tsinghua.edu.cn/ubuntu/ xenial-security universe" >> /etc/apt/sources.list
RUN echo "deb http://mirrors.tuna.tsinghua.edu.cn/ubuntu/ xenial-security multiverse" >> /etc/apt/sources.list
RUN apt-get update


ENV LANG=C.UTF-8 LC_ALL=C.UTF-8

# vim
RUN apt-get install vim

# anaconda
RUN apt-get update --fix-missing && apt-get install -y wget bzip2 ca-certificates \
    libglib2.0-0 libxext6 libsm6 libxrender1 \
    git mercurial subversion
RUN echo 'export PATH=/opt/conda/bin:$PATH' > /etc/profile.d/conda.sh && \
    wget --quiet https://repo.continuum.io/archive/Anaconda3-5.0.1-Linux-x86_64.sh -O ~/anaconda.sh && \
    /bin/bash ~/anaconda.sh -b -p /opt/conda && \
    rm ~/anaconda.sh

RUN apt-get install -y curl grep sed dpkg && \
    TINI_VERSION=`curl https://github.com/krallin/tini/releases/latest | grep -o "/v.*\"" | sed 's:^..\(.*\).$:\1:'` && \
    curl -L "https://github.com/krallin/tini/releases/download/v${TINI_VERSION}/tini_${TINI_VERSION}.deb" > tini.deb && \
    dpkg -i tini.deb && \
    rm tini.deb && \
    apt-get clean
RUN echo "export PATH=\"/opt/conda/bin:$PATH\"" >> /etc/bash.bashrc
ENV PATH /opt/conda/bin:$PATH

#cuda
RUN echo "export CUDA_HOME=\"/usr/local/cuda-9.0/\"" >> /etc/bash.bashrc
RUN echo "export PATH=$PATH:$CUDA_HOME/bin" >> /etc/bash.bashrc
RUN echo "export LD_LIBRARY_PATH=$LD_LIBRARY_PATH:$CUDA_HOME/lib64" >> /etc/bash.bashrc
RUN echo "export LIBRARY_PATH=$LIBRARY_PATH:$CUDA_HOME/lib64" >> /etc/bash.bashrc
RUN apt-get install libcupti-dev
RUN pip install numpy --upgrade


#jupyter
RUN mkdir -p /root/jupyter
RUN jupyter notebook --generate-config  --allow-root
RUN echo "c.NotebookApp.ip = '*'" >> /root/.jupyter/jupyter_notebook_config.py
RUN echo "c.NotebookApp.password = 'sha1:fbc4098e99ca:30ee6637f61c1c23395795e64a6e405e056cc326'" >> /root/.jupyter/jupyter_notebook_config.py
RUN echo "c.NotebookApp.open_browser = False" >> /root/.jupyter/jupyter_notebook_config.py
RUN echo "c.NotebookApp.port =8888 " >> /root/.jupyter/jupyter_notebook_config.py
RUN echo "c.NotebookApp.notebook_dir = '/root/jupyter'" >> /root/.jupyter/jupyter_notebook_config.py


# tensorflow
RUN pip install tensorflow-gpu

# rdkit
RUN conda install -c rdkit rdkit

# ssh
RUN apt-get install -y openssh-server
RUN mkdir -p /var/run/sshd
RUN mkdir -p /root/.ssh
RUN sed -ri 's/session    required     pam_loginuid.so/# session    required     pam_loginuid.so/g' /etc/pam.d/sshd
RUN sed -ri 's/PermitRootLogin  without-password/# PermitRootLogin  without-password/g' /etc/ssh/sshd_config
RUN sed -ri 's/PermitRootLogin prohibit-password/# PermitRootLogin prohibit-password/g' /etc/ssh/sshd_config
RUN echo "PermitRootLogin    yes" >> /etc/ssh/sshd_config

# entrypoint
RUN touch /entrypoint.sh
RUN echo "#! /bin/bash" >> /entrypoint.sh
RUN echo "# start sshd server" >> /entrypoint.sh
RUN echo "/usr/sbin/sshd &" >> /entrypoint.sh
RUN echo "# start jupyter & tensorboard" >> /entrypoint.sh
RUN echo "nohup jupyter notebook --allow-root \"\$@\" &" >> /entrypoint.sh
RUN echo "nohup tensorboard --logdir=/tmp &" >> /entrypoint.sh
RUN echo "/bin/bash" >> /entrypoint.sh
RUN chmod 755 /entrypoint.sh

EXPOSE 8888 22 6006
CMD ["/entrypoint.sh"]

