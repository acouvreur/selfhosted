# See http://download.ebz.epson.net/man/linux/epsonscan2_e.html#sec5-1-4
FROM sbs20/scanservjs:v2.27.0

RUN apt-get update \
  && apt-get install -y wget

RUN wget https://download3.ebz.epson.net/dsc/f/03/00/15/17/69/0ef02802c476a6564f13cac929859c394f40326a/epsonscan2-6.7.63.0-1.src.tar.gz \
  && tar -xzvf epsonscan2-6.7.63.0-1.src.tar.gz

WORKDIR epsonscan2-6.7.63.0-1

RUN ./install-deps
RUN cmake .
RUN make
RUN make install

WORKDIR "$APP_DIR"