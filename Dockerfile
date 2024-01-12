FROM cdrx/pyinstaller-linux:python2

WORKDIR /app
COPY ./sources .
RUN "sh pyinstaller -F add2vals.py"