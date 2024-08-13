FROM python:3.9.13-alpine3.14 AS compile-image
#the idea of a docker is to fix in space and time a thing, hence the fixed versions
RUN apk add g++=10.3.1_git20210424-r2
RUN apk add make=4.3-r0
# RUN apt add --no-cache git
RUN apk add bash=5.1.16-r0
#for the fmt util for the plumed compilation
RUN apk add coreutils=8.32-r2 
RUN apk add gcc python3-dev musl-dev linux-headers

RUN wget https://github.com/plumed/plumed2/releases/download/v2.9.0/plumed-src-2.9.0.tgz
RUN tar -zxf plumed-src-2.9.0.tgz

WORKDIR /plumed-2.9.0
RUN ./configure --prefix /plumed-build
RUN make -j6
RUN make install
RUN mkdir -p /wheels
WORKDIR /wheels
RUN pip install -U pip wheel
RUN pip wheel plumed==2.9.0
RUN pip wheel jupyterlab==4.1.6
RUN pip wheel numpy==2.0.1
# CMD ["python3", "-m", "http.server", "8080"]

FROM python:3.9.13-alpine3.14 AS run-image
COPY --from=compile-image /plumed-build /plumed-build
COPY --from=compile-image /wheels /wheels
#adding runtime dependencies, without the compilers
RUN apk add --no-cache libstdc++=10.3.1_git20210424-r2
RUN apk add --no-cache libgomp=10.3.1_git20210424-r2

RUN pip install -U pip
RUN pip install --no-index --find-links=/wheels plumed==2.9.0 jupyterlab numpy
 #psutils
RUN rm -rf /wheels
ENV PLUMED_KERNEL=/plumed-build/lib/libplumedKernel.so

EXPOSE 8888

ENTRYPOINT ["jupyter", "lab", "--ip=0.0.0.0", "--allow-root"]
# CMD ["python3", "-m", "http.server", "8080"]
