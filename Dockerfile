FROM cdrx/pyinstaller-linux:python2

WORKDIR /app
COPY ./sources .
CMD ["pyinstaller", "-F", "add2vals.py"]